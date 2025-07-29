import { query } from '../config/db';

export interface MoodMap {
  id: number;
  preset_id: number;
  chapter: number;
  page_fraction: number;
  mood_id?: number;
  background_id?: number;
  transition_type: string;
}

export interface CreateMoodMapData {
  preset_id: number;
  chapter: number;
  page_fraction: number;
  mood_id?: number;
  background_id?: number;
  transition_type?: string;
}

export interface UpdateMoodMapData {
  chapter?: number;
  page_fraction?: number;
  mood_id?: number;
  background_id?: number;
  transition_type?: string;
}

export const createMoodMap = async (moodMapData: CreateMoodMapData): Promise<MoodMap> => {
  const result = await query(`
    INSERT INTO MoodMap (preset_id, chapter, page_fraction, mood_id, background_id, transition_type)
    VALUES ($1, $2, $3, $4, $5, $6)
    RETURNING *
  `, [
    moodMapData.preset_id,
    moodMapData.chapter,
    moodMapData.page_fraction,
    moodMapData.mood_id,
    moodMapData.background_id,
    moodMapData.transition_type || 'fade'
  ]);

  return result.rows[0];
};

export const findMoodMapById = async (id: number): Promise<MoodMap | null> => {
  const result = await query('SELECT * FROM MoodMap WHERE id = $1', [id]);
  return result.rows[0] || null;
};

export const findMoodMapsByPreset = async (presetId: number): Promise<MoodMap[]> => {
  const result = await query(`
    SELECT * FROM MoodMap 
    WHERE preset_id = $1 
    ORDER BY chapter, page_fraction
  `, [presetId]);
  return result.rows;
};

export const findMoodMapsByChapter = async (presetId: number, chapter: number): Promise<MoodMap[]> => {
  const result = await query(`
    SELECT * FROM MoodMap 
    WHERE preset_id = $1 AND chapter = $2 
    ORDER BY page_fraction
  `, [presetId, chapter]);
  return result.rows;
};

export const findMoodMapForProgress = async (presetId: number, chapter: number, pageFraction: number): Promise<MoodMap | null> => {
  const result = await query(`
    SELECT * FROM MoodMap 
    WHERE preset_id = $1 AND chapter = $2 AND page_fraction <= $3 
    ORDER BY chapter DESC, page_fraction DESC 
    LIMIT 1
  `, [presetId, chapter, pageFraction]);
  return result.rows[0] || null;
};

export const updateMoodMap = async (id: number, moodMapData: UpdateMoodMapData): Promise<MoodMap | null> => {
  const setClause = [];
  const values = [];
  let paramIndex = 1;

  Object.entries(moodMapData).forEach(([key, value]) => {
    if (value !== undefined) {
      setClause.push(`${key} = $${paramIndex}`);
      values.push(value);
      paramIndex++;
    }
  });

  if (setClause.length === 0) {
    return findMoodMapById(id);
  }

  values.push(id);
  const result = await query(`
    UPDATE MoodMap 
    SET ${setClause.join(', ')} 
    WHERE id = $${paramIndex}
    RETURNING *
  `, values);

  return result.rows[0] || null;
};

export const deleteMoodMap = async (id: number): Promise<boolean> => {
  const result = await query('DELETE FROM MoodMap WHERE id = $1', [id]);
  return result.rowCount > 0;
};

export const deleteMoodMapsByPreset = async (presetId: number): Promise<boolean> => {
  const result = await query('DELETE FROM MoodMap WHERE preset_id = $1', [presetId]);
  return result.rowCount > 0;
};