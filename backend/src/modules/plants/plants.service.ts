import fs from 'fs';
import path from 'path';
import { PrismaClient } from '@prisma/client';
import { AppError } from '../../middleware/errorHandler';
import { SavePlantBody } from './plants.types';

// Yaygın iç mekan bitkileri için kültürel veri
const CULTURAL_DB: Record<string, { origin: string; family: string; funFact: string; difficulty: string }> = {
  'pistacia vera':    { origin: 'Orta Asya ve Orta Doğu', family: 'Anacardiaceae (Sakazağacı familyası)', funFact: 'Antep fıstığı binlerce yıldır Orta Doğu mutfağının vazgeçilmezidir. Meyveleri tam olgunlaşınca kabukları doğal olarak çatlar.', difficulty: 'medium' },
  'monstera':        { origin: 'Meksika ve Orta Amerika', family: 'Araceae (Yılanotu familyası)', funFact: 'Yapraklarındaki delikler rüzgara karşı direnç için evrilmiştir. Yetişkin yapraklar 90 cm\'e ulaşabilir.', difficulty: 'easy' },
  'ficus':           { origin: 'Güney ve Güneydoğu Asya', family: 'Moraceae (Dut familyası)', funFact: 'Ficus cinsinde 850\'den fazla tür bulunur. Tropikal ormanlarda ekosistem anahtarı bitkileri arasındadır.', difficulty: 'medium' },
  'epipremnum':      { origin: 'Fransız Polinezyası', family: 'Araceae (Yılanotu familyası)', funFact: 'NASA\'nın temiz hava çalışmasında formaldehit ve benzeni filtreleyen en etkili bitkiler arasındadır.', difficulty: 'easy' },
  'spathiphyllum':   { origin: 'Kolombiya ve Venezuela', family: 'Araceae (Yılanotu familyası)', funFact: 'Beyaz spatası barış sembolü olarak bilinir. Gece de nem çekerek ortamı ferahlatır.', difficulty: 'easy' },
  'sansevieria':     { origin: 'Batı Afrika', family: 'Asparagaceae (Kuşkonmaz familyası)', funFact: 'Diğer bitkilerden farklı olarak gece de oksijen üretir. Yatak odası için idealdir.', difficulty: 'easy' },
  'dracaena':        { origin: 'Afrika ve Asya tropikleri', family: 'Asparagaceae', funFact: 'Dracaena draco türü 6000 yıl yaşayabilir; Kanarya Adaları\'nda binlerce yıllık örnekler mevcuttur.', difficulty: 'easy' },
  'aloe':            { origin: 'Arabistan Yarımadası', family: 'Asphodelaceae (Çiçeksiz zambak familyası)', funFact: 'Mısır\'da Kleopatra\'nın güzellik sırrı olarak kullanıldığı bilinir. Jeli yanık ve cilt tahrişlerini giderir.', difficulty: 'easy' },
  'pothos':          { origin: 'Güneydoğu Asya', family: 'Araceae (Yılanotu familyası)', funFact: 'Işıksız ortamlarda bile yaşayabilen ender bitkilerden biri; ofis ve bodrum katlarda sıklıkla tercih edilir.', difficulty: 'easy' },
  'philodendron':    { origin: 'Orta ve Güney Amerika tropikleri', family: 'Araceae (Yılanotu familyası)', funFact: 'Filodendron adı Yunanca "ağacı seven" anlamına gelir; doğada ağaç gövdelerine tırmanarak büyür.', difficulty: 'easy' },
  'calathea':        { origin: 'Brezilya tropik ormanları', family: 'Marantaceae (Maranta familyası)', funFact: 'Gece yapraklarını yukarı katlayan "dua eden bitki" olarak bilinir. Bu hareket nyktinasti olarak adlandırılır.', difficulty: 'hard' },
  'cactus':          { origin: 'Amerika kıtası çölleri', family: 'Cactaceae (Kaktüs familyası)', funFact: 'Kaktüsler 35 milyon yıl önce evrilmiştir. Gövdeleri yüzlerce litre su depolayabilir.', difficulty: 'easy' },
  'succulents':      { origin: 'Küresel — çoğunlukla Afrika ve Amerika', family: 'Çeşitli familyalar', funFact: 'Sukulent yapraklar, su depolayan özel hücreler içerir. Kuraklıkta bu hücrelerdeki su serbest bırakılır.', difficulty: 'easy' },
  'zamioculcas':     { origin: 'Doğu Afrika', family: 'Araceae (Yılanotu familyası)', funFact: 'ZZ bitkisi aylarca susuz kalabilir. Yaprak ve gövdelerinde su ve besin depolayan rizomları vardır.', difficulty: 'easy' },
  'chlorophytum':    { origin: 'Güney Afrika', family: 'Asparagaceae', funFact: 'Arap otu olarak da bilinen bu bitki, 200\'den fazla yavrucuk sürgünü üretebilir. NASA listesinde hava temizleyici.', difficulty: 'easy' },
};

function lookupCultural(scientificName: string) {
  const lower = scientificName.toLowerCase();
  for (const [key, val] of Object.entries(CULTURAL_DB)) {
    if (lower.includes(key)) return val;
  }
  return null;
}

const prisma = new PrismaClient();

// Ensure uploads directory exists
const UPLOADS_DIR = path.join(__dirname, '..', '..', '..', 'uploads', 'plants');
fs.mkdirSync(UPLOADS_DIR, { recursive: true });

/**
 * Save uploaded image file to disk and return the public URL path.
 */
function saveImageFile(plantId: string, file: Express.Multer.File): string {
  const ext = file.originalname?.split('.').pop()?.toLowerCase() || 'jpg';
  const safeExt = ['jpg', 'jpeg', 'png', 'webp', 'gif'].includes(ext) ? ext : 'jpg';
  const filename = `${plantId}.${safeExt}`;
  const filePath = path.join(UPLOADS_DIR, filename);
  fs.writeFileSync(filePath, file.buffer);
  return `/uploads/plants/${filename}`;
}

export async function getPlants(userId: string) {
  return prisma.userPlant.findMany({
    where: { userId },
    include: { species: true, carePlan: true },
    orderBy: { addedAt: 'desc' },
  });
}

export async function savePlant(userId: string, body: SavePlantBody, imageFile?: Express.Multer.File) {
  let speciesId = body.speciesId;

  if (!speciesId) {
    if (!body.scientificName) throw new AppError(400, 'speciesId veya scientificName gereklidir');
    const existing = await prisma.plantSpecies.findFirst({
      where: { scientificName: body.scientificName },
    });
    const cultural = lookupCultural(body.scientificName);
    const species = existing ?? await prisma.plantSpecies.create({
      data: {
        scientificName: body.scientificName,
        commonName: body.commonName || body.scientificName,
        turkishName: body.turkishName,
        imageUrl: body.imageUrl,
        waterFrequencyDays: body.waterFrequencyDays || 7,
        lightRequirement: body.lightRequirement || 'indirect',
        ...(cultural ?? {}),
      },
    });
    // Mevcut tür kültürel veriden yoksunsa güncelle
    if (existing && !existing.origin && cultural) {
      await prisma.plantSpecies.update({ where: { id: existing.id }, data: cultural });
    }
    speciesId = species.id;
  }

  // Create plant first (to get the ID for the filename)
  const plant = await prisma.userPlant.create({
    data: {
      userId,
      speciesId,
      nickname: body.nickname,
      location: body.location,
      imageUrl: body.imageUrl, // temporary — will be overwritten if file is uploaded
    },
    include: { species: true },
  });

  // If an image file was uploaded, save it and update the imageUrl
  let finalImageUrl = plant.imageUrl;
  if (imageFile) {
    finalImageUrl = saveImageFile(plant.id, imageFile);
    await prisma.userPlant.update({
      where: { id: plant.id },
      data: { imageUrl: finalImageUrl },
    });
  }

  await prisma.carePlan.create({
    data: {
      userPlantId: plant.id,
      speciesId,
      wateringDays: body.waterFrequencyDays || plant.species.waterFrequencyDays,
      fertilizingDays: 30,
      repottingDays: 365,
    },
  });

  const savedPlant = await prisma.userPlant.findUniqueOrThrow({
    where: { id: plant.id },
    include: { species: true, carePlan: true },
  });

  // Otomatik hatırlatıcılar oluştur
  const wateringDays = body.waterFrequencyDays || savedPlant.species.waterFrequencyDays;
  const now = new Date();
  await prisma.reminder.createMany({
    data: [
      {
        userId,
        userPlantId: plant.id,
        type: 'watering',
        title: `${savedPlant.species.turkishName ?? savedPlant.species.commonName} Sulaması`,
        dueDate: new Date(now.getTime() + wateringDays * 86400000),
      },
      {
        userId,
        userPlantId: plant.id,
        type: 'fertilizing',
        title: `${savedPlant.species.turkishName ?? savedPlant.species.commonName} Gübrelemesi`,
        dueDate: new Date(now.getTime() + 30 * 86400000),
      },
    ],
  });

  return savedPlant;
}

/**
 * Upload or replace a plant's photo.
 */
export async function uploadPlantPhoto(userId: string, plantId: string, file: Express.Multer.File) {
  const plant = await prisma.userPlant.findFirst({ where: { id: plantId, userId } });
  if (!plant) throw new AppError(404, 'Bitki bulunamadı');

  const imageUrl = saveImageFile(plantId, file);

  return prisma.userPlant.update({
    where: { id: plantId },
    data: { imageUrl },
    include: { species: true, carePlan: true },
  });
}

export async function updatePlantNotes(userId: string, plantId: string, notes: string) {
  const plant = await prisma.userPlant.findFirst({ where: { id: plantId, userId } });
  if (!plant) throw new AppError(404, 'Bitki bulunamadı');

  return prisma.userPlant.update({
    where: { id: plantId },
    data: { notes },
    include: { species: true, carePlan: true },
  });
}

export async function deletePlant(userId: string, plantId: string) {
  const plant = await prisma.userPlant.findFirst({ where: { id: plantId, userId } });
  if (!plant) throw new AppError(404, 'Bitki bulunamadı');

  // Clean up uploaded photo if exists
  if (plant.imageUrl?.startsWith('/uploads/plants/')) {
    const filePath = path.join(__dirname, '..', '..', '..', plant.imageUrl);
    try { fs.unlinkSync(filePath); } catch { /* ignore if file doesn't exist */ }
  }

  await prisma.carePlan.deleteMany({ where: { userPlantId: plantId } });
  await prisma.reminder.deleteMany({ where: { userPlantId: plantId } });
  await prisma.userPlant.delete({ where: { id: plantId } });
}

export async function getPlantById(userId: string, plantId: string) {
  const plant = await prisma.userPlant.findFirst({
    where: { id: plantId, userId },
    include: {
      species: true,
      carePlan: true,
      reminders: { where: { completed: false }, orderBy: { dueDate: 'asc' }, take: 5 },
    },
  });
  if (!plant) throw new AppError(404, 'Bitki bulunamadı');
  return plant;
}
