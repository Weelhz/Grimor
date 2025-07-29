import { Request, Response, NextFunction } from 'express';
import { AuthenticatedRequest } from './auth';
import { createError } from './errorHandler';

export type UserRole = 'reader' | 'creator' | 'admin';

export interface AuthenticatedRequestWithRole extends AuthenticatedRequest {
  user: AuthenticatedRequest['user'] & {
    role: UserRole;
  };
}

// Middleware to check if user has required role
export const requireRole = (requiredRoles: UserRole | UserRole[]) => {
  return (req: AuthenticatedRequestWithRole, res: Response, next: NextFunction) => {
    if (!req.user) {
      throw createError('User not authenticated', 401);
    }

    const roles = Array.isArray(requiredRoles) ? requiredRoles : [requiredRoles];
    
    if (!roles.includes(req.user.role)) {
      throw createError(`Access denied. Required role: ${roles.join(' or ')}`, 403);
    }

    next();
  };
};

// Specific role middlewares
export const requireCreator = requireRole(['creator', 'admin']);
export const requireAdmin = requireRole('admin');

// Check if user can upload books (creators and admins only)
export const canUploadBooks = (req: AuthenticatedRequestWithRole, res: Response, next: NextFunction) => {
  if (!req.user) {
    throw createError('User not authenticated', 401);
  }

  if (!['creator', 'admin'].includes(req.user.role)) {
    throw createError('Only creators can upload books', 403);
  }

  next();
};

// Check if user can create mood presets (creators and admins only)
export const canCreateMoodPresets = (req: AuthenticatedRequestWithRole, res: Response, next: NextFunction) => {
  if (!req.user) {
    throw createError('User not authenticated', 401);
  }

  if (!['creator', 'admin'].includes(req.user.role)) {
    throw createError('Only creators can create mood presets', 403);
  }

  next();
};

// Check if user owns a resource or has admin role
export const canModifyResource = (resourceCreatorId: string) => {
  return (req: AuthenticatedRequestWithRole, res: Response, next: NextFunction) => {
    if (!req.user) {
      throw createError('User not authenticated', 401);
    }

    if (req.user.role === 'admin' || req.user.userId === resourceCreatorId) {
      next();
    } else {
      throw createError('Access denied. You can only modify your own resources', 403);
    }
  };
};