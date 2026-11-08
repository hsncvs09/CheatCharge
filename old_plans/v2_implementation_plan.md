# CheatCharge v2.0 Detaylı Uygulama Planı

Bu doküman, kullanıcının belirlediği gereksinimler ve tasarım kararları doğrultusunda CheatCharge versiyon 2 sürümünün eksiksiz teknik mimarisini, veri modellerini, iş mantığını, arayüz bileşenlerini ve Ana Ekran Widget'ını tanımlar.

---

## 1. Temel Kurallar ve Mantıksal Mimari

### 1.1. Kredi Devretme (Rollover) ve Harcama Motoru (FIFO Kuralı)
1. **Tek Seferlik Devir (Non-Cumulative Rollover):** Yalnızca içinde bulunulan haftada kazanılıp harcanmayan net kalori bir sonraki haftaya devredebilir. Bir önceki haftadan devralınmış bakiye kullanılmazsa **çöpe gider (expire olur)**, zincirleme devretmez.
2. **İlk Harcama Önceliği (FIFO - First In First Out):** Yeni haftada yapılan kaçamak harcamaları **önce devreden bakiyeden** düşülür. Devreden bakiye tükendikten sonra harcamalar bu haftanın kazanılan kalorilerinden düşülmeye başlar.
3. **Haftalık Değişkenler:**
   - $E_t$: Bu hafta kazanılan kalori (Charge)
   - $R_t$: Geçen haftadan devreden bakiye
   - $S_t$: Bu hafta yapılan toplam harcama (Cheat)
   - $S_{rollover} = \min(S_t, R_t)$ (Devirden harcanan)
   - $S_{current} = \max(0, S_t - R_t)$ (Bu haftanın kazanımından harcanan)
   - **Gelecek Haftaya Devredecek Bakiye ($R_{t+1}$):** $\max(0, E_t - S_{current})$ *(Devreden bakiyenin harcanmayan kısmı bir sonraki haftaya aktarılmaz!)*

### 1.2. İlerleme Mekanikleri: "Başarılı Hafta", "Seviye" ve "Seri" Ayrımı

Sistemde ilerleme üç bağımsız kavram üzerinden yönetilir:

```
[Hafta Kapanışı] ──► Başarılı mı? 
                          │
          ┌───────────────┴───────────────┐
          ▼                               ▼
       [EVET]                           [HAYIR]
  (Bilanço ≥ 0 VE Efor > 0)       (Bilanço < 0 VEYA Efor = 0)
          │                               │
    ┌─────┴────────────────┐              │
    ▼                      ▼              ▼
[Kalıcı Seviye]      [Anlık Seri]   [Anlık Seri]
Toplam Başarılı      Alev +1        Alev Söner
Hafta +1 (Bileklik)  (🔥 Streak)    (Streak = 0)
(Asla Gerilemez)                    (Bileklik Seviyesi DÜŞMEZ!)
```

#### A. "Başarılı Hafta" Tanımı
Bir takvim haftasının başarılı sayılabilmesi için şu iki şartın aynı anda sağlanması zorunludur:
1. **Net Bilanço Pozitif/Nötr Olmalı:** $(E_t + R_t) \ge S_t$ (Hafta sonunda eksiye düşülmemiş olmalı).
2. **Aktif Efor Şartı (Pasiflik Engeli):** Kazanılan Kalori $E_t > 0$ olmalıdır. (Hem antrenmanın hem kaçamağın 0 olduğu pasif haftalar başarılı sayılmaz).

#### B. Seviye Sistemi (Kümülatif İlerleme - Bileklikler)
- **Peş Peşe Olma Şartı Kesinlikle Yoktur:** Seviye, kullanıcının hayatı boyunca tamamladığı **Toplam Başarılı Hafta** sayısına (`totalSuccessfulWeeks`) bakar.
- Başarısız geçen bir hafta seviyeyi asla düşürmez; birikimli sayaç yerinde kalır, kullanıcı sonraki haftalarda başarılı oldukça üzerine eklemeye devam eder.

#### C. Seri Sistemi (Kesintisiz İlerleme - Alev 🔥)
- Başarılı haftalardan **bağımsız anlık bir motivasyon ve disiplin göstergesidir.**
- Peş peşe gelen her başarılı hafta alev sayacını 1 artırır (`currentStreak += 1`).
- Bilanço eksiye düşerse veya 0'a 0 pasif bir hafta geçirilirse alev söner ve sayaç sıfırlanır (`currentStreak = 0`). Bu sıfırlanma kalıcı bileklik seviyesini **kesinlikle etkilemez**.

---

### 1.3. Afterburn (1.2x Direnç Antrenmanı Çarpanı)
- HealthKit'ten gelen `.traditionalStrengthTraining`, `.functionalStrengthTraining`, `.coreTraining` aktiviteleri veya manuel "Ağırlık" kayıtları için geçerlidir.
- `Workout` modelinde:
  - `rawCalories`: Orijinal kalori (örn. 300 kcal)
  - `afterburnMultiplier`: 1.2
  - `caloriesBurned`: 360 kcal (`rawCalories * 1.2`)
- UI'da kullanıcıya: *"300 kcal + 60 kcal Afterburn 🔥"* etiketiyle gösterilir.

### 1.4. 210 kcal Modüler Sıvı Bardağı & Jiroskop Dalgalanması
- **Birim Hacim:** Bir bardak tam **210 kcal** kalori kredisine denk gelir.
- **Çarpan Gösterimi (Multiplier):**
  - Kalan net bakiye $B$:
  - Dolu bardak sayısı $N = \lfloor B / 210 \rfloor$
  - Bardağın içindeki mevcut doluluk = $(B \pmod{210}) / 210$
  - Örneğin **500 kcal** bakiye:
    - Bardağın önünde neon **"2x"** çarpan rozeti.
    - Bardak içi ise $500 - (2 \times 210) = 80\text{ kcal}$ seviyesinde (%38 dolu) dalgalanır.
  - Bakiye eksiye düştüğünde bardak boşalır, neon kırmızı çatlak/açık uyarısı verir.
- **Jiroskop (CoreMotion - CMMotionManager):**
  - `attitude.roll` değeri dinlenir; telefon sağa/sola eğildiğinde bardağın içindeki sıvının yüzey açısı yerçekimine zıt olarak eğilir.
  - SwiftUI `Canvas` ile sinüs dalgası çizilir; fizik kurallarına göre dalgalanır. (Simulator için akıcı otomatik animasyon alternatifi).

---

## 2. Veri Modelleri (SwiftData)

### 2.1. `TreatCategory` Enum & `TreatItem` Güncellemesi
```swift
enum TreatCategory: String, Codable, CaseIterable, Identifiable {
    case burger = "Burger"
    case pizza = "Pizza"
    case beer = "Bira"
    case cocktail = "Kokteyl / Alkol"
    case dessert = "Tatlı"
    case fastFood = "Fast Food"
    case snack = "Atıştırmalık"
    case drink = "İçecek"
    case other = "Diğer"
    
    var id: String { rawValue }
    var defaultIcon: String {
        switch self {
        case .burger: return "🍔"
        case .pizza: return "🍕"
        case .beer: return "🍺"
        case .cocktail: return "🍸"
        case .dessert: return "🍰"
        case .fastFood: return "🍟"
        case .snack: return "🍿"
        case .drink: return "🥤"
        case .other: return "🍽️"
        }
    }
}
```
`TreatItem` modeline `var categoryRaw: String = TreatCategory.other.rawValue` eklenecektir.

### 2.2. `Workout` Modeli Güncellemesi
- `var rawCalories: Double`: HealthKit'ten veya elle girilen ham kalori.
- `var afterburnMultiplier: Double`: Direnç antrenmanı ise 1.2, değilse 1.0.
- `caloriesBurned`: `rawCalories * afterburnMultiplier`.

### 2.3. Yeni Model: `WeekRecord` (Geçmiş Hafta Arşivi)
```swift
@Model
final class WeekRecord {
    var id: UUID
    var weekStartDate: Date
    var weekEndDate: Date
    var earnedCalories: Double
    var spentCalories: Double
    var rolloverReceived: Double       // Önceki haftadan gelen devir
    var rolloverRemaining: Double      // Devirden arta kalan (kullanılmayıp yanan)
    var rolloverCarriedForward: Double  // Bir sonraki haftaya devredilen
    var isSuccessful: Bool              // Başarılı hafta mı?
    
    init(...)
}
```

### 2.4. Yeni Model: `UserGamificationState` (Kullanıcı İlerleme Durumu)
```swift
@Model
final class UserGamificationState {
    var id: UUID
    /// Kalıcı bileklik seviyesini belirler. Sadece artar, asla düşmez.
    var totalSuccessfulWeeks: Int
    /// Anlık motivasyon alev sayacı (🔥). Kural bozulduğunda 0'a döner.
    var currentStreak: Int
    /// Bu hafta kullanılabilir devir kredisi (FIFO ile önce bundan harcanır)
    var currentRolloverBalance: Double
    /// En son kapanışı yapılan hafta başlangıç tarihi
    var lastEvaluatedWeekStart: Date
    
    @Relationship(deleteRule: .cascade) var unlockedBadges: [BadgeRecord]
}
```

### 2.5. Yeni Model: `BadgeRecord`
```swift
@Model
final class BadgeRecord {
    var id: UUID
    var badgeKey: String // "iron_will", "burger_boss" vb.
    var unlockedDate: Date
    var triggerNote: String?
}
```

---

## 3. Seviye (Bileklik) ve Rozet Kataloğu

### 3.1. Bileklik (Wristband) Kademeleri
Kullanıcının **Toplam Başarılı Hafta** sayısına (`totalSuccessfulWeeks`) göre belirlenir. Peş peşe olma şartı yoktur ve seviye asla düşmez:
1. **0 Hafta:** Beyaz Bileklik (Çaylak) - `#FFFFFF`
2. **2 Hafta:** Yeşil Bileklik (Başlangıç) - `#22C55E`
3. **4 Hafta:** Mavi Bileklik (Disiplin) - `#3B82F6`
4. **8 Hafta:** Kırmızı Bileklik (Kararlılık) - `#EF4444`
5. **12 Hafta:** Mor Bileklik (Launch Control) - `#A855F7`
6. **24 Hafta:** Altın Bileklik (Elit) - `#EAB308`
7. **52 Hafta:** Siyah Bileklik (Yenilmez / You vs. You) - `#111827` (Neon çerçeveli)

### 3.2. v2.0 Rozet Kataloğu (Mesafe/İrtifa Olmaksızın)

#### A. Charge (Efor) Rozetleri
1. **Demir İrade (Iron Will):** Aynı haftada 3 gün direnç antrenmanı kaydetmek.
2. **Tükenmez Pil (Endless Battery):** Tek seansta $\ge 500$ kcal yakmak.
3. **Hafta Sonu Savaşçısı (Weekend Warrior):** Cumartesi veya Pazar günü $\ge 400$ kcal antrenman yapmak.
4. **İlk Şarj (First Charge):** İlk antrenman kaydı.
5. **7K Charge:** Kümülatif 7.000 kcal antrenman barajı (1 kg yağ dengi).
6. **14K Charge:** Kümülatif 14.000 kcal antrenman barajı (2 kg yağ dengi).
7. **28K Charge:** Kümülatif 28.000 kcal antrenman barajı (4 kg yağ dengi).
8. **Charge Machine:** Bir takvim haftasında toplam $\ge 1.500$ kcal antrenman.
9. **Early Charger:** Sabah 06:00 - 09:00 arasında antrenman kaydı.
10. **Night Charger:** Gece 21:00 - 00:00 arasında antrenman kaydı.
11. **Overcharged:** Aynı takvim gününde toplam $\ge 1.000$ kcal antrenman.

#### B. Cheat (Kaçamak) Rozetleri
1. **First Cheat:** İlk kaçamak kaydı.
2. **Cheat Happens:** İlk kez bakiye kullanarak kaçamak harcaması yapmak.
3. **Burger Boss:** 10 defa Burger kategorisinde kayıt girmek.
4. **Pizza Party:** 10 defa Pizza kategorisinde kayıt girmek.
5. **Beer O'Clock:** 10 defa Bira kategorisinde kayıt girmek.
6. **Cheat Collector:** En az 6 farklı kategoride kaçamak deneyimlemek.
7. **Cheat Weekend:** Cumartesi veya Pazar günü kaçamak kaydetmek.
8. **Agave Ruhu:** Kokteyl / Alkol kategorisinden kayıt girmek.
9. **Şeker Koması:** Arka arkaya 2 gün Tatlı kategorisinden kaçamak girmek.
10. **Sıfır Suçluluk (Zero Guilt):** Kalan bakiye pozitif kalarak tek günde $\ge 1.000$ kcal kaçamak yapmak.
11. **Klasik İkili (The Classic Duo):** Aynı günde hem Burger hem Bira kaydetmek.
12. **Taktiksel Mola (Tactical Pause):** 150 kcal altı ufak kaçamak kaydetmek.

#### C. Gizli Rozetler (Easter Eggs)
1. **Yin & Yang:** Aynı gün içinde hem $\ge 600$ kcal antrenman hem $\ge 600$ kcal kaçamak kaydetmek.
2. **Gece Kuşu (Agave Ruhu - Dark):** Cuma veya Cumartesi gecesi 23:00 - 04:00 saatleri arasında kokteyl/alkol kaydı girmek.

---

## 4. Ekran ve Sekme (Navigation) Yapısı

Uygulama 5 sekmeli modern bir yapıya kavuşur:
```
TabView
├── 1. Özet (DashboardView)
│   ├── Üst Bar: Bileklik Rozeti (Kümülatif Seviye) | Seri Alevi (🔥 Streak)
│   ├── Dinamik Sıvı Bardağı (210 kcal modüler dolum, jiroskop eğim dalgalanması, "2x" çarpanı)
│   ├── Kalan Bütçe & Devreden Bakiye Kartı (Rollover göstergesi)
│   └── Hızlı Kaçamak / Senkronizasyon Aksiyonları
├── 2. Antrenmanlar (WorkoutsView)
│   ├── Liste (Afterburn rozetli "+60 kcal Afterburn")
│   └── Sağlık Eşitleme Durumu
├── 3. Kaçamaklar (TreatsView)
│   ├── Kategori Filtreli Tüketim Geçmişi
│   └── Şablon Yönetimi (Kategori Seçicili)
├── 4. Başarımlar & Geçmiş (ProgressView) [YENİ SEKME]
│   ├── Seviye Vitrini (Kümülatif Başarılı Hafta Sayacı & Bileklik Yolculuğu)
│   ├── Rozet Galerisi (Charge, Cheat, Gizli Rozetler - Kazanılanlar / Kilitliler)
│   └── Geçmiş Haftalar İstatistik Arşivi (Haftalık Net Bilanço Grafiği)
└── 5. Ayarlar (SettingsView)
    ├── Hafta Başlangıcı: Pazartesi (sabit, yalnızca bilgi satırı; seçenek kapsam dışı)
    ├── Afterburn Çarpanı Durumu (1.2x)
    └── Manuel Veri Yönetimi & Sağlık İzinleri
```

---

## 5. Ana Ekran Widget'ı (Home Screen Widget) Mimarisi

Uygulama dışından doğrudan iOS ana ekranında bütçeyi ve motivasyonu göstermek üzere **WidgetKit** entegrasyonu:

### 5.1. Widget Boyutları ve Tasarımı
- **Küçük Boyut (`systemSmall`):**
  - **Odak:** Kalan Net Bakiye + Mini Sıvı Bardağı + Seri (🔥 Streak).
  - Bakiye pozitifse neon yeşil, negatifse neon kırmızı gösterim.
  - 210 kcal barajına göre mini bardak doluluğu ve `xN` çarpanı.
  - Güncel seri: Sağ üst köşede `🔥 4`.
- **Orta Boyut (`systemMedium`):**
  - **Sol Taraf:** Küçük boyuttaki mini bardak ve kalan net kalori.
  - **Sağ Taraf:** Haftalık özet (Kazanılan: $\text{kcal}$, Harcanan: $\text{kcal}$, Devreden: $\text{kcal}$) + Kullanıcının aktif Bileklik rengi ve unvanı (örn: Mor Bileklik - *Launch Control*).

### 5.2. Veri Paylaşımı ve Yenileme (App Group)
- **App Group:** `group.com.cheatcharge.shared` (veya proje bundle ID'sine uygun grup).
- **Paylaşılan Hafif Model (`WidgetDataPayload`):**
  ```swift
  struct WidgetDataPayload: Codable {
      let remainingCalories: Int
      let earnedCalories: Int
      let spentCalories: Int
      let rolloverCalories: Int
      let streak: Int
      let wristbandColorHex: String
      let wristbandTitle: String
      let multiplierCount: Int
      let cupFillRatio: Double
      let lastUpdated: Date
  }
  ```
- **Tetikleme (WidgetCenter):**
  - Her HealthKit senkronizasyonunda,
  - Her yeni antrenman / kaçamak eklendiğinde veya silindiğinde,
  - `WidgetCenter.shared.reloadAllTimelines()` çağrılarak ana ekran widget'ı anında güncellenir.

---

## 6. Geliştirme Fazları ve İş Paketleri

1. **Faz 1: Veri Modelleri ve Şema Geçişi** ✅ *TAMAMLANDI (bkz. Bölüm 7)*
   - `TreatCategory` enum ve `TreatItem` entegrasyonu.
   - `Workout` afterburn özellikleri (`rawCalories`, `afterburnMultiplier`).
   - `WeekRecord`, `UserGamificationState`, `BadgeRecord` SwiftData modelleri.
   - `ModelContainer` konfigürasyonunun güncellenmesi.

2. **Faz 2: Hafta Kapanış ve Devir Motoru (`WeekRolloverEngine`)** ✅ *TAMAMLANDI (bkz. Bölüm 7)*
   - Haftanın bitişini algılayan ve yeni haftaya geçerken geçmiş haftayı arşivleyen servis.
   - FIFO devir mantığı (harcamanın önce devirden, sonra bu haftadan düşmesi).
   - Kümülatif Seviye (`totalSuccessfulWeeks`) ve bağımsız Seri (`currentStreak`) hesaplama lojiği.

3. **Faz 3: Rozet Değerlendirme Motoru (`BadgeEvaluator`)** ✅ *TAMAMLANDI (bkz. Bölüm 7)*
   - Her antrenman ve kaçamak eklendiğinde arka planda çalışan rozet kontrol servisi.
   - 11 Charge + 12 Cheat + 2 Gizli rozetin tetikleme koşulları.
   - Kilit açıldığında tetiklenecek görsel bildirim modeli.

4. **Faz 4: Dinamik Sıvı Bardağı & Jiroskop (`LiquidGlassView`)** ✅ *TAMAMLANDI (bkz. Bölüm 7)*
   - 210 kcal modüler hacim ve çarpan (xN) gösterimi.
   - `CoreMotion` entegrasyonu ve `Canvas` dalga fiziği.
   - Cyber-Athletic Dark Mode paletinin uygulanması.

5. **Faz 5: Arayüz ve Navigasyon (5. Sekme AchievementsView & Dashboard)** 👉 *SIRADAKİ İŞ*
   - Dashboard'a Wristband & Streak rozetlerinin eklenmesi.
   - Yeni `ProgressView` (Bileklik seviyesi, Rozet vitrini, Geçmiş haftalık istatistikler).
   - Antrenman detay kartlarına Afterburn göstergesi eklenmesi.

6. **Faz 6: Ana Ekran Widget'ı (WidgetKit & App Group)**
   - Widget extension target ve App Group entegrasyonu.
   - Küçük (`systemSmall`) ve orta (`systemMedium`) ana ekran widget görünümleri.
   - Veri senkronizasyonu ve `WidgetCenter` tetikleme lojiği.

7. **Faz 7: Test ve Doğrulama**
   - Devir hesaplama (FIFO ve tek haftalık sonlanma) birim testleri.
   - Kümülatif seviye ve bağımsız alev serisi testleri.
   - Rozet kazanım kuralları testleri.
   - Farklı bakiye değerlerinde (0, 150, 210, 450, -100 kcal) sıvı bardağı görsel testleri.
   - Ana ekran widget canlı veri testi.

---

# 7. 🤝 HAND-OFF (Devir Teslim) — Yeni Yapay Zeka Modeli İçin

> **Son güncelleme:** 2026-10-03 · **Durum:** Faz 1 ✅ · Faz 2 ✅ · Faz 3 ✅ · Faz 4 ✅ · **Sıradaki: Faz 5** · Faz 6-7 beklemede
>
> **Önce bunu oku:** Bu bölüm, Bölüm 1-6'daki orijinal plandan **sonra** alınmış kararları ve gerçek kod durumunu içerir. Plan ile bu bölüm çelişirse **bu bölüm geçerlidir** (bkz. 7.5 "Plandan Sapmalar").

## 7.0. Proje Özeti ve Çalışma Şekli

- **Uygulama:** CheatCharge: kullanıcının yalnızca bilinçli antrenmanlarından kazandığı kaloriyi kredi olarak biriktirip "kaçamak" harcamalarıyla dengeleyen haftalık bütçe takip uygulaması. **Swift, SwiftUI, SwiftData, HealthKit. Yalnızca iOS 17+.**
- **Kod kökü:** `/Users/hsncvs/Documents/CheatCharge/CheatCharge/CheatCharge/`. Plan dosyaları: `/Users/hsncvs/Documents/CheatCharge/` (`CheatCharge_Project_Plan.md` = v1 gereksinimi, bu dosya = v2 planı).
- **Xcode projesi "senkronize klasör" yapısındadır** (`PBXFileSystemSynchronizedRootGroup`). Kaynak klasöre oluşturulan/silinen her `.swift` dosyası Xcode'a **otomatik** yansır; `.pbxproj` düzenlemeye gerek yoktur. Widget target'ı ve capability'ler (Faz 6) hariç.
- **Kullanıcı ile iletişim:** Türkçe, kısa ve net. Belirsiz kararları varsayım yapmadan **önce sorar** (`ask_question`). Dosya/sembol referanslarını tıklanabilir link olarak verir. Büyük iş sonunda ne yapıldığını ve kullanıcının Xcode'da elle yapması gerekenleri açıkça yazar.
- **Kullanıcı Garmin Venu 4 kullanıyor.** Tek kaynak: Garmin Connect → Apple Health. HealthKit verisi bu akıştan gelir.

---

## 7.1. ✅ Completed (Tamamlananlar)

### Faz 1: Veri Modelleri

| Dosya (`Models/`) | Durum |
|---|---|
| `Workout.swift` | `rawCalories`, `afterburnMultiplier` eklendi. `caloriesBurned` = `rawCalories × afterburnMultiplier` olarak **saklanır**. `sourceID` (HealthKit UUID), `isSyncedFromHealth` mevcut. |
| `TreatCategory.swift` | 9 kategorili enum (`burger, pizza, beer, cocktail, dessert, fastFood, snack, drink, other`) + `defaultIcon`. |
| `TreatItem.swift` | `categoryRaw` (varsayılan "Diğer") + tip güvenli `category` erişimcisi. |
| `TreatLog.swift` | v1'den değişmedi: `treat: TreatItem?`, `date`. Kategori `log.treat?.category` ile okunur. |
| `WeekRecord.swift` | Kapanan haftanın donuk arşivi. `weekEndDate` **dışlayıcı** sınırdır (= sonraki haftanın başı). |
| `UserGamificationState.swift` | **Singleton.** `totalSuccessfulWeeks`, `currentStreak`, `currentRolloverBalance`, `openWeekStart`, `unlockedBadges` (cascade, inverse `BadgeRecord.state`). |
| `BadgeRecord.swift` | `badgeKey`, `unlockedDate`, `triggerNote`, `state` (inverse). |

Faz 1 ile birlikte UI'a yansıyanlar:
- `AddWorkoutSheet`: ham kalori girişi; "Ağırlık" seçilince `300 kcal + 60 kcal Afterburn 🔥 = 360 kcal` önizlemesi; **saat seçici eklendi** (Early/Night Charger için); tarih aralığı **yalnızca içinde bulunulan hafta** ile sınırlı.
- `AddTreatItemSheet`: kategori seçici (kategori değişince önerilen emoji otomatik seçilir); emoji ızgarası 6 sütun / 18 emoji.

### Faz 2: Hafta Kapanış ve Devir Motoru

| Dosya | Görevi |
|---|---|
| `Utilities/WeekHelper.swift` | **Hafta her zaman Pazartesi 00:00'da başlar (sabit).** Saf, takvim tabanlı: `weekStart(containing:)`, `weekEnd(startingAt:)` (dışlayıcı), `currentWeekStart/End(now:)`, `isInCurrentWeek(_:now:)`, `weekRangeString`. Hiçbir saklanan duruma bağlı değildir. |
| `Services/WeekRolloverCalculator.swift` | **SwiftData'dan bağımsız saf hesaplayıcı.** `close(earned:spent:rollover:) -> WeekRolloverResult` (FIFO devir, başarılı hafta kuralı) ve `liveBalance(...)` = `R + E − S`. |
| `Services/WeekRolloverEngine.swift` | `@MainActor enum`. `closeElapsedWeeks(context:now:)`: `state.openWeekStart` süresi dolduysa **eksik her haftayı sırayla** kapatır: `WeekRecord` oluşturur, `totalSuccessfulWeeks`/`currentStreak`/`currentRolloverBalance` günceller, `openWeekStart`'ı ilerletir. **Hepsi tek `context.save()` ile atomiktir**; hata olursa `rollback()`. Ayrıca `fetchOrCreateState(context:)` ve `hasElapsedWeek(state:now:)`. |
| `Services/WeekMaintenanceService.swift` | `@MainActor enum`. `run(context:healthKit:)`: (1) state'i hazırla, (2) kapanacak hafta varsa ve kullanıcı daha önce HealthKit eşitlemesi yaptıysa (`lastSyncDate != nil`) **kapatmadan önce** `syncWorkouts(from: state.openWeekStart)` çalıştır, (3) motoru çalıştır. Yeniden giriş korumalıdır (`isRunning`). |
| `CheatChargeApp.swift` | `.onChange(of: scenePhase, initial: true)` ile açılışta ve her öne gelişte `WeekMaintenanceService.run` çağrılır. Şemada 6 model vardır. |
| `Views/DashboardView.swift` | Kalan bakiye = `R + E − S` (`WeekRolloverCalculator.liveBalance`). Halka oranı `spent / (earned + rollover)`. Devir > 0 ise "Devreden: +X kcal" satırı. |
| `Views/SettingsView.swift` | Hafta başı seçicisi **kaldırıldı**; salt okunur "Pazartesi" bilgi satırı. |
| `Services/HealthKitManager.swift` | `syncWorkouts(into:from:)` artık opsiyonel `startDate` alır (varsayılan: bu haftanın başı). Duplike temizliği ve güncelleme `rawCalories` üzerinden çalışır. |

### Faz 3: Rozet Değerlendirme Motoru (`BadgeEvaluator`)

| Dosya | Görevi |
|---|---|
| `Services/BadgeCatalog.swift` | 25 rozetin eksiksiz kataloğu (`BadgeDefinition`, `BadgeCategory`). 11 Charge, 12 Cheat, 2 Gizli rozet (`yin_yang`, `night_owl`). Anahtar, başlık, açıklama ve `isSecret` özellikleri. |
| `Services/BadgeRules.swift` | SwiftData'dan bağımsız **saf mantık motoru**. Hafif `WorkoutSnapshot`, `TreatSnapshot` ve `BadgeEvaluationInput` modelleriyle 25 kuralın tümünü takvim duyarlılığıyla değerlendirir. |
| `Services/BadgeUnlockCenter.swift` | `@Observable @MainActor` bildirim kuyruğu modeli. Yeni açılan rozetleri kuyruklar; `CheatChargeApp`'e `@Environment` ile enjekte edildi. |
| `Services/BadgeEvaluator.swift` | `@MainActor enum`. `evaluate(context:now:unlockCenter:)`: Tüm geçmiş kayıtları çeker, kuralları çalıştırır, zaten kazanılmış olanları atlar (idempotent), yeni `BadgeRecord` kayıtlarını `state.unlockedBadges`'e ekleyip kaydeder ve bildirim kuyruğuna yollar. |
| `CheatChargeApp.swift` | `badgeUnlockCenter` tekil instance'ı `.environment` ile tüm view hiyerarşisine bağlandı. |
| `Views/AddWorkoutSheet.swift` | Manuel antrenman kaydedildikten hemen sonra `BadgeEvaluator.evaluate` tetiklenir. |
| `Views/AddTreatLogSheet.swift` | Kaçamak log'u kaydedildikten hemen sonra `BadgeEvaluator.evaluate` tetiklenir. |
| `Services/HealthKitManager.swift` | Garmin / HealthKit eşitlemesi tamamlanıp yeni/güncellenen antrenman kaydedilince `BadgeEvaluator.evaluate` tetiklenir. |
| `DevTools/LogicTests/Faz3LogicTests.swift` | 25 kuralın pozitif/negatif senaryoları, katalog bütünlüğü ve bellek içi SwiftData entegrasyonu/idempotens testleri (60+ doğrulama) **eksiksiz geçti**. |

### Faz 4: Dinamik Sıvı Bardağı & Jiroskop (`LiquidGlassView`)

| Dosya | Görevi |
|---|---|
| `Utilities/CyberTheme.swift` | Cyber-Athletic koyu tema tasarım token'ları: neon yeşil (`#00FF66`), açık/koyu yeşiller, neon kırmızı (`#FF3B30`), neon cyan, koyu zemin (`#0D0E12`) ve kart yüzeyleri (`#161822`). |
| `Services/LiquidGlassCalculator.swift` | 210 kcal modüler bardak doluluk oranı, tam bardak adedi, çarpan rozeti (`hasMultiplier`, `"1x"`, `"2x"`, `"3x"`) ve açık (deficit) durumunu hesaplayan saf motor. |
| `Services/MotionManager.swift` | `CMMotionManager` ile telefonun sağa/sola eğim açısını (`gravity.x`) dinler, yumuşatır; Simulator/sensörsüz ortamlar için otomatik salınım simülasyonu sunar; lifecycle'da pili korur. |
| `Views/LiquidGlassView.swift` | `GlassCupShape` cam bardak silueti; `TimelineView(.animation)` + SwiftUI `Canvas` ile çift katmanlı sakin sinüs dalgası fiziği, yüzey ışıması, yükselen mikro baloncuklar, cam yansımaları, merkez kalori göstergesi, neon çarpan veya kırmızı "AÇIK" rozeti. |
| `Views/DashboardView.swift` | Eski `CalorieRingView` yerine `LiquidGlassView` entegre edildi. Özet kartları, devir satırı ve aksiyon butonları `CyberTheme` paletiyle koyu temaya geçirildi. |
| `ContentView.swift` | Tüm uygulamaya `.preferredColorScheme(.dark)` uygulandı ve `.tint(CyberTheme.neonGreen)` ile tema kilitlendi. |
| `DevTools/LogicTests/Faz4LogicTests.swift` | 210 kcal modüler hesaplamaları, 500 kcal plandaki senaryosu, tam katlar, tek bardak ve açık durumları (15+ assertion) **eksiksiz geçti**. |

### Faz 5: Arayüz ve Navigasyon (`AchievementsView` & Dashboard İlerleme) (**az önce bitirilen son iş**)

| Dosya | Görevi |
|---|---|
| `Models/WristbandTier.swift` | Kümülatif başarılı hafta sayısına göre 7 bileklik kademesi (Beyaz, Yeşil, Mavi, Kırmızı, Mor, Altın, Siyah), renkler, unvanlar, sonraki kademe hesaplaması ve ilerleme çubuğu yüzdesi matematiği. |
| `Views/AchievementsView.swift` | 5. sekme ekranı: (1) Aktif Bileklik Hero kartı, ilerleme çubuğu ve 7 kademe yolculuk haritası, (2) Kategori filtreli 25 rozet galerisi (açılanlar, kilitliler, sürpriz gizli rozetler ve detay sheet'i), (3) Kapanmış geçmiş haftaların net bilanço ($E + R - S$) ve devir akış arşivi. |
| `Views/DashboardView.swift` | Üst navigation bar'a sol tarafta kullanıcının güncel Bileklik seviyesi rozeti (ör. "Launch Control"), sağ tarafta alev seri rozeti (`🔥 currentStreak`) eklendi. |
| `Views/WorkoutsView.swift` | Ağırlık ve direnç antrenmanı satırlarına `+X kcal Afterburn 🔥` neon rozeti eklendi. |
| `Views/SettingsView.swift` | "Afterburn Etkisi (EPOC)" bilgi bölümü eklendi (Ağırlık/Direnç için 1.2x / +%20 EPOC açıklaması). |
| `ContentView.swift` | 5 sekmeli yapı kuruldu: Özet, Antrenmanlar, Kaçamaklar, Başarımlar (`AchievementsView`), Ayarlar. |
| `DevTools/LogicTests/Faz5LogicTests.swift` | 7 kademe geçişleri, kalan hafta hesapları ve ilerleme yüzdeleri testleri **%100 geçti**. |

**Doğrulama sonucu (Faz 5):** Bileklik seviye vitrini, rozet galerisi ve hafta arşivi test edildi. Faz 2, Faz 3, Faz 4 ve Faz 5 regresyon testleri geçti. Bütün uygulama kaynakları `-warnings-as-errors` ile **0 hata, 0 uyarı** derlendi.

### Faz 1 öncesinden gelen (v1) özellikler: bozulmamalı
- 5 sekme: Özet, Antrenmanlar, Kaçamaklar, Başarımlar, Ayarlar (`ContentView`).
- HealthKit okuma (yalnızca `HKObjectType.workoutType()`), Garmin duplike önleme (UUID **veya** başlangıç saati ±180 sn), `context.save()`, `activeEnergyCalories` ile modern `statistics(for:)` API'si (deprecated `totalEnergyBurned` **kullanılmaz**).
- Manuel antrenman girişi (HealthKit'te kaydı olmayan antrenmanlar için; **kaldırılmamalı**), kaçamak şablonları ve log'ları, haftalık veri sıfırlama.

---

## 7.2. 🏗️ Architecture & Conventions (Mimari ve Kurallar)

### Veri akışı
```
HealthKit ──► HealthKitManager.syncWorkouts ──► SwiftData (Workout)
Manuel giriş ─► AddWorkoutSheet / AddTreatLogSheet ──► SwiftData (Workout / TreatLog)
                                   │
         ┌─────────────────────────┴──────────────────────────┐
         ▼                                                    ▼
  View'lar: @Query + hesaplanan özellik           WeekMaintenanceService (açılış / öne gelme)
  (WeekHelper.isInCurrentWeek ile süz)                       │
                                                  WeekRolloverEngine.closeElapsedWeeks
                                                  (WeekRecord + UserGamificationState)
```

### State management
- **Servis:** `HealthKitManager` bir `@Observable final class`. `CheatChargeApp`'te `@State` ile yaratılır, `.environment(healthKitManager)` ile enjekte edilir; view'larda `@Environment(HealthKitManager.self)`.
- **View'lar veriyi `@Query` ile okur.** Tüm kayıtlar çekilir, "bu hafta" süzmesi `WeekHelper.isInCurrentWeek` ile **hesaplanan özellikte** yapılır. Dashboard devir bakiyesini `@Query private var gamificationStates: [UserGamificationState]` ile okur (`.first`).
- **Servisler / motorlar `caseless enum` + `static func`** olarak yazılır (örn. `WeekRolloverEngine`, `WeekMaintenanceService`, `WeekHelper`). `ModelContext`'e dokunanlar `@MainActor`'dır.
- **İş mantığı iki katmana ayrılır:** (a) SwiftData'dan bağımsız **saf hesaplayıcı** (`WeekRolloverCalculator`), birim testi kolay; (b) hesaplayıcıyı çağırıp `ModelContext`'e yazan **motor**. **Faz 3'ün rozet mantığı da bu kalıba uymalıdır.**
- Ayarlar basit değerler için `UserDefaults`/`@AppStorage` kullanılabilir. Kullanıcı ilerlemesi (seviye, seri, devir, rozet) **SwiftData'dadır**, `UserDefaults`'ta değil.

### HealthKit veri işleme kuralları
- Yalnızca **okuma**; yalnızca antrenman türü. Günlük aktif enerji / BMR **kullanılmaz**.
- HealthKit'ten gelen kalori **HAM kaloridir** (`rawCalories`). **Afterburn yalnızca `Workout` modelinde uygulanır.**
- **Asla `workout.caloriesBurned`'a doğrudan değer atama.** Şunları kullan: `Workout(type:rawCalories:...)`, `updateRawCalories(_:)`, `updateType(_:)`. Aksi halde `raw × çarpan` ilişkisi bozulur.
- Afterburn kuralı tür adına bağlıdır: `Workout.multiplier(forType:)` → `type == "Ağırlık" ? 1.2 : 1.0`. `HKWorkoutActivityType.turkishName` `traditionalStrengthTraining/functionalStrengthTraining/coreTraining` → `"Ağırlık"` döndürür. **İki yerdeki `"Ağırlık"` dizesi senkron kalmalıdır.**
- Garmin kayıtlarını güncelleyip yeni UUID üretebilir. Eşleşme: UUID birebir **veya** `isSyncedFromHealth` + başlangıç saati farkı < 180 sn. Eşleşen kayıt güncellenir, yeni açılmaz. Eşitleme sonunda `try context.save()` çağrılır.

### Hafta ve devir kuralları (Faz 2'de uygulandı)
- Hafta **Pazartesi 00:00**'da başlar. Sınır: `[start, start+7 gün)`.
- FIFO: `S_rollover = min(S, R)`, `S_current = max(0, S − R)`, **bir sonraki devir** `R' = max(0, E − S_current)`. Devirden arta kalan **yanar**; zincirleme devir yok.
- **Başarılı hafta:** `(E + R) ≥ S` **ve** `E > 0`. Başarılıysa `totalSuccessfulWeeks += 1` ve `currentStreak += 1`; değilse yalnızca `currentStreak = 0`. **`totalSuccessfulWeeks` asla azalmaz.**
- **Kapanan haftalar donuktur:** arşiv ve devir zinciri sonradan yeniden hesaplanmaz. Manuel antrenman tarihi bu yüzden yalnızca içinde bulunulan haftayla sınırlıdır.
- Yalnızca **kapanmış** haftalar seviye/seriye girer; devam eden hafta sayılmaz.
- `UserGamificationState` **tek kayıt olmalıdır.** Her zaman `WeekRolloverEngine.fetchOrCreateState(context:)` kullan; elle `UserGamificationState()` insert etme.

### İsimlendirme ve kod standartları
- **Türkçe:** UI metinleri, `///` dokümantasyon yorumları ve `// MARK: -` başlıkları Türkçe. **Tür/tip adları ve kod tanımlayıcıları İngilizce** (`WeekRolloverEngine`, `rawCalories`). Eski, ilgisiz yorumları **silme** (kullanıcı kuralı).
- Dosya başlığı: `//  DosyaAdi.swift / CheatCharge / Created by Hasan Cavusoglu on GG.AA.YYYY.`
- Klasörler: `Models/`, `Services/`, `Utilities/`, `Views/`. Her `View` dosyasının sonunda `#Preview` bulunur (`.modelContainer(for: [...], inMemory: true)` + gerekirse `.environment(HealthKitManager())`).
- Dört sekmenin 5.'si için **`ProgressView` ADI KULLANILMAZ**; SwiftUI'ın `ProgressView`'u (spinner) ile çakışır (kodda kullanılıyor). Yeni ekranın adı **`AchievementsView`**.
- Rozet anahtarları (`badgeKey`): `snake_case`, İngilizce (bkz. 7.3.2 tablosu).
- **Sıfır uyarı politikası:** Xcode'da 0 hata / 0 uyarı hedeflenir (deprecated API kullanma).

### Doğrulama yöntemi (bu ortamda `xcodebuild` ÇALIŞMAZ)
`xcodebuild` bu makinede iOS Simulator hedefi bulamıyor; derleme için kullanıcı Xcode'u kullanır. Sen şunları kullan:

1. **Tip denetimi** (SwiftData/Observable makroları için **sandbox dışında** çalıştırılmalıdır, `BypassSandbox: true`). Cwd: `/Users/hsncvs/Documents/CheatCharge`. **Yeni dosya eklediysen listeye ekle:**
   ```bash
   xcrun --sdk iphonesimulator swiftc -typecheck -warnings-as-errors \
     -module-cache-path DevTools/.build/modcache-ios \
     -target arm64-apple-ios17.0-simulator -swift-version 5 \
     $(find CheatCharge/CheatCharge -name "*.swift")
   ```
2. **Mantık testleri** (macOS hedefi, bellek içi SwiftData; derleme adımı `BypassSandbox: true` ister). Test dosyası: `DevTools/LogicTests/Faz2LogicTests.swift`. Beklenen çıktı **"TÜM TESTLER GEÇTİ"** (araya giren `CoreData: error: Failed to create directory ...` satırı sandbox kaynaklıdır, zararsız):
   ```bash
   xcrun --sdk macosx swiftc -parse-as-library -swift-version 5 -target arm64-apple-macos14.0 \
     -module-cache-path DevTools/.build/modcache \
     CheatCharge/CheatCharge/Models/*.swift \
     CheatCharge/CheatCharge/Utilities/WeekHelper.swift \
     CheatCharge/CheatCharge/Services/WeekRolloverCalculator.swift \
     CheatCharge/CheatCharge/Services/WeekRolloverEngine.swift \
     DevTools/LogicTests/Faz2LogicTests.swift -o DevTools/.build/faz2tests \
   && DevTools/.build/faz2tests
   ```
   Faz 3 için aynı kalıpla `Faz3LogicTests.swift` yaz. Bittiğinde `DevTools/.build/` klasörünü sil.

---

## 7.3. 👉 Next Immediate Step (Sıradaki İlk İş): **Faz 6, Ana Ekran Widget'ı (Home Screen WidgetKit & App Group)**

### 7.3.1. Hedef ve Mimari
Widget'ın doğrudan ana ekrandan kilit bütçe ve motivasyon verisini anlık gösterebilmesi:
1. **Paylaşılan Hafif Model (`WidgetDataPayload`):**
   - Ana uygulama SwiftData verilerini hesaplayıp App Group (`group.com.cheatcharge.shared`) `UserDefaults` veya dosya alanına JSON olarak yazar.
   - Model içeriği: `remainingCalories`, `earnedCalories`, `spentCalories`, `rolloverCalories`, `streak`, `wristbandColorHex`, `wristbandTitle`, `multiplierCount`, `cupFillRatio`, `lastUpdated`.
2. **Widget Güncelleme Senkronizasyonu (`WidgetSyncService`):**
   - Her antrenman eklendiğinde/silindiğinde, kaçamak girildiğinde, HealthKit eşitlemesi bittiğinde veya hafta kapandığında `WidgetCenter.shared.reloadAllTimelines()` tetiklenir.
3. **Widget Boyutları:**
   - **`systemSmall`:** Kalan Net Bakiye + Mini Sıvı Bardağı (Cyber neon) + Sağ üstte Seri Alevi (`🔥 X`).
   - **`systemMedium`:** Sol tarafta küçük boyuttaki mini bardak ve kalan net kalori; sağ tarafta haftalık özet (Kazanılan, Harcanan, Devreden) + Aktif Bileklik seviyesi rozeti.

### 7.3.2. Kullanıcı/Xcode Tarafı Adımları
- Xcode projesine `CheatChargeWidget` adında yeni bir Widget Extension target'ı eklenmesi.
- Her iki target için "App Groups" capability eklenmesi (`group.com.cheatcharge.shared`).

---

## 7.4. ⚠️ Known Context / TODOs (Bilinmesi Gerekenler)

### Hassas noktalar (kodu bozmamak için)
1. **`caloriesBurned`'ı asla elle yazma** (bkz. 7.2). Tüm toplamlar (`@Query` + `reduce`) bu saklanan alana dayanır.
2. **`UserGamificationState` tek kayıt olmalı.** Çoğaltırsan Dashboard `.first` ile yanlış kaydı okuyabilir.
3. **`WeekRolloverEngine` atomikliğine dokunma.** Hafta kaydı + seviye/seri/devir + `openWeekStart` ilerlemesi **tek `save()`** içinde kalmalı. Bunu bölersen aynı haftaya çift kayıt veya kayıp ilerleme oluşur.
4. **Şema değiştirirsen:** Yeni alanlara **varsayılan değer** ver (hafif migration için). **Migration kodu yoktur.** `V2MigrationService` bilinçli olarak silindi (uygulama yayında değil). Şema kırıcı değiştiyse kullanıcı uygulamayı **silip yeniden yüklemek** zorundadır, bunu ona söyle.
5. **Kapanan haftalar donuk.** Geçmiş haftaya yazma/yeniden hesaplama ekleme.
6. **HealthKit otomatik eşitleme izin penceresi:** `WeekMaintenanceService` yalnızca `lastSyncDate != nil` ise otomatik eşitler; aksi halde kullanıcı beklenmedik izin penceresi görür.
7. `UserGamificationState.init`'in varsayılan argümanı `WeekHelper.currentWeekStart()`'a bağlıdır.

### Bekleyen / geçici / doğrulanmamış kısımlar
- **UI Geliştirmeleri (Faz 5):** ✅ Eksiksiz tamamlandı (`AchievementsView` 5. sekme, Dashboard'da Bileklik ve Seri rozetleri, `WorkoutsView`'da Afterburn neon etiketi, `SettingsView`'da Afterburn EPOC bölümü).
- **Cyber-Athletic koyu tema (Faz 4):** ✅ Faz 4'te uygulandı; `ContentView`'da `.preferredColorScheme(.dark)`, `.tint(CyberTheme.neonGreen)` ve `CyberTheme` paleti devrede.
- **Ayarlar → "Bu Haftanın Verilerini Sıfırla"** yalnızca bu haftanın antrenman/kaçamak kayıtlarını siler; `UserGamificationState`'e (devir, seviye, seri, rozetler) **dokunmaz**.
- **HealthKit sessiz atlama riski (doğrulanmadı):** `activeEnergyCalories` Garmin kaydında `activeEnergyBurned` istatistiği yoksa `0` döner ve kayıt `guard calories > 0` ile **sessizce atlanır.** Gerçek Garmin verisiyle doğrulanmalı.
- **Faz 6 (Widget)** Xcode'da kullanıcının **elle** yapması gereken adımlar içerir: Widget Extension target ekleme, her iki target'ta App Group capability (`group.com.cheatcharge.shared`). SwiftData store'u **taşıma**; widget yalnızca `WidgetDataPayload` (App Group `UserDefaults`/dosya) okur.
- **Faz 7 (Test):** Projede **henüz Xcode test target'ı yok** (target'ı kullanıcının Xcode'dan eklemesi gerekir). Şimdilik `DevTools/LogicTests/` altındaki bağımsız harness kullanılıyor; test target'ı eklenince bu senaryolar `XCTest`/Swift Testing'e taşınmalı.
- **Geç gelen Garmin verisi:** Hafta kapanırken Apple Health'e henüz düşmemiş antrenman, hafta donuk olduğu için sonradan eklenemez (bilinen ve kabul edilen sınırlama).
- Bu ortamda `xcodebuild` çalışmıyor (7.2). Kullanıcı Xcode'da derlerken uyarı/hata görürse çıktısını bekle ve düzelt.

---

## 7.5. Plandan Sapmalar (Bölüm 1-6 ile çelişen yerler: **bu tablo geçerli**)

| Plan (Bölüm 1-6) | Gerçek durum / karar |
|---|---|
| Haftanın başlangıç günü Ayarlar'dan seçilebilir | **Kapsam dışı.** Hafta her zaman **Pazartesi**. |
| 2.4: `UserGamificationState.lastEvaluatedWeekStart` | Adı **`openWeekStart`** ("kapatılmamış en eski haftanın başı"). Hafta kaydıyla atomik ilerler. |
| 2.2: `caloriesBurned` türetilmiş gibi | **Saklanan** alan (`rawCalories × çarpan`). |
| 4: 4. sekme adı `ProgressView` | **`AchievementsView`** (SwiftUI isim çakışması). |
| 6/Faz 2: `WeekRolloverEngine` tek parça | `WeekRolloverCalculator` (saf) + `WeekRolloverEngine` + `WeekMaintenanceService` olarak üçe ayrıldı. |
| v1 → v2 migration | **Yok.** Veri sıfırdan başlar; eski haftalar arşive girmez, seviye/seri/devir 0'dır. |
| Manuel antrenman tarihi serbest | Yalnızca **içinde bulunulan hafta** (+ saat seçici). |

## 7.6. Alınan Kararların Kaydı (kullanıcı onaylı)
1. Eski verilerle geçmiş haftalar **hesaplanmaz**, sıfırdan başlanır.
2. Kapanan haftalar **donuk**; manuel giriş yalnızca bu haftaya.
3. Hafta başı seçeneği **kaldırıldı**, Pazartesi sabit.
4. Uygulama **her zaman koyu tema** (Faz 4'te uygulandı).
5. Afterburn (1.2x) yalnızca `"Ağırlık"` türüne.
6. Uygulama yayında değil; şema değişince kullanıcı uygulamayı silip yeniden yükler.
7. Uygulama yalnızca **dikey (portrait)** modda çalışır (yatay yönelim devre dışı bırakıldı).
8. Bardak çarpan rozeti **sol üst köşede** daha büyük boyutta yer alır; kalori metni sıvı renginden bağımsız **beyaz** ve buzlu koyu kapsül üzerinde okunabilir yapıldı.
9. Jiroskop eğimi yerçekimiyle eşitlendi (sağa yatınca sıvı sağ duvara toplanır).
10. Bardak çarpan rozeti ilk bardak dolup bakiye 210 kcal'e ulaştığında "1x" olarak görünmeye başlar (1 tam bardak yedekte); 420 kcal'de "2x", 630 kcal'de "3x" olarak artar.
11. Bardak içi sinüs dalgalanması sakinleştirildi (akıcı ve dingin akış için dalga hızı yarıdan fazla yavaşlatıldı).
12. Telefon yan yatırıldığında yerçekimi tepkisi belirginleştirildi; eğim çarpanı ve sınırları genişletilerek sıvının bardağın üst çeperine kadar tırmanması sağlandı.
