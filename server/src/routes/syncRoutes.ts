import { Router } from 'express';
import { getSyncDeltaEndpoint, processSyncDeltaEndpoint, getSyncStats, clearSyncData } from '../controllers/syncController';
import { authenticateToken } from '../middleware/auth';

const router = Router();

// All sync routes require authentication
router.get('/delta', authenticateToken, getSyncDeltaEndpoint);
router.post('/delta', authenticateToken, processSyncDeltaEndpoint);
router.get('/stats', authenticateToken, getSyncStats);
router.delete('/data', authenticateToken, clearSyncData);

export default router;