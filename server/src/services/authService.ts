import { generateAccessToken, generateRefreshToken, verifyRefreshToken } from '../utils/token';
import { createUser, verifyUserPassword, findUserById, CreateUserData } from '../models/User';
import { createAuditLog } from '../models/AuditLog';
import { createError } from '../middleware/errorHandler';
import logger from '../utils/logger';

export interface AuthResponse {
  user: {
    id: string;
    username: string;
    display_name?: string;
    user_role: 'reader' | 'creator' | 'admin';
    email: string;
    avatar_url?: string;
    preferences: any;
  };
  accessToken: string;
  refreshToken: string;
}

export const registerUser = async (userData: CreateUserData): Promise<AuthResponse> => {
  try {
    const user = await createUser(userData);
    
    const accessToken = generateAccessToken({ userId: user.id, username: user.username, role: user.user_role });
    const refreshToken = generateRefreshToken({ userId: user.id, username: user.username, role: user.user_role });

    // Log registration
    await createAuditLog({
      user_id: user.id,
      action: 'USER_REGISTERED',
      entity_type: 'user',
      entity_id: user.id,
      details: { username: user.username }
    });

    logger.info('User registered successfully', { userId: user.id, username: user.username });

    return {
      user: {
        id: user.id,
        username: user.username,
        display_name: user.display_name,
        user_role: user.user_role,
        email: user.email,
        avatar_url: user.avatar_url,
        preferences: user.preferences
      },
      accessToken,
      refreshToken
    };
  } catch (error: any) {
    if (error.constraint === 'users_username_key') {
      throw createError('Username already exists', 409);
    }
    throw error;
  }
};

export const loginUser = async (username: string, password: string): Promise<AuthResponse> => {
  const user = await verifyUserPassword(username, password);
  
  if (!user) {
    throw createError('Invalid credentials', 401);
  }

  const accessToken = generateAccessToken({ userId: user.id, username: user.username, role: user.user_role });
  const refreshToken = generateRefreshToken({ userId: user.id, username: user.username, role: user.user_role });

  // Log login
  await createAuditLog({
    user_id: user.id,
    action: 'USER_LOGIN',
    entity_type: 'user',
    entity_id: user.id,
    details: { username: user.username }
  });

  logger.info('User logged in successfully', { userId: user.id, username: user.username });

  return {
    user: {
      id: user.id,
      username: user.username,
      display_name: user.display_name,
      user_role: user.user_role,
      email: user.email,
      avatar_url: user.avatar_url,
      preferences: user.preferences
    },
    accessToken,
    refreshToken
  };
};

export const refreshAccessToken = async (refreshToken: string): Promise<{ accessToken: string; refreshToken: string }> => {
  try {
    const payload = verifyRefreshToken(refreshToken);
    
    // Verify user still exists
    const user = await findUserById(payload.userId);
    if (!user) {
      throw createError('User not found', 401);
    }

    const newAccessToken = generateAccessToken({ userId: user.id, username: user.username, role: user.user_role });
    const newRefreshToken = generateRefreshToken({ userId: user.id, username: user.username, role: user.user_role });

    logger.debug('Access token refreshed', { userId: user.id });

    return {
      accessToken: newAccessToken,
      refreshToken: newRefreshToken
    };
  } catch (error) {
    throw createError('Invalid refresh token', 401);
  }
};

export const validateUser = async (userId: string): Promise<boolean> => {
  const user = await findUserById(userId);
  return !!user;
};