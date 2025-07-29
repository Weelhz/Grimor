import { query } from '../config/db';
import { findMoodMapForProgress, MoodMap } from '../models/MoodMap';
import { createAuditLog } from '../models/AuditLog';
import logger from '../utils/logger';

export interface MoodReference {
  id: number;
  mood_name: string;
  tempo_electronic: number;
  tempo_classic: number;
  tempo_lofi: number;
  tempo_custom: number;
}

export interface Background {
  id: number;
  mood_id: number;
  background_path: string;
}

export interface MoodTrigger {
  mood: MoodReference;
  background?: Background;
  tempo: number;
  transition_type: string;
}

export const getMoodReferences = async (): Promise<MoodReference[]> => {
  const result = await query('SELECT * FROM MoodReference ORDER BY mood_name');
  return result.rows;
};

export const getMoodById = async (id: number): Promise<MoodReference | null> => {
  const result = await query('SELECT * FROM MoodReference WHERE id = $1', [id]);
  return result.rows[0] || null;
};

export const getBackgroundsByMood = async (moodId: number): Promise<Background[]> => {
  const result = await query('SELECT * FROM Background WHERE mood_id = $1', [moodId]);
  return result.rows;
};

export const calculateMoodTrigger = async (
  presetId: number,
  chapter: number,
  pageFraction: number,
  musicGenre: string = 'electronic',
  moodSensitivity: number = 1.0
): Promise<MoodTrigger | null> => {
  // Find the mood map entry for the current reading progress
  const moodMapEntry = await findMoodMapForProgress(presetId, chapter, pageFraction);
  
  if (!moodMapEntry || !moodMapEntry.mood_id) {
    return null;
  }

  // Get mood reference data
  const mood = await getMoodById(moodMapEntry.mood_id);
  if (!mood) {
    return null;
  }

  // Get background if specified
  let background: Background | undefined;
  if (moodMapEntry.background_id) {
    const backgroundResult = await query('SELECT * FROM Background WHERE id = $1', [moodMapEntry.background_id]);
    background = backgroundResult.rows[0];
  }

  // Calculate tempo based on genre and sensitivity
  let baseTempo: number;
  switch (musicGenre.toLowerCase()) {
    case 'electronic':
      baseTempo = mood.tempo_electronic;
      break;
    case 'classic':
      baseTempo = mood.tempo_classic;
      break;
    case 'lofi':
      baseTempo = mood.tempo_lofi;
      break;
    case 'custom':
      baseTempo = mood.tempo_custom || mood.tempo_electronic;
      break;
    default:
      baseTempo = mood.tempo_electronic;
  }

  // Apply mood sensitivity scaling
  const sensitivityMultiplier = Math.max(0.1, Math.min(2.0, moodSensitivity));
  const adjustedTempo = Math.round(baseTempo * sensitivityMultiplier);

  logger.debug('Mood trigger calculated', {
    presetId,
    chapter,
    pageFraction,
    moodName: mood.mood_name,
    baseTempo,
    adjustedTempo,
    sensitivity: moodSensitivity
  });

  return {
    mood,
    background,
    tempo: adjustedTempo,
    transition_type: moodMapEntry.transition_type
  };
};

export const logMoodTrigger = async (
  userId: number,
  presetId: number,
  chapter: number,
  pageFraction: number,
  moodTrigger: MoodTrigger
): Promise<void> => {
  await createAuditLog({
    user_id: userId,
    action: 'MOOD_TRIGGERED',
    entity_type: 'mood_map',
    entity_id: presetId,
    details: {
      chapter,
      pageFraction,
      moodName: moodTrigger.mood.mood_name,
      tempo: moodTrigger.tempo,
      transitionType: moodTrigger.transition_type,
      backgroundPath: moodTrigger.background?.background_path
    }
  });
};

export const createMoodReference = async (
  moodName: string,
  tempoElectronic: number,
  tempoClassic: number,
  tempoLofi: number,
  tempoCustom: number = 0
): Promise<MoodReference> => {
  const result = await query(`
    INSERT INTO MoodReference (mood_name, tempo_electronic, tempo_classic, tempo_lofi, tempo_custom)
    VALUES ($1, $2, $3, $4, $5)
    RETURNING *
  `, [moodName, tempoElectronic, tempoClassic, tempoLofi, tempoCustom]);

  return result.rows[0];
};

export const createBackground = async (moodId: number, backgroundPath: string): Promise<Background> => {
  const result = await query(`
    INSERT INTO Background (mood_id, background_path)
    VALUES ($1, $2)
    RETURNING *
  `, [moodId, backgroundPath]);

  return result.rows[0];
};