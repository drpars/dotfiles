#!/usr/bin/env python3
"""Waybar peripheral battery module.

Reports the Razer keyboard (via the openrazer daemon) and the Logitech mouse
(via solaar) battery levels. Designed to back a waybar drawer group:

    peripheral-battery.py kbd       -> keyboard JSON
    peripheral-battery.py mouse     -> mouse JSON
    peripheral-battery.py summary   -> combined trigger JSON (tooltip = both)

Each call prints a single waybar JSON object: {text, tooltip, class, percentage}.
"""

import json
import re
import subprocess
import sys

# Device matched by substring against solaar's "Codename" line.
MOUSE_CODENAME = "G502 X PLUS"

KBD_GLYPH = "\U000f030c"    # 󰌌  keyboard
MOUSE_GLYPH = "\U000f037d"  # 󰍽  mouse

# Discharging battery glyphs by 10% bucket (index 0 = 0-9%, 10 = 100%).
_BATT = ["\U000f007a", "\U000f007a", "\U000f007b", "\U000f007c", "\U000f007d",
         "\U000f007e", "\U000f007f", "\U000f0080", "\U000f0081", "\U000f0082",
         "\U000f0079"]
_CHARGING = "\U000f0084"   # 󰂄
_UNKNOWN = "\U000f0091"    # 󰂑


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


def read_keyboard():
    """(name, level, charging) for the Razer keyboard, or (None, None, None)."""
    try:
        from openrazer.client import DeviceManager
        for d in DeviceManager().devices:
            if d.has("battery"):
                return d.name, int(d.battery_level), bool(d.is_charging)
    except Exception:
        pass
    return None, None, None


def read_mouse():
    """(name, level, charging) for the Logitech mouse, or (None, None, None)."""
    try:
        out = subprocess.run(
            ["solaar", "show", MOUSE_CODENAME],
            capture_output=True, text=True, timeout=10,
        ).stdout
    except Exception:
        return None, None, None

    m = re.search(r"Battery:\s*(\d+)%,\s*BatteryStatus\.(\w+)", out)
    if not m:
        return MOUSE_CODENAME, None, None
    level = int(m.group(1))
    status = m.group(2).upper()
    charging = "CHARG" in status and "DISCHARG" not in status
    return MOUSE_CODENAME, level, charging


def device_obj(glyph, name, level, charging):
    pct = "?" if level is None else f"{level}%"
    return {
        "text": f"{glyph} {pct}",
        "tooltip": f"{name or 'cihaz yok'}: {pct}"
                   + (" (şarjda)" if charging else ""),
        "class": level_class(level, charging),
        "percentage": level if level is not None else 0,
    }


def main():
    what = sys.argv[1] if len(sys.argv) > 1 else "summary"

    if what == "kbd":
        name, level, charging = read_keyboard()
        print(json.dumps(device_obj(KBD_GLYPH, name, level, charging)))
        return

    if what == "mouse":
        name, level, charging = read_mouse()
        print(json.dumps(device_obj(MOUSE_GLYPH, name, level, charging)))
        return

    # summary: one trigger icon driven by the lower of the two levels, with a
    # tooltip listing both peripherals.
    k_name, k_lvl, k_chg = read_keyboard()
    m_name, m_lvl, m_chg = read_mouse()

    lines = [
        f"{KBD_GLYPH}  {k_name or 'Klavye yok'}: "
        f"{'?' if k_lvl is None else str(k_lvl) + '%'}"
        + (" (şarjda)" if k_chg else ""),
        f"{MOUSE_GLYPH}  {m_name or 'Fare yok'}: "
        f"{'?' if m_lvl is None else str(m_lvl) + '%'}"
        + (" (şarjda)" if m_chg else ""),
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
