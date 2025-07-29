import jwt from 'jsonwebtoken';
import path from 'path';
import fs from 'fs';
import env from '../config/env';
import { createError } from '../middleware/errorHandler';

export interface SignedUrlPayload {
  filepath: string;
  userId?: number;
  exp?: number;
}

export const generateSignedUrl = (filepath: string, userId?: number): string => {
  const payload: SignedUrlPayload = {
    filepath,
    userId
  };

  const token = jwt.sign(payload, env.JWT_SECRET, { expiresIn: `${env.SIGNED_URL_EXPIRY}s` });
  return `/api/files/${token}`;
};

export const verifySignedUrl = (token: string): SignedUrlPayload => {
  try {
    return jwt.verify(token, env.JWT_SECRET) as SignedUrlPayload;
  } catch (error) {
    throw createError('Invalid or expired file access token', 401);
  }
};

export const validateFileAccess = async (filepath: string, userId?: number): Promise<boolean> => {
  // Check if file exists
  if (!fs.existsSync(filepath)) {
    return false;
  }

  // For now, we'll implement basic file access validation
  // In a production system, you might want to check file ownership, permissions, etc.
  const allowedExtensions = ['.pdf', '.epub', '.txt', '.mp3', '.wav', '.ogg', '.jpg', '.jpeg', '.png', '.gif'];
  const fileExtension = path.extname(filepath).toLowerCase();
  
  if (!allowedExtensions.includes(fileExtension)) {
    return false;
  }

  // Additional validation logic can be added here
  // For example, checking if the user has permission to access this file
  
  return true;
};

export const getFileMetadata = (filepath: string): { size: number; mimeType: string; filename: string } => {
  if (!fs.existsSync(filepath)) {
    throw createError('File not found', 404);
  }

  const stats = fs.statSync(filepath);
  const filename = path.basename(filepath);
  const extension = path.extname(filepath).toLowerCase();
  
  const mimeTypes: Record<string, string> = {
    '.pdf': 'application/pdf',
    '.epub': 'application/epub+zip',
    '.txt': 'text/plain',
    '.mp3': 'audio/mpeg',
    '.wav': 'audio/wav',
    '.ogg': 'audio/ogg',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.gif': 'image/gif'
  };

  const mimeType = mimeTypes[extension] || 'application/octet-stream';

  return {
    size: stats.size,
    mimeType,
    filename
  };
};