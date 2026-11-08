Uygulamaya yeni bir sekme (Tab) olarak eklenecek `AvatarBaseTabView.swift` adında bağımsız, tam ekran bir SwiftUI görünümü oluştur. 

Tasarım dili: **Dark Neobrutalist / Cyber-Tactical Kat Planı**. 
- Arka plan: Çok koyu karbon/siyah (`#0D0D0D`).
- Kartlar ve Odalar: Kalın (2-3pt) keskin çerçeveler, bulanık olmayan 45 derece sert ofset gölgeler (hard drop shadow), monospace (teknik) fontlar ve yüksek kontrastlı neon renkler.
- Dışarıdan hiçbir PNG veya görsel asset KULLANMA. Tüm karakter, mobilya ve ikonları SwiftUI `Canvas` veya piksel matrisleri (2D Array) kullanarak kodla 8-bit/16-bit piksel sanatı olarak çiz.

Ekran yukarıdan aşağıya 3 ana bölümden oluşmalı:

### BÖLÜM 1: Üst Durum Barı (Tactical Header)
- Kalın çerçeveli bir üst bar. İçinde `[ BASE_OPS // LIVE_FEED ]` başlığı, yanında yanıp sönen yeşil bir "REC" noktası ve o anki aktif durumu gösteren bir etiket (Örn: `STATE: HYPER-CHARGE`).

### BÖLÜM 2: 2D İnteraktif Kat Planı (Ana Sahne - Ekranın %60'ı)
`GeometryReader` kullanarak ekranın ortasına kareye yakın büyük bir "Brutalist Kat Planı (Blueprint)" yerleştir. Arka planında çok silik bir noktalı ızgara (dot-matrix grid) olsun.
Harita 2x2'lik 4 ana odaya (Zone) bölünsün ve tam ortalarında odaları birbirine bağlayan bir **Merkez Koridor (Center Hub - x: 0.5, y: 0.5)** bulunsun. Odaların merkeze bakan köşelerinde kapı boşlukları olsun:

1. **Üst Sol - `[ ZONE 01: IRON GYM ]`** (Çerçeve ve Vurgu: Neon Yeşil `#CCFF00` / Koordinat: `x: 0.25, y: 0.25`):
   - İçine piksel çizimle bir bench sehpası/halter ve koşu bandı ikonu yerleştir.
2. **Üst Sağ - `[ ZONE 02: FUEL LAB ]`** (Çerçeve ve Vurgu: Neon Pembe `#FF0055` / Koordinat: `x: 0.75, y: 0.25`):
   - İçine piksel çizimle bir mutfak tezgahı ve neon burger/pizza ikonu yerleştir.
3. **Alt Sol - `[ ZONE 03: CRYO LOUNGE ]`** (Çerçeve ve Vurgu: Sıcak Amber `#FF9900` / Koordinat: `x: 0.25, y: 0.75`):
   - İçine piksel çizimle bir koltuk, TV ve el konsolu ikonu yerleştir.
4. **Alt Sağ - `[ ZONE 04: COMMAND DECK ]`** (Çerçeve ve Vurgu: Neon Cyan `#00F0FF` / Koordinat: `x: 0.75, y: 0.75`):
   - İçine piksel çizimle çoklu monitörlü bir bilgisayar masası ve sunucu kabini yerleştir.

**Karakter ve Yürüme (Waypoint Pathfinding) Mantığı:**
- Sahnede 16x16 piksellik bir matrisle çizilen küçük bir karakterimiz (Avatar) olsun. Karakterin kafasının üstünde o anki moduna göre küçük bir piksel konuşma balonu (`⚡`, `🍔`, `💤`, `💻`) çıksın.
- Karakter bir odadan diğerine geçerken duvarların içinden doğrudan çapraz GEÇMEMELİ. 
- İki aşamalı bir `walkToZone(_ targetZone: Zone)` fonksiyonu yaz:
  1. Karakter başka bir odadaysa önce durumunu `.walking` yap ve `withAnimation(.linear(duration: 0.7))` ile **Merkez Koridora (`x: 0.5, y: 0.5`)** yürüt.
  2. `0.7` saniye sonra ikinci bir animasyonla Merkez Koridordan **Hedef Odanın koordinatına** yürüt ve oraya vardığında durumunu o odanın aksiyonuna (`.workingOut`, `.eating`, `.resting`, `.analyzing`) geçir.
- Yürüme sırasında karakterin bacak pikselleri `TimelineView` ile hızlıca hareket etsin (yürüme animasyonu). Odada sabitken ise o odaya özel 2-3 karelik (frame) aksiyon animasyonunu yapsın (Gym'de ağırlık kaldırma, Fuel Lab'de burger yeme, Lounge'da uyuklama/oyun oynama, Command'da klavye kullanma).

### BÖLÜM 3: Alt CCTV Zoom Monitörü ve Simülasyon Kontrolleri (Ekranın %30'u)
- Haritanın hemen altında kalın çerçeveli, sert gölgeli bir **"CCTV ZOOM INSPECTOR"** kartı olsun.
- Kartın sol tarafında, karakterin o anki piksel animasyonunun **3 kat büyütülmüş (Zoomed-in)** hali canlı olarak oynasın (böylece küçük haritada görünmeyen piksel detayları burada net görünsün).
- Sağ tarafında ise terminal/log formatında bilgiler yazsın:
  - `LOC: [Bulunduğu Oda]`
  - `ACT: [Yaptığı Eylem - Örn: LIFTING HEAVY / CONSUMING REWARD]`
  - `SYS_MSG: [Duruma uygun esprili/teknik bir mesaj]`
- En alta, bu sahneyi hemen test edebilmem için 4 odayı temsil eden 4 adet Neobrutalist buton (`[ ⚡ CHARGE ]`, `[ 🍔 CHEAT ]`, `[ 💤 REST ]`, `[ 💻 IDLE ]`) ekle. Butonlara bastığımda veya haritadaki odaların üzerine doğrudan tıkladığımda karakter merkez koridoru kullanarak o odaya yürüsün.