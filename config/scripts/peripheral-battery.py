#!/usr/bin/env python3
"""Waybar peripheral battery module.

Reports the Razer peripheral (via the openrazer daemon) and the Logitech mouse
(via the kernel's hidpp power_supply node) battery levels. Designed to back a
waybar drawer group:

    peripheral-battery.py kbd       -> openrazer device JSON
    peripheral-battery.py mouse     -> hidpp power_supply JSON
    peripheral-battery.py summary   -> combined trigger JSON (tooltip = both)

The `kbd` verb and the `custom/keyboard-battery` module name are the openrazer
*slot*, not a claim about the device in it: this laptop's Razer device is a
mouse. The glyph follows what openrazer reports the device to be, so the slot
name never reaches the bar.

Each call prints a single waybar JSON object: {text, tooltip, class, percentage}.

When a device is not reachable -- no openrazer, no hidpp node, nothing paired --
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

# Matched as a substring against the power_supply node's own model_name, which
# reads exactly "G502 X PLUS" on PANTHERA-ARCH.
MOUSE_CODENAME = "G502 X PLUS"

KBD_GLYPH = "\U000f030c"    # 󰌌  keyboard
MOUSE_GLYPH = "\U000f037d"  # 󰍽  mouse

# Discharging battery glyphs by 10% bucket (index 0 = 0-9%, 10 = 100%).
_BATT = ["\U000f007a", "\U000f007a", "\U000f007b", "\U000f007c", "\U000f007d",
         "\U000f007e", "\U000f007f", "\U000f0080", "\U000f0081", "\U000f0082",
         "\U000f0079"]
_CHARGING = "\U000f0084"   # 󰂄
_UNKNOWN = "\U000f0091"    # 󰂑

# openrazer's DeviceManager reports a device class (measured on this laptop:
# type == "mouse"); only these two glyphs are verified present in the bar font,
# so anything else falls back to the unknown-battery glyph rather than to a
# guessed codepoint or -- worse -- to a glyph that names the wrong device.
RAZER_GLYPHS = {"keyboard": KBD_GLYPH, "mouse": MOUSE_GLYPH}


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


def read_razer():
    """(glyph, name, level, charging) for the Razer device, or (…, None, None)."""
    try:
        from openrazer.client import DeviceManager
        for d in DeviceManager().devices:
            if d.has("battery"):
                glyph = RAZER_GLYPHS.get(getattr(d, "type", None), _UNKNOWN)
                return glyph, d.name, int(d.battery_level), bool(d.is_charging)
    except Exception:
        pass
    return _UNKNOWN, None, None, None


# The kernel's hid-logitech-hidpp driver publishes the HID++ battery as an
# ordinary power_supply device, so the level is a file read rather than a
# `solaar show` subprocess. Speed is the smaller half of why: measured on
# PANTHERA-ARCH, solaar takes 2.19-3.04 s and a sysfs read 0.015 ms. The half
# that matters is contention. All three modules of group/peripherals share one
# 300 s interval, so they fire together; three concurrent solaar calls lost the
# race in 5 of 15 measured reads and came back with no battery line at all. A
# losing module reads that as "no mouse", which flips its sibling's `solo` cap
# -- and the wrong shape then sits on the bar until the next poll. Reading a
# file has no such race, so the three modules can no longer disagree about the
# rendered set.
#
# The node index is not stable across reconnects, so the device is found by its
# own model_name rather than by hidpp_battery_0. No node at all means no mouse,
# which is exactly what this laptop reports (it has neither the mouse nor the
# driver's device) -- the same answer solaar used to give by being absent.
HIDPP_GLOB = "/sys/class/power_supply/hidpp_battery_*"


def _attr(path, name):
    with open(os.path.join(path, name)) as fh:
        return fh.read().strip()


def read_mouse():
    """(name, level, charging) for the Logitech mouse, or (None, None, None)."""
    for path in sorted(glob.glob(HIDPP_GLOB)):
        try:
            name = _attr(path, "model_name")
        except OSError:
            continue
        if MOUSE_CODENAME not in name:
            continue
        try:
            return name, int(_attr(path, "capacity")), _attr(path, "status") == "Charging"
        except (OSError, ValueError):
            # The device is known but its reading is not; a hidden child, not
            # a missing one. Same shape as the openrazer branch above.
            return name, None, None
    return None, None, None


# Waybar hides a custom module whose text is empty.
HIDDEN = {"text": ""}


def device_obj(glyph, name, level, charging, solo=False):
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
                   + (" (şarjda)" if charging else ""),
        "class": classes,
        "percentage": level if level is not None else 0,
    }


def main():
    what = sys.argv[1] if len(sys.argv) > 1 else "summary"

    if what in ("kbd", "mouse"):
        # Both devices are read even though only one is reported: the caps are a
        # property of the rendered set, not of the device (see module docstring).
        k_glyph, k_name, k_lvl, k_chg = read_razer()
        m_name, m_lvl, m_chg = read_mouse()
        solo = (k_lvl is None) != (m_lvl is None)
        if what == "kbd":
            print(json.dumps(device_obj(k_glyph, k_name, k_lvl, k_chg, solo)))
        else:
            print(json.dumps(device_obj(MOUSE_GLYPH, m_name, m_lvl, m_chg, solo)))
        return

    # summary: one trigger icon driven by the lower of the two levels, with a
    # tooltip listing both peripherals.
    k_glyph, k_name, k_lvl, k_chg = read_razer()
    m_name, m_lvl, m_chg = read_mouse()

    # Hiçbiri okunamıyorsa bu makinede bu çevre birimleri yok: gizlen.
    if k_lvl is None and m_lvl is None:
        print(json.dumps(HIDDEN))
        return

    # The tooltip lists the RENDERED SET, same as the caps do: a device whose
    # level is None is a hidden child, so a line for it would describe something
    # the drawer never draws. It would also be wrong about what is missing --
    # on this laptop there is no hidpp node at all, so "Fare: ?" read as a flat
    # battery when there is no mouse to have one. The guard above is what keeps
    # this list from ever coming out empty.
    lines = [
        f"{glyph}  {name}: {lvl}%" + (" (şarjda)" if chg else "")
        for glyph, name, lvl, chg in (
            (k_glyph, k_name, k_lvl, k_chg),
            (MOUSE_GLYPH, m_name, m_lvl, m_chg),
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
