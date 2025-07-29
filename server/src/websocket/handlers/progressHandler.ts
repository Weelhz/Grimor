import { Socket } from 'socket.io';
import { calculateMoodTrigger, logMoodTrigger } from '../../services/moodService';
import { generateSignedUrl } from '../../services/signedUrlService';
import { findUserById } from '../../models/User';
import { createAuditLog } from '../../models/AuditLog';
import { ProgressUpdateSchema, ClientToServerEvents, ServerToClientEvents, SocketData } from '../events';
import logger from '../../utils/logger';

export const progressHandler = (socket: Socket<ClientToServerEvents, ServerToClientEvents, {}, SocketData>) => {
  socket.on('progress:update', async (data) => {
    try {
      // Validate input data
      const validatedData = ProgressUpdateSchema.parse(data);
      const { userId } = socket.data;

      // Get user settings for mood sensitivity
      const user = await findUserById(userId);
      if (!user) {
        socket.emit('error', { message: 'User not found' });
        return;
      }

      const { bookId, presetId, chapter, pageFraction } = validatedData;

      // Calculate mood trigger based on current progress
      const moodTrigger = await calculateMoodTrigger(
        presetId,
        chapter,
        pageFraction,
        'electronic', // TODO: Get user's preferred music genre
        user.mood_sensitivity
      );

      if (moodTrigger) {
        // Generate signed URL for background image if present
        let backgroundImageUrl: string | undefined;
        if (moodTrigger.background) {
          backgroundImageUrl = generateSignedUrl(moodTrigger.background.background_path, userId);
        }

        // Create mood trigger event
        const moodTriggerEvent = {
          moodName: moodTrigger.mood.mood_name,
          tempo: moodTrigger.tempo,
          backgroundImageUrl,
          transitionType: moodTrigger.transition_type as 'fade' | 'crossfade' | 'jump',
          timestamp: Date.now()
        };

        // Send mood trigger to user
        socket.emit('mood:trigger', moodTriggerEvent);

        // Log mood trigger
        await logMoodTrigger(userId, presetId, chapter, pageFraction, moodTrigger);

        // Optionally, broadcast to other users in the same book room
        // (for collaborative reading features)
        const roomName = `book:${bookId}`;
        socket.to(roomName).emit('mood:trigger', moodTriggerEvent);

        logger.debug('Mood trigger sent', {
          userId,
          bookId,
          presetId,
          chapter,
          pageFraction,
          moodName: moodTrigger.mood.mood_name,
          tempo: moodTrigger.tempo
        });
      }

      // Log progress update
      await createAuditLog({
        user_id: userId,
        action: 'READING_PROGRESS_WEBSOCKET',
        entity_type: 'book',
        entity_id: bookId,
        details: {
          presetId,
          chapter,
          pageFraction,
          timestamp: validatedData.timestamp
        }
      });

      logger.debug('Progress update processed', {
        userId,
        bookId,
        presetId,
        chapter,
        pageFraction
      });

    } catch (error) {
      logger.error('Error processing progress update', { error, userId: socket.data.userId });
      socket.emit('error', { 
        message: 'Failed to process progress update',
        code: 'PROGRESS_UPDATE_ERROR'
      });
    }
  });
};