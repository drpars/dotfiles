#!/bin/bash

# main flag'i true olan klavyeyi bul
SELECTED_DEVICE=$(hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .name' | head -1)

# Layout'u al
LAYOUT=$(hyprctl devices -j | jq -r ".keyboards[] | select(.name == \"$SELECTED_DEVICE\") | .active_keymap" | head -1)

# Çıktıyı üret
if [[ "$LAYOUT" == *"Turkish"* ]]; then
    echo '{"text": "TR", "class": "tr", "tooltip": "Türkçe Klavye"}'
else
    echo '{"text": "US", "class": "us", "tooltip": "İngilizce Klavye"}'
fi
