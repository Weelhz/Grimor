import { query } from '../config/db';

export interface Preset {
  id: number;
  creator_id: number;
  preset_name: string;
  book_id: number;
  created_at: Date;
}

export interface CreatePresetData {
  creator_id: number;
  preset_name: string;
  book_id: number;
}

export interface UpdatePresetData {
  preset_name?: string;
  book_id?: number;
}

export const createPreset = async (presetData: CreatePresetData): Promise<Preset> => {
  const result = await query(`
    INSERT INTO Presets (creator_id, preset_name, book_id)
    VALUES ($1, $2, $3)
    RETURNING *
  `, [presetData.creator_id, presetData.preset_name, presetData.book_id]);

  return result.rows[0];
};

export const findPresetById = async (id: number): Promise<Preset | null> => {
  const result = await query('SELECT * FROM Presets WHERE id = $1', [id]);
  return result.rows[0] || null;
};

export const findPresetsByCreator = async (creatorId: number): Promise<Preset[]> => {
  const result = await query('SELECT * FROM Presets WHERE creator_id = $1 ORDER BY created_at DESC', [creatorId]);
  return result.rows;
};

export const findPresetsByBook = async (bookId: number): Promise<Preset[]> => {
  const result = await query('SELECT * FROM Presets WHERE book_id = $1 ORDER BY created_at DESC', [bookId]);
  return result.rows;
};

export const updatePreset = async (id: number, presetData: UpdatePresetData): Promise<Preset | null> => {
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
    return findPresetById(id);
  }

  values.push(id);
  const result = await query(`
    UPDATE Presets 
    SET ${setClause.join(', ')} 
    WHERE id = $${paramIndex}
    RETURNING *
  `, values);

  return result.rows[0] || null;
};

export const deletePreset = async (id: number): Promise<boolean> => {
  const result = await query('DELETE FROM Presets WHERE id = $1', [id]);
  return result.rowCount > 0;
};