# Proje Planı: CheatCharge (Haftalık Kalori Dengeleyici)

## 1. Uygulama Özeti
Bu iOS uygulaması, kullanıcının yalnızca bilinçli olarak yaptığı fiziksel antrenmanlardan (koşu, ağırlık vb.) kazandığı kalorileri bir kredi sistemine dönüştüren haftalık denge takip aracıdır. Elde edilen bu krediler, kullanıcının kendi oluşturduğu özel "kaçamak" (treat) ürünleriyle (alkol, fast food) harcanır. Temel amaç, haftalık bazda net kalori dengesini sıfırda veya artıda tutmaktır.

## 2. Temel Kurallar ve Kapsam (MVP)
- **Sadece Antrenman Kalorisi:** Günlük aktif enerji veya bazal metabolizma (BMR) dikkate alınmaz. Sadece Apple Health'e kaydedilen "Antrenman (Workout)" kalorileri gelir (Örn: Garmin Connect üzerinden gelen kayıtlar).
- **Özel Kaçamak Sistemi (Custom Treats):** Dış API (FatSecret vb.) kullanılmaz. Kullanıcı kendi favori kaçamaklarını kalori değerleriyle bir kez oluşturur (Örn: "Ev Yapımı Burger - 600 kcal") ve tüketim anında listeden seçer.
- **Haftalık Döngü:** Her Pazartesi günü sayaçlar sıfırlanır.

## 3. Veri Modelleri (SwiftData)

**Model 1: Workout (Antrenman - Girdi/Kazanılan)**
- `id`: UUID
- `type`: String (Koşu, Ağırlık vb.)
- `caloriesBurned`: Double
- `date`: Date
- `isSyncedFromHealth`: Bool

**Model 2: TreatItem (Kaçamak Şablonları)**
- `id`: UUID
- `name`: String (Bira, Pizza, Çikolata)
- `calories`: Double
- `icon`: String (Emoji veya SF Symbol)

**Model 3: TreatLog (Tüketilen Kaçamaklar - Çıktı/Harcanan)**
- `id`: UUID
- `treat`: TreatItem (İlişkisel veri)
- `date`: Date

## 4. Ekranlar (UI/UX - SwiftUI)

**1. Ana Ekran (Dashboard View)**
- En üstte: "Kalan Kalori Kredisi" (Kazanılan - Harcanan formülü. Eksiye düşerse kırmızı, artıdaysa yeşil).
- Ortada: İlerleme çubuğu (Progress Bar) veya dairesel grafik.
- Alt kısımda butonlar: "Verileri Eşitle (HealthKit)" ve "Kaçamak Ekle".

**2. Antrenmanlar (Workouts View)**
- Bu hafta yapılan antrenmanların listesi (Tarih, Tür ve Kalori).
- HealthKit senkronizasyon durumu.

**3. Kaçamaklar (Treats View)**
- Tüketilen kaçamakların log kaydı listesi.
- "Yeni Kaçamak Ekle" butonu -> Tıklandığında önceden tanımlanmış `TreatItem` şablonları listelenir.
- Sağ üstte "Düzenle" ikonu -> Şablon (TreatItem) ekleme/silme yönetimi.

## 5. Teknik Altyapı
- **Dil / UI:** Swift, SwiftUI
- **Local Storage:** SwiftData
- **Servisler:** HealthKit (`HKHealthStore`) 
  - *İzinler:* YALNIZCA Okuma (Read) - `HKObjectType.workoutType()`

## 6. Geliştirme Fazları (Antigravity Prompt Adımları)
1. **Faz 1 - Veri Katmanı ve Şablonlar:** SwiftData modellerinin (`Workout`, `TreatItem`, `TreatLog`) oluşturulması.
2. **Faz 2 - Arayüz ve Manuel Akış:** Dashboard, Antrenman Listesi ve Kaçamak Listesi ekranlarının tasarlanması. `TreatItem` ekleme ve bunlardan `TreatLog` oluşturma (harcama yapma) lojiğinin yazılması.
3. **Faz 3 - HealthKit Entegrasyonu:** Sadece `HKWorkout` verilerinin son 7 gün için çekilmesi, `totalEnergyBurned` değerlerinin okunup `Workout` modeline aktarılması.
4. **Faz 4 - İş Mantığı ve Cila:** Dashboard'daki Kalan Kredi matematiğinin dinamik bağlanması, haftalık (Pazartesi) sıfırlanma (reset) lojiğinin yazılması ve UI iyileştirmeleri.
