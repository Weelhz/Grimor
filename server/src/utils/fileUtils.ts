import fs from 'fs';
import path from 'path';
import { v4 as uuidv4 } from 'uuid';
import env from '../config/env';

export const ensureDirectoryExists = (dirPath: string): void => {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
};

export const generateFileName = (originalName: string): string => {
  const ext = path.extname(originalName);
  const name = path.basename(originalName, ext);
  const timestamp = Date.now();
  const uuid = uuidv4().slice(0, 8);
  return `${name}_${timestamp}_${uuid}${ext}`;
};

export const getUploadPath = (subDir: string = ''): string => {
  const uploadPath = path.join(env.UPLOAD_PATH, subDir);
  ensureDirectoryExists(uploadPath);
  return uploadPath;
};

export const deleteFile = (filePath: string): void => {
  if (fs.existsSync(filePath)) {
    fs.unlinkSync(filePath);
  }
};

export const getFileSize = (filePath: string): number => {
  if (fs.existsSync(filePath)) {
    return fs.statSync(filePath).size;
  }
  return 0;
};

export const validateFileType = (filename: string, allowedTypes: string[]): boolean => {
  const ext = path.extname(filename).toLowerCase();
  return allowedTypes.includes(ext);
};

export default {
  ensureDirectoryExists,
  generateFileName,
  getUploadPath,
  deleteFile,
  getFileSize,
  validateFileType
};