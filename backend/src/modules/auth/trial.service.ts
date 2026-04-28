import { PrismaClient } from '@prisma/client';
import { AppError } from '../../middleware/errorHandler';

const prisma = new PrismaClient();

const TRIAL_DAYS = 3;
const DAILY_SCAN_LIMIT = 2;

export interface TrialStatus {
  isTrialAccepted: boolean;
  isPremium: boolean;
  trialDaysLeft: number;
  trialExpired: boolean;
  scansUsedToday: number;
  scansRemainingToday: number;
  canScan: boolean;
}

export async function getTrialStatus(userId: string): Promise<TrialStatus> {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) throw new AppError(404, 'Kullanıcı bulunamadı');

  if (user.isPremium) {
    return {
      isTrialAccepted: true,
      isPremium: true,
      trialDaysLeft: 999,
      trialExpired: false,
      scansUsedToday: 0,
      scansRemainingToday: 999,
      canScan: true,
    };
  }

  const now = new Date();
  let trialDaysLeft = 0;
  let trialExpired = true;

  if (user.trialStartedAt) {
    const msLeft = user.trialStartedAt.getTime() + TRIAL_DAYS * 86400000 - now.getTime();
    trialDaysLeft = Math.max(0, Math.ceil(msLeft / 86400000));
    trialExpired = msLeft <= 0;
  }

  // Bugün yapılan scan sayısı
  const startOfDay = new Date(now);
  startOfDay.setHours(0, 0, 0, 0);

  const scansToday = await prisma.scanHistory.count({
    where: { userId, createdAt: { gte: startOfDay } },
  });

  const scansRemaining = Math.max(0, DAILY_SCAN_LIMIT - scansToday);
  const canScan = user.trialAccepted && !trialExpired && scansRemaining > 0;

  return {
    isTrialAccepted: user.trialAccepted,
    isPremium: user.isPremium,
    trialDaysLeft,
    trialExpired,
    scansUsedToday: scansToday,
    scansRemainingToday: scansRemaining,
    canScan,
  };
}

export async function acceptTrial(userId: string): Promise<TrialStatus> {
  await prisma.user.update({
    where: { id: userId },
    data: {
      trialAccepted: true,
      trialStartedAt: new Date(),
    },
  });
  return getTrialStatus(userId);
}

export async function checkScanAllowed(userId: string): Promise<void> {
  if (userId === 'dev-user-id') return; // dev bypass — trial check atlanır

  const status = await getTrialStatus(userId);

  if (!status.isTrialAccepted) {
    throw new AppError(403, 'Deneme sürenizi başlatmak için ödeme sayfasını onaylayın.');
  }
  if (status.trialExpired && !status.isPremium) {
    throw new AppError(403, 'Deneme süreniz doldu. Premium\'a geçin.');
  }
  if (status.scansRemainingToday === 0 && !status.isPremium) {
    throw new AppError(429, 'Günlük 2 tarama hakkınızı kullandınız. Yarın tekrar deneyin veya Premium\'a geçin.');
  }
}
