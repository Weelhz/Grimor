-- BookSphere Database Setup
-- Complete database schema for Ubuntu deployment

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    display_name VARCHAR(100),
    avatar_url TEXT,
    user_role VARCHAR(20) DEFAULT 'reader' CHECK (user_role IN ('reader', 'creator', 'admin')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    preferences JSONB DEFAULT '{}'::jsonb
);

-- Books table
CREATE TABLE IF NOT EXISTS books (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    creator_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(500) NOT NULL,
    author VARCHAR(300),
    description TEXT,
    file_path TEXT NOT NULL,
    file_size BIGINT,
    file_type VARCHAR(10) NOT NULL,
    cover_image_url TEXT,
    isbn VARCHAR(20),
    language VARCHAR(10) DEFAULT 'en',
    page_count INTEGER,
    word_count INTEGER,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_accessed TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}'::jsonb,
    is_published BOOLEAN DEFAULT true,
    tags TEXT[] DEFAULT '{}',
    genre VARCHAR(100)
);

-- Music tracks table
CREATE TABLE IF NOT EXISTS music_tracks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(300) NOT NULL,
    artist VARCHAR(200),
    album VARCHAR(200),
    file_path TEXT NOT NULL,
    file_size BIGINT,
    duration INTEGER, -- in seconds
    bpm INTEGER,
    genre VARCHAR(100),
    mood_tags TEXT[],
    energy_level INTEGER CHECK (energy_level >= 1 AND energy_level <= 10),
    valence INTEGER CHECK (valence >= 1 AND valence <= 10), -- positive/negative emotion
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB DEFAULT '{}'::jsonb,
    is_public BOOLEAN DEFAULT false
);

-- Mood types reference table
CREATE TABLE IF NOT EXISTS mood_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    color_scheme JSONB, -- {primary: "#hex", secondary: "#hex", accent: "#hex"}
    audio_characteristics JSONB, -- {tempo_range: [min, max], energy_range: [min, max], etc}
    visual_effects JSONB, -- {background_type: "gradient", particle_effects: [], etc}
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- User reading progress
CREATE TABLE IF NOT EXISTS reading_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    book_id UUID NOT NULL REFERENCES books(id) ON DELETE CASCADE,
    current_page INTEGER DEFAULT 1,
    total_pages INTEGER,
    progress_percentage DECIMAL(5,2) DEFAULT 0.00,
    reading_time_minutes INTEGER DEFAULT 0,
    last_position TEXT, -- JSON string with detailed position info
    notes TEXT,
    bookmarks JSONB DEFAULT '[]'::jsonb,
    highlights JSONB DEFAULT '[]'::jsonb,
    current_mood_id UUID REFERENCES mood_types(id),
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(user_id, book_id)
);

-- Mood presets (creator-defined mood configurations for books)
CREATE TABLE IF NOT EXISTS mood_presets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    creator_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    book_id UUID NOT NULL REFERENCES books(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(book_id, name)
);

-- Mood triggers table (now linked to presets)
CREATE TABLE IF NOT EXISTS mood_triggers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    preset_id UUID NOT NULL REFERENCES mood_presets(id) ON DELETE CASCADE,
    mood_type_id UUID NOT NULL REFERENCES mood_types(id) ON DELETE CASCADE,
    trigger_condition JSONB NOT NULL, -- {page_range: [start, end], keywords: [], passage_text: "", etc}
    music_track_id UUID REFERENCES music_tracks(id) ON DELETE SET NULL,
    background_image_url TEXT,
    visual_effects JSONB,
    transition_duration INTEGER DEFAULT 3000, -- milliseconds
    is_active BOOLEAN DEFAULT true,
    priority INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- User playlists
CREATE TABLE IF NOT EXISTS playlists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    mood_type_id UUID REFERENCES mood_types(id),
    track_ids UUID[], -- Array of music_track IDs
    is_public BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Reading sessions (for analytics)
CREATE TABLE IF NOT EXISTS reading_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    book_id UUID NOT NULL REFERENCES books(id) ON DELETE CASCADE,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP WITH TIME ZONE,
    pages_read INTEGER DEFAULT 0,
    mood_changes JSONB DEFAULT '[]'::jsonb,
    device_info JSONB,
    location_info JSONB -- {country, city, timezone} - for personalization
);

-- Background images table
CREATE TABLE IF NOT EXISTS background_images (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    file_path TEXT NOT NULL,
    file_size BIGINT,
    mood_tags TEXT[],
    is_public BOOLEAN DEFAULT false,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- User refresh tokens
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    revoked_at TIMESTAMP WITH TIME ZONE,
    device_info JSONB
);

-- Audit log
CREATE TABLE IF NOT EXISTS audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50),
    resource_id UUID,
    details JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(user_role);
CREATE INDEX IF NOT EXISTS idx_books_creator_id ON books(creator_id);
CREATE INDEX IF NOT EXISTS idx_books_title ON books USING gin(to_tsvector('english', title));
CREATE INDEX IF NOT EXISTS idx_books_published ON books(is_published);
CREATE INDEX IF NOT EXISTS idx_books_genre ON books(genre);
CREATE INDEX IF NOT EXISTS idx_books_tags ON books USING gin(tags);
CREATE INDEX IF NOT EXISTS idx_music_tracks_user_id ON music_tracks(user_id);
CREATE INDEX IF NOT EXISTS idx_music_tracks_mood_tags ON music_tracks USING gin(mood_tags);
CREATE INDEX IF NOT EXISTS idx_reading_progress_user_book ON reading_progress(user_id, book_id);
CREATE INDEX IF NOT EXISTS idx_mood_presets_creator_id ON mood_presets(creator_id);
CREATE INDEX IF NOT EXISTS idx_mood_presets_book_id ON mood_presets(book_id);
CREATE INDEX IF NOT EXISTS idx_mood_triggers_preset_id ON mood_triggers(preset_id);
CREATE INDEX IF NOT EXISTS idx_reading_sessions_user_id ON reading_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_reading_sessions_book_id ON reading_sessions(book_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_expires ON refresh_tokens(expires_at);
CREATE INDEX IF NOT EXISTS idx_audit_log_user_id ON audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_created_at ON audit_log(created_at);

-- Insert default mood types
INSERT INTO mood_types (id, name, description, color_scheme, audio_characteristics, visual_effects) VALUES
(
    uuid_generate_v4(),
    'Calm',
    'Peaceful and relaxing atmosphere for focused reading',
    '{"primary": "#4A90E2", "secondary": "#7BB3F0", "accent": "#B3D4F7"}',
    '{"tempo_range": [60, 90], "energy_range": [1, 4], "preferred_genres": ["ambient", "classical", "meditation"]}',
    '{"background_type": "gradient", "particle_effects": ["gentle_float"], "opacity": 0.7}'
),
(
    uuid_generate_v4(),
    'Energetic',
    'Upbeat and motivating environment for active reading',
    '{"primary": "#FF6B6B", "secondary": "#FF8E8E", "accent": "#FFB3B3"}',
    '{"tempo_range": [120, 160], "energy_range": [6, 9], "preferred_genres": ["electronic", "upbeat", "motivational"]}',
    '{"background_type": "dynamic", "particle_effects": ["energy_burst", "rhythm_pulse"], "opacity": 0.8}'
),
(
    uuid_generate_v4(),
    'Mysterious',
    'Dark and atmospheric mood for thriller and mystery books',
    '{"primary": "#6A4C93", "secondary": "#8B6BB1", "accent": "#A891C4"}',
    '{"tempo_range": [70, 110], "energy_range": [3, 7], "preferred_genres": ["dark_ambient", "cinematic", "orchestral"]}',
    '{"background_type": "shadowy", "particle_effects": ["mist", "shadow_play"], "opacity": 0.9}'
),
(
    uuid_generate_v4(),
    'Romantic',
    'Warm and intimate setting for romance novels',
    '{"primary": "#FFB6C1", "secondary": "#FFC0CB", "accent": "#FFD1DC"}',
    '{"tempo_range": [80, 120], "energy_range": [3, 6], "preferred_genres": ["romantic", "soft_jazz", "acoustic"]}',
    '{"background_type": "warm_gradient", "particle_effects": ["heart_flutter", "soft_glow"], "opacity": 0.6}'
),
(
    uuid_generate_v4(),
    'Adventure',
    'Epic and adventurous atmosphere for action and fantasy',
    '{"primary": "#32CD32", "secondary": "#50E050", "accent": "#7FFF7F"}',
    '{"tempo_range": [100, 140], "energy_range": [5, 8], "preferred_genres": ["epic", "orchestral", "adventure"]}',
    '{"background_type": "landscape", "particle_effects": ["wind_effect", "epic_glow"], "opacity": 0.75}'
),
(
    uuid_generate_v4(),
    'Melancholic',
    'Reflective and contemplative mood for dramatic literature',
    '{"primary": "#708090", "secondary": "#858EA0", "accent": "#9CA5B0"}',
    '{"tempo_range": [50, 90], "energy_range": [1, 5], "preferred_genres": ["melancholic", "piano", "strings"]}',
    '{"background_type": "misty", "particle_effects": ["rain_drops", "gentle_sway"], "opacity": 0.8}'
),
(
    uuid_generate_v4(),
    'Focus',
    'Minimal distractions for academic and technical reading',
    '{"primary": "#2E8B57", "secondary": "#3EA969", "accent": "#5FBA7A"}',
    '{"tempo_range": [70, 100], "energy_range": [2, 5], "preferred_genres": ["focus", "minimal", "binaural"]}',
    '{"background_type": "clean", "particle_effects": ["subtle_grid"], "opacity": 0.3}'
),
(
    uuid_generate_v4(),
    'Nostalgic',
    'Vintage and warm atmosphere for classic literature',
    '{"primary": "#DEB887", "secondary": "#F0D0A0", "accent": "#F5E6C8"}',
    '{"tempo_range": [60, 100], "energy_range": [2, 6], "preferred_genres": ["vintage", "classical", "jazz"]}',
    '{"background_type": "sepia", "particle_effects": ["old_film", "dust_motes"], "opacity": 0.7}'
),
(
    uuid_generate_v4(),
    'Futuristic',
    'Modern and technological mood for sci-fi reading',
    '{"primary": "#00CED1", "secondary": "#20E0E3", "accent": "#40F0F5"}',
    '{"tempo_range": [90, 130], "energy_range": [4, 8], "preferred_genres": ["electronic", "synthwave", "futuristic"]}',
    '{"background_type": "digital", "particle_effects": ["data_stream", "neon_glow"], "opacity": 0.85}'
),
(
    uuid_generate_v4(),
    'Cozy',
    'Warm and comfortable environment for light reading',
    '{"primary": "#CD853F", "secondary": "#D2B48C", "accent": "#DDD0B8"}',
    '{"tempo_range": [70, 110], "energy_range": [2, 5], "preferred_genres": ["acoustic", "folk", "cozy"]}',
    '{"background_type": "fireplace", "particle_effects": ["warm_sparkles", "gentle_flicker"], "opacity": 0.6}'
)
ON CONFLICT (name) DO NOTHING;

-- Create function to update updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at columns
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_reading_progress_updated_at ON reading_progress;
CREATE TRIGGER update_reading_progress_updated_at BEFORE UPDATE ON reading_progress FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_mood_triggers_updated_at ON mood_triggers;
CREATE TRIGGER update_mood_triggers_updated_at BEFORE UPDATE ON mood_triggers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_playlists_updated_at ON playlists;
CREATE TRIGGER update_playlists_updated_at BEFORE UPDATE ON playlists FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Grant permissions (adjust as needed for your deployment)
-- These will be customized during deployment based on the actual user setup
GRANT USAGE ON SCHEMA public TO bookuser;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO bookuser;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO bookuser;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO bookuser;