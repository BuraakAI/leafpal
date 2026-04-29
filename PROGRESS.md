# LeafPal — Sprint Progressu

---

## ✅ Sprint 1 — 2026-04-26 — Temel Kurulum

### M-2026-04-26-001 Tasarım Analizi
- Stitch dosyası okundu: 25+ ekran, 13 core ekran
- App adı: **LeafPal** (CLAUDE.md'de PlantCoach yazıyordu)
- Tasarım sistemi: **Botanical Minimalist**
- Font: **Manrope** (400/600/700/800)
- Renk paleti: primary `#061b0e`, background `#fbf9f4`, surface `#fbf9f4`
- Card radius 24px, butonlar pill/full

### M-2026-04-26-002 Backend (Node.js + TS + Express + Prisma)
- 25 dosya yazıldı
- 6 Prisma modeli: User, PlantSpecies, UserPlant, CarePlan, Reminder, ScanHistory
- 9 endpoint: health, auth, scan, plants, care-plans, reminders
- SQLite (PostgreSQL kurulmadığı için dev'de) — schema.prisma `provider = "sqlite"`
- Seed: 5 bitki türü + `dev-user-id` sabit ID'li demo kullanıcı
- Mock PlantIdentification provider (gerçek API gelince değişecek)
- `SKIP_AUTH=true` geliştirme modu

### M-2026-04-26-003 Flutter App Shell
- 30+ Dart dosyası yazıldı
- Tüm 13 ekran scaffold
- Riverpod state, go_router navigasyon, Dio network
- Stitch'ten birebir token: AppColors, AppTextStyles, AppTheme, AppSpacing

### Çalışan servisler (Sprint 1 sonu)
- Backend: `http://localhost:3000` ✅
- `flutter pub get` + `flutter analyze: No issues found` ✅
- `flutter create .` ile platform dosyaları oluşturuldu ✅

---

## ✅ Sprint 2 — 2026-04-26 — UI Tamamlama + API

### M-2026-04-26-004 Eksik Ekranlar
- `splash_screen.dart` — animasyonlu logo, first-launch detection
- `onboarding_screen.dart` — 3 sayfa PageView, Stitch card stack
- `onboarding_paywall_screen.dart` — "7 Gün Ücretsiz Dene"
- `diagnosis_screen.dart` — sorun tespiti, fotoğraf + belirti seçimi

### Düzeltilen akışlar
- İlk açılış: Splash → Onboarding (3 sayfa) → Paywall → Login → Home
- Login sonrası paywall tetikle (ilk kez sadece)
- Router: `/splash` initial route
- Home "Sorun Tespit Et" → `/diagnosis`

### M-2026-04-26-005 PlantNet API Entegrasyonu
- `plantnet.provider.ts` yazıldı — `/v2/identify/all` endpoint
- API Key: `.env` içinde `PLANT_API_KEY`
- `include-related-images=true` — thumbnail URL'leri alınıyor
- `PLANT_API_KEY` varsa PlantNet, yoksa mock provider
- Test sonucu: Zantedeschia, Tulipa döndürdü ✅
- Türkçe ad eşleme tablosu: 14 tür

### M-2026-04-26-006 Critical Bug Fixes
- **PathNotFoundException**: `File(xFile.path)` → `XFile.readAsBytes()` + `MultipartFile.fromBytes()`
  - Web'de `blob:http://...` URL'i gerçek dosya yolu değil
- **Scan ekranı scale**: `InteractiveViewer` + `TransformationController` — pinch-to-zoom 0.8x–5x
- **Foreign key hatası**: seed'de `dev-user-id` sabit ID yoktu → `prisma.user.upsert({ where: { id: 'dev-user-id' } })`

---

## ✅ Sprint 3 — 2026-04-27 — Bug Fix Turu

### M-2026-04-27-001 Bitki Resim Sistemi
**Sorun:** Tüm ekranlarda `Icons.eco` placeholder, `CachedNetworkImage` hiç kullanılmıyordu

**Çözüm — `core/widgets/plant_image.dart`:**
- Katman 1: PlantNet'ten gelen `imageUrl` (API'de `include-related-images=true` yapıldı)
- Katman 2: 14 bilinen tür için Wikimedia Commons stabil URL'leri (genus eşleşmesi de var)
- Katman 3: Deterministik renk gradient + baş harf fallback

**Güncellenen dosyalar:**
- `home_screen.dart` — bitki kartı görseli
- `my_plants_screen.dart` — grid kart görseli
- `plant_detail_screen.dart` — hero image
- `scan_result_screen.dart` — eşleşme kart görseli

### M-2026-04-27-002 Web Storage Fix
**Sorun:** `flutter_secure_storage` web'de `WebOptions` ayarsız hata veriyor, splash çöküyor

**Çözüm — `core/utils/secure_storage.dart`:**
- `AppStorage` singleton: `kIsWeb` kontrolü
- Web → `SharedPreferences`
- Mobil → `FlutterSecureStorage` (Android: `encryptedSharedPreferences`)
- `auth_state.dart`, `splash_screen.dart`, `api_client.dart` güncellendi

### M-2026-04-27-003 Home Gerçek Data + Scan→Save→Refresh
**Sorun:** Home hardcoded "Günaydın!", reminder kartı statik, scan sonrası plants refresh yok

**Düzeltmeler:**
- `Günaydın, Ece 🌿` — `authProvider`'dan kullanıcı adı
- Reminder summary kartı gerçek veri (bugün/yarın vadeli hatırlatıcılar)
- `ScanResult` → kaydet → `plantsProvider.refresh()` → `/plants`
- `SnackBar` floating behavior

### M-2026-04-27-004 Küçük Fixler
- `main.dart`: `initializeDateFormatting('tr_TR')` — takvim Türkçe locale
- Bottom nav: "Ana Sayfa" → "Anasayfa", "Bitkilerim" → "Bitkiler" (truncate sorunu)
- `my_plants_screen.dart`: Sulama tarihi hesabı
  - `addedAt + wateringDays` → "Yarın", "N gün sonra", "Sulama vakti!" (kırmızı)

---

---

## ✅ Sprint 5 — 2026-04-27 — UI Tamamlama + Bug Fix + Prod Config

### M-2026-04-27-004 Care Plan Tam Fix
- `plants.service.ts:savePlant` → carePlan.create'e `fertilizingDays: 30, repottingDays: 365` eklendi
- Response'a `carePlan: true` include edildi — scan sonrası kayıt tam veri döndürüyor

### M-2026-04-27-005 Dark Mode
- `app_colors.dart` → `AppColorsDark` sınıfı (botanical dark palette)
- `app_theme.dart` → `AppTheme.dark()` ThemeData
- `di.dart` → `themeModeProvider` (StateProvider<ThemeMode>)
- `app.dart` → `ConsumerWidget`, `darkTheme` + `themeMode` bağlandı
- `profile_screen.dart` → "Karanlık Mod" satırı + Switch

### M-2026-04-27-006 Reminder → Bitki Bağlantısı
- `router.dart` → `/reminder/setup` extra `({plantId, plantName})` alıyor
- `reminder_setup_screen.dart` → opsiyonel plantId/plantName, bitki banner gösterimi
- `plant_detail_screen.dart` → "Hatırlatıcı Ekle" butonu plant.id + displayName geçiyor

### M-2026-04-27-007 Onboarding Kart Animasyonu
- `PageController.addListener` ile `_pageOffset` takibi
- Back card rotation parallax, middle card counter-rotation, front card scale+fade
- Text section horizontal parallax translate

### M-2026-04-27-008 Production PostgreSQL
- `docker-compose.yml` → postgres:16-alpine
- `.env.example` → SQLite (dev) + PostgreSQL (prod) seçenekleri

### Sprint 5 Sonu — `flutter analyze` → `No issues found` ✅

---

---

## ✅ Sprint 6 — 2026-04-27 — Silme + Bildirim + Polish

### M-2026-04-27-009 Bitki Silme
- `plants.service.ts` → `deletePlant()`: carePlan + reminder cascade delete, sonra UserPlant sil
- `plants.router.ts` → `DELETE /api/plants/:id` (204)
- `plants_repository.dart` → `deletePlant(id)`
- `plants_provider.dart` → `deletePlant(id)` — optimistic state update
- `plant_detail_screen.dart` → AppBar çöp kutusu ikonu + onay dialog → `/plants`'a yönlendir

### M-2026-04-27-010 Local Notifications
- `pubspec.yaml` → `flutter_local_notifications: ^17.2.2` + `timezone: ^0.9.4`
- `AndroidManifest.xml` → 4 permission + 2 receiver (ScheduledNotification + BootReceiver)
- `core/utils/notification_service.dart` → singleton, `init()`, `scheduleReminder()`, `cancel()`
- `main.dart` → `NotificationService.instance.init()`
- `reminders_provider.dart` → `create()` artık `Reminder` döndürüyor
- `reminder_setup_screen.dart` → kaydet sonrası `scheduleReminder()` çağrısı

### M-2026-04-27-011 Pull-to-Refresh + UX Polish
- `my_plants_screen.dart` → `RefreshIndicator` + `LinearProgressIndicator` (yükleme anı)
- `reminders_screen.dart` → `RefreshIndicator`, pull-to-refresh çalışan ListView
- `flutter analyze` → `No issues found` ✅

---

---

## ✅ Sprint 6b — 2026-04-27 — Dev Bypass + Hata Mesajları

### Değişiklikler
- `app_exception.dart` → `parseApiError(e)`: DioException türüne göre Türkçe mesaj (bağlantı yok, timeout, sunucu hatası)
- `api_constants.dart` → `baseUrl` getter: `kIsWeb` → localhost, değilse `10.0.2.2` (emülatör)
- `login_screen.dart` → `parseApiError` kullan + `kDebugMode`'da "Geliştirici Girişi" butonu
  - Dev login: `dev-token` storage'a yazar, hardcoded user state set eder, trial'ı kabul eder → direkt Home
- `register_screen.dart` → `parseApiError` kullan

### Kullanım
- Emülatörde uygulamayı aç → Login ekranında en altta **"Geliştirici Girişi"** butonuna bas
- Backend olmadan direkt `/home`'a geçer
- Release build'de bu buton görünmez

---

---

## ✅ Sprint 7 — 2026-04-28 — UI Yenileme + Bug Fix Turu

### Onboarding Tam Yeniden Yazma
- Gerçek fotoğraflar: `devetabani.webp`, `kemanyaprakliincir.webp`, `kiraz.jpg`
- Full-screen hero fotoğraf + paralaks kaydırma efekti
- Koyu gradient alt panel, büyük beyaz tipografi
- Ok butonu → son sayfada "Başlayalım" animasyonu
- Fotoğraflar `assets/images/`'e kopyalandı

### Bug Fixes
| Bug | Fix |
|-----|-----|
| `/api/auth/me` kullanıcı adı dönmüyor | `auth.router.ts` → `name` eklendi, `auth.ts` AuthUser'a `name?` eklendi |
| Splash user state set etmiyordu | `splash_screen.dart` → `/me` response'dan `authProvider` + `trialProvider` güncelleniyor |
| Home "Günaydın, null" | `auth_state.dart:checkAuth` hardcoded Ece silindi; home saate göre selamlama |
| Plant detail bakım planı boş | Artık `carePlan` null ise species default değerleri gösteriliyor |
| Scan sonucu boş match crash | Empty guard + "Bitki tanımlanamadı" ekranı |
| Scan kaydet → boş ekran | Kayıt sonrası `/plants/:id` (plant detail)'e yönlendiriyor |
| Trial scan hakkı güncellenmiyordu | `TrialNotifier.refresh()` + kayıt sonrası çağrılıyor |
| Reminders FAB overlap | Height %65 → FAB'ın altında kalıyor |

---

## NEREDE KALDIK (Oturum Kesilirse Buradan Devam)

**Son durum (2026-04-27 Sprint 6):**
- Backend: `localhost:3000` — DELETE endpoint aktif, cascade delete
- Flutter: `No issues found` — bildirim sistemi, bitki silme, pull-to-refresh

**Çalıştırma komutları:**
```bash
# Backend (yeni terminalde)
cd C:\Users\burak\OneDrive\Belgeler\plant_app\backend
npm run dev

# Flutter
cd C:\Users\burak\OneDrive\Belgeler\plant_app\mobile
flutter run -d chrome    # web (bildirim çalışmaz)
flutter run              # Android/iOS (bildirim çalışır)
```

---

## ✅ Sprint 4 — 2026-04-27 — Trial Sistemi

### M-2026-04-27-003 Trial Sistemi — 3 Gün, Günde 2 Scan, Zorunlu Auth

**Yeni akış:**
```
Splash → Onboarding → Login (ZORUNLU, bypass yok)
  → Register → Paywall ("3 Günlük Denemeyi Başlat")
  → POST /api/auth/trial/accept → Home
```

**Backend değişiklikleri:**
- Prisma: `trialStartedAt`, `trialAccepted`, `isPremium`, `subscriptionEndsAt` eklendi
- `trial.service.ts`: `getTrialStatus`, `acceptTrial`, `checkScanAllowed`
- Scan endpoint: `checkScanAllowed` → 403/429 döner
- `GET /api/auth/me` + `POST /api/auth/trial/accept` endpoint'leri
- Login/Register response'a `trial` objesi eklendi
- **Kritik bug fix:** `SKIP_AUTH=true` artık gerçek JWT token'ı tanıyor

**Flutter değişiklikleri:**
- `trial_state.dart` + `auth_repository.dart` (yeni)
- Login/Register: gerçek API çağrısı, hata kutusu, Google placeholder
- Paywall: "3 Günlük Denemeyi Başlat", 2 scan/gün badge
- Scan ekranı: kalan hak rozeti + blocker ekranı
- Premium ekranı: trial durumu göstergesi
- Splash: token varsa `/api/auth/me` → paywall veya home

**Test sonuçları:**
- Yeni kayıt → `trialAccepted: false` ✅
- Trial kabul → `scansLeft: 2, canScan: true` ✅
- Kendi token ile `/me` → `isTrialAccepted: true` ✅
- Dev token → `dev-user-id` ✅

**Açık kalan sorunlar (Sprint 5):**
1. Plant detail — care plan null durumu
2. Onboarding card stack animasyonu
3. Dark mode
4. Android emülatör testi
5. Production PostgreSQL geçişi

**Dosya yapısı özeti:**
```
plant_app/
├── backend/          Node.js + TS + Express + Prisma (SQLite dev)
│   ├── src/          25 dosya — tüm modüller
│   ├── .env          DATABASE_URL + PLANT_API_KEY set
│   └── dev.db        SQLite — seeded
└── mobile/           Flutter
    └── lib/          41 Dart dosyası
        ├── app/      router, theme, di
        ├── core/     widgets (PlantImage!), network, utils
        └── features/ auth+onboarding, home, scan, plants, reminders, premium, profile, diagnosis
```

---

## ✅ Sprint 8 — 2026-04-28 — Premium UI Pass (Todolist)

### Kaynak: `C:\Users\burak\OneDrive\Desktop\todolist.txt`

| Madde | Durum |
|-------|-------|
| Onboarding fotoğraflar net + widget güzel | ✅ |
| Akıllı bakım planı → otomatik hatırlatıcı | ✅ |
| Login ekranı göz alıcı | ✅ |
| Bildirimler ana sayfada üstte | ✅ |
| Bitki detay premium redesign | ✅ |
| Takvim ekranı (calendar grid) | ✅ |
| Bitki detayda not alanı | ✅ |

### M-2026-04-28-001 Onboarding Hero Fotoğraf
- `devetabani.webp`, `kemanyaprakliincir.webp`, `kiraz.jpg` → `assets/images/` kopyalandı
- Full-screen hero fotoğraf + paralaks kaydırma efekti
- Koyu accent gradient alt panel + büyük beyaz tipografi
- Üst chip etiketi, ok butonu son sayfada "Başlayalım" yazısına dönüşüyor

### M-2026-04-28-002 Login Ekranı Yeniden Tasarım
- Hero Monstera fotoğrafı full-screen arka plan + koyu yeşil gradient
- Bottom sheet beyaz form — Manrope tipografi
- Geliştirici Girişi butonu (kDebugMode only)
- Google ile Giriş placeholder

### M-2026-04-28-003 Home Premium Pass
- Filigran: sağ üst %4.5 opacity Monstera
- AppBar bildirim ikonu — vadesi geçmiş sayısı kırmızı badge
- Bildirim banner: acil hatırlatıcılar renkli kart
- Bitki kartları: sulama acil → kırmızı badge
- Premium banner: gradient yeşil

### M-2026-04-28-004 My Plants Premium Grid
- Yeşil-krem gradient header
- Kart: sulama durumu badge (kırmızı/yeşil), green-tinted shadow
- "Yeni Bitki Ekle" kartı: yeşil tonlu

### M-2026-04-28-005 Premium Ekran Tam Yeniden Tasarım
- Koyu yeşil (`#061b0e`) full-screen arka plan
- Fotoğraf filigranı (kemanyaprakliincir + devetabani)
- Gradient plan kartları (yeşil-koyu gradient)
- Altın rozet, garantiler satırı

### M-2026-04-28-006 Profil Ekranı Premium
- Yeşil gradient header kartı + büyük avatar
- Trial/Premium durumu badge (tıklanınca premium'a git)
- Section etiketleri + ikonlu menü satırları

### M-2026-04-28-007 Takvim Ekranı — Calendar Grid
- Aylık takvim grid (external package yok, custom)
- Hatırlatıcısı olan günler yeşil nokta, gecikmiş kırmızı nokta
- Gün seçince altında o güne ait hatırlatıcılar
- Renk kodlu tile: mavi=sulama, yeşil=gübreleme, kahve=saksı
- Gecikmiş → "Gecikmiş" kırmızı badge

### M-2026-04-28-008 Bitki Detay Premium Redesign
- Full-height hero fotoğraf + gradient overlay
- Bitki adı/bilimi doğrudan fotoğraf üstünde beyaz
- 3 renk-kodlu bakım kartı (sulama=mavi, gübreleme=yeşil, saksı=kahve)
- Not bölümü zarif card içinde (düzenle/kaydet akışı)
- Hatırlatıcı Ekle butonu tam genişlik

### M-2026-04-28-009 Akıllı Otomatik Hatırlatıcı
- `plants.service.ts:savePlant` → bitki kaydedilince 2 hatırlatıcı otomatik oluşuyor
  - Sulama: türün `waterFrequencyDays` kadar sonra
  - Gübreleme: 30 gün sonra
- `PATCH /api/plants/:id/notes` endpoint eklendi
- `UserPlant.notes` alanı Prisma + Flutter modeline eklendi, DB push yapıldı

### M-2026-04-28-010 Bug Fix Turu
- `/api/auth/me` → `name` alanı eklendi, `AuthUser` tipine `name?` eklendi
- Splash: `/me` response'dan `authProvider` + `trialProvider` güncelleniyor
- `auth_state.dart:checkAuth` hardcoded "Ece" silindi
- Home saate göre selamlama (günaydın/merhaba/iyi akşamlar)
- Plant detail: `carePlan` null → species default değerleri
- Scan: boş match guard + "tanımlanamadı" ekranı
- Scan kaydet → `/plants/:id`'ye yönlendiriyor
- `TrialNotifier.refresh()` scan sonrası çağrılıyor
- `dev-user-id` için `checkScanAllowed` bypass (seed gerektirmez)
- DioException → `parseApiError()` — Türkçe hata mesajları
- `baseUrl`: web=localhost, emülatör=10.0.2.2 (otomatik)
- `build.gradle.kts`: ndkVersion 27.0.12077973 + coreLibraryDesugaring

---

## 📍 NEREDE KALDIK — 2026-04-28 (Güncel)

### Proje Durumu
| Katman | Durum |
|--------|-------|
| Backend | `localhost:3000` ✅ — PlantNet + Trial + Auto-reminder + Notes |
| Flutter | `No issues found` ✅ — 45+ Dart dosyası |
| Android build | NDK 27 + desugaring fix ✅ |
| Onboarding | Hero fotoğraf + paralaks ✅ |
| Login | Hero + bottom sheet ✅ |
| Home | Filigran + bildirim banner ✅ |
| My Plants | Premium grid ✅ |
| Plant Detail | Premium hero + care cards + notes ✅ |
| Takvim | Calendar grid ✅ |
| Premium | Koyu yeşil full redesign ✅ |
| Profil | Gradient header ✅ |

### Çalıştırma
```bash
# Backend
cd C:\Users\burak\OneDrive\Belgeler\plant_app\backend
npm run dev

# Flutter — emülatör
cd C:\Users\burak\OneDrive\Belgeler\plant_app\mobile
flutter run

# Flutter — web (bildirimler çalışmaz)
flutter run -d chrome
```

### Dev Girişi
Login ekranında "Geliştirici Girişi" butonu (debug build only)
→ Backend gerektirmez, direkt Home'a geçer

### Açık Kalan (Sonraki Sprint)
1. **Scan akışı UI** — kamera önizleme daha premium
2. **App ikonu** — varsayılan Flutter ikonu değişmeli
3. **App ismi** — `plant_app` → `LeafPal` (bundle ID, manifest)
4. **Backend production deploy** — Railway / Render
5. **Flutter production baseUrl** — deploy sonrası
6. **App Store meta** — ekran görüntüleri, açıklama, sertifika
7. Diagnosis ekranı gerçek akış
8. Premium ödeme gerçek entegrasyon (RevenueCat / IAP)
9. My Plants arama aktif
10. Kullanıcı adı düzenleme (profil)


---

## Sprint 9 - 2026-04-28 - Todolist Kapatma Turu

**Yapan:** Codex
**Kapsam:** Kullanici todolist eksiklerini kapatma, mevcut LeafPal akisini bozmadan UI/UX ve fonksiyon tamamlamalari.
**Not:** Bu bloktaki maddeler Codex tarafindan bu oturumda yapildi; onceki sprint maddeleriyle karismasin.

### Tamamlananlar
- My Plants arama alanı gerçek filtrelemeye bağlandı; takma ad, konum, Türkçe ad, yaygın ad ve bilimsel ad içinde arıyor.
- Kullanıcı bitkiyi biliyorsa tarama yapmadan ekleyebilsin diye `/plants/new` manuel bitki ekleme ekranı eklendi.
- Ana sayfa sağ üstündeki bildirim ikonu yerine aktif tarama hakkı rozeti getirildi; Premium durumda "Sınırsız" gösteriyor.
- Scan ekranındaki hak rozeti kaldırıldı; hak bilgisi artık scan içinde görünmüyor.
- Scan fotoğraf seçme ekranı premium görünümlü hero alan, net CTA'lar ve filigran görsel ile yenilendi.
- Hatırlatıcı ekleme türleri genişletildi: nemlendirme, budama, yaprak temizliği, yön çevirme, zararlı kontrolü eklendi.
- Profil hesap bölümüne "Üyelik ve Ödeme" yönetim sheet'i eklendi; paket, durum, ödeme yöntemi ve iptal aksiyonu gösteriliyor.
- Karanlık mod tercihi kalıcı hale getirildi; seçim storage'a yazılıyor ve uygulama açılışında geri yükleniyor.
- Android ve iOS görünen uygulama adı `LeafPal` olarak güncellendi.

### Doğrulama
- `mobile`: `flutter analyze` -> No issues found
- `backend`: `npm.cmd run build` -> başarılı

### Bilinçli Ertelenenler
- Dil sistemi todolist'te "sonraya bırakabilirsin" olarak not edildiği için eklenmedi.
- Gerçek ödeme entegrasyonu RevenueCat / IAP bağlanmadan canlı kart/fatura verisi üretmez; profil ve premium tarafında ürün akışı için demo UI hazır.
- Android ve iOS varsayılan Flutter launcher ikonları LeafPal yeşil yaprak ikonlarıyla değiştirildi.

---

## Sprint 10 - 2026-04-28 - Codex Görsel Düzeltme ve Log Netleştirme

**Yapan:** Codex
**Sebep:** Kullanıcı ekran görüntülerinde önceki düzeltmelerin yeterli görünmediğini, bazı Türkçe metinlerin bozuk çıktığını, fotoğrafların net olmadığını ve bazı ekranların daha da kötüleştiğini bildirdi.
**Kapsam:** Bu bölüm sadece Codex'in bu oturumdaki ikinci düzeltme turudur; önceki sprintlerle karıştırılmamalı.

### Düzeltilenler
- Onboarding ekranı yeniden düzenlendi: bozuk Türkçe metinler temizlendi, Playfair Display başlık fontu eklendi, daha güçlü kontrast ve okunabilir alt metin uygulandı.
- Onboarding ve auth görselleri yerel olarak büyütülüp keskinleştirildi; `devetabani.webp`, `kemanyaprakliincir.webp`, `kiraz.jpg` artık daha yüksek çözünürlüklü asset olarak duruyor.
- Login ekranı yeniden yazıldı: hero yazısı okunur hale getirildi, premium font eklendi, alt form paneli ekranın dibine oturtuldu, altta siyah boşluk bırakılmadı.
- Kayıt ekranı todolist isteğine göre yeniden yazıldı: arkada %40-50 opaklıkta deve tabanı filigranı, premium başlık, cam efektli input alanları ve plan/deneme bilgilendirmesi eklendi.
- Hatırlatıcı ekleme ekranı yeniden yazıldı: mojibake Türkçe metinler temizlendi, türler iki kolon premium grid'e alındı, chip karmaşası azaltıldı, başlık/tarih alanları okunur hale getirildi.
- Bitki tarama ekranı yeniden yazıldı: boş seçim ekranında görsel artık küçük bir kutu değil full-screen arka plan; alttaki gereksiz ikinci buton satırı kaldırıldı.
- Bitki detay ekranında geri tuşu `context.pop()` yerine `/plants` route'una dönecek şekilde düzeltildi; kayıt sonrası detay ekranında sıkışma riski azaltıldı.
- Görsel placeholder düzeltildi: fotoğrafı olmayan bitkilerde tek harfli düz placeholder yerine premium yaprak görselli fallback kullanılıyor.
- Profil ekranı dark mode için düzeltildi: profil gövdesi ve satır kartları artık karanlık temada koyu yüzeyleri kullanıyor.
- My Plants ekranı premiumlaştırıldı: fotoğraflı büyük header, Playfair Display başlık, açıklama ve daha zengin üst alan eklendi.

### Doğrulama
- `mobile`: `flutter analyze` -> No issues found
- `backend`: `npm.cmd run build` -> başarılı

### Kalan Notlar
- Canlı ödeme entegrasyonu hâlâ RevenueCat / IAP ürün bilgileri gerektirir.
- Tüm uygulamada yüzde yüz dark mode için kalan eski ekranlarda AppColors sabitlerinin Theme renklerine taşınması sonraki refactor işi olabilir; bu turda kullanıcının gösterdiği profil/dark mode problemi hedeflendi.

## Sprint 11 - 2026-04-28 - Premium UI Genel Pass + Dark Mode Stabilizasyonu

**Yapan:** Antigravity (Claude Opus 4.6)
**Sebep:** Kullanıcı todolist'i 15 madde içeriyordu — font, görsel netliği, karanlık mod, premium UI, hatırlatıcı türleri, tarama hakkı counter, ödeme akışı, vb.
**Kapsam:** 14 madde (dil desteği kullanıcı talimatıyla ertelendi)

### Yapılanlar

#### Onboarding (Madde 1, 2)
- Eyebrow metin boyutu 11→13, weight w900, text shadow eklendi (ör. "SULAMA VAKTİ" okunabilir)
- Başlık fontu Playfair Display 38px, subtitle 16px w500 ile daha net
- Gradient stops optimize edildi — fotoğraflar üstte net, altta okunabilir metin

#### Login (Madde 3)
- **Siyah alt katman bug fix:** `Positioned.fill` ile fotoğraf tam ekran kaplıyor, scaffold bg koyu yeşile çekildi
- Form paneli `Theme.of(context).colorScheme.surface` ile dark mode uyumlu
- Tüm form renkleri theme-aware

#### Karanlık Mod Stabilizasyonu (Madde 4)
- **Tüm ekranlar** `AppColors.xxx` sabitlerinden `Theme.of(context).colorScheme` referanslarına taşındı:
  - `home_screen.dart` — Scaffold, kartlar, butonlar, quickaction, scan pill
  - `my_plants_screen.dart` — Arama çubuğu, bitki kartları, FAB
  - `plant_detail_screen.dart` — Notlar, bakım kartları, silme diyaloğu
  - `reminders_screen.dart` — Takvim grid, hatırlatıcı kartları
  - `reminder_setup_screen.dart` — Grid, tarih seçici, kaydet butonu
  - `premium_screen.dart` — Alt beyaz panel, özellik listesi, plan kartları
  - `profile_screen.dart` — Tüm menü satırları, toggle, billing sheet
  - `router.dart` — NavBar arka plan, ikon, shadow renkleri
  - `onboarding_paywall_screen.dart` — Tüm renkler theme-aware

#### Onboarding Paywall (Madde 4, 13)
- Mojibake Türkçe karakterler düzeltildi (Ä, Ã, Å → doğru UTF-8)
- Aylık/Yıllık plan seçim kartları eklendi (animated, highlight efekti)
- Seçilen plana göre alt metin güncelleniyor

#### Kayıt Ekranı (Madde 6)
- Deve tabanı filigranı %42 opacity ile büyük ve net
- Playfair Display başlık (38px)
- Premium plan bilgilendirme kartı (gradient, mini taglar: ₺99/ay, ₺799/yıl, 3 gün)
- Glass field efekti dark mode'da da çalışıyor

#### Hatırlatıcı Ekle (Madde 7)
- **3 sütun grid** (eski 2 yerine) — kartlar yapışık değil, 12px spacing
- 9 bakım türü: Sulama, Gübreleme, Saksı Değişimi, Nemlendirme, Budama, Yaprak Temizliği, Yön Çevirme, Zararlı Kontrolü, Özel
- Seçili kartlarda tür rengiyle gradient + shadow
- Playfair Display başlık, gradient kaydet butonu

#### Scan Ekranı (Madde 9)
- EmptyPreview gradient stops düzeltildi — fotoğraf→siyah geçişi pürüzsüz
- Bottom action panel üst kenarlığı eklendi
- Hak rozeti scan ekranında yok (confirmed removed)

#### Premium Sayfası (Madde 11)
- Başlık fontunu Playfair Display (32px) yaptı
- Filigran daha belirgin (opacity 0.08, filterQuality.high)
- Radial gradient sparkle accent
- Premium ikon amber glow

#### Profil Üyelik (Madde 12)
- Billing sheet tema uyumlu
- Premium kullanıcılar için "Üye olma tarihi" satırı
- Non-premium kullanıcılar için "Premium'a Geç" CTA butonu
- Playfair Display profil adı

#### Hatırlatıcı Butonları (Madde 15)
- Tamamla butonu: tür rengiyle gradient + shadow (canlı, premium)
- Yeni tür renkleri eklendi (misting, pruning, cleaning, rotation, pest_check)
- Takvim header Playfair Display (32px)

### Değişen Dosyalar
- `lib/features/auth/presentation/onboarding_screen.dart`
- `lib/features/auth/presentation/login_screen.dart`
- `lib/features/auth/presentation/register_screen.dart`
- `lib/features/auth/presentation/onboarding_paywall_screen.dart`
- `lib/features/home/presentation/home_screen.dart`
- `lib/features/my_plants/presentation/my_plants_screen.dart`
- `lib/features/my_plants/presentation/plant_detail_screen.dart`
- `lib/features/reminders/presentation/reminders_screen.dart`
- `lib/features/reminders/presentation/reminder_setup_screen.dart`
- `lib/features/plant_scan/presentation/scan_screen.dart`
- `lib/features/premium/presentation/premium_screen.dart`
- `lib/features/profile/presentation/profile_screen.dart`
- `lib/app/router.dart`

### Doğrulama
- `flutter analyze` → 0 errors, 0 warnings (10 info-level prefer_const hints)

### Sonraki Adımlar
- Gerçek RevenueCat/IAP ödeme entegrasyonu
- Çok dilli destek (i18n)
- Bitki fotoğraf yükleme (image_picker + backend PATCH endpoint)
- Sorun Teşhisi akışı geliştirme

## Sprint 12 - 2026-04-28 - Filigran Kaldırma + Bitki Fotoğraf Upload Sistemi

**Yapan:** Antigravity (Claude Opus 4.6)
**Sebep:** Kullanıcı ana sayfa ve premium ekrandaki filigranları kaldırmak istedi. Ayrıca tarama sonrası bitkinin fotoğrafının otomatik olarak kaydedilmesini ve görünmesini istedi.
**Kapsam:** 3 bölüm — filigran kaldırma, backend foto upload, frontend foto akışı

### Yapılanlar

#### Bölüm 1 — Filigran Kaldırma
- `home_screen.dart` — Arka plandaki devetabanı filigranı tamamen kaldırıldı
- `premium_screen.dart` — Her iki filigran (`kemanyaprakliincir`, `devetabani`) ve radial gradient sparkle kaldırıldı
- Kullanılmayan `size` değişkeni temizlendi

#### Bölüm 2 — Backend Fotoğraf Upload Sistemi
- `app.ts` — `express.static('/uploads')` middleware eklendi; yüklenen fotoğraflar `http://host/uploads/plants/{id}.jpg` üzerinden erişilebilir
- `plants.router.ts` — `POST /` artık `upload.single('image')` ile multipart kabul ediyor; `PATCH /:id/photo` endpoint eklendi (sonradan fotoğraf değiştirmek için)
- `plants.service.ts`:
  - `saveImageFile()` fonksiyonu: Buffer'ı `uploads/plants/{plantId}.{ext}` olarak diske yazıyor
  - `savePlant()` fonksiyonuna `imageFile` opsiyonel parametresi eklendi
  - `uploadPlantPhoto()` fonksiyonu eklendi (PATCH endpoint için)
  - `deletePlant()` silinirken yüklenen dosyayı da temizliyor
  - `uploads/plants/` dizini modül yüklenirken otomatik oluşturuluyor

#### Bölüm 3 — Frontend Fotoğraf Akışı
- `scan_screen.dart` — `_selectedImage` XFile'ı artık sonuç ekranına `(matches, scannedImage)` record olarak aktarılıyor
- `router.dart` — `/scan/result` route extra tipi `({List<PlantMatch> matches, XFile? scannedImage})` record'a güncellendi; `image_picker` import eklendi
- `scan_result_screen.dart`:
  - `scannedImage` parametresi kabul ediyor
  - "Kaydet" butonunda `savePlant(match, imageFile: scannedImage)` çağırıyor
  - Tüm hardcoded `AppColors` referansları `Theme.of(context).colorScheme` ile değiştirildi (dark mode fix)
- `plants_repository.dart`:
  - `savePlant()` artık her zaman `FormData` (multipart) olarak gönderiyor
  - XFile varsa `MultipartFile.fromBytes` ile ekleniyor
  - `uploadPlantPhoto()` metodu eklendi (PATCH endpoint için)
- `plants_provider.dart` — `savePlant()` fonksiyonuna `XFile? imageFile` parametresi eklendi

#### Ek Düzeltmeler (bu oturum)
- Login ekranı: `SingleChildScrollView` kaldırıldı, form paneli artık ekrana fit oluyor (scroll yok)
- Scan ekranı: `_EmptyPreview` arka plan fotoğrafı kaldırıldı, temiz koyu gradient arka plan
- Hatırlatıcı ekle: Bitki seçici (bottom sheet) eklendi, tür butonları pill/chip tasarımına geçti

### Değişen Dosyalar (Backend)
- `src/app.ts`
- `src/modules/plants/plants.router.ts`
- `src/modules/plants/plants.service.ts`

### Değişen Dosyalar (Frontend)
- `lib/features/home/presentation/home_screen.dart`
- `lib/features/premium/presentation/premium_screen.dart`
- `lib/features/plant_scan/presentation/scan_screen.dart`
- `lib/features/plant_scan/presentation/scan_result_screen.dart`
- `lib/features/my_plants/data/plants_repository.dart`
- `lib/features/my_plants/presentation/plants_provider.dart`
- `lib/features/reminders/presentation/reminder_setup_screen.dart`
- `lib/features/auth/presentation/login_screen.dart`
- `lib/app/router.dart`

### Doğrulama
- `flutter analyze` → 0 errors, 0 warnings
- `npm.cmd run build` → başarılı

### Sonraki Adımlar
- Gerçek RevenueCat/IAP ödeme entegrasyonu
- Çok dilli destek (i18n)
- Sorun Teşhisi akışı geliştirme
- Üretim ortamı için S3/Cloudinary fotoğraf depolama

---
> Oturum kapandı: 2026-04-28 10:48


---

## Sprint 13 — 2026-04-28 — Backend Deploy + Profil Düzenleme + Diagnosis Gerçek Akış

### M-2026-04-28-011 Kullanıcı Adı Düzenleme
- `PATCH /api/auth/profile` endpoint eklendi (auth.service + auth.router)
- Flutter: `AuthRepository.updateProfile()` + `AuthNotifier.updateName()`
- `profile_screen.dart`: "Ad Soyad" satırı + kalem ikonu + dialog

### M-2026-04-28-012 Diagnosis Ekranı Gerçek Akış
- Backend: `src/modules/diagnosis/` yeni modül — kural tabanlı 8 belirti analizi
  - `POST /api/diagnosis` endpoint (multipart, auth korumalı)
  - Severity: high/medium/low — Türkçe açıklama + çözüm önerisi
- Flutter: `diagnosis_screen.dart` tam yeniden yazma — 3 adımlı akış
  - Adım 0: Fotoğraf seç (opsiyonel, dark hero background)
  - Adım 1: Belirti seç (2-kolon grid, çoklu seçim)
  - Adım 2: Sonuç kartları (severity badge, açıklama, çözüm)

### Backend Deploy — Railway
- `schema.prisma` → provider `sqlite` → `postgresql`
- `railway.toml` oluşturuldu — buildCommand + startCommand + healthcheck
- `package.json` → `postinstall: "prisma generate"` eklendi
- `.env.example` → PostgreSQL URL formatına güncellendi
- `.env` → local dev için docker-compose PostgreSQL URL'e güncellendi

### Doğrulama
- `npm run build` → başarılı ✅
- `flutter analyze` → 0 error, 0 warning ✅

### Sonraki Adımlar
1. **Railway deploy için:** Terminal'de şunu çalıştır:
   ```bash
   cd backend
   docker-compose up -d           # Local PostgreSQL başlat
   npx prisma db push             # Şemayı oluştur
   npx ts-node src/prisma/seed.ts # Seed
   npm run dev                    # Test et
   ```
2. Railway'de deploy:
   - GitHub'a push
   - Railway'de "New Project → Deploy from GitHub Repo"
   - PostgreSQL plugin ekle
   - ENV: JWT_SECRET, PLANT_API_KEY, SKIP_AUTH=false, NODE_ENV=production
3. Deploy sonrası: `api_constants.dart`'ta production `baseUrl`'i güncelle
4. Gerçek RevenueCat/IAP ödeme entegrasyonu
5. S3/Cloudinary fotoğraf depolama

---
> Oturum kapandı: 2026-04-28 10:57


---
> Oturum kapandı: 2026-04-28 22:06


---
> Oturum kapandı: 2026-04-28 22:11


### 2026-04-28
- Scan screen: dark gradient → temiz/premium _EmptyState tasarımı (cs.* renkler, köşe bracketler, ActionCard butonlar)
- ManualPlantScreen: context.go → context.push (geri nav fix), filigran kaldırıldı, hardcoded AppColors → cs.*
- Dark theme: ColorScheme'e surfaceContainer* alanları eklendi (light + dark)
- Diagnosis screen: gradient kaldırıldı, fotoğraf zorunlu (Devam Et disabled), kayıtlı bitki seçici eklendi
- ScanScreen + DiagnosisScreen: tam ekran loading animasyonu (5 adım, pulse, mesaj rotate)
- PlantImage: /uploads/ URL'leri baseUrl ile birleştiriliyor (bitki fotoğrafı fix)
- PlantSpecies: origin, family, funFact, difficulty alanları eklendi (schema + seed + Flutter model)
- PlantDetailScreen: _CulturalCard widget eklendi (köken, familya, zorluk, ilginç bilgi)
- Sonraki adım: PlantNet provider'da da funFact/family populate edilebilir; premium ekran gerçek RevenueCat bağlantısı

---
> Oturum kapandı: 2026-04-28 23:33


---

## Sprint 14 - 2026-04-29 - GCS + Cloud Run + Gemini Vision AI

**Yapan:** Claude (Cowork)
**Kapsam:** Backend deploy altyapisi, GCS fotograf depolama, Gemini Vision AI diagnosis, CI/CD

### Yapılanlar

#### Prisma
- `schema.prisma` provider: `sqlite` -> `postgresql`

#### Google Cloud Storage (GCS)
- `@google-cloud/storage` paketi eklendi
- `src/modules/storage/gcs.service.ts` olusturuldu
  - `uploadToGCS(folder, filename, buffer, mimeType)` -> public URL
  - `deleteFromGCS(publicUrl)` -> eski fotografi temizle
  - `isGcsEnabled()` -> GCS_BUCKET env set mi?
- `plants.service.ts` guncellendi: local disk -> GCS (dev'de local fallback korundu)
- `app.ts` guncellendi: GCS aktifse static middleware kapatilir

#### Gemini Vision AI Diagnosis
- `@google/generative-ai` paketi eklendi
- `src/modules/diagnosis/gemini.service.ts` olusturuldu
  - Model: `gemini-2.0-flash`
  - Fotograf + belirti + bitki adi -> Turkce JSON rapor
  - `{ summary, issues, generalAdvice, disclaimer }` format
- `diagnosis.router.ts` guncellendi:
  - `POST /api/diagnosis` -> mevcut kural tabanli (ucretsiz)
  - `POST /api/diagnosis/ai` -> Gemini Vision (premium only, trial kabul edenler dahil)
  - Premium kontrol: `user.isPremium || user.trialAccepted`

#### Dockerfile + GitHub Actions
- `backend/Dockerfile` olusturuldu (multi-stage, node:20-alpine)
- `backend/.dockerignore` olusturuldu
- `.github/workflows/deploy.yml` olusturuldu
  - Tetikleyici: `main` branch'e push (backend degisiklikleri)
  - Workload Identity Federation ile sifresiz GCP auth
  - GCR'a image push -> Cloud Run deploy
  - Secrets: Google Cloud Secret Manager uzerinden

#### Flutter - Diagnosis Ekrani
- `diagnosis_screen.dart` guncellendi:
  - Trial/premium kontrolu: premium ise `/api/diagnosis/ai`, degilse `/api/diagnosis`
  - AI sonucu: summary karti (AI rozeti), generalAdvice karti (yesil)
  - Kural tabanli sonuc: eski `possibleIssues` formati

#### env.ts / .env.example
- `GCS_BUCKET`, `GCS_PROJECT_ID`, `GCS_KEY_FILE`, `GEMINI_API_KEY` eklendi

### Dogrulama
- `npm run build` -> basarili
- `flutter analyze` -> Windows'ta calistir

### GCP Kurulum Adimları (senin yapman gerekenler)

1. **GCS Bucket olustur:**
   ```
   gsutil mb -l europe-west1 gs://leafpal-uploads
   gsutil iam ch allUsers:objectViewer gs://leafpal-uploads
   ```

2. **Gemini API Key al:** https://aistudio.google.com/app/apikey
   - `.env` dosyasina `GEMINI_API_KEY=...` ekle

3. **GitHub Secrets ekle:**
   - `GCP_PROJECT_ID`: GCP proje ID'n
   - `GCP_WIF_PROVIDER`: Workload Identity Provider
   - `GCP_SA_EMAIL`: Servis hesabi emaili

4. **Cloud Run servisi olustur (ilk deploy icin):**
   ```
   gcloud run deploy leafpal-backend --region europe-west1 --source backend/
   ```

5. **GCS_BUCKET secret'i Cloud Run'a ekle (deploy.yml zaten yapiyor)**

### Sonraki Adımlar
- RevenueCat entegrasyonu
- Cloud SQL (production PostgreSQL)
- Flutter production baseUrl guncellemesi


---

## Sprint 14b - 2026-04-29 - Production Deploy + Cloudinary

### Degisiklikler
- GCS yerine Cloudinary fotograf depolama secildi (web UI yeterli, CLI gerekmiyor)
- `cloudinary.service.ts` olusturuldu, `gcs.service.ts` yedekte kaldi
- `plants.service.ts` Cloudinary'ye gecti
- `app.ts` Cloudinary kontrolune guncellendi
- `.env.example` guncellendi: CLOUDINARY_CLOUD_NAME/API_KEY/API_SECRET
- `api_constants.dart` guncellendi:
  - Release build -> production Cloud Run URL
  - Debug web -> localhost:3000
  - Debug Android emulator -> 10.0.2.2:3000

### Production URL
`https://leafpal-890668370416.europe-west1.run.app`

### Test komutlari (Windows terminal)
```
# Health check
curl https://leafpal-890668370416.europe-west1.run.app/health

# Login
curl -X POST https://leafpal-890668370416.europe-west1.run.app/api/auth/login -H "Content-Type: application/json" -d "{"email":"demo@plant.app","password":"demo1234"}"

# AI Diagnosis (token ile)
curl -X POST https://leafpal-890668370416.europe-west1.run.app/api/diagnosis/ai -H "Authorization: Bearer TOKEN" -F "symptoms=["yellowing","wilting"]" -F "plantName=Monstera"
```

### Sonraki Adimlar
- RevenueCat entegrasyonu
- Cloudinary hesap ac, 3 degeri Cloud Run'a ekle
