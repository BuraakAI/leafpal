## Orkestra konfigürasyonu

- **Project tag**: `#plant_app` — her mission dosyasının frontmatter `tags:` listesine ekle.
- **Project root**: `C:\Users\burak\OneDrive\Belgeler\plant_app`
- **Log vault**: global default (`C:\Users\burak\OneDrive\Belgeler\claude-orchestra-log`) — bu projeye özel log yok, hepsi aynı yerde, tag ile filtre.
- **Mission ID prefix**: standart `M-YYYY-MM-DD-NNN` — proje ön eki yok, tag yeter.

Maestro: yeni mission açarken frontmatter'a `tags: [plant_app, <başka relevant taglar>]` ekle.
Tüm uzmanlar: misyon dosyasında "Dokunulan dosyalar" altında `plant_app/` ile başlayan göreli yollar kullan.

You are an AI engineering team building a production-minded MVP for a premium indoor plant care mobile app.

Context:
I will provide a Stitch frontend design file/prototype. Use that design as the visual and UX reference. The goal is to convert the design into a working Flutter mobile application connected to a backend API.

Product:
The app is a premium indoor plant care coach, not just a plant identifier.

Core flow:
Scan plant photo -> show identification result -> save to My Plants -> generate care plan -> set reminders.

Target users:

- Beginner and intermediate indoor plant owners
- Users who forget watering schedules
- Users who want simple plant care guidance
- Turkish-speaking users

Tech stack:

- Mobile frontend: Flutter
- Backend: Node.js + TypeScript + Express
- Database: PostgreSQL + Prisma
- Plant identification: external API through backend only
- Development environment: Windows local development

Important rules:

- Do not call external plant identification APIs directly from the mobile app.
- API keys must stay on the backend.
- Keep the MVP simple and runnable.
- Do not overengineer.
- Do not introduce microservices, CQRS, event sourcing, or unnecessary abstractions.
- Match the Stitch design as closely as practical.
- Turkish UI copy should be used in the app.
- Code identifiers and comments should be in English.
- Prioritize working product over excessive abstraction.

Frontend requirements:
Build the Flutter app based on the Stitch design.

Architecture:
Use feature-based architecture.

Required structure:
lib/
  main.dart
  app/
    app.dart
    router.dart
    di.dart
    theme/
  core/
    constants/
    error/
    network/
    utils/
    widgets/
  features/
    auth/
    home/
    plant_scan/
    my_plants/
    reminders/
    premium/
    profile/

Required screens:

1. Splash / Welcome
2. Onboarding
3. Login / Sign up
4. Home dashboard
5. Plant scan screen
6. Scan result screen
7. My Plants collection
8. Plant detail
9. Care schedule / Calendar
10. Reminder setup
11. Problem detection placeholder
12. Premium subscription screen
13. Profile / Settings

Navigation:
Use bottom tab navigation:

- Ana Sayfa
- Bitkilerim
- Tara
- Takvim
- Profil

Core frontend behavior:

- User can open scan screen
- User can select or capture an image
- App sends image to backend scan endpoint
- App displays top plant matches
- User can save selected plant to My Plants
- User can see saved plants
- User can open plant detail
- User can see care plan information
- User can create simple reminders
- Premium page exists but real payment can be mocked initially

UI expectations:

- Follow the Stitch file closely
- Premium, calm, clean visual style
- Soft cards
- Rounded corners
- Clear typography
- Minimal clutter
- Mobile-first iOS-like feel
- Use Turkish labels and microcopy
- Keep spacing consistent
- Use reusable components for buttons, cards, loading, empty states, error states

Backend requirements:
Build or connect to a Node.js + TypeScript backend.

Required backend modules:

- auth
- plant-identification
- plants
- care-plans
- reminders
- subscriptions placeholder

Required endpoints:

- GET /health
- POST /api/plant-identification/scan
- GET /api/plants
- POST /api/plants
- GET /api/plants/:id
- POST /api/care-plans
- GET /api/reminders
- POST /api/reminders
- PATCH /api/reminders/:id/complete

Plant identification:
Create a provider abstraction:

- PlantIdentificationProvider
- PlantNetProvider or ExternalPlantProvider implementation placeholder

The backend should:

- accept image upload
- call external provider from backend only
- normalize results
- return top 3 matches
- handle errors gracefully
- support timeout/retry basics
- keep API key in environment variables

Database:
Use Prisma with PostgreSQL.

Starter models:

- User
- PlantSpecies
- UserPlant
- CarePlan
- Reminder
- ScanHistory

MVP assumptions:

- Auth can be mocked or basic JWT
- Payments can be mocked
- Problem diagnosis can be placeholder
- Push notifications can be local/reminder placeholder initially
- Plant identification can use mocked data until API key is configured

Deliverables:

1. Working Flutter mobile app
2. Working backend API
3. Prisma schema
4. Environment example files
5. README with Windows setup instructions
6. Clear folder structure
7. Basic seed/mock data
8. Short implementation summary
9. Known limitations
10. Next recommended steps

Quality requirements:

- App should run locally
- Backend should run locally
- No broken navigation
- No hardcoded API keys
- No direct external API calls from frontend
- Clean error/loading/empty states
- Code should be readable and maintainable
- Keep implementation MVP-focused

Execution instructions:

- First inspect the Stitch file/prototype and summarize the main screens and reusable components.
- Then map the Stitch screens to Flutter screens/components.
- Then implement the app shell.
- Then implement backend endpoints.
- Then connect the scan flow.
- Then connect My Plants and Care Plan flow.
- Then polish UI to match Stitch.
- Finally run lint/build checks where possible and report exact commands.

Do not expand the product beyond the MVP unless explicitly asked.
