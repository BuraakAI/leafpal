import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  const species = [
    {
      scientificName: 'Monstera deliciosa',
      commonName: 'Swiss Cheese Plant',
      turkishName: 'İsviçre Peyniri Bitkisi',
      description: 'Tropikal kökenli, karakteristik delikli yapraklarıyla tanınan popüler iç mekan bitkisi. Hızlı büyür, uzun ömürlüdür.',
      waterFrequencyDays: 7,
      lightRequirement: 'indirect',
      humidityLevel: 'high',
      origin: 'Meksika ve Orta Amerika tropikal ormanları',
      family: 'Araceae (Yılanotu familyası)',
      funFact: 'Yapraklarındaki delikler rüzgara karşı direnç sağlamak için evrilmiştir. Yetişkin yapraklar doğada 90 cm\'e ulaşabilir.',
      difficulty: 'easy',
    },
    {
      scientificName: 'Ficus lyrata',
      commonName: 'Fiddle Leaf Fig',
      turkishName: 'Keman Yapraklı İncir',
      description: 'Büyük keman şeklindeki yapraklarıyla dekoratif bir iç mekan bitkisi. Istikrarlı ortam sever.',
      waterFrequencyDays: 10,
      lightRequirement: 'bright_indirect',
      humidityLevel: 'medium',
      origin: 'Batı Afrika tropikleri (Sierra Leone\'dan Kamerun\'a)',
      family: 'Moraceae (Dut familyası)',
      funFact: 'Viktorya döneminde (1800\'ler) salon bitkisi olarak modaya girdi. Doğada 12 metreye kadar büyüyebilir.',
      difficulty: 'hard',
    },
    {
      scientificName: 'Epipremnum aureum',
      commonName: 'Pothos',
      turkishName: 'Şeytan Sarmaşığı',
      description: 'Bakımı kolay, sarılıcı iç mekan bitkisi. Düşük ışık ve ihmal karşısında bile dayanıklıdır.',
      waterFrequencyDays: 7,
      lightRequirement: 'low_to_indirect',
      humidityLevel: 'medium',
      origin: 'Fransız Polinezyası — Mo\'orea adası',
      family: 'Araceae (Yılanotu familyası)',
      funFact: 'NASA\'nın temiz hava çalışmasında formaldehit ve benzeni filtreleyen en etkili bitkiler arasında gösterilmiştir.',
      difficulty: 'easy',
    },
    {
      scientificName: 'Spathiphyllum wallisii',
      commonName: 'Peace Lily',
      turkishName: 'Barış Çiçeği',
      description: 'Beyaz çiçekleri ve koyu yeşil yapraklarıyla hava temizleyici bir bitki. Susadığında yaprakları sarkar.',
      waterFrequencyDays: 5,
      lightRequirement: 'low_to_indirect',
      humidityLevel: 'high',
      origin: 'Kolombiya ve Venezuela tropikal ormanları',
      family: 'Araceae (Yılanotu familyası)',
      funFact: 'NASA\'nın en iyi 50 hava temizleyici bitkisi listesinde yer alır. Beyaz spatası Hristiyan geleneğinde barış ve saflığın sembolüdür.',
      difficulty: 'easy',
    },
    {
      scientificName: 'Sansevieria trifasciata',
      commonName: 'Snake Plant',
      turkishName: 'Kayınvalide Dili',
      description: 'Çok az bakım gerektiren, ihmal edilmeye dayanıklı sert yapraklı bir bitki. Neredeyse her koşulda yaşar.',
      waterFrequencyDays: 14,
      lightRequirement: 'any',
      humidityLevel: 'low',
      origin: 'Batı Afrika — Nijerya ve Kongo bölgesi',
      family: 'Asparagaceae (Kuşkonmaz familyası)',
      funFact: 'Diğer bitkilerden farklı olarak gece de oksijen üretir. Bu özelliği yatak odası için ideal kılar.',
      difficulty: 'easy',
    },
  ];

  for (const s of species) {
    const existing = await prisma.plantSpecies.findFirst({
      where: { scientificName: s.scientificName },
    });
    if (existing) {
      await prisma.plantSpecies.update({ where: { id: existing.id }, data: s });
    } else {
      await prisma.plantSpecies.create({ data: s });
    }
  }

  const hashed = await bcrypt.hash('demo1234', 10);
  await prisma.user.upsert({
    where: { id: 'dev-user-id' },
    update: { trialAccepted: true, trialStartedAt: new Date() },
    create: {
      id: 'dev-user-id',
      email: 'demo@plant.app',
      password: hashed,
      name: 'Demo Kullanıcı',
      trialAccepted: true,
      trialStartedAt: new Date(),
    },
  });

  // Dev kullanıcının bugünkü scan geçmişini temizle (test için)
  const startOfDay = new Date();
  startOfDay.setHours(0, 0, 0, 0);
  await prisma.scanHistory.deleteMany({
    where: { userId: 'dev-user-id', createdAt: { gte: startOfDay } },
  });

  console.log('Seed completed: 5 species + 1 demo user (scan history cleared)');
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
