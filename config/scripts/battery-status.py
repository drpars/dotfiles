#!/usr/bin/env python3

import json
import re
import subprocess
import sys
import time
from typing import Any, Dict, Optional

# Cache değişkenleri
_mouse_cache: Optional[Dict[str, Any]] = None
_keyboard_cache: Optional[Dict[str, Any]] = None

def get_solaar_battery() -> Optional[Dict[str, Any]]:
    """Logitech mouse bataryasını Solaar ile al"""
    try:
        result = subprocess.run(
            ["solaar", "show"], capture_output=True, text=True, timeout=5
        )
        output = result.stdout

        # Solaar çıktısında fareyi bul (Wired modda Receiver listesinde olmayabilir)
        mouse_match = re.search(r"^\s*\d+:\s+(.+?)$", output, re.MULTILINE)
        if not mouse_match:
            return None

        mouse_name = mouse_match.group(1).strip()
        battery_match = re.search(
            r"(?:Battery|Batarya):\s*(\d+)%", output, re.IGNORECASE
        )
        
        # Solaar çıktısında şarj veya kablolu durumunu tespit et
        is_wired = bool(re.search(r"(charging|şarj|offline)", output, re.IGNORECASE))
        battery = int(battery_match.group(1)) if battery_match else (100 if is_wired else None)

        if battery is not None or is_wired:
            return {"name": mouse_name, "battery": battery, "type": "mouse", "is_wired": is_wired}
            
    except Exception as e:
        print(f"Solaar error: {e}", file=sys.stderr)
        
    return None

def get_razer_battery() -> Optional[Dict[str, Any]]:
    """Razer klavye bataryasını razer-cli ile al"""
    try:
        # Önce kablosuz (Wireless) model adıyla sorgula
        wireless = subprocess.run(
            ["razer-cli", "-d", "Razer DeathStalker V2 Pro TKL (Wireless)", "--battery", "print"],
            capture_output=True, text=True, timeout=5
        )
        output = wireless.stdout + wireless.stderr
        is_wired = False

        # Eğer kablosuz cihaz bulunamazsa, klavye kabloyla bağlanmış olabilir. Kablolu adıyla dene:
        if not output.strip() or "No device found" in output:
            wired = subprocess.run(
                ["razer-cli", "-d", "Razer DeathStalker V2 Pro TKL", "--battery", "print"],
                capture_output=True, text=True, timeout=5
            )
            output = wired.stdout + wired.stderr
            is_wired = True

        if output.strip() and "No device found" not in output:
            charge_match = re.search(r"charge:\s*(\d+)", output)
            battery = int(charge_match.group(1)) if charge_match else (100 if is_wired else None)
            
            if battery is not None or is_wired:
                return {
                    "name": "DeathStalker V2 Pro",
                    "battery": battery,
                    "type": "keyboard",
                    "is_wired": is_wired,
                }
                
    except Exception as e:
        print(f"Razer error: {e}", file=sys.stderr)
        
    return None

def get_battery_icon(battery: Optional[int], is_wired: bool) -> str:
    """Batarya seviyesine göre ikon döndür"""
    if is_wired:
        return ""  # Şarj oluyor / Kablolu bağlı ikonu
    if battery is None:
        return "󱉺"  # Hata / Bilgi yok
    if battery >= 80:
        return ""
    if battery >= 60:
        return ""
    if battery >= 40:
        return ""
    if battery >= 20:
        return ""
    return ""

def get_battery_class(battery: Optional[int], is_wired: bool) -> str:
    """Batarya seviyesine göre CSS class döndür"""
    if is_wired:
        return "charging" # waybar CSS dosyanızda ".charging" için özel renk verebilirsiniz
    if battery is None:
        return "na"
    if battery >= 80:
        return "high"
    if battery >= 60:
        return "medium-high"
    if battery >= 40:
        return "medium"
    if battery >= 20:
        return "low"
    return "critical"

def format_percentage(battery: Optional[int], is_wired: bool) -> str:
    """Yüzde değerini formatla (Kabloluysa belirt)"""
    if is_wired and battery is not None:
        return f"%{battery} "
    elif is_wired:
        return "Kablolu "
    return f"%{battery}" if battery is not None else "?"

def update_cache() -> None:
    """Cache'leri güncelle"""
    global _mouse_cache, _keyboard_cache
    _mouse_cache = get_solaar_battery()
    _keyboard_cache = get_razer_battery()

def main() -> None:
    global _mouse_cache, _keyboard_cache

    SORGULAMA_ARALIGI = 900  # 15 dakika
    DONUSUM_ARALIGI = 30     # 30 saniye
    
    update_cache()
    last_cache_update = time.monotonic()
    cycle_index = 0

    while True:
        current_time = time.monotonic()
        if (current_time - last_cache_update) >= SORGULAMA_ARALIGI:
            update_cache()
            last_cache_update = current_time

        mouse = _mouse_cache
        keyboard = _keyboard_cache

        mouse_battery = mouse["battery"] if mouse else None
        kb_battery = keyboard["battery"] if keyboard else None
        
        # Kablolu durumları değişkene aktar
        mouse_wired = mouse.get("is_wired", False) if mouse else False
        kb_wired = keyboard.get("is_wired", False) if keyboard else False

        mouse_name = mouse["name"] if mouse else "G502 X PLUS"
        kb_name = keyboard["name"] if keyboard else "DeathStalker V2 Pro"

        mouse_perc = format_percentage(mouse_battery, mouse_wired)
        kb_perc = format_percentage(kb_battery, kb_wired)

        tooltip_lines = [
            f"🖱️ {mouse_name}\t\t\t{mouse_perc}",
            f"⌨️ {kb_name}\t{kb_perc}"
        ]

        # Waybar ekranında gösterilecek cihazı belirle
        if cycle_index % 2 == 0:
            icon = get_battery_icon(mouse_battery, mouse_wired)
            cls = get_battery_class(mouse_battery, mouse_wired)
        else:
            icon = get_battery_icon(kb_battery, kb_wired)
            cls = get_battery_class(kb_battery, kb_wired)

        tooltip = "\n".join(tooltip_lines)
        result = {"text": icon, "class": cls, "tooltip": tooltip}

        print(json.dumps(result))
        sys.stdout.flush()

        cycle_index += 1
        time.sleep(DONUSUM_ARALIGI)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(0)
