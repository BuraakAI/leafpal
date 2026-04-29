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

  // Google Cloud Storage (eski - artık kullanılmıyor, Cloudinary'ye geçildi)
  gcsBucket: process.env.GCS_BUCKET || '',
  gcsProjectId: process.env.GCS_PROJECT_ID || '',
  gcsKeyFile: process.env.GCS_KEY_FILE || '',

  // Cloudinary (fotoğraf depolama)
  cloudinaryCloudName: process.env.CLOUDINARY_CLOUD_NAME || '',
  cloudinaryApiKey: process.env.CLOUDINARY_API_KEY || '',
  cloudinaryApiSecret: process.env.CLOUDINARY_API_SECRET || '',

  // Gemini AI
  geminiApiKey: process.env.GEMINI_API_KEY || '',

  // Perenual (bitki fotoğraf + bakım verisi zenginleştirme)
  perenualApiKey: process.env.PERENUAL_API_KEY || '',
};
