import { Router } from 'express';
import { createUserPlaylist, getUserPlaylists, getPlaylist, updateUserPlaylist, deleteUserPlaylist, addTrackToUserPlaylist, removeTrackFromUserPlaylist } from '../controllers/playlistController';
import { authenticateToken } from '../middleware/auth';

const router = Router();

// All playlist routes require authentication
router.post('/', authenticateToken, createUserPlaylist);
router.get('/', authenticateToken, getUserPlaylists);
router.get('/:id', authenticateToken, getPlaylist);
router.put('/:id', authenticateToken, updateUserPlaylist);
router.delete('/:id', authenticateToken, deleteUserPlaylist);
router.post('/:id/tracks', authenticateToken, addTrackToUserPlaylist);
router.delete('/:id/tracks/:musicId', authenticateToken, removeTrackFromUserPlaylist);

export default router;