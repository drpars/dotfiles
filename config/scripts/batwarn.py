#!/usr/bin/env python3
"""batwarn -- the subscriber UPower's low-battery policy was missing.

The policy was never the missing piece. /etc/UPower/UPower.conf on this machine
already says PercentageLow=20, PercentageCritical=5, PercentageAction=2 and
CriticalPowerAction=Auto, and upowerd flips the WarningLevel property on
/org/freedesktop/UPower/devices/DisplayDevice as the charge falls. What was
missing was anyone listening: no poweralertd, no batsignal, no desktop shell
(measured 2026-08-08). That is the entire reason nothing happened at 20%.

So this adds a subscriber and nothing else. It owns no thresholds: move the
numbers in UPower.conf and this follows, because it never reads a percentage to
make a decision -- only to write it into the message. Nothing here needs to
change if the policy changes.

Two ready-made subscribers were dropped. batsignal (extra) polls sysfs and
carries its own -w/-c thresholds, so it would place a second policy beside
UPower's and let the two disagree silently. poweralertd is not in the official
repos and its strings are English.

Started from hypr autostart, not a systemd user unit: graphical-session.target
is inactive on this machine (measured -- SDDM starts bare Hyprland, not uwsm),
so a unit wanting that target would never run, and wanting default.target would
need a per-machine `systemctl --user enable` plus an activation symlink inside
the repo. The session is also exactly the right lifetime: a warning is only
worth sending while mako is up to draw it.

Machines without a battery need no guard at the call site -- DisplayDevice
reports Type != Battery there and this exits at once.
"""

import fcntl
import os
import sys

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib  # noqa: E402

# Held for the life of the process, so a second copy exits instead of doubling
# every warning. It is worth having because logind here does not kill user
# processes at logout (KillUserProcesses=no): without the lock, one relogin
# would be enough to leave the old instance running beside the new one.
LOCK_PATH = os.path.join(
    os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "batwarn.lock")
_lock_handle = None

UPOWER = "org.freedesktop.UPower"
DISPLAY_DEVICE = "/org/freedesktop/UPower/devices/DisplayDevice"
DEVICE_IFACE = "org.freedesktop.UPower.Device"

NOTIFY_NAME = "org.freedesktop.Notifications"
NOTIFY_PATH = "/org/freedesktop/Notifications"
NOTIFY_IFACE = "org.freedesktop.Notifications"

# org.freedesktop.UPower.Device enums. Level 2 (Discharging) is UPS-only and
# never appears on a laptop battery; anything not in MESSAGES counts as "no
# warning", which is how the level falling back to None clears the notification.
TYPE_BATTERY = 2
LOW, CRITICAL, ACTION = 3, 4, 5

URGENCY_NORMAL, URGENCY_CRITICAL = 1, 2

# Timeouts are passed explicitly instead of leaning on mako's default-timeout,
# so how long a warning stays on screen is a property of the warning. Zero means
# "until dismissed" -- correct for the two levels where the machine is about to
# act on its own. mako keeps everything in its history either way.
MESSAGES = {
    LOW: ("Pil azalıyor", "", URGENCY_NORMAL, 20000),
    CRITICAL: ("Pil kritik", " Fişe takın.", URGENCY_CRITICAL, 0),
    # UPower runs CriticalPowerAction itself at this level. Measured 2026-08-23,
    # and both halves of what used to stand here were wrong. Auto does not
    # resolve to hybrid-sleep: GetCriticalAction() answers "Sleep", which is
    # logind's Sleep(), which takes the first supported entry of
    # SleepOperation= -- unset here, so the documented default order applies and
    # suspend-then-hibernate wins. And it has fired on this machine, in a test
    # that raised PercentageAction above the current charge: upowerd asked
    # logind, the machine spent 163 s hibernated and came back with boot_id
    # unchanged. The text still promises sleep rather than a method, because the
    # method is three defaults deep and any of them can change without saying so.
    ACTION: ("Pil tükendi", " Sistem birazdan kendini uyutacak.",
             URGENCY_CRITICAL, 0),
}


def fmt_time(seconds):
    """'1 sa 23 dk' / '26 dk'. Empty when UPower has no estimate yet (0)."""
    if not seconds or seconds < 0:
        return ""
    minutes = int(seconds // 60)
    if minutes >= 60:
        return f"{minutes // 60} sa {minutes % 60} dk"
    return f"{minutes} dk"


class BatWarn:
    def __init__(self):
        self.system_bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)
        self.session_bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
        # A proxy rather than a raw signal subscription, for one thing the
        # subscription does not give: it tracks who owns the name, which is how
        # an upowerd restart is noticed at all (see _on_owner_changed).
        self.device = Gio.DBusProxy.new_sync(
            self.system_bus, Gio.DBusProxyFlags.NONE, None,
            UPOWER, DISPLAY_DEVICE, DEVICE_IFACE, None)
        self.device.connect("g-properties-changed", self._on_changed)
        self.device.connect("notify::g-name-owner", self._on_owner_changed)
        self.level = None
        self.notification_id = 0

    def _get(self, name, default=None):
        """Read a property off the bus instead of the proxy's cache.

        The cache is right for detecting a change and wrong for reading one: it
        is refilled asynchronously after a name-owner change, so a value read
        during that window is either the vanished daemon's or missing. This runs
        only when the level actually changes, so the extra round trip is free.
        """
        try:
            reply = self.system_bus.call_sync(
                UPOWER, DISPLAY_DEVICE, "org.freedesktop.DBus.Properties",
                "Get", GLib.Variant("(ss)", (DEVICE_IFACE, name)),
                GLib.VariantType("(v)"), Gio.DBusCallFlags.NONE, 5000, None)
        except GLib.Error:
            return default
        return reply.unpack()[0]

    def _on_changed(self, _proxy, changed, _invalidated):
        # Discharging emits PropertiesChanged every few seconds for Percentage
        # and TimeToEmpty. Only WarningLevel is acted on: re-sending the message
        # on every percentage tick would re-fire mako's on-notify sound, which
        # runs a command per notification.
        changes = changed.unpack()
        if "WarningLevel" in changes:
            self.apply(changes["WarningLevel"])

    def _on_owner_changed(self, *_):
        """upowerd came back -- re-evaluate, because nothing else will.

        Measured 2026-08-09: with the threshold already crossed,
        `systemctl restart upower` produced no notification at all. The proxy
        stays alive and keeps its socket, but the new daemon never re-announces
        a level it did not change, and the cache reload that follows a
        name-owner change does not arrive as PropertiesChanged. Without this the
        subscriber goes deaf at every upower upgrade until the next login.
        """
        if self.device.get_name_owner() is None:
            return  # gone, not back yet: wait for the second half of the swap
        self.level = None
        self.apply(self._get("WarningLevel"))

    def apply(self, level):
        if level == self.level:
            return
        self.level = level
        if level not in MESSAGES:
            self.clear()
            return
        summary, tail, urgency, timeout = MESSAGES[level]
        remaining = fmt_time(self._get("TimeToEmpty", 0))
        percentage = f"%{self._get('Percentage', 0):.0f}"
        body = (f"{percentage} — yaklaşık {remaining} kaldı.{tail}"
                if remaining else f"{percentage}.{tail}")
        self.notify(summary, body, self._get("IconName", ""), urgency, timeout)

    def notify(self, summary, body, icon, urgency, timeout):
        hints = {
            "urgency": GLib.Variant("y", urgency),
            "category": GLib.Variant("s", "device"),
        }
        args = GLib.Variant("(susssasa{sv}i)", (
            "Pil", self.notification_id, icon, summary, body, [], hints, timeout))
        reply = self._call("Notify", args, GLib.VariantType("(u)"))
        if reply is not None:
            # Reusing the id means Low -> Critical replaces in place instead of
            # stacking, and gives clear() something to close.
            self.notification_id = reply.unpack()[0]

    def clear(self):
        if not self.notification_id:
            return
        # Charging again, or simply back above the threshold. A timeout of 0 was
        # handed out at the critical levels, so without this the warning would
        # sit on screen after it stopped being true.
        self._call("CloseNotification",
                   GLib.Variant("(u)", (self.notification_id,)), None)
        self.notification_id = 0

    def _call(self, method, args, reply_type):
        try:
            return self.session_bus.call_sync(
                NOTIFY_NAME, NOTIFY_PATH, NOTIFY_IFACE, method, args,
                reply_type, Gio.DBusCallFlags.NONE, 5000, None)
        except GLib.Error as err:
            # No notification server yet (autostart races mako) or it died. The
            # next level change tries again; a battery warning is not worth
            # taking the process down for. Hyprland gives its children
            # fd1=fd2=/dev/null, so this line is for running it by hand.
            print(f"batwarn: {method} basarisiz: {err.message}", file=sys.stderr)
            return None

    def run(self):
        if self._get("Type") != TYPE_BATTERY:
            return 0  # desktop: no battery behind the composite device
        # Deliberately notifies when the session starts already low, instead of
        # only on a transition: logging in at 12% is exactly when the message is
        # worth having, and the level will not change again on its way down.
        self.apply(self._get("WarningLevel"))
        GLib.MainLoop().run()
        return 0


def single_instance():
    """False when another copy already holds the lock.

    The handle is parked in a module global rather than left local: flock lives
    on the open file description, so letting the local fall out of scope closes
    the file and drops the lock the moment this function returns. Measured --
    the first version did exactly that and a second copy started happily.
    """
    global _lock_handle
    handle = open(LOCK_PATH, "w")
    try:
        fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        return False
    _lock_handle = handle
    return True


def main():
    if not single_instance():
        return 0
    try:
        return BatWarn().run()
    except GLib.Error as err:
        print(f"batwarn: UPower'a baglanilamadi: {err.message}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
