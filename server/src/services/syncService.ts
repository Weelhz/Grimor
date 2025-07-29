import { createAuditLog } from '../models/AuditLog';
import logger from '../utils/logger';

export interface SyncEvent {
  id: string;
  type: 'progress' | 'mood_trigger' | 'settings_change';
  timestamp: number;
  userId: number;
  bookId?: number;
  presetId?: number;
  data: Record<string, any>;
}

export interface SyncDelta {
  events: SyncEvent[];
  lastSyncTimestamp: number;
}

// In-memory storage for sync events (in production, use Redis or similar)
const syncStore = new Map<number, SyncEvent[]>();

export const storeSyncEvent = async (event: SyncEvent): Promise<void> => {
  const userEvents = syncStore.get(event.userId) || [];
  userEvents.push(event);
  
  // Keep only last 1000 events per user
  if (userEvents.length > 1000) {
    userEvents.splice(0, userEvents.length - 1000);
  }
  
  syncStore.set(event.userId, userEvents);

  // Log sync event
  await createAuditLog({
    user_id: event.userId,
    action: 'SYNC_EVENT_STORED',
    entity_type: 'sync',
    entity_id: event.userId,
    details: {
      eventType: event.type,
      eventId: event.id,
      timestamp: event.timestamp
    }
  });

  logger.debug('Sync event stored', { eventId: event.id, type: event.type, userId: event.userId });
};

export const getSyncDelta = async (userId: number, lastSyncTimestamp: number): Promise<SyncDelta> => {
  const userEvents = syncStore.get(userId) || [];
  
  // Filter events that are newer than the last sync timestamp
  const deltaEvents = userEvents.filter(event => event.timestamp > lastSyncTimestamp);
  
  const currentTimestamp = Date.now();
  
  logger.debug('Sync delta retrieved', { 
    userId, 
    lastSyncTimestamp, 
    currentTimestamp,
    deltaCount: deltaEvents.length 
  });

  return {
    events: deltaEvents,
    lastSyncTimestamp: currentTimestamp
  };
};

export const processSyncDelta = async (userId: number, events: SyncEvent[]): Promise<void> => {
  for (const event of events) {
    // Validate event structure
    if (!event.id || !event.type || !event.timestamp) {
      logger.warn('Invalid sync event received', { event, userId });
      continue;
    }

    // Process different types of sync events
    switch (event.type) {
      case 'progress':
        await processProgressEvent(userId, event);
        break;
      case 'mood_trigger':
        await processMoodTriggerEvent(userId, event);
        break;
      case 'settings_change':
        await processSettingsChangeEvent(userId, event);
        break;
      default:
        logger.warn('Unknown sync event type', { type: event.type, userId });
    }
  }

  logger.info('Sync delta processed', { userId, eventCount: events.length });
};

const processProgressEvent = async (userId: number, event: SyncEvent): Promise<void> => {
  const { bookId, presetId, chapter, pageFraction } = event.data;
  
  // Store the progress event
  await storeSyncEvent(event);
  
  // Log reading progress
  await createAuditLog({
    user_id: userId,
    action: 'READING_PROGRESS',
    entity_type: 'book',
    entity_id: bookId,
    details: {
      presetId,
      chapter,
      pageFraction,
      timestamp: event.timestamp
    }
  });
};

const processMoodTriggerEvent = async (userId: number, event: SyncEvent): Promise<void> => {
  const { moodName, tempo, transitionType, backgroundPath } = event.data;
  
  // Store the mood trigger event
  await storeSyncEvent(event);
  
  // Log mood trigger
  await createAuditLog({
    user_id: userId,
    action: 'MOOD_TRIGGER_SYNC',
    entity_type: 'sync',
    entity_id: userId,
    details: {
      moodName,
      tempo,
      transitionType,
      backgroundPath,
      timestamp: event.timestamp
    }
  });
};

const processSettingsChangeEvent = async (userId: number, event: SyncEvent): Promise<void> => {
  const { settingName, oldValue, newValue } = event.data;
  
  // Store the settings change event
  await storeSyncEvent(event);
  
  // Log settings change
  await createAuditLog({
    user_id: userId,
    action: 'SETTINGS_CHANGE_SYNC',
    entity_type: 'user',
    entity_id: userId,
    details: {
      settingName,
      oldValue,
      newValue,
      timestamp: event.timestamp
    }
  });
};

export const clearUserSyncData = async (userId: number): Promise<void> => {
  syncStore.delete(userId);
  
  await createAuditLog({
    user_id: userId,
    action: 'SYNC_DATA_CLEARED',
    entity_type: 'sync',
    entity_id: userId,
    details: { timestamp: Date.now() }
  });

  logger.info('User sync data cleared', { userId });
};

export const getUserSyncStats = async (userId: number): Promise<{ eventCount: number; oldestEvent?: number; newestEvent?: number }> => {
  const userEvents = syncStore.get(userId) || [];
  
  if (userEvents.length === 0) {
    return { eventCount: 0 };
  }

  const timestamps = userEvents.map(event => event.timestamp);
  
  return {
    eventCount: userEvents.length,
    oldestEvent: Math.min(...timestamps),
    newestEvent: Math.max(...timestamps)
  };
};