#!/usr/bin/env python3

import subprocess
import json
import re

def get_battery():
    try:
        result = subprocess.run(['solaar', 'show'], capture_output=True, text=True, timeout=5)
        output = result.stdout
        
        # Receiver takılı mı kontrol et (Lightspeed Alıcı veya başlık var mı)
        if "Lightspeed Alıcı" not in output and "Receiver" not in output:
            return None
        
        # Mouse ismini bul
        mouse_match = re.search(r'^\s*\d+:\s+(.+?)$', output, re.MULTILINE)
        if not mouse_match:
            return None
            
        mouse_name = mouse_match.group(1).strip()
        
        # Batarya seviyesini bul
        battery_match = re.search(r'(?:Battery|Batarya):\s*(\d+)%', output, re.IGNORECASE)
        
        if battery_match:
            battery = int(battery_match.group(1))
            
            # Batarya seviyesine göre ikon ve renk sınıfı
            if battery >= 80:
                icon = ""
                cls = "high"
            elif battery >= 60:
                icon = ""
                cls = "medium-high"
            elif battery >= 40:
                icon = ""
                cls = "medium"
            elif battery >= 20:
                icon = ""
                cls = "low"
            else:
                icon = ""
                cls = "critical"
            
            # Tooltip: sola dayalı fare + isim, sağda batarya yüzdesi
            tooltip_text = f"🖱️ {mouse_name:<20} %{battery:>3}"
            
            return {
                "text": f"{icon}",
                "class": cls,
                "tooltip": tooltip_text,
                "percentage": battery
            }
    except subprocess.TimeoutExpired:
        pass
    except Exception:
        pass
    
    return None

if __name__ == "__main__":
    result = get_battery()
    if result:
        print(json.dumps(result))
    else:
        # Hiçbir şey çıktı verme - Waybar modülü gizlenir
        pass
