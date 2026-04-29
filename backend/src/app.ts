import express from 'express';
import cors from 'cors';
import path from 'path';
import { errorHandler } from './middleware/errorHandler';
import { isCloudinaryEnabled } from './modules/storage/cloudinary.service';
import healthRouter from './modules/health/health.router';
import authRouter from './modules/auth/auth.router';
import identificationRouter from './modules/plant-identification/identification.router';
import plantsRouter from './modules/plants/plants.router';
import carePlansRouter from './modules/care-plans/care-plans.router';
import remindersRouter from './modules/reminders/reminders.router';
import diagnosisRouter from './modules/diagnosis/diagnosis.router';

export function createApp() {
  const app = express();

  app.use(cors());
  app.use(express.json());

  // Local dev only: serve uploaded photos from disk.
  // Production uses Cloudinary — no static serving needed.
  if (!isCloudinaryEnabled()) {
    app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));
  }

  app.use('/health', healthRouter);
  app.use('/api/auth', authRouter);
  app.use('/api/plant-identification', identificationRouter);
  app.use('/api/plants', plantsRouter);
  app.use('/api/care-plans', carePlansRouter);
  app.use('/api/reminders', remindersRouter);
  app.use('/api/diagnosis', diagnosisRouter);

  app.use(errorHandler);

  return app;
}
