import { config } from 'dotenv';
import { z } from 'zod';

// Load environment variables
config();

// Environment variable schema
const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.string().transform(Number).pipe(z.number().min(1).max(65535)).default(3000),
  
  // Database
  DATABASE_URL: z.string().min(1, 'DATABASE_URL is required'),
  
  // JWT Configuration
  JWT_SECRET: z.string().min(32, 'JWT_SECRET must be at least 32 characters'),
  JWT_REFRESH_SECRET: z.string().min(32, 'JWT_REFRESH_SECRET must be at least 32 characters'),
  JWT_ACCESS_EXPIRY: z.string().default('15m'),
  JWT_REFRESH_EXPIRY: z.string().default('7d'),
  
  // CORS Configuration
  CORS_ORIGIN: z.string().default('*'),
  
  // Rate Limiting
  RATE_LIMIT_WINDOW: z.string().transform(Number).pipe(z.number()).default(900000), // 15 minutes
  RATE_LIMIT_MAX: z.string().transform(Number).pipe(z.number()).default(100),
  
  // File Upload
  UPLOAD_PATH: z.string().default('./uploads'),
  MAX_FILE_SIZE: z.string().transform(Number).pipe(z.number()).default(104857600), // 100MB
  SIGNED_URL_EXPIRY: z.string().transform(Number).pipe(z.number()).default(3600), // 1 hour
  
  // Security
  BCRYPT_ROUNDS: z.string().transform(Number).pipe(z.number()).default(12),
  
  // Logging
  LOG_LEVEL: z.enum(['error', 'warn', 'info', 'debug']).default('info'),
  LOG_FILE: z.string().optional(),
  
  // Server Configuration
  TRUST_PROXY: z.string().transform(val => val === 'true').default(false),
  
  // Database Pool Configuration
  DB_POOL_MIN: z.string().transform(Number).pipe(z.number()).default(2),
  DB_POOL_MAX: z.string().transform(Number).pipe(z.number()).default(10),
  DB_POOL_IDLE_TIMEOUT: z.string().transform(Number).pipe(z.number()).default(30000),
  
  // WebSocket Configuration
  WS_CORS_ORIGIN: z.string().default('*'),
  WS_MAX_CONNECTIONS: z.string().transform(Number).pipe(z.number()).default(1000),
  
  // Performance
  COMPRESSION_LEVEL: z.string().transform(Number).pipe(z.number().min(1).max(9)).default(6),
  
  // Health Check
  HEALTH_CHECK_PATH: z.string().default('/api/health'),
  
  // Cache Configuration
  CACHE_TTL: z.string().transform(Number).pipe(z.number()).default(3600), // 1 hour
  
  // External Services (optional)
  REDIS_URL: z.string().optional(),
  S3_BUCKET: z.string().optional(),
  S3_REGION: z.string().optional(),
  S3_ACCESS_KEY: z.string().optional(),
  S3_SECRET_KEY: z.string().optional(),
});

// Parse and validate environment variables
const parseEnv = () => {
  try {
    return envSchema.parse(process.env);
  } catch (error) {
    console.error('❌ Invalid environment configuration:');
    if (error instanceof z.ZodError) {
      error.errors.forEach(err => {
        console.error(`  ${err.path.join('.')}: ${err.message}`);
      });
    }
    process.exit(1);
  }
};

export const env = parseEnv();

// Derived configurations
export const productionConfig = {
  // Server
  server: {
    port: env.PORT,
    host: '0.0.0.0',
    trustProxy: env.TRUST_PROXY,
  },
  
  // Database
  database: {
    url: env.DATABASE_URL,
    pool: {
      min: env.DB_POOL_MIN,
      max: env.DB_POOL_MAX,
      idleTimeoutMillis: env.DB_POOL_IDLE_TIMEOUT,
    },
  },
  
  // JWT
  jwt: {
    secret: env.JWT_SECRET,
    refreshSecret: env.JWT_REFRESH_SECRET,
    accessExpiry: env.JWT_ACCESS_EXPIRY,
    refreshExpiry: env.JWT_REFRESH_EXPIRY,
  },
  
  // Security
  security: {
    bcryptRounds: env.BCRYPT_ROUNDS,
    cors: {
      origin: env.CORS_ORIGIN === '*' ? true : env.CORS_ORIGIN.split(','),
      credentials: true,
      methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
    },
    rateLimiting: {
      windowMs: env.RATE_LIMIT_WINDOW,
      max: env.RATE_LIMIT_MAX,
      message: 'Too many requests from this IP, please try again later.',
      standardHeaders: true,
      legacyHeaders: false,
    },
  },
  
  // File Upload
  upload: {
    path: env.UPLOAD_PATH,
    maxFileSize: env.MAX_FILE_SIZE,
    signedUrlExpiry: env.SIGNED_URL_EXPIRY,
    allowedMimeTypes: {
      books: ['application/pdf', 'application/epub+zip', 'text/plain'],
      music: ['audio/mpeg', 'audio/wav', 'audio/ogg', 'audio/mp4'],
      images: ['image/jpeg', 'image/png', 'image/webp', 'image/gif'],
    },
  },
  
  // Logging
  logging: {
    level: env.LOG_LEVEL,
    file: env.LOG_FILE,
    format: env.NODE_ENV === 'production' ? 'json' : 'simple',
    colorize: env.NODE_ENV !== 'production',
  },
  
  // WebSocket
  websocket: {
    cors: {
      origin: env.WS_CORS_ORIGIN === '*' ? true : env.WS_CORS_ORIGIN.split(','),
      credentials: true,
    },
    maxConnections: env.WS_MAX_CONNECTIONS,
    pingInterval: 25000,
    pingTimeout: 5000,
  },
  
  // Performance
  performance: {
    compression: {
      level: env.COMPRESSION_LEVEL,
      threshold: 1024, // Only compress responses larger than 1KB
    },
    cache: {
      ttl: env.CACHE_TTL,
    },
  },
  
  // Health Check
  health: {
    path: env.HEALTH_CHECK_PATH,
    checks: {
      database: true,
      memory: true,
      disk: true,
    },
  },
  
  // External Services
  external: {
    redis: env.REDIS_URL ? { url: env.REDIS_URL } : null,
    s3: env.S3_BUCKET ? {
      bucket: env.S3_BUCKET,
      region: env.S3_REGION,
      accessKeyId: env.S3_ACCESS_KEY,
      secretAccessKey: env.S3_SECRET_KEY,
    } : null,
  },
};

// Environment-specific configurations
export const isDevelopment = env.NODE_ENV === 'development';
export const isProduction = env.NODE_ENV === 'production';
export const isTest = env.NODE_ENV === 'test';

// Validation helper
export const validateConfig = () => {
  const issues: string[] = [];
  
  // Check required production settings
  if (isProduction) {
    if (env.JWT_SECRET.length < 64) {
      issues.push('JWT_SECRET should be at least 64 characters in production');
    }
    
    if (env.JWT_REFRESH_SECRET.length < 64) {
      issues.push('JWT_REFRESH_SECRET should be at least 64 characters in production');
    }
    
    if (env.CORS_ORIGIN === '*') {
      issues.push('CORS_ORIGIN should be specific domains in production');
    }
    
    if (env.BCRYPT_ROUNDS < 12) {
      issues.push('BCRYPT_ROUNDS should be at least 12 in production');
    }
  }
  
  return issues;
};

export default env;