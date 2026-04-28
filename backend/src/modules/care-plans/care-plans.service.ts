import { PrismaClient } from '@prisma/client';
import { AppError } from '../../middleware/errorHandler';

const prisma = new PrismaClient();

export async function getCarePlan(userId: string, plantId: string) {
  const plant = await prisma.userPlant.findFirst({ where: { id: plantId, userId } });
  if (!plant) throw new AppError(404, 'Bitki bulunamadı');

  const plan = await prisma.carePlan.findUnique({
    where: { userPlantId: plantId },
    include: { species: true, userPlant: true },
  });
  if (!plan) throw new AppError(404, 'Bakım planı bulunamadı');
  return plan;
}

export async function createCarePlan(
  userId: string,
  body: { userPlantId: string; wateringDays?: number; fertilizingDays?: number; repottingDays?: number; notes?: string },
) {
  const plant = await prisma.userPlant.findFirst({ where: { id: body.userPlantId, userId } });
  if (!plant) throw new AppError(404, 'Bitki bulunamadı');

  return prisma.carePlan.upsert({
    where: { userPlantId: body.userPlantId },
    update: {
      wateringDays: body.wateringDays,
      fertilizingDays: body.fertilizingDays,
      repottingDays: body.repottingDays,
      notes: body.notes,
    },
    create: {
      userPlantId: body.userPlantId,
      speciesId: plant.speciesId,
      wateringDays: body.wateringDays || 7,
      fertilizingDays: body.fertilizingDays || 30,
      repottingDays: body.repottingDays || 365,
      notes: body.notes,
    },
    include: { species: true, userPlant: true },
  });
}
