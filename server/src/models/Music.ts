import { query } from '../config/db';

export interface Music {
  id: number;
  title: string;
  genre?: string;
  filepath: string;
  is_public: boolean;
  initial_tempo: number;
}

export interface CreateMusicData {
  title: string;
  genre?: string;
  filepath: string;
  is_public?: boolean;
  initial_tempo: number;
}

export interface UpdateMusicData {
  title?: string;
  genre?: string;
  filepath?: string;
  is_public?: boolean;
  initial_tempo?: number;
}

export const createMusic = async (musicData: CreateMusicData): Promise<Music> => {
  const result = await query(`
    INSERT INTO Music (title, genre, filepath, is_public, initial_tempo)
    VALUES ($1, $2, $3, $4, $5)
    RETURNING *
  `, [
    musicData.title,
    musicData.genre,
    musicData.filepath,
    musicData.is_public !== undefined ? musicData.is_public : true,
    musicData.initial_tempo
  ]);

  return result.rows[0];
};

export const findMusicById = async (id: number): Promise<Music | null> => {
  const result = await query('SELECT * FROM Music WHERE id = $1', [id]);
  return result.rows[0] || null;
};

export const findAllMusic = async (): Promise<Music[]> => {
  const result = await query('SELECT * FROM Music WHERE is_public = true ORDER BY title');
  return result.rows;
};

export const findMusicByGenre = async (genre: string): Promise<Music[]> => {
  const result = await query('SELECT * FROM Music WHERE genre = $1 AND is_public = true ORDER BY title', [genre]);
  return result.rows;
};

export const updateMusic = async (id: number, musicData: UpdateMusicData): Promise<Music | null> => {
  const setClause = [];
  const values = [];
  let paramIndex = 1;

  Object.entries(musicData).forEach(([key, value]) => {
    if (value !== undefined) {
      setClause.push(`${key} = $${paramIndex}`);
      values.push(value);
      paramIndex++;
    }
  });

  if (setClause.length === 0) {
    return findMusicById(id);
  }

  values.push(id);
  const result = await query(`
    UPDATE Music 
    SET ${setClause.join(', ')} 
    WHERE id = $${paramIndex}
    RETURNING *
  `, values);

  return result.rows[0] || null;
};

export const deleteMusic = async (id: number): Promise<boolean> => {
  const result = await query('DELETE FROM Music WHERE id = $1', [id]);
  return result.rowCount > 0;
};

export const searchMusic = async (searchTerm: string): Promise<Music[]> => {
  const result = await query(`
    SELECT * FROM Music 
    WHERE (title ILIKE $1 OR genre ILIKE $1) AND is_public = true
    ORDER BY title
  `, [`%${searchTerm}%`]);
  return result.rows;
};