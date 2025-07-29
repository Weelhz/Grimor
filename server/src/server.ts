import { createServer } from 'http';
import app from './app';
import { initializeSocket } from './websocket/socketServer';
import logger from './utils/logger';
import env from './config/env';
import { query } from './config/db';

const server = createServer(app);

// Initialize Socket.IO
const io = initializeSocket(server);

// Test database connection
const testDatabaseConnection = async () => {
  try {
    await query('SELECT 1');
    logger.info('Database connection successful');
  } catch (error) {
    logger.error('Database connection failed', { error });
    process.exit(1);
  }
};

// Graceful shutdown
const gracefulShutdown = (signal: string) => {
  logger.info(`Received ${signal}. Starting graceful shutdown...`);
  
  server.close(() => {
    logger.info('HTTP server closed');
    
    // Close Socket.IO server
    io.close(() => {
      logger.info('Socket.IO server closed');
      process.exit(0);
    });
  });
  
  // Force shutdown after 10 seconds
  setTimeout(() => {
    logger.error('Forced shutdown after timeout');
    process.exit(1);
  }, 10000);
};

// Handle shutdown signals
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  logger.error('Uncaught exception', { error });
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled rejection', { reason, promise });
  process.exit(1);
});

// Start server
const start = async () => {
  try {
    await testDatabaseConnection();
    
    server.listen(env.PORT, '0.0.0.0', () => {
      logger.info(`Book Sphere server started successfully`, {
        port: env.PORT,
        environment: env.NODE_ENV,
        nodeVersion: process.version
      });
    });
  } catch (error) {
    logger.error('Failed to start server', { error });
    process.exit(1);
  }
};

start();