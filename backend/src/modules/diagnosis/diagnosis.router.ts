import { Router, Request, Response, NextFunction } from 'express';
import multer from 'multer';
import { authMiddleware } from '../../middleware/auth';
import { analyzePlant } from './diagnosis.service';

const router = Router();
const upload = multer({ storage: multer.memoryStorage() });

router.post('/', authMiddleware, upload.single('image'), async (req: Request, res: Response, next: NextFunction) => {
  try {
    let symptoms: string[] = [];
    if (req.body.symptoms) {
      try {
        symptoms = JSON.parse(req.body.symptoms as string);
      } catch {
        symptoms = [];
      }
    }
    const result = analyzePlant(symptoms);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

export default router;
