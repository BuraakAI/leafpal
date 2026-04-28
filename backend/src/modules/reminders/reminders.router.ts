import { Router, Request, Response, NextFunction } from 'express';
import { authMiddleware } from '../../middleware/auth';
import { completeReminder, createReminder, getReminders } from './reminders.service';

const router = Router();

router.use(authMiddleware);

router.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const reminders = await getReminders(req.user!.id);
    res.json(reminders);
  } catch (err) {
    next(err);
  }
});

router.post('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const reminder = await createReminder(req.user!.id, req.body);
    res.status(201).json(reminder);
  } catch (err) {
    next(err);
  }
});

router.patch('/:id/complete', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const reminder = await completeReminder(req.user!.id, req.params.id);
    res.json(reminder);
  } catch (err) {
    next(err);
  }
});

export default router;
