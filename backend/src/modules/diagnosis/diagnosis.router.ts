import { Router, Request, Response, NextFunction } from 'express';
import multer from 'multer';
import { authMiddleware } from '../../middleware/auth';
import { analyzePlant } from './diagnosis.service';
import { analyzeWithGemini } from './gemini.service';
import prisma from '../../lib/prisma';

const router = Router();
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 10 * 1024 * 1024 } });

// Rule-based diagnosis (free tier)
router.post('/', authMiddleware, upload.single('image'), async (req: Request, res: Response, next: NextFunction) => {
  try {
    let symptoms: string[] = [];
    if (req.body.symptoms) {
      try { symptoms = JSON.parse(req.body.symptoms as string); } catch { symptoms = []; }
    }
    const result = analyzePlant(symptoms);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

// AI diagnosis with Gemini Vision (premium only)
router.post('/ai', authMiddleware, upload.single('image'), async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = (req as any).userId as string;

    // Premium check
    const user = await prisma.user.findUnique({ where: { id: userId } });
    const isPremium = user?.isPremium || user?.trialAccepted || false;
    if (!isPremium) {
      res.status(403).json({ error: 'Bu ozellik premium kullanicilar icindir.' });
      return;
    }

    let symptoms: string[] = [];
    if (req.body.symptoms) {
      try { symptoms = JSON.parse(req.body.symptoms as string); } catch { symptoms = []; }
    }

    const plantName = req.body.plantName as string | undefined;

    const imageBuffer = req.file?.buffer;
    const imageMimeType = req.file?.mimetype;

    const result = await analyzeWithGemini(symptoms, plantName, imageBuffer, imageMimeType);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

export default router;
