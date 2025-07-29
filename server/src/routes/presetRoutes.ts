import { Router } from 'express';
import { authenticateToken } from '../middleware/auth';
import { canCreateMoodPresets } from '../middleware/roleAuth';
import {
  createPreset,
  getPresetsByBook,
  getPresetsByCreator,
  updatePreset,
  deletePreset,
  createTrigger,
  getTriggersByPreset,
  getTriggersForPosition,
  updateTrigger,
  deleteTrigger
} from '../controllers/moodPresetController';

const router = Router();

// Mood Preset Routes
router.post('/', authenticateToken, canCreateMoodPresets, createPreset);
router.get('/book/:bookId', getPresetsByBook);
router.get('/creator/my-presets', authenticateToken, canCreateMoodPresets, getPresetsByCreator);
router.put('/:id', authenticateToken, canCreateMoodPresets, updatePreset);
router.delete('/:id', authenticateToken, canCreateMoodPresets, deletePreset);

// Mood Trigger Routes
router.post('/triggers', authenticateToken, canCreateMoodPresets, createTrigger);
router.get('/:presetId/triggers', getTriggersByPreset);
router.get('/:presetId/triggers/position/:page', getTriggersForPosition);
router.put('/triggers/:id', authenticateToken, canCreateMoodPresets, updateTrigger);
router.delete('/triggers/:id', authenticateToken, canCreateMoodPresets, deleteTrigger);

export default router;