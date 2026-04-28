import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';

export interface AuthUser {
  id: string;
  email: string;
  name?: string;
}

declare global {
  namespace Express {
    interface Request {
      user?: AuthUser;
    }
  }
}

export function authMiddleware(req: Request, res: Response, next: NextFunction): void {
  const authHeader = req.headers.authorization;

  // Token varsa her zaman verify et
  if (authHeader?.startsWith('Bearer ')) {
    const token = authHeader.slice(7);
    // Dev token → dev-user-id
    if (token === 'dev-token' && env.skipAuth && env.isDev) {
      req.user = { id: 'dev-user-id', email: 'dev@plant.app', name: 'Geliştirici' };
      next();
      return;
    }
    try {
      const payload = jwt.verify(token, env.jwtSecret) as AuthUser;
      req.user = payload;
      next();
      return;
    } catch {
      res.status(401).json({ error: 'Invalid token' });
      return;
    }
  }

  // Token yoksa: SKIP_AUTH modunda dev kullanıcı ver
  if (env.skipAuth && env.isDev) {
    req.user = { id: 'dev-user-id', email: 'dev@plant.app' };
    next();
    return;
  }

  res.status(401).json({ error: 'Unauthorized' });
}
