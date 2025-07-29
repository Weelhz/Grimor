import { Router } from 'express';
import { getMoods, getMoodBackgrounds, createMood, createMoodBackground } from '../controllers/moodController';
import { authenticateToken } from '../middleware/auth';

const router = Router();

// Public routes
router.get('/', getMoods);
router.get('/:moodId/backgrounds', getMoodBackgrounds);

// Protected routes (Creator only - in production, you'd add role-based middleware)
router.post('/', authenticateToken, createMood);
router.post('/:moodId/backgrounds', authenticateToken, createMoodBackground);

export default router;