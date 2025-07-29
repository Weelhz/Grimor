import { Socket } from 'socket.io';
import { storeSyncEvent, getSyncDelta } from '../../services/syncService';
import { ClientToServerEvents, ServerToClientEvents, SocketData } from '../events';
import logger from '../../utils/logger';

export const syncHandler = (socket: Socket<ClientToServerEvents, ServerToClientEvents, {}, SocketData>) => {
  // Handle sync-related events
  // This complements the HTTP sync endpoints for real-time sync

  // Example: Handle real-time sync events
  socket.on('sync:event', async (data: any) => {
    try {
      const { userId } = socket.data;
      
      // Store sync event for later processing
      await storeSyncEvent({
        id: data.id || `${userId}-${Date.now()}`,
        type: data.type,
        timestamp: data.timestamp || Date.now(),
        userId,
        bookId: data.bookId,
        presetId: data.presetId,
        data: data.data
      });

      // Acknowledge the sync event
      socket.emit('sync:status', {
        status: 'syncing',
        message: 'Event synchronized',
        timestamp: Date.now()
      });

      logger.debug('Sync event processed', { userId, eventType: data.type });
      
    } catch (error) {
      logger.error('Error processing sync event', { error, userId: socket.data.userId });
      socket.emit('error', { 
        message: 'Failed to process sync event',
        code: 'SYNC_EVENT_ERROR'
      });
    }
  });

  // Handle sync status requests
  socket.on('sync:status_request', async () => {
    try {
      const { userId } = socket.data;
      
      // Get current sync status
      const syncDelta = await getSyncDelta(userId, 0);
      
      socket.emit('sync:status', {
        status: 'connected',
        message: `${syncDelta.events.length} events pending`,
        timestamp: Date.now()
      });

      logger.debug('Sync status requested', { userId, pendingEvents: syncDelta.events.length });
      
    } catch (error) {
      logger.error('Error getting sync status', { error, userId: socket.data.userId });
      socket.emit('error', { 
        message: 'Failed to get sync status',
        code: 'SYNC_STATUS_ERROR'
      });
    }
  });

  // Handle connection recovery
  socket.on('sync:recover', async (data: any) => {
    try {
      const { userId } = socket.data;
      const { lastSyncTimestamp } = data;
      
      // Get missed events since last sync
      const syncDelta = await getSyncDelta(userId, lastSyncTimestamp);
      
      // Send recovery data
      socket.emit('sync:recovery', {
        events: syncDelta.events,
        timestamp: Date.now()
      });

      logger.debug('Sync recovery completed', { 
        userId, 
        lastSyncTimestamp, 
        recoveredEvents: syncDelta.events.length 
      });
      
    } catch (error) {
      logger.error('Error during sync recovery', { error, userId: socket.data.userId });
      socket.emit('error', { 
        message: 'Failed to recover sync data',
        code: 'SYNC_RECOVERY_ERROR'
      });
    }
  });
};