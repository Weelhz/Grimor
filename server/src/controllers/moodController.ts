import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { getMoodReferences, getBackgroundsByMood, createMoodReference, createBackground } from '../services/moodService';
import { createError } from '../middleware/errorHandler';
import { AuthenticatedRequest } from '../middleware/auth';

const createMoodReferenceSchema = z.object({
  mood_name: z.string().min(1).max(50),
  tempo_electronic: z.number().min(30).max(200),
  tempo_classic: z.number().min(30).max(200),
  tempo_lofi: z.number().min(30).max(200),
  tempo_custom: z.number().min(30).max(200).optional()
});

const createBackgroundSchema = z.object({
  mood_id: z.number().min(1),
  background_path: z.string().min(1)
});

export const getMoods = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const moods = await getMoodReferences();
    
    res.json({
      message: 'Mood references retrieved successfully',
      data: moods
    });
  } catch (error) {
    next(error);
  }
};

export const getMoodBackgrounds = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const moodId = parseInt(req.params.moodId);
    if (isNaN(moodId)) {
      throw createError('Invalid mood ID', 400);
    }

    const backgrounds = await getBackgroundsByMood(moodId);
    
    res.json({
      message: 'Mood backgrounds retrieved successfully',
      data: backgrounds
    });
  } catch (error) {
    next(error);
  }
};

export const createMood = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const validatedData = createMoodReferenceSchema.parse(req.body);
    const mood = await createMoodReference(
      validatedData.mood_name,
      validatedData.tempo_electronic,
      validatedData.tempo_classic,
      validatedData.tempo_lofi,
      validatedData.tempo_custom || 0
    );
    
    res.status(201).json({
      message: 'Mood reference created successfully',
      data: mood
    });
  } catch (error) {
    next(error);
  }
};

export const createMoodBackground = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const validatedData = createBackgroundSchema.parse(req.body);
    const background = await createBackground(
      validatedData.mood_id,
      validatedData.background_path
    );
    
    res.status(201).json({
      message: 'Mood background created successfully',
      data: background
    });
  } catch (error) {
    next(error);
  }
};