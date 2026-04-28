# LeafPal — Premium Indoor Plant Care App

Flutter + Node.js MVP. Tasarım: Stitch Botanical Minimalist.

---

## Kurulum (Windows)

### Gereksinimler
- Node.js 18+
- Flutter 3.19+
- PostgreSQL 15+ (lokal veya Docker)
- Android emülatör veya fiziksel cihaz

---

### 1. Backend

```powershell
cd plant_app\backend

# .env dosyası oluştur
copy .env.example .env
# .env'i düzenle: DATABASE_URL'i PostgreSQL bağlantı bilgilerinle güncelle

# Bağımlılıkları yükle
npm install

# Veritabanı şemasını oluştur
npx prisma db push

# Seed verisi yükle (5 bitki türü + demo kullanıcı)
npm run db:seed

# Geliştirme sunucusunu başlat
npm run dev
# → http://localhost:3000/health
```

#### Demo kullanıcı
- E-posta: `demo@plant.app`
- Şifre: `demo1234`

#### .env açıklaması
```env
DATABASE_URL="postgresql://USER:PASSWORD@localhost:5432/plant_app"
JWT_SECRET="uzun-rastgele-bir-string"
PORT=3000
NODE_ENV=development
SKIP_AUTH=true          # true = auth bypass (geliştirme için)
PLANT_API_KEY=""        # Gerçek API anahtarı gelince buraya yaz
```

---

### 2. Flutter App

```powershell
cd plant_app\mobile

# Bağımlılıkları yükle
flutter pub get

# Android emülatörde çalıştır
flutter run

# iOS (macOS gerektirir)
flutter run -d ios
```

> **Not:** Android emülatöründe backend'e `http://10.0.2.2:3000` üzerinden bağlanır.
> Fiziksel cihazda `lib/core/constants/api_constants.dart` içindeki `baseUrl`'i
> bilgisayarınızın lokal IP'siyle değiştirin (örn. `http://192.168.1.x:3000`).

---

## Proje Yapısı

```
plant_app/
├── backend/                  # Node.js + TypeScript + Express
│   ├── src/
│   │   ├── app.ts
│   │   ├── server.ts
│   │   ├── config/env.ts
│   │   ├── prisma/
│   │   │   ├── schema.prisma
│   │   │   └── seed.ts
│   │   ├── middleware/
│   │   └── modules/
│   │       ├── health/
│   │       ├── auth/
│   │       ├── plant-identification/
│   │       ├── plants/
│   │       ├── care-plans/
│   │       └── reminders/
│   ├── .env.example
│   └── package.json
│
└── mobile/                   # Flutter
    └── lib/
        ├── main.dart
        ├── app/              # Router, theme, DI
        ├── core/             # Network, widgets, constants
        └── features/
            ├── auth/
            ├── home/
            ├── plant_scan/
            ├── my_plants/
            ├── reminders/
            ├── premium/
            └── profile/
```

---

## API Endpoint'leri

| Method | Path | Açıklama |
|--------|------|----------|
| GET | /health | Sunucu durumu |
| POST | /api/auth/register | Kayıt |
| POST | /api/auth/login | Giriş |
| POST | /api/plant-identification/scan | Bitki tara |
| GET | /api/plants | Bitkilerim |
| POST | /api/plants | Bitki kaydet |
| GET | /api/plants/:id | Bitki detayı |
| POST | /api/care-plans | Bakım planı oluştur |
| GET | /api/care-plans/:plantId | Bakım planı getir |
| GET | /api/reminders | Hatırlatıcılar |
| POST | /api/reminders | Hatırlatıcı ekle |
| PATCH | /api/reminders/:id/complete | Tamamlandı işaretle |

---

## Bilinen Kısıtlamalar (MVP)

1. Bitki tanımlama **mock** — gerçek API için `PLANT_API_KEY` ve `mock.provider.ts` yerine gerçek provider yazılmalı
2. Auth **SKIP_AUTH=true** modunda — production için `false` yapılmalı
3. Ödeme sistemi **mock** — gerçek ödeme entegrasyonu yok
4. Sorun teşhisi **placeholder** — henüz implement edilmedi
5. Push notification **yok** — lokal hatırlatıcılar eklenebilir
6. Görsel önbellek — `CachedNetworkImage` kullanılıyor ama bitki görselleri henüz gerçek URL değil

---

## Sonraki Adımlar

1. **PlantNet API** entegrasyonu (`mock.provider.ts` → gerçek provider)
2. **JWT auth** production'a al (`SKIP_AUTH=false`)
3. **Push notifications** (Firebase FCM veya local_notifications)
4. **Sorun teşhis** ekranı implement et
5. **RevenueCat** veya **Iaptic** ile gerçek ödeme
6. **Dark mode** (Stitch'te `_dark` varyantları mevcut)
7. **CI/CD** pipeline (GitHub Actions + Fastlane)
