import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { 
  createMoodPreset, 
  findMoodPresetsByBook, 
  findMoodPresetsByCreator,
  updateMoodPreset,
  deleteMoodPreset,
  canUserModifyPreset,
  createMoodTrigger,
  findMoodTriggersByPreset,
  updateMoodTrigger,
  deleteMoodTrigger,
  getMoodTriggersForPosition
} from '../models/MoodPreset';
import { canUserModifyBook } from '../models/Book';
import { createError } from '../middleware/errorHandler';
import { AuthenticatedRequestWithRole } from '../middleware/roleAuth';

const createPresetSchema = z.object({
  book_id: z.string().uuid(),
  name: z.string().min(1).max(200),
  description: z.string().optional(),
  is_default: z.boolean().optional()
});

const updatePresetSchema = z.object({
  name: z.string().min(1).max(200).optional(),
  description: z.string().optional(),
  is_default: z.boolean().optional()
});

const createTriggerSchema = z.object({
  preset_id: z.string().uuid(),
  mood_type_id: z.string().uuid(),
  trigger_condition: z.object({
    page_range: z.array(z.number()).length(2).optional(),
    keywords: z.array(z.string()).optional(),
    passage_text: z.string().optional(),
    time_of_day: z.array(z.string()).optional(),
    reading_speed: z.object({
      min: z.number(),
      max: z.number()
    }).optional()
  }),
  music_track_id: z.string().uuid().optional(),
  background_image_url: z.string().url().optional(),
  visual_effects: z.any().optional(),
  transition_duration: z.number().min(100).max(10000).optional(),
  priority: z.number().min(1).max(100).optional()
});

const updateTriggerSchema = z.object({
  mood_type_id: z.string().uuid().optional(),
  trigger_condition: z.object({
    page_range: z.array(z.number()).length(2).optional(),
    keywords: z.array(z.string()).optional(),
    passage_text: z.string().optional(),
    time_of_day: z.array(z.string()).optional(),
    reading_speed: z.object({
      min: z.number(),
      max: z.number()
    }).optional()
  }).optional(),
  music_track_id: z.string().uuid().optional(),
  background_image_url: z.string().url().optional(),
  visual_effects: z.any().optional(),
  transition_duration: z.number().min(100).max(10000).optional(),
  is_active: z.boolean().optional(),
  priority: z.number().min(1).max(100).optional()
});

// Mood Preset Controllers
export const createPreset = async (req: AuthenticatedRequestWithRole, res: Response, next: NextFunction) => {
  try {
    if (!req.user) {
      throw createError('User not authenticated', 401);
    }

    const validatedData = createPresetSchema.parse(req.body);
    
    // Check if user can modify this book
    const canModify = await canUserModifyBook(validatedData.book_id, req.user.userId);
    if (!canModify) {
      throw createError('You can only create presets for your own books', 403);
    }

    const preset = await createMoodPreset({
      ...validatedData,
      creator_id: req.user.userId
    });
    
    res.status(201).json({
      message: 'Mood preset created successfully',
      data: preset
    });
  } catch (error) {
    next(error);
  }
};

export const getPresetsByBook = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const bookId = req.params.bookId;
    if (!bookId) {
      throw createError('Book ID is required', 400);
    }

    const presets = await findMoodPresetsByBook(bookId);
    
    res.json({
      message: 'Mood presets retrieved successfully',
      data: presets
    });
  } catch (error) {
    next(error);
  }
};

export const getPresetsByCreator = async (req: AuthenticatedRequestWithRole, res: Response, next: NextFunction) => {
  try {
    if (!req.user) {
      throw createError('User not authenticated', 401);
    }

    const presets = await findMoodPresetsByCreator(req.user.userId);
    
    res.json({
      message: 'Creator presets retrieved successfully',
      data: presets
    });
  } catch (error) {
    next(error);
  }
};

export const updatePreset = async (req: AuthenticatedRequestWithRole, res: Response, next: NextFunction) => {
  try {
    if (!req.user) {
      throw createError('User not authenticated', 401);
    }

    const presetId = req.params.id;
    if (!presetId) {
      throw createError('Preset ID is required', 400);
    }

    const canModify = await canUserModifyPreset(presetId, req.user.userId);
    if (!canModify) {
      throw createError('You can only modify your own presets', 403);
    }

    const validatedData = updatePresetSchema.parse(req.body);
    const preset = await updateMoodPreset(presetId, validatedData);
    
    if (!preset) {
      throw createError('Preset not found', 404);
    }

    res.json({
      message: 'Mood preset updated successfully',
      data: preset
    });
  } catch (error) {
    next(error);
  }
};

export const deletePreset = async (req: AuthenticatedRequestWithRole, res: Response, next: NextFunction) => {
  try {
    if (!req.user) {
      throw createError('User not authenticated', 401);
    }

    const presetId = req.params.id;
    if (!presetId) {
      throw createError('Preset ID is required', 400);
    }

    const canModify = await canUserModifyPreset(presetId, req.user.userId);
    if (!canModify) {
      throw createError('You can only delete your own presets', 403);
    }

    const deleted = await deleteMoodPreset(presetId);
    
    if (!deleted) {
      throw createError('Preset not found', 404);
    }

    res.json({
      message: 'Mood preset deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

// Mood Trigger Controllers
export const createTrigger = async (req: AuthenticatedRequestWithRole, res: Response, next: NextFunction) => {
  try {
    if (!req.user) {
      throw createError('User not authenticated', 401);
    }

    const validatedData = createTriggerSchema.parse(req.body);
    
    // Check if user can modify this preset
    const canModify = await canUserModifyPreset(validatedData.preset_id, req.user.userId);
    if (!canModify) {
      throw createError('You can only create triggers for your own presets', 403);
    }

    const trigger = await createMoodTrigger(validatedData);
    
    res.status(201).json({
      message: 'Mood trigger created successfully',
      data: trigger
    });
  } catch (error) {
    next(error);
  }
};

export const getTriggersByPreset = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const presetId = req.params.presetId;
    if (!presetId) {
      throw createError('Preset ID is required', 400);
    }

    const triggers = await findMoodTriggersByPreset(presetId);
    
    res.json({
      message: 'Mood triggers retrieved successfully',
      data: triggers
    });
  } catch (error) {
    next(error);
  }
};

export const getTriggersForPosition = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { presetId, page } = req.params;
    if (!presetId || !page) {
      throw createError('Preset ID and page number are required', 400);
    }

    const pageNumber = parseInt(page);
    if (isNaN(pageNumber)) {
      throw createError('Invalid page number', 400);
    }

    const triggers = await getMoodTriggersForPosition(presetId, pageNumber);
    
    res.json({
      message: 'Position-based triggers retrieved successfully',
      data: triggers
    });
  } catch (error) {
    next(error);
  }
};

export const updateTrigger = async (req: AuthenticatedRequestWithRole, res: Response, next: NextFunction) => {
  try {
    if (!req.user) {
      throw createError('User not authenticated', 401);
    }

    const triggerId = req.params.id;
    if (!triggerId) {
      throw createError('Trigger ID is required', 400);
    }

    // Get the trigger to check ownership via preset
    const trigger = await findMoodTriggerById(triggerId);
    if (!trigger) {
      throw createError('Trigger not found', 404);
    }

    const canModify = await canUserModifyPreset(trigger.preset_id, req.user.userId);
    if (!canModify) {
      throw createError('You can only modify triggers for your own presets', 403);
    }

    const validatedData = updateTriggerSchema.parse(req.body);
    const updatedTrigger = await updateMoodTrigger(triggerId, validatedData);
    
    res.json({
      message: 'Mood trigger updated successfully',
      data: updatedTrigger
    });
  } catch (error) {
    next(error);
  }
};

export const deleteTrigger = async (req: AuthenticatedRequestWithRole, res: Response, next: NextFunction) => {
  try {
    if (!req.user) {
      throw createError('User not authenticated', 401);
    }

    const triggerId = req.params.id;
    if (!triggerId) {
      throw createError('Trigger ID is required', 400);
    }

    // Get the trigger to check ownership via preset
    const trigger = await findMoodTriggerById(triggerId);
    if (!trigger) {
      throw createError('Trigger not found', 404);
    }

    const canModify = await canUserModifyPreset(trigger.preset_id, req.user.userId);
    if (!canModify) {
      throw createError('You can only delete triggers for your own presets', 403);
    }

    const deleted = await deleteMoodTrigger(triggerId);
    
    res.json({
      message: 'Mood trigger deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

// Import the missing function
import { findMoodTriggerById } from '../models/MoodPreset';