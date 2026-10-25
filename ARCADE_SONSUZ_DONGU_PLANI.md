# 🚜 Arcade Modu: Sonsuz Römork Döngüsü & Akıllı İstif Planı

## 1. Mevcut Problemin Teşhisi (Ekran Görüntüsündeki Durum)

Ekran görüntüsünde (`43/45` balya, `20850` skor, `1 Kalp`) oyunun mevcut mekaniğindeki **iki kritik tıkanma noktası** net olarak görülüyor:

1. **Dolu Hücre Tuzağı (Catch-22 / İmkansız Durum):**
   - Römorktaki 9 hücrenin **7 tanesi `5/5` (maksimum)** kapasiteye ulaşmış, sadece `(sol-orta)` ve `(sağ-arka)` hücreleri `4/5` durumunda.
   - Ancak `BaleSpawner._generateBale` hücrelerin doluluk oranına bakmadan tamamen rastgele `(col, row)` seçiyor. Bu durumda atılan balyaların **%78'i zaten `5/5` dolu olan hücrelere** (ekran görüntüsündeki sağ-ön `5/5` hücresi gibi) düşüyor.
   - Oyuncu o hücreye gidip balyayı **yakalarsa**: `_handleColumnOverflowPhysics` çalışıyor ve **"5 ROW MAX! -15 HP"** cezası kesiyor.
   - Oyuncu o hücreye gitmeyip balyayı **bırakırsa**: `evaluateLandingCollisions` çalışıyor ve **"MISSED! -15 HP"** cezası kesiyor.
   - **Sonuç:** Oyuncu balyayı tutsa da tutmasa da can kaybediyor ve oyunu kaybetmeye mahkum oluyor.

2. **Arcade Modunun `45/45`'te Bitmesi:**
   - `_executeSuccessfulCatch` içinde `_stackedBales.length >= 45` olduğunda `_isVictory = true; _isGameOver = true;` çalışarak oyunu bitiriyor. Oysa **Arcade Modu sonsuz bir döngü (Endless Score & Wagon Chase)** olmalı.

---

## 2. Tasarım Seçenekleri: "Doldukça Yeni Römork mu, Tam Dolmayanlar Ne Olacak?"

Sonsuz döngüye geçerken *"Doldukça yeni römork mu gelsin, bu sefer de tam dolmayan diğer hücreler ne olacak?"* sorusu için **3 farklı yaklaşım** ve bunların en güçlü yanlarını birleştiren **Önerilen Hibrit Mimari** aşağıdadır:

| Yaklaşım | Nasıl Çalışır? | Artıları | Eksileri |
| :--- | :--- | :--- | :--- |
| **1. Saf Yeni Römork (`45/45` Beklemeli)** | Sadece tüm römork `45/45` olduğunda yeni römork gelir. | Görsel olarak tam dolu römork göndermek tatmin edicidir. | Son 3-4 balya kalınca boş hücreleri doldurmak çok zorlaşır, oyun tıkanır. |
| **2. Katman Erimesi (Tetris / Layer Clear)** | 9 hücrenin tamamında en alt kat (3x3 = 9 balya) dolunca o kat erir, üsttekiler 1 kat aşağı iner. | Römork asla tıkanmaz, yarım kalan sütunlar hep korunur. | "Römorku doldurup gönderme" (Haul/Sevkiyat) hissiyatı zayıf kalır. |
| **3. ÖNERİLEN: Sonsuz Römork Konvoyu + Akıllı Kaydırma (Smart Spillover)** | Dolu hücrede tutulan balya otomatik olarak komşu boş hücreye yuvarlanır + `45/45` (veya erken sevk) ile yeni römork gelir. | **Hem tam dolmayan hücreler otomatik dolar, hem oyuncu asla haksız can kaybetmez, hem de römork sevkiyat hissi korunur.** | Yok — Arcade akışına en uygun modeldir. |

---

## 3. Önerilen Sistem Mimarisi (4 Temel Kural)

### Kural 1: Akıllı Spawner (Boş Hücre Önceliklendirme)
- `BaleSpawner.update` metoduna mevcut hücre doluluk bilgisi (`availableCells`) verilir.
- Eğer römorkta `< 5` olan hücreler varsa:
  - Fırlatılan saman balyalarının **%80'i doğrudan henüz dolmamış (`< 5`) hücrelerden birini** hedefler.
  - Kalan **%20'si** oyuncuyu hareketli tutmak için rastgele bir hücreyi hedefler.
- Böylece `43/45` durumundayken oyuncunun beklediği son 2 balya doğrudan eksik olan `4/5`'lik hücrelere (veya yanına) atılır.

### Kural 2: "Ceza Yerine Yan Hücreye Yuvarlanma" (Smart Spillover — Tam Dolmayan Hücrelerin Çözümü)
- Oyuncu `5/5` dolu bir hücrenin üstünde durup gelen balyayı yakaladığında:
  - **Eski davranış:** Balya dışarı düşüp `-15 HP` can götürüyordu.
  - **Yeni davranış:** Oyuncu balyayı yakaladığı için **ödüllendirilir!** Yakalanan balya, 5'lik sütunun tepesinden **en yakın `< 5` olan komşu hücreye** (Manhattan mesafesine göre en yakın eksik hücreye) otomatik olarak yuvarlanıp yerleşir.
  - Bu sayede:
    1. **Tam dolmayan diğer hücreler**, dolu hücrelerden seken balyalarla kendiliğinden tamamlanır.
    2. Oyuncu doğru yerde durup balya yakaladığı için **asla can kaybetmez** (Can kaybı sadece balyayı tamamen kaçırırsa veya kafasına çarparak stun olursa yaşanır).

### Kural 3: Römork Dolduğunda (`45/45`) Yeni Römork Sevkiyatı (Endless Wagon Swap)
- Römork `45/45` kapasiteye ulaştığında oyun bitmez (`_isGameOver = true` kaldırılır).
- Bunun yerine **Römork Sevkiyatı (Wagon Haul Complete)** tetiklenir:
  1. **`completedWagons` (`_wagonsCompleted`) sayacı +1 artar** (HUD'da `🚛 1 • 43/45` şeklinde kaçıncı römorkta olunduğu görünür).
  2. **Ödüller verilir:**
     - `+1000 Puan` Römork Tamamlama Bonusu.
     - `+25 HP` (+1 Kalp yenilenmesi, maksimum 4 kalp) — oyuncuya uzun soluklu Arcade döngüsünde nefes aldırır.
  3. **Görsel Geçiş (1.5 Saniye):**
     - Römorktaki 45 balya altın rengi bir parıltıyla paketlenip arkaya doğru kayarak boşalır (`_stackedBales.clear()`) ve karakter yeni boş römorkun zeminine (`tier 0`) iner.
     - Geçiş sırasında havadaki balyalar temizlenir, oyuncuya 1.5 saniye hazırlık süresi verilir (`"🚛 RÖMORK #1 TAMAM! +1000"` bildirimi).
  4. **Artan Zorluk (Wave Scaling):**
     - Her tamamlanan römorkta (`_wagonsCompleted`) balya atış hızı ve traktör sarsıntısı çok hafif (%5) artar, böylece 1. römorktan 10. römorka doğru heyecanlı bir sonsuz döngü oluşur.

### Kural 4: "Erken Sevkiyat / Düzenleme" Esnekliği (Opsiyonel Konfor)
- Eğer oyuncu römorkta en az **30/45 (%66+)** balya biriktirdiyse, 7 saniyelik izometrik düzenleme ekranında **"OTOMATİK DENGELE"** butonunun yanında **"🚛 RÖMORKU GÖNDER"** seçeneği de yer alabilir:
  - Oyuncu `45/45` tam doldurursa **Tam Kapasite Bonusu (`+1000 Puan` + `+1 Kalp`)** alır.
  - Erken gönderirse (`30..44` balya arası) **`balyaSayısı x 15 Puan`** kısmi sevkiyat bonusu alıp yeni boş römorka geçebilir.

---

## 4. Değiştirilecek Dosyalar & Uygulama Adımları

1. **`lib/physics/bale_spawner.dart`**
   - `update()` ve `_generateBale()` metodlarına boş hücre listesini (`availableCells`) ekleyerek, `< 5` olan hücrelere %80 öncelik tanınması.
2. **`lib/controllers/game_controller.dart`**
   - `_wagonsCompleted` (Tamamlanan Römork sayısı) ve `lifetimeWagonsCompleted` istatistiğinin eklenmesi.
   - `_executeSuccessfulCatch()` içinde `existingInCell >= 5` olduğunda `_handleColumnOverflowPhysics` (ceza) yerine `_findNearestAvailableCell(targetCol, targetRow)` ile komşu boş hücreye otomatik yerleştirme (Smart Spillover) yapılması.
   - `_stackedBales.length >= maxWagonCapacity (45)` olduğunda oyunu bitirmek yerine `_completeWagonAndSpawnNext()` metodunu çağırarak `+1000 Puan`, `+25 HP` ve yeni boş römorka geçişin sağlanması.
3. **`lib/views/widgets/top_hud_panel.dart`**
   - Üst sol rozette `43/45` bilgisinin yanına tamamlanan römork sayısının (`🚛 2 • 14/45` gibi kompakt biçimde) eklenmesi.
4. **`lib/views/widgets/stats_dialog.dart` & `lib/views/widgets/game_over_dialog.dart`**
   - İstatistik ve Oyun Sonu ekranlarında **"Tamamlanan Römork (Sevkiyat)"** bilgisinin gösterilmesi.
