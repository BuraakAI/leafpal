import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { PrismaClient } from '@prisma/client';
import { env } from '../../config/env';
import { AppError } from '../../middleware/errorHandler';
import { AuthResponse, LoginBody, RegisterBody } from './auth.types';
import { getTrialStatus } from './trial.service';

const prisma = new PrismaClient();

export async function register(body: RegisterBody): Promise<AuthResponse> {
  const existing = await prisma.user.findUnique({ where: { email: body.email } });
  if (existing) throw new AppError(409, 'Bu e-posta adresi zaten kullanımda');

  const hashed = await bcrypt.hash(body.password, 10);
  const user = await prisma.user.create({
    data: { email: body.email, password: hashed, name: body.name },
  });

  const token = jwt.sign({ id: user.id, email: user.email }, env.jwtSecret, { expiresIn: '30d' });
  const trial = await getTrialStatus(user.id);
  return { token, user: { id: user.id, email: user.email, name: user.name }, trial };
}

export async function login(body: LoginBody): Promise<AuthResponse> {
  const user = await prisma.user.findUnique({ where: { email: body.email } });
  if (!user) throw new AppError(401, 'E-posta veya şifre hatalı');

  const valid = await bcrypt.compare(body.password, user.password);
  if (!valid) throw new AppError(401, 'E-posta veya şifre hatalı');

  const token = jwt.sign({ id: user.id, email: user.email }, env.jwtSecret, { expiresIn: '30d' });
  const trial = await getTrialStatus(user.id);
  return { token, user: { id: user.id, email: user.email, name: user.name }, trial };
}

export async function updateProfile(userId: string, name: string): Promise<{ id: string; email: string; name: string | null }> {
  if (!name || name.trim().length === 0) throw new AppError(400, 'Ad boş olamaz');
  const user = await prisma.user.update({
    where: { id: userId },
    data: { name: name.trim() },
  });
  return { id: user.id, email: user.email, name: user.name };
}
