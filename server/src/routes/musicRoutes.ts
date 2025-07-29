import { Router } from 'express';
import multer from 'multer';
import { createMusic, uploadMusic, getMusic, getMusicList, updateMusic, deleteMusic } from '../controllers/musicController';
import { authenticateToken, optionalAuth } from '../middleware/auth';
import { uploadLimiter } from '../middleware/rateLimiter';
import { validateFileType, getUploadPath } from '../utils/fileUtils';

const router = Router();

// Configure multer for music uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, getUploadPath('temp'));
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + '-' + file.originalname);
  }
});

const upload = multer({
  storage,
  fileFilter: (req, file, cb) => {
    const allowedTypes = ['.mp3', '.wav', '.ogg', '.m4a'];
    if (validateFileType(file.originalname, allowedTypes)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only MP3, WAV, OGG, and M4A files are allowed.'));
    }
  },
  limits: {
    fileSize: 20 * 1024 * 1024, // 20MB limit
  }
});

// Public routes
router.get('/', getMusicList);
router.get('/:id', getMusic);

// Protected routes
router.post('/', authenticateToken, createMusic);
router.post('/upload', authenticateToken, uploadLimiter, upload.single('music'), uploadMusic);
router.put('/:id', authenticateToken, updateMusic);
router.delete('/:id', authenticateToken, deleteMusic);

export default router;