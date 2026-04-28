import { Router, Request, Response, NextFunction } from 'express';
import { authMiddleware } from '../../middleware/auth';
import { createCarePlan, getCarePlan } from './care-plans.service';

const router = Router();

router.use(authMiddleware);

router.get('/:plantId', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const plan = await getCarePlan(req.user!.id, req.params.plantId);
    res.json(plan);
  } catch (err) {
    next(err);
  }
});

router.post('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const plan = await createCarePlan(req.user!.id, req.body);
    res.status(201).json(plan);
  } catch (err) {
    next(err);
  }
});

export default router;
