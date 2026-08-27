#!/usr/bin/env python3
"""Tokyo Night Qt renk semasini TEK kaynaktan uc formatta uretir.

  ./tokyonight-uret.py            # uc dosyayi da yerinde gunceller

CIKTILAR
  ../../../local/share/color-schemes/TokyoNight.colors
                     KDE colorscheme formati. qt6ct-kde (AUR) okur; okurken
                     ayrica KDE_COLOR_SCHEME_PATH'i kurar, yani KDE/Kirigami/QML
                     tarafi da bu dosyadan beslenir. KDE'nin kendi kesif dizini
                     oldugu icin tek ev burasi -- depo bir ara ayni paletin DORT
                     birebir kopyasini tasiyordu (config/qt6ct/colors/'da iki,
                     burada iki; sha256 hepsinde 420b7f01...) ve hangisinin
                     okundugu ancak biri degistirilince goruldu.
  TokyoNight.conf    qt6ct'nin KENDI formati. extra depodaki duz qt6ct de okur.
                     Ama .colors olmadigi icin KDE_COLOR_SCHEME_PATH SILINIR
                     (yama kosulu: Qt6CT::isKColorScheme() -> ".colors" uzantisi),
                     ve KDE tarafi ../../kdeglobals'a duser.
  ../../kdeglobals   [Colors:*] bolumleri. Yukaridaki dusus hedefi burasi.

NEDEN TEK KAYNAK: ayni palet birden cok dosyada yaziliysa biri ilerler, otekiler
donar ve donan taraf donduğunu soylemez. Renk degistirilecekse YALNIZ burasi
duzenlenir, sonra bu betik kosturulur.

TUZAK -- qt6ct.conf'ta color_scheme_path MUTLAK yazilir, "~" ile DEGIL.
  Olculdu (2026-08-27, qt6ct-kde 0.11-8, bu makine): iki kosu, ikisinde de tam
  yeniden baslatma (pkill dolphin + systemctl --user restart plasma-dolphin),
  tek degisken yoldu. Semaya bilerek saf kirmizi bir Highlight konuldu:
    ~/.config/...       -> kirmizi 0 px, ESKI palet yururlukte (#A4BBEF 8230 px)
    /home/drpars/...    -> kirmizi geldi
  Ariza sessiz: hata yok, cikis kodu yok, uygulama temalanmis GORUNUR -- cunku
  yuklenemeyen yol, kesif dizinindeki ayni adli bayat kopyaya dusuyor. Yani iki
  kopya varken yanlis yol bile "calisiyor" gibi durur.

SECIM RENGI NEDEN KOYU (olculdu 2026-08-27, bu makine, Darkly + Dolphin 26.08.0)
  Dolphin'in ikon gorunumu secili etiketi HighlightedText ile DEGIL, normal
  view metniyle ciziyor. Yalitik sonda: HighlightedText=saf kirmizi,
  Text=saf yesil yapildi -> harfler YESIL cikti; kirmizi yalnizca secim
  dikdortgeninin alt kenarindaki 1 px cizgide (y=141, 132 piksel).
  Yerler kenar cubugu ise HighlightedText'i kullaniyor.
  Sonuc: acik zeminli bir Highlight, ikon gorunumunde acik-uzerine-acik verir.
  Eski Tokyo.colors: #D6D9E1 / #A3BAEE = 1,38:1 (WCAG esigi 4,5).
  Tek bir Highlight rengi hem koyu hem acik metni tasiyamaz -- 256 tonun
  tamami tarandi, teorik en iyi ortak kontrast 3,50:1. O yuzden tek tutarli
  cozum KOYU zemin + ACIK metin.
  Yururlukteki cift: #33467c / #c0caf5 = 5,65:1.

MENU VURGUSU AYRI BIR ANAHTARDAN GELIYOR (olculdu 2026-08-27, Darkly, bu makine)
  !! BUGUN UYKUDA (2026-08-28): stil Kvantum ve menu rengini temanin kendi
  !! SVG'sinden (menuitem-toggled) aliyor; Darkly kaldirildi. Asagidaki
  !! olcum ve AYKIRI girdisi Darkly'ye geri donulurse yeniden gecerli olur --
  !! o yuzden silinmedi. Ayrica parantezdeki custom_palette=true kosulu da
  !! artik gecerli degil: bugun false, ve .conf uzantisiyla
  !! KDE_COLOR_SCHEME_PATH zaten hic kurulmuyor.
  Darkly'nin sag tik menusundeki vurgulu satir QPalette::Highlight'i KULLANMIYOR;
  rengi [Colors:View] DecorationFocus'tan aliyor. Bolum bolum ikame ile bulundu:
  yedi [Colors:*] bolumunun DecorationFocus'u tek tek saf kirmiziya cevrildi,
  yalnizca View menuyu kirmiziya dondurdu. kdeglobals DEGIL -- oradaki yedi
  bolumun DecorationFocus/DecorationHover'i birden degistirildiginde menu hic
  oynamadi (qt6ct custom_palette=true iken KDE_COLOR_SCHEME_PATH bu .colors
  dosyasini gosteriyor, kdeglobals'a dusulmuyor).

  Onceki deger blue (#7aa2f7) idi ve metin #c0caf5 ile ciziliyor: 1,56:1.
  Gercek ekran goruntusunde vurgulu satirin 8000 pikselinde kontrasti 1,2'yi
  gecen TEK BIR govde pikseli yoktu. SECIM'e cevrilince metin govdesi 4,76:1,
  tepe 5,64:1.

  Yan etki olculdu: gercek Dolphin penceresinde iki kol arasinda 862.629
  pikselin 0'i farkli; odakli QLineEdit sondasinda da 0. Odak halkasi (#293459)
  ve liste secimi (#33467c) palet Highlight'indan geliyor, bu anahtardan degil.
  KAPSAM: Dolphin ana penceresi (ikon gorunumu, bir secim, menu kapali) + sentetik
  sonda (odakli metin kutusu, liste, kutucuk, dugme, metin alani). Baska
  uygulamalar ve KDE diyaloglari render EDILMEDI.
"""
import pathlib, sys

# --- Tokyo Night (Night) -- sayilar dotfiles'ta fiilen geciyor (2026-08-27 sayimi)
bg        = "#1a1b26"   # 101x
bg_dark   = "#16161e"
bg_hl     = "#292e42"   # 34x
fg_gutter = "#3b4261"
term_blk  = "#414868"
comment   = "#565f89"   # 10x  (waybar .disabled)
fg        = "#c0caf5"   # 15x
blue      = "#7aa2f7"   # 32x
magenta   = "#bb9af7"   # 18x
red       = "#f7768e"   # 17x
yellow    = "#e0af68"   # 17x
green     = "#9ece6a"   # 19x
SECIM     = "#33467c"   # secim zemini -- gerekce yukarida

ONPLAN = {
    "ForegroundNormal": fg,        "ForegroundInactive": comment,
    "ForegroundActive": blue,      "ForegroundLink": blue,
    "ForegroundVisited": magenta,  "ForegroundNegative": red,
    "ForegroundNeutral": yellow,   "ForegroundPositive": green,
    "DecorationFocus": blue,       "DecorationHover": blue,
}
# Bolume ozgu aykirilar: ONPLAN her bolume aynen uygulanir, buradakiler ezer.
# View/DecorationFocus -- Darkly'nin MENU vurgusu; ayrintili gerekce yukarida.
# Darkly kaldirildi (2026-08-28), bu aykiri bugun ETKISIZ; geri donus icin duruyor.
AYKIRI = {
    "View": {"DecorationFocus": SECIM},
}
ZEMIN = {                       # bolum: (BackgroundNormal, BackgroundAlternate)
    "Window":        (bg,      bg_dark),
    "View":          (bg,      bg_dark),
    "Button":        (bg_hl,   fg_gutter),
    "Tooltip":       (bg_hl,   bg_dark),
    "Complementary": (bg_dark, bg),
    "Header":        (bg_dark, bg_dark),
    "Selection":     (SECIM,   fg_gutter),
}

def rgb(h):
    h = h.lstrip("#")
    return "%d,%d,%d" % tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def bolum(ad):
    d = dict(ONPLAN)
    d.update(AYKIRI.get(ad, {}))
    d["BackgroundNormal"], d["BackgroundAlternate"] = ZEMIN[ad]
    return "".join("%s=%s\n" % (k, rgb(d[k])) for k in sorted(d))

# ---------------------------------------------------------------- KDE .colors
KDE_EK = """[ColorEffects:Disabled]
Color=%s
ColorAmount=0.15
ColorEffect=2
ContrastAmount=0.8
ContrastEffect=1
IntensityAmount=-1
IntensityEffect=2

[ColorEffects:Inactive]
ChangeSelectionColor=false
Enable=false

[General]
ColorScheme=TokyoNight
Name=Tokyo Night
shadeSortColumn=true

[KDE]
contrast=4

[WM]
activeBackground=%s
activeBlend=%s
activeForeground=%s
inactiveBackground=%s
inactiveBlend=%s
inactiveForeground=%s
""" % (rgb(bg_hl), rgb(bg), rgb(fg), rgb(fg), rgb(bg_dark), rgb(comment), rgb(comment))

def yaz_colors(p):
    # ColorEffects:Inactive Enable=false -> odaksiz pencere rengi degistirmez;
    # okunurluk odaga bagli olmasin diye bilerek boyle.
    govde = "".join("[Colors:%s]\n%s\n" % (a, bolum(a)) for a in sorted(ZEMIN))
    p.write_text("# URETILDI: tokyonight-uret.py -- elle duzenleme, ilk uretimde kaybolur\n"
                 + govde + KDE_EK)

# ------------------------------------------------------- qt6ct native .conf
# Rol sirasi qt6ct'nin kendi ornek dosyalarindan turetildi (/usr/share/qt6ct/
# colors/darker.conf + airy.conf): koyu ornekte 12=mavi, 13=beyaza yakin;
# acik ornekte 0 ve 6 siyah. Iki dosya birbirini dogruluyor.
ROL = ["WindowText","Button","Light","Midlight","Dark","Mid","Text","BrightText",
       "ButtonText","Base","Window","Shadow","Highlight","HighlightedText","Link",
       "LinkVisited","AlternateBase","NoRole","ToolTipBase","ToolTipText",
       "PlaceholderText"]
AKTIF = {"WindowText": fg, "Button": bg_hl, "Light": term_blk, "Midlight": fg_gutter,
         "Dark": bg_dark, "Mid": bg_hl, "Text": fg, "BrightText": red,
         "ButtonText": fg, "Base": bg, "Window": bg, "Shadow": bg_dark,
         "Highlight": SECIM, "HighlightedText": fg, "Link": blue,
         "LinkVisited": magenta, "AlternateBase": bg_dark, "NoRole": bg,
         "ToolTipBase": bg_hl, "ToolTipText": fg, "PlaceholderText": comment}

def yaz_conf(p):
    pasif = dict(AKTIF, Highlight=bg_hl)
    devre = dict(AKTIF, Highlight=bg_hl)
    for r in ("WindowText", "Text", "ButtonText", "HighlightedText", "BrightText"):
        devre[r] = comment
    def satir(d):
        return ", ".join("#%s%s" % ("80" if r == "PlaceholderText" else "ff",
                                    d[r].lstrip("#")) for r in ROL)
    p.write_text("# URETILDI: tokyonight-uret.py -- elle duzenleme, ilk uretimde kaybolur\n"
                 "[ColorScheme]\nactive_colors=%s\ndisabled_colors=%s\ninactive_colors=%s\n"
                 % (satir(AKTIF), satir(devre), satir(pasif)))

# -------------------------------------------------------------- kdeglobals
BASLIK = "# --- [Colors:*] URETILDI: qt6ct/colors/tokyonight-uret.py ---"

def yaz_kdeglobals(p):
    metin = p.read_text()
    kesim = metin.find(BASLIK)
    if kesim != -1:
        metin = metin[:kesim]
    govde = "".join("[Colors:%s]\n%s\n" % (a, bolum(a)) for a in sorted(ZEMIN))
    p.write_text(metin.rstrip("\n") + "\n\n" + BASLIK + "\n" + govde)

kok = pathlib.Path(__file__).resolve().parent
yaz_colors(kok.parent.parent.parent / "local/share/color-schemes/TokyoNight.colors")
yaz_conf(kok / "TokyoNight.conf")
yaz_kdeglobals(kok.parent.parent / "kdeglobals")
print("uretildi: TokyoNight.colors, TokyoNight.conf, ../../kdeglobals")
