#!/usr/bin/env python3
"""Waybar peripheral battery module.

Reports the Razer peripheral and the Logitech mouse battery levels. Both come
straight from sysfs, so no daemon and no python binding sit between the bar and
the kernel; see each reader for which node and why it beat the userspace path.
Designed to back a waybar drawer group:

    peripheral-battery.py kbd       -> razer* driver attribute JSON
    peripheral-battery.py mouse     -> kernel power_supply JSON
    peripheral-battery.py summary   -> combined trigger JSON (tooltip = both)

Both verb names are *channel* slots, not claims about the device in them. `kbd`
is whatever openrazer's out-of-tree driver has claimed -- on this laptop that is
a mouse -- and `mouse` is whatever the kernel itself exports as a peripheral
battery. Each slot works out its own glyph, so neither verb reaches the bar.

The slot COUNT is fixed at two on purpose. waybar reads its module set from
modules.json once at startup, so a device-driven set would mean regenerating
that file and restarting the bar, and that chain has taken the bar down twice
in this repo. Two channels cover what these machines have.

Each call prints a single waybar JSON object: {text, tooltip, class, percentage}.

When a device is not reachable -- no razer node, no hidpp node, nothing paired --
the object is printed with an empty text, which is waybar's way of hiding a
custom module. That is what keeps the drawer out of the bar on machines
without these peripherals, so the same config works everywhere and nothing
has to be commented out per machine.

A hidden module also takes its CSS margin with it, and the rounded caps of the
children pill are pinned to a device in style.css (keyboard = left cap, mouse =
right cap + gap). So each child has to know the whole *rendered set*, not just
its own device: when it is the only visible child it emits an extra `solo`
class and style.css gives it a full capsule. waybar cannot work this out on its
own -- see the `.solo` rule for why structural CSS selectors cannot see sibling
modules.
"""

import glob
import json
import os
import sys
import time

KBD_GLYPH = "\U000f030c"    # 󰌌  keyboard
MOUSE_GLYPH = "\U000f037d"  # 󰍽  mouse

# Discharging battery glyphs by 10% bucket (index 0 = 0-9%, 10 = 100%).
_BATT = ["\U000f007a", "\U000f007a", "\U000f007b", "\U000f007c", "\U000f007d",
         "\U000f007e", "\U000f007f", "\U000f0080", "\U000f0081", "\U000f0082",
         "\U000f0079"]
_CHARGING = "\U000f0084"   # 󰂄
_UNKNOWN = "\U000f0091"    # 󰂑

# The device class comes from the driver bound to the HID device, which is the
# class itself: razermouse on this laptop, razerkbd on the desktop. Only these
# two glyphs are verified present in the bar font, so anything else falls back
# to the unknown-battery glyph rather than to a guessed codepoint or -- worse --
# to a glyph that names the wrong device.
#
# The driver name is brand-specific and it stays, because nothing generic gets
# this right. Four standard channels were read on both machines (2026-08-22) and
# all four call the battery-carrying interface of the DeathStalker KEYBOARD a
# mouse: udev ID_INPUT_*, the raw capabilities bitmaps, the USB boot protocol
# (bInterfaceProtocol=02), and the interface's own HID report descriptor
# (top-level usage Generic Desktop/Mouse). openrazer hangs charge_level on the
# interface that carries its vendor reports, and on both machines that interface
# declares a mouse collection. Measurement -> ../../pars notes, arsiv-2026-08 (58).
RAZER_GLYPHS = {"keyboard": KBD_GLYPH, "mouse": MOUSE_GLYPH}
RAZER_DRIVERS = {"razermouse": "mouse", "razerkbd": "keyboard"}


def batt_glyph(level, charging):
    if level is None:
        return _UNKNOWN
    if charging:
        return _CHARGING
    return _BATT[max(0, min(10, level // 10))]


def level_class(level, charging):
    if level is None:
        return "unknown"
    if charging:
        return "charging"
    if level <= 15:
        return "critical"
    if level <= 30:
        return "low"
    return "normal"


# openrazer's out-of-tree driver claims these devices, so unlike the Logitech
# mouse they get no power_supply node; the driver publishes its own attributes
# on the HID device instead. Reading them needs neither the daemon nor
# python-openrazer, which is the point: measured with the daemon stopped and
# its PID gone from /proc, charge_level returned the same 184 thirty times out
# of thirty, at the same 72 ms, and the read did not DBus-activate the daemon
# back. That closes the failure this file already paid for once -- the python
# binding was swept as an orphan and the whole bar section went dark in silence.
#
# The attributes are root:openrazer 0440, so the user must be in the openrazer
# group; the package's own scriptlet creates it and both machines are in it.
# device_type carries the same friendly name the daemon reports, verbatim.
RAZER_GLOB = "/sys/bus/hid/devices/*"


# charge_level reads 0 when the device does not answer, and that is not a
# battery reading -- rendering it would put a red 0% on the bar for a device
# that is merely quiet. How long it lasts was measured on both machines, after
# 150 s of no reads, sampling every 20 ms:
#
#   razerkbd  (desktop) 4 trials: two clean, two with a single 0 then the value
#   razermouse (laptop) 4 trials: three clean, one where ALL EIGHT reads were 0
#                                 -- about 290 ms of nothing but zeros
#
# So neither "read twice" nor a short retry loop covers it; both were tried and
# both were refuted by the numbers above. The daemon hid this by polling on its
# own and keeping the value warm, which is exactly the job that has to move here
# now that it is out of the path: remember the last real reading and serve it
# while the device is quiet. The tooltip says when it is doing that, so a value
# on the bar is never silently older than it looks.
CACHE = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"),
                     "waybar-razer-battery.json")


def _cache_load():
    try:
        with open(CACHE) as fh:
            d = json.load(fh)
        return int(d["level"]), bool(d["charging"]), float(d["ts"])
    except (OSError, ValueError, KeyError, TypeError):
        return None, None, None


def _cache_store(level, charging):
    # All three modules share one interval and fire together, so the write has
    # to be atomic or a reader can catch a half-written file. Unique temp name
    # per process, then rename.
    tmp = "%s.%d" % (CACHE, os.getpid())
    try:
        with open(tmp, "w") as fh:
            json.dump({"level": level, "charging": charging, "ts": time.time()}, fh)
        os.replace(tmp, CACHE)
    except OSError:
        try:
            os.unlink(tmp)
        except OSError:
            pass


# The zero is the driver reporting a timeout, not a battery reading. Read the
# source: razer_attr_read_charge_level ends in a bare razer_send_payload()
# whose return value it drops, then prints response.arguments[1]
# (razermouse_driver.c:1475); the timeout branch of razer_send_payload
# (:121) leaves that response zeroed. So every failure on this channel reads
# as 0 -- there is no path that hands back a wrong non-zero level.
#
# A zero comes in two lengths and this loop only covers the short one. Read
# back to back while the device is awake, razerkbd gives one or two zeros and
# then the real value inside ~12 ms, and catching that is worth the wait: the
# three modules fire together, and a module that gives up hides its child while
# its sibling still shows one -- the cap mismatch this file already fixed once.
# One step covers a 12 ms settle four times over, which is why there is only one.
#
# The long kind is not a cold cache, it is a device that has stopped answering,
# and more steps do not reach it. Every razermouse timeout the kernel logged
# over the driver's whole life on this laptop was counted (8737 of them,
# 2026-08-15 install to 2026-08-22): the quiet runs in episodes of median 39 s,
# p90 53 min, longest 3.4 h, and inside one of those every poll fails -- 1259
# consecutive at the longest. A five-step budget was tried and measured to buy
# nothing there: in the 24 minutes it was live, the bar entered it five times
# and all five spent it in full, 18 reads across the three modules and ~0.85 s
# of USB traffic to a sleeping mouse, with no partial win anywhere in the log
# (no burst between 2 and 17 reads exists). The cache below is what carries the
# display through; the only case neither covers is a device asleep before it
# was ever read once. A step is spent only when the answer is 0.
RETRY_STEP = 0.05
RETRY_STEPS = 1


def _razer_raw(path):
    raw = int(_attr(path, "charge_level"))
    for _ in range(RETRY_STEPS):
        if raw:
            break
        time.sleep(RETRY_STEP)
        raw = int(_attr(path, "charge_level"))
    return raw


def _razer_level(path):
    """(percentage, charging, age_seconds) -- age is None for a fresh reading."""
    raw = _razer_raw(path)
    if raw:
        level = round(raw / 255 * 100)
        charging = _attr(path, "charge_status") == "1"
        _cache_store(level, charging)
        return level, charging, None
    level, charging, ts = _cache_load()
    if level is None:
        return None, None, None
    return level, charging, time.time() - ts


def read_razer():
    """(glyph, name, level, charging, note) -- note flags a cache-served value."""
    for path in sorted(glob.glob(RAZER_GLOB)):
        if not os.path.exists(os.path.join(path, "charge_level")):
            continue
        try:
            driver = os.path.basename(os.path.realpath(os.path.join(path, "driver")))
            glyph = RAZER_GLYPHS.get(RAZER_DRIVERS.get(driver), _UNKNOWN)
            name = _attr(path, "device_type")
        except OSError:
            return _UNKNOWN, None, None, None, None
        try:
            level, charging, age = _razer_level(path)
        except (OSError, ValueError):
            # Device known, reading not: a hidden child, not a missing one.
            return glyph, name, None, None, None
        note = None if age is None else "uyanmadı, %d dk önce" % (age // 60)
        return glyph, name, level, charging, note
    return _UNKNOWN, None, None, None, None


# The kernel publishes a peripheral battery as an ordinary power_supply device,
# so the level is a file read rather than a `solaar show` subprocess. Speed is
# the smaller half of why: measured on PANTHERA-ARCH, solaar takes 2.19-3.04 s
# and a sysfs read 0.015 ms. The half
# that matters is contention. All three modules of group/peripherals share one
# 300 s interval, so they fire together; three concurrent solaar calls lost the
# race in 5 of 15 measured reads and came back with no battery line at all. A
# losing module reads that as "no mouse", which flips its sibling's `solo` cap
# -- and the wrong shape then sits on the bar until the next poll. Reading a
# file has no such race, so the three modules can no longer disagree about the
# rendered set.
#
# The node is found by what it IS, not by what it is called: type=Battery plus
# scope=Device is the kernel's own marker for "this battery belongs to a
# peripheral, not to the machine". Measured on both machines -- the desktop's
# hidpp_battery_0 is the only node that matches, and the laptop's BAT0 and ADP0
# have no scope file at all (absent, not "System"), so they are skipped by the
# read failing rather than by a name test. That is what un-nails this slot from
# one model: it used to match the substring "G502 X PLUS" against model_name, so
# any other mouse simply went missing from the bar.
#
# No matching node means no such peripheral, which is exactly what this laptop
# reports -- the same answer solaar used to give by being absent.
PSU_GLOB = "/sys/class/power_supply/*"


def _attr(path, name):
    with open(os.path.join(path, name)) as fh:
        return fh.read().strip()


# With the model nailed down no glyph question arose; a generic slot has to ask
# one. udev's own mouse test is "has REL_X and REL_Y", and that is a file read
# here rather than a udevadm subprocess: bits 0 and 1 of capabilities/rel.
# Measured on the G502 (rel=1943, both bits set) and against a plain keyboard
# (AT Translated Set 2, rel=0). Only the mouse branch has a real peripheral
# behind it -- no wireless keyboard was on this channel to measure -- so a
# device with keys and no rel axes gets the keyboard glyph as an inference, and
# anything with neither falls back to unknown rather than to a guessed glyph.
def _class_glyph(psu_path):
    for inp in sorted(glob.glob(os.path.join(psu_path, "device", "input", "input*"))):
        try:
            rel = int(_attr(inp, "capabilities/rel").split()[-1], 16)
            key = int(_attr(inp, "capabilities/key").split()[-1], 16)
        except (OSError, ValueError, IndexError):
            continue
        if rel & 0x3:
            return MOUSE_GLYPH
        if key:
            return KBD_GLYPH
    return _UNKNOWN


def read_mouse():
    """(glyph, name, level, charging) for the kernel-side peripheral battery."""
    for path in sorted(glob.glob(PSU_GLOB)):
        try:
            if _attr(path, "type") != "Battery" or _attr(path, "scope") != "Device":
                continue
        except OSError:
            # A system battery has no scope file at all; that is the skip.
            continue
        try:
            name = _attr(path, "model_name")
        except OSError:
            name = os.path.basename(path)
        glyph = _class_glyph(path)
        try:
            return (glyph, name, int(_attr(path, "capacity")),
                    _attr(path, "status") == "Charging")
        except (OSError, ValueError):
            # The device is known but its reading is not; a hidden child, not
            # a missing one. Same shape as the openrazer branch above.
            return glyph, name, None, None
    return _UNKNOWN, None, None, None


# Waybar hides a custom module whose text is empty.
HIDDEN = {"text": ""}


def device_obj(glyph, name, level, charging, solo=False, note=None):
    if level is None:
        return HIDDEN
    pct = f"{level}%"
    # waybar accepts a string or an array here (src/modules/custom.cpp), and it
    # clears the previous classes on every update, so the array is safe.
    classes = [level_class(level, charging)]
    if solo:
        classes.append("solo")
    return {
        "text": f"{glyph} {pct}",
        "tooltip": f"{name or 'cihaz yok'}: {pct}"
                   + (" (şarjda)" if charging else "")
                   + (f" ({note})" if note else ""),
        "class": classes,
        "percentage": level if level is not None else 0,
    }


def main():
    what = sys.argv[1] if len(sys.argv) > 1 else "summary"

    if what in ("kbd", "mouse"):
        # Both devices are read even though only one is reported: the caps are a
        # property of the rendered set, not of the device (see module docstring).
        k_glyph, k_name, k_lvl, k_chg, k_note = read_razer()
        m_glyph, m_name, m_lvl, m_chg = read_mouse()
        solo = (k_lvl is None) != (m_lvl is None)
        if what == "kbd":
            print(json.dumps(device_obj(k_glyph, k_name, k_lvl, k_chg, solo, k_note)))
        else:
            print(json.dumps(device_obj(m_glyph, m_name, m_lvl, m_chg, solo)))
        return

    # summary: one trigger icon driven by the lower of the two levels, with a
    # tooltip listing both peripherals.
    k_glyph, k_name, k_lvl, k_chg, k_note = read_razer()
    m_glyph, m_name, m_lvl, m_chg = read_mouse()

    # Hiçbiri okunamıyorsa bu makinede bu çevre birimleri yok: gizlen.
    if k_lvl is None and m_lvl is None:
        print(json.dumps(HIDDEN))
        return

    # The tooltip lists the RENDERED SET, same as the caps do: a device whose
    # level is None is a hidden child, so a line for it would describe something
    # the drawer never draws. It would also be wrong about what is missing --
    # this laptop exports no peripheral battery at all, so "Fare: ?" read as a
    # flat battery when there is no mouse to have one. The guard above is what keeps
    # this list from ever coming out empty.
    lines = [
        f"{glyph}  {name}: {lvl}%" + (" (şarjda)" if chg else "")
                                   + (f" ({note})" if note else "")
        for glyph, name, lvl, chg, note in (
            (k_glyph, k_name, k_lvl, k_chg, k_note),
            (m_glyph, m_name, m_lvl, m_chg, None),
        )
        if lvl is not None
    ]

    levels = [(l, c) for l, c in ((k_lvl, k_chg), (m_lvl, m_chg)) if l is not None]
    if levels:
        low_lvl, low_chg = min(levels, key=lambda x: x[0])
        text = batt_glyph(low_lvl, low_chg)
        klass = level_class(low_lvl, low_chg)
    else:
        text = _UNKNOWN
        klass = "unknown"

    print(json.dumps({"text": text, "tooltip": "\n".join(lines),
                      "class": klass, "percentage": levels and min(l for l, _ in levels) or 0}))


if __name__ == "__main__":
    main()
