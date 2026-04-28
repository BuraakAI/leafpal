import { PrismaClient } from '@prisma/client';
import { AppError } from '../../middleware/errorHandler';

const prisma = new PrismaClient();

export async function getReminders(userId: string) {
  return prisma.reminder.findMany({
    where: { userId, completed: false },
    include: { userPlant: { include: { species: true } } },
    orderBy: { dueDate: 'asc' },
  });
}

export async function createReminder(
  userId: string,
  body: { type: string; title: string; dueDate: string; userPlantId?: string },
) {
  return prisma.reminder.create({
    data: {
      userId,
      type: body.type,
      title: body.title,
      dueDate: new Date(body.dueDate),
      userPlantId: body.userPlantId,
    },
    include: { userPlant: { include: { species: true } } },
  });
}

export async function completeReminder(userId: string, reminderId: string) {
  const reminder = await prisma.reminder.findFirst({ where: { id: reminderId, userId } });
  if (!reminder) throw new AppError(404, 'Hatırlatıcı bulunamadı');

  return prisma.reminder.update({
    where: { id: reminderId },
    data: { completed: true, completedAt: new Date() },
  });
}
