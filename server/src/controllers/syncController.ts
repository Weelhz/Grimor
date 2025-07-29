import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { getSyncDelta, processSyncDelta, getUserSyncStats, clearUserSyncData, SyncEvent } from '../services/syncService';
import { createError } from '../middleware/errorHandler';
import { AuthenticatedRequest } from '../middleware/auth';

const getSyncDeltaSchema = z.object({
  lastSyncTimestamp: z.number().min(0)
});

const syncEventSchema = z.object({
  id: z.string(),
  type: z.enum(['progress', 'mood_trigger', 'settings_change']),
  timestamp: z.number().min(0),
  bookId: z.number().optional(),
  presetId: z.number().optional(),
  data: z.record(z.any())
});

const processSyncDeltaSchema = z.object({
  events: z.array(syncEventSchema)
});

export const getSyncDeltaEndpoint = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    if (!req.user) {
      throw createError('User not authenticated', 401);
    }

    const { lastSyncTimestamp } = getSyncDeltaSchema.parse(req.query);
    const syncDelta = await getSyncDelta(req.user.userId, lastSyncTimestamp);
    
    res.json({
      message: 'Sync delta retrieved successfully',
      data: syncDelta
    });
  } catch (error) {
    next(error);
  }
};

export const processSyncDeltaEndpoint = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    if (!req.user) {
      throw createError('User not authenticated', 401);
    }

    const { events } = processSyncDeltaSchema.parse(req.body);
    
    // Add userId to each event
    const eventsWithUserId: SyncEvent[] = events.map(event => ({
      ...event,
      userId: req.user!.userId
    }));
    
    await processSyncDelta(req.user.userId, eventsWithUserId);
    
    res.json({
      message: 'Sync delta processed successfully',
      data: {
        processedEvents: events.length
      }
    });
  } catch (error) {
    next(error);
  }
};

export const getSyncStats = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    if (!req.user) {
      throw createError('User not authenticated', 401);
    }

    const stats = await getUserSyncStats(req.user.userId);
    
    res.json({
      message: 'Sync stats retrieved successfully',
      data: stats
    });
  } catch (error) {
    next(error);
  }
};

export const clearSyncData = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    if (!req.user) {
      throw createError('User not authenticated', 401);
    }

    await clearUserSyncData(req.user.userId);
    
    res.json({
      message: 'Sync data cleared successfully'
    });
  } catch (error) {
    next(error);
  }
};