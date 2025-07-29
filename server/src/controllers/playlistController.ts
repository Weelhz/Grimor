import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { createPlaylist, findPlaylistById, findPlaylistsByUser, updatePlaylist, deletePlaylist, addTrackToPlaylist, getPlaylistTracks, removeTrackFromPlaylist } from '../models/Playlist';
import { createError } from '../middleware/errorHandler';
import { AuthenticatedRequest } from '../middleware/auth';

const createPlaylistSchema = z.object({
  name: z.string().min(1).max(100)
});

const updatePlaylistSchema = z.object({
  name: z.string().min(1).max(100).optional()
});

const addTrackSchema = z.object({
  music_id: z.number().min(1),
  track_order: z.number().min(1)
});

export const createUserPlaylist = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    if (!req.user) {
      throw createError('User not authenticated', 401);
    }

    const validatedData = createPlaylistSchema.parse(req.body);
    const playlist = await createPlaylist({
      user_id: req.user.userId,
      name: validatedData.name
    });
    
    res.status(201).json({
      message: 'Playlist created successfully',
      data: playlist
    });
  } catch (error) {
    next(error);
  }
};

export const getUserPlaylists = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    if (!req.user) {
      throw createError('User not authenticated', 401);
    }

    const playlists = await findPlaylistsByUser(req.user.userId);
    
    res.json({
      message: 'Playlists retrieved successfully',
      data: playlists
    });
  } catch (error) {
    next(error);
  }
};

export const getPlaylist = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    if (!req.user) {
      throw createError('User not authenticated', 401);
    }

    const playlistId = parseInt(req.params.id);
    if (isNaN(playlistId)) {
      throw createError('Invalid playlist ID', 400);
    }

    const playlist = await findPlaylistById(playlistId);
    if (!playlist) {
      throw createError('Playlist not found', 404);
    }

    // Check if user owns this playlist
    if (playlist.user_id !== req.user.userId) {
      throw createError('Unauthorized to access this playlist', 403);
    }

    const tracks = await getPlaylistTracks(playlistId);
    
    res.json({
      message: 'Playlist retrieved successfully',
      data: {
        ...playlist,
        tracks
      }
    });
  } catch (error) {
    next(error);
  }
};

export const updateUserPlaylist = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    if (!req.user) {
      throw createError('User not authenticated', 401);
    }

    const playlistId = parseInt(req.params.id);
    if (isNaN(playlistId)) {
      throw createError('Invalid playlist ID', 400);
    }

    // Check if user owns this playlist
    const existingPlaylist = await findPlaylistById(playlistId);
    if (!existingPlaylist) {
      throw createError('Playlist not found', 404);
    }
    if (existingPlaylist.user_id !== req.user.userId) {
      throw createError('Unauthorized to update this playlist', 403);
    }

    const validatedData = updatePlaylistSchema.parse(req.body);
    const playlist = await updatePlaylist(playlistId, validatedData);
    
    res.json({
      message: 'Playlist updated successfully',
      data: playlist
    });
  } catch (error) {
    next(error);
  }
};

export const deleteUserPlaylist = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    if (!req.user) {
      throw createError('User not authenticated', 401);
    }

    const playlistId = parseInt(req.params.id);
    if (isNaN(playlistId)) {
      throw createError('Invalid playlist ID', 400);
    }

    // Check if user owns this playlist
    const existingPlaylist = await findPlaylistById(playlistId);
    if (!existingPlaylist) {
      throw createError('Playlist not found', 404);
    }
    if (existingPlaylist.user_id !== req.user.userId) {
      throw createError('Unauthorized to delete this playlist', 403);
    }

    const deleted = await deletePlaylist(playlistId);
    
    res.json({
      message: 'Playlist deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

export const addTrackToUserPlaylist = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    if (!req.user) {
      throw createError('User not authenticated', 401);
    }

    const playlistId = parseInt(req.params.id);
    if (isNaN(playlistId)) {
      throw createError('Invalid playlist ID', 400);
    }

    // Check if user owns this playlist
    const existingPlaylist = await findPlaylistById(playlistId);
    if (!existingPlaylist) {
      throw createError('Playlist not found', 404);
    }
    if (existingPlaylist.user_id !== req.user.userId) {
      throw createError('Unauthorized to modify this playlist', 403);
    }

    const validatedData = addTrackSchema.parse(req.body);
    const track = await addTrackToPlaylist({
      playlist_id: playlistId,
      music_id: validatedData.music_id,
      track_order: validatedData.track_order
    });
    
    res.status(201).json({
      message: 'Track added to playlist successfully',
      data: track
    });
  } catch (error) {
    next(error);
  }
};

export const removeTrackFromUserPlaylist = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    if (!req.user) {
      throw createError('User not authenticated', 401);
    }

    const playlistId = parseInt(req.params.id);
    const musicId = parseInt(req.params.musicId);
    
    if (isNaN(playlistId) || isNaN(musicId)) {
      throw createError('Invalid playlist or music ID', 400);
    }

    // Check if user owns this playlist
    const existingPlaylist = await findPlaylistById(playlistId);
    if (!existingPlaylist) {
      throw createError('Playlist not found', 404);
    }
    if (existingPlaylist.user_id !== req.user.userId) {
      throw createError('Unauthorized to modify this playlist', 403);
    }

    const removed = await removeTrackFromPlaylist(playlistId, musicId);
    
    if (!removed) {
      throw createError('Track not found in playlist', 404);
    }
    
    res.json({
      message: 'Track removed from playlist successfully'
    });
  } catch (error) {
    next(error);
  }
};