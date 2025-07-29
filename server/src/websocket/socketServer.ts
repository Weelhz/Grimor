import { Server as HTTPServer } from 'http';
import { Server as SocketIOServer } from 'socket.io';
import { verifyAccessToken } from '../utils/token';
import { findUserById } from '../models/User';
import { createAuditLog } from '../models/AuditLog';
import logger from '../utils/logger';
import env from '../config/env';
import { 
  ClientToServerEvents, 
  ServerToClientEvents, 
  InterServerEvents, 
  SocketData 
} from './events';
import { progressHandler } from './handlers/progressHandler';
import { moodHandler } from './handlers/moodHandler';
import { syncHandler } from './handlers/syncHandler';

export type BookSphereSocket = SocketIOServer<
  ClientToServerEvents,
  ServerToClientEvents,
  InterServerEvents,
  SocketData
>;

export let io: BookSphereSocket;

export const initializeSocket = (server: HTTPServer): BookSphereSocket => {
  io = new SocketIOServer(server, {
    cors: {
      origin: env.CORS_ORIGIN,
      methods: ['GET', 'POST']
    },
    pingTimeout: 60000,
    pingInterval: 25000
  });

  // Authentication middleware
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token;
      if (!token) {
        return next(new Error('Authentication token required'));
      }

      const payload = verifyAccessToken(token);
      const user = await findUserById(payload.userId);
      
      if (!user) {
        return next(new Error('User not found'));
      }

      socket.data = {
        userId: user.id,
        username: user.username,
        joinedAt: Date.now()
      };

      next();
    } catch (error) {
      logger.warn('Socket authentication failed', { error });
      next(new Error('Invalid authentication token'));
    }
  });

  // Connection handling
  io.on('connection', async (socket) => {
    const { userId, username } = socket.data;
    
    logger.info('User connected via WebSocket', { userId, username, socketId: socket.id });

    // Log connection
    await createAuditLog({
      user_id: userId,
      action: 'WEBSOCKET_CONNECTED',
      details: { socketId: socket.id }
    });

    // Send connection confirmation
    socket.emit('sync:status', {
      status: 'connected',
      message: 'Connected to Book Sphere',
      timestamp: Date.now()
    });

    // Register event handlers
    progressHandler(socket);
    moodHandler(socket);
    syncHandler(socket);

    // Handle ping/pong for connection monitoring
    socket.on('ping', () => {
      socket.emit('pong');
    });

    // Handle room joining
    socket.on('room:join', async (data) => {
      try {
        const roomName = `book:${data.bookId}`;
        socket.join(roomName);
        
        socket.data.currentBookId = data.bookId;
        socket.data.currentPresetId = data.presetId;

        // Notify other users in the room
        socket.to(roomName).emit('user:joined', {
          userId,
          username,
          timestamp: Date.now()
        });

        logger.debug('User joined book room', { userId, bookId: data.bookId, presetId: data.presetId });
      } catch (error) {
        logger.error('Error joining room', { error, userId, data });
        socket.emit('error', { message: 'Failed to join room' });
      }
    });

    // Handle room leaving
    socket.on('room:leave', async (data) => {
      try {
        const roomName = `book:${data.bookId}`;
        socket.leave(roomName);

        // Notify other users in the room
        socket.to(roomName).emit('user:left', {
          userId,
          username,
          timestamp: Date.now()
        });

        socket.data.currentBookId = undefined;
        socket.data.currentPresetId = undefined;

        logger.debug('User left book room', { userId, bookId: data.bookId });
      } catch (error) {
        logger.error('Error leaving room', { error, userId, data });
        socket.emit('error', { message: 'Failed to leave room' });
      }
    });

    // Handle user settings updates
    socket.on('settings:update', async (data) => {
      try {
        // In a real implementation, you'd update the user's settings in the database
        // For now, we'll just log the update
        await createAuditLog({
          user_id: userId,
          action: 'SETTINGS_UPDATED_VIA_WEBSOCKET',
          details: { settings: data }
        });

        logger.debug('User settings updated via WebSocket', { userId, settings: data });
      } catch (error) {
        logger.error('Error updating settings', { error, userId, data });
        socket.emit('error', { message: 'Failed to update settings' });
      }
    });

    // Handle disconnection
    socket.on('disconnect', async (reason) => {
      logger.info('User disconnected from WebSocket', { userId, username, reason, socketId: socket.id });

      // Log disconnection
      await createAuditLog({
        user_id: userId,
        action: 'WEBSOCKET_DISCONNECTED',
        details: { reason, socketId: socket.id, duration: Date.now() - socket.data.joinedAt }
      });

      // Notify rooms about user leaving
      if (socket.data.currentBookId) {
        const roomName = `book:${socket.data.currentBookId}`;
        socket.to(roomName).emit('user:left', {
          userId,
          username,
          timestamp: Date.now()
        });
      }
    });

    // Handle errors
    socket.on('error', (error) => {
      logger.error('Socket error', { error, userId, socketId: socket.id });
    });
  });

  return io;
};

export const getSocket = (): BookSphereSocket => {
  if (!io) {
    throw new Error('Socket.IO not initialized');
  }
  return io;
};