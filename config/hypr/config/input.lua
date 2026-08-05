-- =======================================================
-- INPUT AYARLARI
-- =======================================================

hl.config({
	input = {
		-- Fiziksel klavye makineye göre değişiyor (bkz. config/hosts/).
		kb_layout = host.kb_layout,
		kb_options = "grp:alt_shift_toggle",
		kb_variant = "",
		kb_model = "",
		kb_rules = "",
		numlock_by_default = true,
		follow_mouse = 1,

		-- Uyarlamalı (adaptive) fare ivmesini kapat: 1:1, hareket hızından
		-- bağımsız sabit oran (Windows hissine yakın, daha kontrollü).
		accel_profile = "flat",

		touchpad = {
			natural_scroll = false,
			clickfinger_behavior = true,

			-- Karar (2026-08-05, kullanıcı): kapalı kalıyor.
			-- libinput varsayılanı true — yazarken ve hemen ardından touchpad'in
			-- HAREKETİ bastırılır, fiziksel tıklama geçmeye devam eder. Bu satır
			-- bir teşhis turunda kondu (semptom: tıklama kaydediliyor, imleç
			-- oynamıyor, klavyeden sonra belirginleşiyor) ama **teşhisi tutmadı**:
			-- kapalıyken de gecikme sürdü, sonra kendiliğinden geçti. Yani burada
			-- duruyor olması gecikmeyi çözdüğü için değil, tercih edildiği için.
			-- Bedeli: yazarken avuç/parmak sürtmesi imleci oynatabilir.
			disable_while_typing = false,
		},
	},
})

-- =======================================================
-- HAREKETLER (GESTURES)
-- =======================================================
-- Üç parmak yatay kaydırma → çalışma alanı değiştir.
--
-- Bu ayrı bir çağrı, `gestures` bölümünün altında bir anahtar DEĞİL: Hyprland
-- 0.51'de hareketler yeniden yazıldı ve açma/kapama anahtarı olan
-- `gestures:workspace_swipe` KALDIRILDI (0.56.1'de `hyprctl getoption` "no such
-- option" diyor). `gestures` altında yalnızca ayar düğmeleri kaldı —
-- `workspace_swipe_distance`, `_invert`, `_cancel_ratio`, `_create_new` … —
-- ama hiçbiri hareketi var etmiyor; hareketin kendisi burada bildirilir.
-- Bu yüzden .conf'tan Lua'ya geçerken sessizce düştü: taşınacak bir anahtar
-- yoktu. Karşılığı dağıtımın örnek dosyasında duruyor: /usr/share/hypr/hyprland.lua.
--
-- Makine koruması yok: touchpad'i olmayan makinede hareket hiç tetiklenmez,
-- yani masaüstünde ölü değil, sadece sessiz.
hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})

-- Üç parmak aşağı → aktif pencereyi kapat.
--
-- `close` **aktif** pencereyi kapatır, cursor'un altındakini değil (wiki:
-- "Closes the active window"). İkisi burada çakışıyor çünkü yukarıda
-- `follow_mouse = 1` var; follow_mouse değişirse bu hareket de hedef değiştirir.
--
-- `scale` SÜS DEĞİL, çalışması için gerekli. Eşik delta cinsinden ve bu panel
-- 126x74 mm — dikey yol yatayın %59'u. Çarpansız `down` hiç kapatmıyordu;
-- yatay kaydırmanın aynı anda çalışıyor olması da bunun mesafe sorunu olduğunu
-- gösteriyor, yön ya da eylem sorunu değil (ikisi de bildirim sondasıyla ayrı
-- ayrı elendi → NOTLAR). Kazara kapanma olursa düşürülecek düğme budur.
--
-- Modifier yok: kullanıcı kararı, asıl istenen çıplak hareketti. Bedeli
-- kabul edildi — yanlışlıkla yapılan hareket aktif pencereyi kapatır ve `close`
-- geri alınamaz. Geri istenirse tek satır: `mods = "ALT"`.
hl.gesture({
	fingers = 3,
	direction = "down",
	scale = 3.0,
	action = "close",
})
