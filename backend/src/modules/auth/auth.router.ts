import { Router, Request, Response, NextFunction } from 'express';
import { authMiddleware } from '../../middleware/auth';
import { login, register, updateProfile } from './auth.service';
import { acceptTrial, getTrialStatus } from './trial.service';

const router = Router();

router.post('/register', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await register(req.body);
    res.status(201).json(result);
  } catch (err) {
    next(err);
  }
});

router.post('/login', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await login(req.body);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

router.get('/me', authMiddleware, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const status = await getTrialStatus(req.user!.id);
    res.json({ userId: req.user!.id, email: req.user!.email, name: req.user!.name, ...status });
  } catch (err) {
    next(err);
  }
});

router.post('/trial/accept', authMiddleware, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const status = await acceptTrial(req.user!.id);
    res.json(status);
  } catch (err) {
    next(err);
  }
});

router.patch('/profile', authMiddleware, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { name } = req.body as { name: string };
    const result = await updateProfile(req.user!.id, name);
    res.json(result);
  } catch (err) {
    next(err);
  }
});

export default router;
