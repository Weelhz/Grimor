import { query } from '../config/db';

export interface UserPlaylist {
  id: number;
  user_id: number;
  name: string;
  created_at: Date;
}

export interface PlaylistTrack {
  id: number;
  playlist_id: number;
  music_id: number;
  track_order: number;
}

export interface CreatePlaylistData {
  user_id: number;
  name: string;
}

export interface UpdatePlaylistData {
  name?: string;
}

export interface AddTrackData {
  playlist_id: number;
  music_id: number;
  track_order: number;
}

export const createPlaylist = async (playlistData: CreatePlaylistData): Promise<UserPlaylist> => {
  const result = await query(`
    INSERT INTO UserPlaylist (user_id, name)
    VALUES ($1, $2)
    RETURNING *
  `, [playlistData.user_id, playlistData.name]);

  return result.rows[0];
};

export const findPlaylistById = async (id: number): Promise<UserPlaylist | null> => {
  const result = await query('SELECT * FROM UserPlaylist WHERE id = $1', [id]);
  return result.rows[0] || null;
};

export const findPlaylistsByUser = async (userId: number): Promise<UserPlaylist[]> => {
  const result = await query('SELECT * FROM UserPlaylist WHERE user_id = $1 ORDER BY created_at DESC', [userId]);
  return result.rows;
};

export const updatePlaylist = async (id: number, playlistData: UpdatePlaylistData): Promise<UserPlaylist | null> => {
  const setClause = [];
  const values = [];
  let paramIndex = 1;

  Object.entries(playlistData).forEach(([key, value]) => {
    if (value !== undefined) {
      setClause.push(`${key} = $${paramIndex}`);
      values.push(value);
      paramIndex++;
    }
  });

  if (setClause.length === 0) {
    return findPlaylistById(id);
  }

  values.push(id);
  const result = await query(`
    UPDATE UserPlaylist 
    SET ${setClause.join(', ')} 
    WHERE id = $${paramIndex}
    RETURNING *
  `, values);

  return result.rows[0] || null;
};

export const deletePlaylist = async (id: number): Promise<boolean> => {
  const result = await query('DELETE FROM UserPlaylist WHERE id = $1', [id]);
  return result.rowCount > 0;
};

export const addTrackToPlaylist = async (trackData: AddTrackData): Promise<PlaylistTrack> => {
  const result = await query(`
    INSERT INTO PlaylistTracks (playlist_id, music_id, track_order)
    VALUES ($1, $2, $3)
    RETURNING *
  `, [trackData.playlist_id, trackData.music_id, trackData.track_order]);

  return result.rows[0];
};

export const getPlaylistTracks = async (playlistId: number): Promise<PlaylistTrack[]> => {
  const result = await query(`
    SELECT pt.*, m.title, m.genre, m.filepath, m.initial_tempo
    FROM PlaylistTracks pt
    JOIN Music m ON pt.music_id = m.id
    WHERE pt.playlist_id = $1
    ORDER BY pt.track_order
  `, [playlistId]);
  return result.rows;
};

export const removeTrackFromPlaylist = async (playlistId: number, musicId: number): Promise<boolean> => {
  const result = await query('DELETE FROM PlaylistTracks WHERE playlist_id = $1 AND music_id = $2', [playlistId, musicId]);
  return result.rowCount > 0;
};

export const reorderPlaylistTracks = async (playlistId: number, trackOrders: { musicId: number; order: number }[]): Promise<boolean> => {
  const client = await query('BEGIN', []);
  
  try {
    for (const { musicId, order } of trackOrders) {
      await query('UPDATE PlaylistTracks SET track_order = $1 WHERE playlist_id = $2 AND music_id = $3', [order, playlistId, musicId]);
    }
    
    await query('COMMIT', []);
    return true;
  } catch (error) {
    await query('ROLLBACK', []);
    throw error;
  }
};