import { createMusic, findMusicById, findAllMusic, findMusicByGenre, updateMusic, deleteMusic, searchMusic, CreateMusicData } from '../models/Music';
import { createAuditLog } from '../models/AuditLog';
import { generateSignedUrl } from './signedUrlService';
import { generateFileName, getUploadPath, deleteFile } from '../utils/fileUtils';
import { createError } from '../middleware/errorHandler';
import logger from '../utils/logger';

export interface MusicWithSignedUrl {
  id: number;
  title: string;
  genre?: string;
  filepath: string;
  is_public: boolean;
  initial_tempo: number;
  fileUrl: string;
}

export const createNewMusic = async (musicData: CreateMusicData): Promise<MusicWithSignedUrl> => {
  try {
    const music = await createMusic(musicData);

    // Generate signed URL for file access
    const fileUrl = generateSignedUrl(music.filepath);

    // Log music creation
    await createAuditLog({
      action: 'MUSIC_CREATED',
      entity_type: 'music',
      entity_id: music.id,
      details: { title: music.title, genre: music.genre, filepath: music.filepath }
    });

    logger.info('Music created successfully', { musicId: music.id, title: music.title });

    return {
      ...music,
      fileUrl
    };
  } catch (error) {
    logger.error('Failed to create music', { error, musicData });
    throw error;
  }
};

export const getMusicById = async (musicId: number): Promise<MusicWithSignedUrl | null> => {
  const music = await findMusicById(musicId);
  
  if (!music) {
    return null;
  }

  // Generate signed URL for file access
  const fileUrl = generateSignedUrl(music.filepath);

  return {
    ...music,
    fileUrl
  };
};

export const getAllMusic = async (): Promise<MusicWithSignedUrl[]> => {
  const musicList = await findAllMusic();
  
  return musicList.map(music => ({
    ...music,
    fileUrl: generateSignedUrl(music.filepath)
  }));
};

export const getMusicByGenre = async (genre: string): Promise<MusicWithSignedUrl[]> => {
  const musicList = await findMusicByGenre(genre);
  
  return musicList.map(music => ({
    ...music,
    fileUrl: generateSignedUrl(music.filepath)
  }));
};

export const searchMusicService = async (searchTerm: string): Promise<MusicWithSignedUrl[]> => {
  const musicList = await searchMusic(searchTerm);
  
  return musicList.map(music => ({
    ...music,
    fileUrl: generateSignedUrl(music.filepath)
  }));
};

export const updateMusicService = async (musicId: number, updateData: { title?: string; genre?: string; is_public?: boolean; initial_tempo?: number }): Promise<MusicWithSignedUrl | null> => {
  const updatedMusic = await updateMusic(musicId, updateData);
  
  if (!updatedMusic) {
    return null;
  }

  // Generate signed URL for file access
  const fileUrl = generateSignedUrl(updatedMusic.filepath);

  // Log music update
  await createAuditLog({
    action: 'MUSIC_UPDATED',
    entity_type: 'music',
    entity_id: musicId,
    details: { title: updatedMusic.title, changes: updateData }
  });

  logger.info('Music updated successfully', { musicId, title: updatedMusic.title });

  return {
    ...updatedMusic,
    fileUrl
  };
};

export const deleteMusicService = async (musicId: number): Promise<boolean> => {
  // First check if music exists
  const existingMusic = await findMusicById(musicId);
  if (!existingMusic) {
    throw createError('Music not found', 404);
  }

  // Delete the music from database
  const deleted = await deleteMusic(musicId);
  
  if (deleted) {
    // Delete the actual file
    try {
      deleteFile(existingMusic.filepath);
    } catch (error) {
      logger.warn('Failed to delete music file', { filepath: existingMusic.filepath, error });
    }

    // Log music deletion
    await createAuditLog({
      action: 'MUSIC_DELETED',
      entity_type: 'music',
      entity_id: musicId,
      details: { title: existingMusic.title, filepath: existingMusic.filepath }
    });

    logger.info('Music deleted successfully', { musicId, title: existingMusic.title });
  }

  return deleted;
};

export const handleMusicUpload = async (
  file: Express.Multer.File,
  title: string,
  genre: string,
  initial_tempo: number,
  is_public: boolean = true
): Promise<MusicWithSignedUrl> => {
  const musicDir = getUploadPath('music');
  const fileName = generateFileName(file.originalname);
  const filePath = `${musicDir}/${fileName}`;

  // Move uploaded file to final location
  require('fs').renameSync(file.path, filePath);

  // Create music record
  const music = await createNewMusic({
    title,
    genre,
    filepath: filePath,
    is_public,
    initial_tempo
  });

  logger.info('Music uploaded successfully', { musicId: music.id, title, genre, filepath: filePath });

  return music;
};

export const getTempoForMood = async (musicId: number, moodTempo: number): Promise<number> => {
  const music = await findMusicById(musicId);
  if (!music) {
    throw createError('Music not found', 404);
  }

  // Calculate tempo adjustment based on mood
  const tempoRatio = moodTempo / music.initial_tempo;
  const adjustedTempo = Math.round(music.initial_tempo * tempoRatio);

  // Ensure tempo stays within reasonable bounds
  return Math.max(30, Math.min(200, adjustedTempo));
};