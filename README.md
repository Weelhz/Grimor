# Book Sphere - Cross-Platform Reading Application

A sophisticated reading application that provides dynamic mood-based audio-visual experiences with real-time synchronization across Web, Android, and Windows platforms.

## Features

- **Cross-Platform**: Works on Web, Android, and Windows
- **Dynamic Mood System**: Real-time audio-visual changes based on reading progress
- **Offline Reading**: Full offline support with background synchronization
- **User Roles**: Reader and Creator roles with different permissions
- **Real-Time Sync**: WebSocket-based progress synchronization
- **Security**: JWT authentication, rate limiting, input validation
- **File Management**: Book and music upload with signed URL access

## Quick Start

### Prerequisites
- Node.js 20 or higher
- PostgreSQL database
- Flutter SDK (for client builds)

### Server Setup
1. Install dependencies:
   ```bash
   cd server
   npm install
   ```

2. Set up environment variables:
   ```bash
   cp .env.example .env
   # Edit .env with your database credentials
   ```

3. Start the server:
   ```bash
   npm run dev
   ```

### Database Setup
The database schema is automatically created when you run the server. Reference data is included.

### Testing
Run the feature test suite:
```bash
./test_features.sh
```

## Deployment

### Ubuntu Server
```bash
sudo ./deploy.sh
```
Complete server setup with Nginx, PM2, and PostgreSQL.

### Android APK
```bash
./build_android.sh
```
Builds APK with installation instructions.

### Windows Desktop
```bash
build_windows.bat
```
Creates Windows desktop application with installer.

### Web Deployment
```bash
./build_web.sh
```
Builds for static hosting (Netlify, Vercel, Firebase).

## Architecture

### Backend (Node.js/TypeScript)
- Express.js REST API
- PostgreSQL database
- WebSocket server (Socket.io)
- JWT authentication
- File upload system
- Rate limiting and security

### Frontend (Flutter)
- Cross-platform UI
- Provider state management
- WebSocket integration
- Offline-first architecture
- Local caching system

### Database Schema
- Users and authentication
- Books and file management
- Music and playlist system
- Mood references and mappings
- Real-time sync data
- Audit logging

## API Endpoints

### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `GET /api/auth/profile` - Get user profile

### Books
- `GET /api/books` - List books
- `POST /api/books` - Create book
- `POST /api/books/upload` - Upload book file

### Music
- `GET /api/music` - List music
- `POST /api/music` - Create music entry
- `POST /api/music/upload` - Upload music file

### Moods
- `GET /api/moods` - List mood references
- `GET /api/moods/backgrounds` - List background images

### Playlists
- `GET /api/playlists` - List user playlists
- `POST /api/playlists` - Create playlist
- `POST /api/playlists/:id/tracks` - Add track to playlist

## Security Features

- Password hashing with bcrypt
- JWT access and refresh tokens
- Rate limiting on all endpoints
- Input validation with Zod
- CORS configuration
- Security headers (Helmet)
- Signed URLs for file access
- Audit logging for all operations

## Real-Time Features

- Reading progress synchronization
- Mood-based audio-visual triggers
- Multi-device sync
- Offline support with delta sync
- WebSocket connection management

## File Management

- Book uploads (PDF, EPUB, TXT)
- Music file uploads
- Background image management
- Signed URL access control
- File compression and optimization

## Testing

The application includes comprehensive testing:
- API endpoint validation
- Authentication flow testing
- WebSocket connection testing
- Security feature verification
- Database connectivity testing

## Production Deployment

All deployment scripts are included and tested:
- Ubuntu server with Nginx and PM2
- Android APK with installation guide
- Windows desktop with installer
- Web build for static hosting

## Support

For deployment assistance or bug reports, refer to:
- `DEPLOYMENT_SUMMARY.md` - Complete deployment guide
- `TODOLIST.md` - Implementation status
- `Description.txt` - Original requirements

## Status

✅ **READY FOR PRODUCTION DEPLOYMENT**

All core features implemented and tested across all target platforms.

---

*Book Sphere - Immersive Reading Experience*