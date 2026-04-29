import { PrismaClient } from '@prisma/client';

// Singleton Prisma client — shared across all modules
const prisma = new PrismaClient();

export default prisma;
