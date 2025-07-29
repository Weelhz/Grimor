import { query } from '../config/db';
import { hashPassword, verifyPassword } from '../utils/hash';

export interface User {
  id: string;
  email: string;
  username: string;
  display_name?: string;
  password_hash: string;
  user_role: 'reader' | 'creator' | 'admin';
  avatar_url?: string;
  created_at: Date;
  updated_at: Date;
  last_login?: Date;
  is_active: boolean;
  preferences: any;
}

export interface CreateUserData {
  email: string;
  username: string;
  display_name?: string;
  password: string;
  user_role?: 'reader' | 'creator' | 'admin';
  preferences?: any;
}

export interface UpdateUserData {
  display_name?: string;
  avatar_url?: string;
  user_role?: 'reader' | 'creator' | 'admin';
  preferences?: any;
}

export const createUser = async (userData: CreateUserData): Promise<User> => {
  const passwordHash = await hashPassword(userData.password);
  
  const result = await query(`
    INSERT INTO users (email, username, display_name, password_hash, user_role, preferences)
    VALUES ($1, $2, $3, $4, $5, $6)
    RETURNING *
  `, [
    userData.email,
    userData.username,
    userData.display_name,
    passwordHash,
    userData.user_role || 'reader',
    userData.preferences || {}
  ]);

  return result.rows[0];
};

export const findUserByUsername = async (username: string): Promise<User | null> => {
  const result = await query('SELECT * FROM users WHERE username = $1', [username]);
  return result.rows[0] || null;
};

export const findUserByEmail = async (email: string): Promise<User | null> => {
  const result = await query('SELECT * FROM users WHERE email = $1', [email]);
  return result.rows[0] || null;
};

export const findUserById = async (id: string): Promise<User | null> => {
  const result = await query('SELECT * FROM users WHERE id = $1', [id]);
  return result.rows[0] || null;
};

export const updateUser = async (id: string, userData: UpdateUserData): Promise<User | null> => {
  const setClause = [];
  const values = [];
  let paramIndex = 1;

  Object.entries(userData).forEach(([key, value]) => {
    if (value !== undefined) {
      setClause.push(`${key} = $${paramIndex}`);
      values.push(value);
      paramIndex++;
    }
  });

  if (setClause.length === 0) {
    return findUserById(id);
  }

  values.push(id);
  const result = await query(`
    UPDATE users 
    SET ${setClause.join(', ')}, updated_at = CURRENT_TIMESTAMP
    WHERE id = $${paramIndex}
    RETURNING *
  `, values);

  return result.rows[0] || null;
};

export const verifyUserPassword = async (username: string, password: string): Promise<User | null> => {
  const user = await findUserByUsername(username);
  if (!user) return null;

  const isValid = await verifyPassword(password, user.password_hash);
  return isValid ? user : null;
};

export const deleteUser = async (id: string): Promise<boolean> => {
  const result = await query('DELETE FROM users WHERE id = $1', [id]);
  return result.rowCount > 0;
};