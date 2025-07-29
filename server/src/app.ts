import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import fs from 'fs';
import path from 'path';
import { verifySignedUrl, validateFileAccess, getFileMetadata } from './services/signedUrlService';
import { apiLimiter } from './middleware/rateLimiter';
import { errorHandler, notFoundHandler } from './middleware/errorHandler';
import { ensureDirectoryExists } from './utils/fileUtils';
import logger from './utils/logger';
import env from './config/env';

// Import routes
import authRoutes from './routes/authRoutes';
import bookRoutes from './routes/bookRoutes';
import musicRoutes from './routes/musicRoutes';
import moodRoutes from './routes/moodRoutes';
import playlistRoutes from './routes/playlistRoutes';
import presetRoutes from './routes/presetRoutes';
import syncRoutes from './routes/syncRoutes';

const app = express();

// Trust proxy for rate limiting behind reverse proxy
app.set('trust proxy', 1);

// Security middleware
app.use(helmet({
  crossOriginResourcePolicy: { policy: 'cross-origin' }
}));

// CORS configuration
app.use(cors({
  origin: env.CORS_ORIGIN,
  credentials: true
}));

// Rate limiting
app.use(apiLimiter);

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Ensure upload directories exist
ensureDirectoryExists(env.UPLOAD_PATH);
ensureDirectoryExists(path.join(env.UPLOAD_PATH, 'books'));
ensureDirectoryExists(path.join(env.UPLOAD_PATH, 'music'));
ensureDirectoryExists(path.join(env.UPLOAD_PATH, 'backgrounds'));
ensureDirectoryExists(path.join(env.UPLOAD_PATH, 'temp'));

// Serve static files from public directory
app.use(express.static(path.join(__dirname, '../public')));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// API health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    version: '1.0.0',
    service: 'BookSphere API'
  });
});

// File serving endpoint with signed URLs
app.get('/api/files/:token', async (req, res) => {
  try {
    const { token } = req.params;
    
    // Verify the signed URL token
    const payload = verifySignedUrl(token);
    
    // Validate file access
    const hasAccess = await validateFileAccess(payload.filepath, payload.userId);
    if (!hasAccess) {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    // Get file metadata
    const metadata = getFileMetadata(payload.filepath);
    
    // Set appropriate headers
    res.setHeader('Content-Type', metadata.mimeType);
    res.setHeader('Content-Length', metadata.size);
    res.setHeader('Content-Disposition', `inline; filename="${metadata.filename}"`);
    res.setHeader('Cache-Control', 'private, max-age=3600'); // 1 hour cache
    
    // Stream the file
    const fileStream = fs.createReadStream(payload.filepath);
    fileStream.pipe(res);
    
    fileStream.on('error', (error) => {
      logger.error('File stream error', { error, filepath: payload.filepath });
      if (!res.headersSent) {
        res.status(500).json({ error: 'File stream error' });
      }
    });
    
  } catch (error) {
    logger.error('File access error', { error, token: req.params.token });
    return res.status(401).json({ error: 'Invalid or expired file access token' });
  }
});

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/books', bookRoutes);
app.use('/api/music', musicRoutes);
app.use('/api/moods', moodRoutes);
app.use('/api/playlists', playlistRoutes);
app.use('/api/presets', presetRoutes);
app.use('/api/sync', syncRoutes);

// Static file serving for development
if (env.NODE_ENV === 'development') {
  app.use('/uploads', express.static(env.UPLOAD_PATH));
}

// 404 handler
app.use(notFoundHandler);

// Error handling middleware
app.use(errorHandler);

export default app;