import fs from 'fs';
import path from 'path';
import { AppError } from '../../middleware/errorHandler';
import { SavePlantBody } from './plants.types';
import { uploadToCloudinary, deleteFromCloudinary, isCloudinaryEnabled } from '../storage/cloudinary.service';
import prisma from '../../lib/prisma';

const CULTURAL_DB: Record<string, { origin: string; family: string; funFact: string; difficulty: string }> = {
  'monstera':      { origin: 'Meksika ve Orta Amerika', family: 'Araceae', funFact: 'Yapraklarindaki delikler ruzgara karsi direnc icin evrilmistir.', difficulty: 'easy' },
  'ficus':         { origin: 'Guney ve Guneydogu Asya', family: 'Moraceae', funFact: 'Ficus cinsinde 850den fazla tur bulunur.', difficulty: 'medium' },
  'epipremnum':    { origin: 'Fransiz Polinezyasi', family: 'Araceae', funFact: 'NASA temiz hava listesinde yer alir.', difficulty: 'easy' },
  'spathiphyllum': { origin: 'Kolombiya ve Venezuela', family: 'Araceae', funFact: 'Beyaz spatas baris sembolu olarak bilinir.', difficulty: 'easy' },
  'sansevieria':   { origin: 'Bati Afrika', family: 'Asparagaceae', funFact: 'Gece de oksijen uretir, yatak odasi icin idealdir.', difficulty: 'easy' },
  'dracaena':      { origin: 'Afrika ve Asya tropikleri', family: 'Asparagaceae', funFact: 'Dracaena draco turu 6000 yil yasayabilir.', difficulty: 'easy' },
  'aloe':          { origin: 'Arabistan Yarimadasi', family: 'Asphodelaceae', funFact: 'Jeli yanik ve cilt tahrisi giderir.', difficulty: 'easy' },
  'pothos':        { origin: 'Guneydogu Asya', family: 'Araceae', funFact: 'Isiksiz ortamlarda bile yasayabilen ender bitkilerdendir.', difficulty: 'easy' },
  'philodendron':  { origin: 'Orta ve Guney Amerika', family: 'Araceae', funFact: 'Yunanca agaci seven anlamina gelir.', difficulty: 'easy' },
  'calathea':      { origin: 'Brezilya tropik ormanlari', family: 'Marantaceae', funFact: 'Gece yapraklarini yukari katlar — dua eden bitki.', difficulty: 'hard' },
  'cactus':        { origin: 'Amerika kitasi colleri', family: 'Cactaceae', funFact: 'Govdeleri yuzlerce litre su depolayabilir.', difficulty: 'easy' },
  'zamioculcas':   { origin: 'Dogu Afrika', family: 'Araceae', funFact: 'Aylarca susuz kalabilir.', difficulty: 'easy' },
  'chlorophytum':  { origin: 'Guney Afrika', family: 'Asparagaceae', funFact: '200den fazla yavrucuk surgun uretebilir.', difficulty: 'easy' },
};

function lookupCultural(scientificName: string) {
  const lower = scientificName.toLowerCase();
  for (const [key, val] of Object.entries(CULTURAL_DB)) {
    if (lower.includes(key)) return val;
  }
  return null;
}


const UPLOADS_DIR = path.join(__dirname, '..', '..', '..', 'uploads', 'plants');
if (!isCloudinaryEnabled()) {
  fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}

async function saveImageFile(plantId: string, file: Express.Multer.File): Promise<string> {
  const ext = (file.originalname?.split('.').pop() || 'jpg').toLowerCase();
  const safeExt = ['jpg', 'jpeg', 'png', 'webp', 'gif'].includes(ext) ? ext : 'jpg';
  const mimeType = file.mimetype || 'image/jpeg';

  if (isCloudinaryEnabled()) {
    return uploadToCloudinary(file.buffer, 'leafpal/plants', plantId, mimeType);
  }

  // Local dev fallback
  const filename = `${plantId}.${safeExt}`;
  const filePath = path.join(UPLOADS_DIR, filename);
  fs.writeFileSync(filePath, file.buffer);
  return `/uploads/plants/${filename}`;
}

async function cleanupPhoto(imageUrl: string | null | undefined): Promise<void> {
  if (!imageUrl) return;
  if (imageUrl.includes('cloudinary.com')) {
    await deleteFromCloudinary(imageUrl);
  } else if (imageUrl.startsWith('/uploads/plants/')) {
    const filePath = path.join(__dirname, '..', '..', '..', imageUrl);
    try { fs.unlinkSync(filePath); } catch (_) { /* ignore */ }
  }
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
    const existing = await prisma.plantSpecies.findFirst({ where: { scientificName: body.scientificName } });
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
    if (existing && !existing.origin && cultural) {
      await prisma.plantSpecies.update({ where: { id: existing.id }, data: cultural });
    }
    speciesId = species.id;
  }

  const plant = await prisma.userPlant.create({
    data: { userId, speciesId, nickname: body.nickname, location: body.location, imageUrl: body.imageUrl },
    include: { species: true },
  });

  if (imageFile) {
    const finalImageUrl = await saveImageFile(plant.id, imageFile);
    await prisma.userPlant.update({ where: { id: plant.id }, data: { imageUrl: finalImageUrl } });
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

  const waterDays = body.waterFrequencyDays || savedPlant.species.waterFrequencyDays;
  const displayName = savedPlant.species.turkishName ?? savedPlant.species.commonName;
  const now = new Date();
  await prisma.reminder.createMany({
    data: [
      { userId, userPlantId: plant.id, type: 'watering',    title: `${displayName} Sulamasi`,    dueDate: new Date(now.getTime() + waterDays * 86400000) },
      { userId, userPlantId: plant.id, type: 'fertilizing', title: `${displayName} Gubrelemesi`, dueDate: new Date(now.getTime() + 30 * 86400000) },
    ],
  });

  return savedPlant;
}

export async function uploadPlantPhoto(userId: string, plantId: string, file: Express.Multer.File) {
  const plant = await prisma.userPlant.findFirst({ where: { id: plantId, userId } });
  if (!plant) throw new AppError(404, 'Bitki bulunamadi');
  await cleanupPhoto(plant.imageUrl);
  const imageUrl = await saveImageFile(plantId, file);
  return prisma.userPlant.update({ where: { id: plantId }, data: { imageUrl }, include: { species: true, carePlan: true } });
}

export async function updatePlantNotes(userId: string, plantId: string, notes: string) {
  const plant = await prisma.userPlant.findFirst({ where: { id: plantId, userId } });
  if (!plant) throw new AppError(404, 'Bitki bulunamadi');
  return prisma.userPlant.update({ where: { id: plantId }, data: { notes }, include: { species: true, carePlan: true } });
}

export async function deletePlant(userId: string, plantId: string) {
  const plant = await prisma.userPlant.findFirst({ where: { id: plantId, userId } });
  if (!plant) throw new AppError(404, 'Bitki bulunamadi');
  await cleanupPhoto(plant.imageUrl);
  await prisma.carePlan.deleteMany({ where: { userPlantId: plantId } });
  await prisma.reminder.deleteMany({ where: { userPlantId: plantId } });
  await prisma.userPlant.delete({ where: { id: plantId } });
}

export async function getPlantById(userId: string, plantId: string) {
  const plant = await prisma.userPlant.findFirst({
    where: { id: plantId, userId },
    include: { species: true, carePlan: true, reminders: { where: { completed: false }, orderBy: { dueDate: 'asc' }, take: 5 } },
  });
  if (!plant) throw new AppError(404, 'Bitki bulunamadi');
  return plant;
}
