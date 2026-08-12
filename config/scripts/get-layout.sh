#!/bin/bash
# waybar custom/language: ana klavyenin etkin düzeni.
#
# TEK hyprctl çağrısı. Önceki biçim aynı soruyu iki kez soruyordu — önce
# main=true klavyenin adı, sonra o adla düzeni — ve modül saniyede bir
# koştuğu için bedeli saniyede iki hyprctl + iki jq'ydu. Ada hiç gerek yok:
# istenen şey zaten "main olan klavyenin active_keymap'i".
#
# Yoklamanın kendisi duruyor ve bu bilerek: Alt+Shift ile yapılan değişim
# (kb_options grp:alt_shift_toggle) compositor'den geçmiyor, yani sinyalle
# haber verilemiyor. Bedeli ölçüldü (2026-08-12): barın BÜTÜN modülleri,
# bütün yoklamaları ve çizimi birlikte 0,51 W — yani buradaki 1 Hz bir güç
# sorunu değil. Barın pahalı olan tarafı sonsuz CSS animasyonuydu (6,86 W),
# o da kaldırıldı.
set -uo pipefail

layout=$(hyprctl devices -j 2>/dev/null \
  | jq -r 'first(.keyboards[] | select(.main == true) | .active_keymap) // empty')

case "$layout" in
  *Turkish*) printf '{"text":"TR","class":"tr","tooltip":"Türkçe Klavye"}\n' ;;
  # Klavye okunamadı (Hyprland yok, jq düştü): modül gizlensin. "US" yazmak
  # bilmediğini biliyormuş gibi göstermek olurdu.
  '')        printf '{"text":""}\n' ;;
  *)         printf '{"text":"US","class":"us","tooltip":"İngilizce Klavye"}\n' ;;
esac
