import { query } from '../config/db';

export interface MoodPreset {
  id: string;
  creator_id: string;
  book_id: string;
  name: string;
  description?: string;
  is_default: boolean;
  created_at: Date;
  updated_at: Date;
}

export interface MoodTrigger {
  id: string;
  preset_id: string;
  mood_type_id: string;
  trigger_condition: any; // JSON object with page_range, keywords, passage_text, etc.
  music_track_id?: string;
  background_image_url?: string;
  visual_effects?: any;
  transition_duration: number;
  is_active: boolean;
  priority: number;
  created_at: Date;
  updated_at: Date;
}

export interface CreateMoodPresetData {
  creator_id: string;
  book_id: string;
  name: string;
  description?: string;
  is_default?: boolean;
}

export interface CreateMoodTriggerData {
  preset_id: string;
  mood_type_id: string;
  trigger_condition: any;
  music_track_id?: string;
  background_image_url?: string;
  visual_effects?: any;
  transition_duration?: number;
  priority?: number;
}

export interface UpdateMoodPresetData {
  name?: string;
  description?: string;
  is_default?: boolean;
}

export interface UpdateMoodTriggerData {
  mood_type_id?: string;
  trigger_condition?: any;
  music_track_id?: string;
  background_image_url?: string;
  visual_effects?: any;
  transition_duration?: number;
  is_active?: boolean;
  priority?: number;
}

// Mood Preset Operations
export const createMoodPreset = async (presetData: CreateMoodPresetData): Promise<MoodPreset> => {
  const result = await query(`
    INSERT INTO mood_presets (creator_id, book_id, name, description, is_default)
    VALUES ($1, $2, $3, $4, $5)
    RETURNING *
  `, [
    presetData.creator_id,
    presetData.book_id,
    presetData.name,
    presetData.description,
    presetData.is_default || false
  ]);

  return result.rows[0];
};

export const findMoodPresetById = async (id: string): Promise<MoodPreset | null> => {
  const result = await query('SELECT * FROM mood_presets WHERE id = $1', [id]);
  return result.rows[0] || null;
};

export const findMoodPresetsByBook = async (bookId: string): Promise<MoodPreset[]> => {
  const result = await query(`
    SELECT mp.*, u.username as creator_username
    FROM mood_presets mp
    JOIN users u ON mp.creator_id = u.id
    WHERE mp.book_id = $1
    ORDER BY mp.is_default DESC, mp.created_at ASC
  `, [bookId]);
  return result.rows;
};

export const findMoodPresetsByCreator = async (creatorId: string): Promise<MoodPreset[]> => {
  const result = await query(`
    SELECT mp.*, b.title as book_title
    FROM mood_presets mp
    JOIN books b ON mp.book_id = b.id
    WHERE mp.creator_id = $1
    ORDER BY mp.created_at DESC
  `, [creatorId]);
  return result.rows;
};

export const updateMoodPreset = async (id: string, presetData: UpdateMoodPresetData): Promise<MoodPreset | null> => {
  const setClause = [];
  const values = [];
  let paramIndex = 1;

  Object.entries(presetData).forEach(([key, value]) => {
    if (value !== undefined) {
      setClause.push(`${key} = $${paramIndex}`);
      values.push(value);
      paramIndex++;
    }
  });

  if (setClause.length === 0) {
    return findMoodPresetById(id);
  }

  values.push(id);
  const result = await query(`
    UPDATE mood_presets 
    SET ${setClause.join(', ')}, updated_at = CURRENT_TIMESTAMP
    WHERE id = $${paramIndex}
    RETURNING *
  `, values);

  return result.rows[0] || null;
};

export const deleteMoodPreset = async (id: string): Promise<boolean> => {
  const result = await query('DELETE FROM mood_presets WHERE id = $1', [id]);
  return result.rowCount > 0;
};

// Mood Trigger Operations
export const createMoodTrigger = async (triggerData: CreateMoodTriggerData): Promise<MoodTrigger> => {
  const result = await query(`
    INSERT INTO mood_triggers (
      preset_id, mood_type_id, trigger_condition, music_track_id, 
      background_image_url, visual_effects, transition_duration, priority
    )
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
    RETURNING *
  `, [
    triggerData.preset_id,
    triggerData.mood_type_id,
    triggerData.trigger_condition,
    triggerData.music_track_id,
    triggerData.background_image_url,
    triggerData.visual_effects,
    triggerData.transition_duration || 3000,
    triggerData.priority || 1
  ]);

  return result.rows[0];
};

export const findMoodTriggerById = async (id: string): Promise<MoodTrigger | null> => {
  const result = await query('SELECT * FROM mood_triggers WHERE id = $1', [id]);
  return result.rows[0] || null;
};

export const findMoodTriggersByPreset = async (presetId: string): Promise<MoodTrigger[]> => {
  const result = await query(`
    SELECT mt.*, mtype.name as mood_name, mtype.color_scheme, mtype.visual_effects as mood_visual_effects
    FROM mood_triggers mt
    JOIN mood_types mtype ON mt.mood_type_id = mtype.id
    WHERE mt.preset_id = $1 AND mt.is_active = true
    ORDER BY mt.priority ASC, mt.created_at ASC
  `, [presetId]);
  return result.rows;
};

export const updateMoodTrigger = async (id: string, triggerData: UpdateMoodTriggerData): Promise<MoodTrigger | null> => {
  const setClause = [];
  const values = [];
  let paramIndex = 1;

  Object.entries(triggerData).forEach(([key, value]) => {
    if (value !== undefined) {
      setClause.push(`${key} = $${paramIndex}`);
      values.push(value);
      paramIndex++;
    }
  });

  if (setClause.length === 0) {
    return findMoodTriggerById(id);
  }

  values.push(id);
  const result = await query(`
    UPDATE mood_triggers 
    SET ${setClause.join(', ')}, updated_at = CURRENT_TIMESTAMP
    WHERE id = $${paramIndex}
    RETURNING *
  `, values);

  return result.rows[0] || null;
};

export const deleteMoodTrigger = async (id: string): Promise<boolean> => {
  const result = await query('DELETE FROM mood_triggers WHERE id = $1', [id]);
  return result.rowCount > 0;
};

// Helper functions
export const canUserModifyPreset = async (presetId: string, userId: string): Promise<boolean> => {
  const result = await query(`
    SELECT mp.creator_id, u.user_role
    FROM mood_presets mp
    JOIN users u ON u.id = $2
    WHERE mp.id = $1
  `, [presetId, userId]);

  if (result.rows.length === 0) return false;

  const { creator_id, user_role } = result.rows[0];
  return creator_id === userId || user_role === 'admin';
};

export const getDefaultPresetForBook = async (bookId: string): Promise<MoodPreset | null> => {
  const result = await query(`
    SELECT * FROM mood_presets 
    WHERE book_id = $1 AND is_default = true
    LIMIT 1
  `, [bookId]);
  return result.rows[0] || null;
};

// Get mood triggers for a specific reading position
export const getMoodTriggersForPosition = async (presetId: string, pageNumber: number): Promise<MoodTrigger[]> => {
  const result = await query(`
    SELECT mt.*, mtype.name as mood_name, mtype.color_scheme, mtype.visual_effects as mood_visual_effects
    FROM mood_triggers mt
    JOIN mood_types mtype ON mt.mood_type_id = mtype.id
    WHERE mt.preset_id = $1 
    AND mt.is_active = true
    AND (
      (mt.trigger_condition->>'page_range' IS NULL) OR
      (
        $2 >= CAST(mt.trigger_condition->'page_range'->0 AS INTEGER) AND
        $2 <= CAST(mt.trigger_condition->'page_range'->1 AS INTEGER)
      )
    )
    ORDER BY mt.priority ASC
  `, [presetId, pageNumber]);
  return result.rows;
};