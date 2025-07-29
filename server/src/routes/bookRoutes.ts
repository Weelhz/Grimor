import { Router } from 'express';
import multer from 'multer';
import { 
  createBookRecord, 
  getBook, 
  getBooks, 
  getCreatorBooks,
  updateBookRecord, 
  deleteBookRecord, 
  uploadBook,
  getPopular,
  getRecent,
  getGenres,
  getTags
} from '../controllers/bookController';
import { authenticateToken, optionalAuth } from '../middleware/auth';
import { canUploadBooks } from '../middleware/roleAuth';
import { uploadLimiter } from '../middleware/rateLimiter';
import { validateFileType, getUploadPath } from '../utils/fileUtils';

const router = Router();

// Configure multer for book uploads
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
    const allowedTypes = ['.pdf', '.epub', '.txt'];
    if (validateFileType(file.originalname, allowedTypes)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only PDF, EPUB, and TXT files are allowed.'));
    }
  },
  limits: {
    fileSize: 50 * 1024 * 1024, // 50MB limit
  }
});

// Discovery routes (must come before /:id route)
router.get('/popular', getPopular);
router.get('/recent', getRecent);
router.get('/genres', getGenres);
router.get('/tags', getTags);

// Public routes
router.get('/', optionalAuth, getBooks);
router.get('/:id', optionalAuth, getBook);

// Creator routes (requires creator role)
router.get('/creator/my-books', authenticateToken, canUploadBooks, getCreatorBooks);
router.post('/', authenticateToken, canUploadBooks, createBookRecord);
router.post('/upload', authenticateToken, canUploadBooks, uploadLimiter, upload.single('book'), uploadBook);
router.put('/:id', authenticateToken, canUploadBooks, updateBookRecord);
router.delete('/:id', authenticateToken, canUploadBooks, deleteBookRecord);

export default router;