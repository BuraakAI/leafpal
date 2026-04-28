import dotenv from 'dotenv';
dotenv.config();

function requireEnv(key: string): string {
  const value = process.env[key];
  if (!value) throw new Error(`Missing required environment variable: ${key}`);
  return value;
}

export const env = {
  databaseUrl: requireEnv('DATABASE_URL'),
  jwtSecret: process.env.JWT_SECRET || 'dev-secret-change-in-production',
  port: parseInt(process.env.PORT || '3000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  skipAuth: process.env.SKIP_AUTH === 'true',
  plantApiKey: process.env.PLANT_API_KEY || '',
  isDev: process.env.NODE_ENV !== 'production',
};
