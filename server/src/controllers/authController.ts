import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { registerUser, loginUser, refreshAccessToken } from '../services/authService';
import { findUserById, updateUser } from '../models/User';
import { createError } from '../middleware/errorHandler';
import { AuthenticatedRequest } from '../middleware/auth';

const registerSchema = z.object({
  email: z.string().email(),
  username: z.string().min(3).max(50),
  display_name: z.string().max(100).optional(),
  password: z.string().min(6),
  user_role: z.enum(['reader', 'creator']).optional().default('reader'),
  preferences: z.any().optional()
});

const loginSchema = z.object({
  username: z.string(),
  password: z.string()
});

const refreshTokenSchema = z.object({
  refreshToken: z.string()
});

export const register = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const validatedData = registerSchema.parse(req.body);
    const authResponse = await registerUser(validatedData);
    
    res.status(201).json({
      message: 'User registered successfully',
      data: authResponse
    });
  } catch (error) {
    next(error);
  }
};

export const login = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { username, password } = loginSchema.parse(req.body);
    const authResponse = await loginUser(username, password);
    
    res.json({
      message: 'Login successful',
      data: authResponse
    });
  } catch (error) {
    next(error);
  }
};

export const refreshToken = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { refreshToken } = refreshTokenSchema.parse(req.body);
    const tokens = await refreshAccessToken(refreshToken);
    
    res.json({
      message: 'Token refreshed successfully',
      data: tokens
    });
  } catch (error) {
    next(error);
  }
};

export const getProfile = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    if (!req.user) {
      throw createError('User not authenticated', 401);
    }

    const user = await findUserById(req.user.userId);
    if (!user) {
      throw createError('User not found', 404);
    }

    res.json({
      message: 'Profile retrieved successfully',
      data: {
        id: user.id,
        username: user.username,
        display_name: user.display_name,
        email: user.email,
        user_role: user.user_role,
        avatar_url: user.avatar_url,
        preferences: user.preferences,
        created_at: user.created_at
      }
    });
  } catch (error) {
    next(error);
  }
};

export const updateProfile = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    if (!req.user) {
      throw createError('User not authenticated', 401);
    }

    const updateSchema = z.object({
      display_name: z.string().max(100).optional(),
      avatar_url: z.string().url().optional(),
      preferences: z.any().optional()
    });

    const validatedData = updateSchema.parse(req.body);
    const updatedUser = await updateUser(req.user.userId, validatedData);
    
    if (!updatedUser) {
      throw createError('User not found', 404);
    }

    res.json({
      message: 'Profile updated successfully',
      data: {
        id: updatedUser.id,
        username: updatedUser.username,
        display_name: updatedUser.display_name,
        email: updatedUser.email,
        user_role: updatedUser.user_role,
        avatar_url: updatedUser.avatar_url,
        preferences: updatedUser.preferences
      }
    });
  } catch (error) {
    next(error);
  }
};