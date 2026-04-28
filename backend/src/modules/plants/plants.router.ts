import { Router, Request, Response, NextFunction } from 'express';
import { authMiddleware } from '../../middleware/auth';
import { upload } from '../../middleware/upload';
import { deletePlant, getPlantById, getPlants, savePlant, updatePlantNotes, uploadPlantPhoto } from './plants.service';

const router = Router();

router.use(authMiddleware);

// GET /api/plants — list user's plants
router.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const plants = await getPlants(req.user!.id);
    res.json(plants);
  } catch (err) {
    next(err);
  }
});

// POST /api/plants — create plant (optionally with photo)
router.post('/', upload.single('image'), async (req: Request, res: Response, next: NextFunction) => {
  try {
    // When sent as multipart, JSON fields come as strings in req.body
    const body = {
      ...req.body,
      waterFrequencyDays: req.body.waterFrequencyDays ? Number(req.body.waterFrequencyDays) : undefined,
    };
    const plant = await savePlant(req.user!.id, body, req.file);
    res.status(201).json(plant);
  } catch (err) {
    next(err);
  }
});

// GET /api/plants/:id — get single plant
router.get('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const plant = await getPlantById(req.user!.id, req.params.id);
    res.json(plant);
  } catch (err) {
    next(err);
  }
});

// PATCH /api/plants/:id/notes — update notes
router.patch('/:id/notes', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const plant = await updatePlantNotes(req.user!.id, req.params.id, req.body.notes ?? '');
    res.json(plant);
  } catch (err) {
    next(err);
  }
});

// PATCH /api/plants/:id/photo — upload/replace photo
router.patch('/:id/photo', upload.single('image'), async (req: Request, res: Response, next: NextFunction) => {
  try {
    if (!req.file) {
      res.status(400).json({ message: 'Resim dosyası gereklidir' });
      return;
    }
    const plant = await uploadPlantPhoto(req.user!.id, req.params.id, req.file);
    res.json(plant);
  } catch (err) {
    next(err);
  }
});

// DELETE /api/plants/:id — delete plant
router.delete('/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    await deletePlant(req.user!.id, req.params.id);
    res.status(204).send();
  } catch (err) {
    next(err);
  }
});

export default router;
