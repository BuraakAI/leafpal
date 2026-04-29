import { Router } from 'express';
import { env } from '../../config/env';

const router = Router();

router.get('/', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Geçici: hangi Gemini modelleri bu key'de mevcut?
router.get('/gemini-models', async (_req, res) => {
  try {
    const url = `https://generativelanguage.googleapis.com/v1beta/models?key=${env.geminiApiKey}`;
    const r = await fetch(url);
    const data = await r.json() as any;
    const models = (data.models ?? [])
      .map((m: any) => m.name)
      .filter((n: string) => n.includes('gemini'));
    res.json({ models });
  } catch (e) {
    res.json({ error: String(e) });
  }
});

export default router;
