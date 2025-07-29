import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { createNewMusic, getMusicById, getAllMusic, getMusicByGenre, searchMusicService, updateMusicService, deleteMusicService, handleMusicUpload } from '../services/musicService';
import { createError } from '../middleware/errorHandler';
import { AuthenticatedRequest } from '../middleware/auth';

const createMusicSchema = z.object({
  title: z.string().min(1).max(100),
  genre: z.string().max(50).optional(),
  filepath: z.string(),
  is_public: z.boolean().optional(),
  initial_tempo: z.number().min(30).max(200)
});

const updateMusicSchema = z.object({
  title: z.string().min(1).max(100).optional(),
  genre: z.string().max(50).optional(),
  is_public: z.boolean().optional(),
  initial_tempo: z.number().min(30).max(200).optional()
});

const searchQuerySchema = z.object({
  q: z.string().optional(),
  genre: z.string().optional(),
  page: z.string().transform(Number).optional(),
  limit: z.string().transform(Number).optional()
});

export const createMusic = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const validatedData = createMusicSchema.parse(req.body);
    const music = await createNewMusic(validatedData);
    
    res.status(201).json({
      message: 'Music created successfully',
      data: music
    });
  } catch (error) {
    next(error);
  }
};

export const uploadMusic = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    if (!req.file) {
      throw createError('No file uploaded', 400);
    }

    const { title, genre, initial_tempo, is_public } = req.body;
    if (!title) {
      throw createError('Title is required', 400);
    }
    if (!initial_tempo) {
      throw createError('Initial tempo is required', 400);
    }

    const music = await handleMusicUpload(
      req.file,
      title,
      genre || 'unknown',
      parseInt(initial_tempo),
      is_public !== 'false'
    );
    
    res.status(201).json({
      message: 'Music uploaded successfully',
      data: music
    });
  } catch (error) {
    next(error);
  }
};

export const getMusic = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const musicId = parseInt(req.params.id);
    if (isNaN(musicId)) {
      throw createError('Invalid music ID', 400);
    }

    const music = await getMusicById(musicId);
    if (!music) {
      throw createError('Music not found', 404);
    }

    res.json({
      message: 'Music retrieved successfully',
      data: music
    });
  } catch (error) {
    next(error);
  }
};

export const getMusicList = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { q, genre, page = 1, limit = 20 } = searchQuerySchema.parse(req.query);
    
    let musicList;
    if (q) {
      musicList = await searchMusicService(q);
    } else if (genre) {
      musicList = await getMusicByGenre(genre);
    } else {
      musicList = await getAllMusic();
    }

    // Simple pagination
    const startIndex = (page - 1) * limit;
    const endIndex = startIndex + limit;
    const paginatedMusic = musicList.slice(startIndex, endIndex);

    res.json({
      message: 'Music retrieved successfully',
      data: {
        music: paginatedMusic,
        pagination: {
          page,
          limit,
          total: musicList.length,
          hasMore: endIndex < musicList.length
        }
      }
    });
  } catch (error) {
    next(error);
  }
};

export const updateMusic = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const musicId = parseInt(req.params.id);
    if (isNaN(musicId)) {
      throw createError('Invalid music ID', 400);
    }

    const validatedData = updateMusicSchema.parse(req.body);
    const music = await updateMusicService(musicId, validatedData);
    
    if (!music) {
      throw createError('Music not found', 404);
    }

    res.json({
      message: 'Music updated successfully',
      data: music
    });
  } catch (error) {
    next(error);
  }
};

export const deleteMusic = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const musicId = parseInt(req.params.id);
    if (isNaN(musicId)) {
      throw createError('Invalid music ID', 400);
    }

    const deleted = await deleteMusicService(musicId);
    
    if (!deleted) {
      throw createError('Music not found', 404);
    }

    res.json({
      message: 'Music deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};