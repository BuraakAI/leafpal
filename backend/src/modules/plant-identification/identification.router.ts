import { Router, Request, Response, NextFunction } from 'express';
import { authMiddleware } from '../../middleware/auth';
import { upload } from '../../middleware/upload';
import { checkScanAllowed } from '../auth/trial.service';
import { scanPlant } from './identification.service';
import { AppError } from '../../middleware/errorHandler';

const router = Router();

router.post(
  '/scan',
  authMiddleware,
  upload.single('image'),
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      if (!req.file) throw new AppError(400, 'Resim dosyası gereklidir');
      await checkScanAllowed(req.user!.id);
      const result = await scanPlant(req.file.buffer, req.file.mimetype, req.user!.id);
      res.json(result);
    } catch (err) {
      if (err instanceof AppError) {
        next(err);
      } else {
        const msg = err instanceof Error ? err.message : 'Bitki tanımlanamadı';
        next(new AppError(422, msg));
      }
    }
  },
);

export default router;
