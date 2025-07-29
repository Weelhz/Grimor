import { query } from '../config/db';

export interface Book {
  id: number;
  creator_id?: number;
  title: string;
  filepath: string;
  uploaded_at: Date;
}

export interface CreateBookData {
  creator_id?: number;
  title: string;
  filepath: string;
}

export interface UpdateBookData {
  title?: string;
  filepath?: string;
}

export const createBook = async (bookData: CreateBookData): Promise<Book> => {
  const result = await query(`
    INSERT INTO Books (creator_id, title, filepath)
    VALUES ($1, $2, $3)
    RETURNING *
  `, [bookData.creator_id, bookData.title, bookData.filepath]);

  return result.rows[0];
};

export const findBookById = async (id: number): Promise<Book | null> => {
  const result = await query('SELECT * FROM Books WHERE id = $1', [id]);
  return result.rows[0] || null;
};

export const findAllBooks = async (): Promise<Book[]> => {
  const result = await query('SELECT * FROM Books ORDER BY uploaded_at DESC');
  return result.rows;
};

export const findBooksByCreator = async (creatorId: number): Promise<Book[]> => {
  const result = await query('SELECT * FROM Books WHERE creator_id = $1 ORDER BY uploaded_at DESC', [creatorId]);
  return result.rows;
};

export const updateBook = async (id: number, bookData: UpdateBookData): Promise<Book | null> => {
  const setClause = [];
  const values = [];
  let paramIndex = 1;

  Object.entries(bookData).forEach(([key, value]) => {
    if (value !== undefined) {
      setClause.push(`${key} = $${paramIndex}`);
      values.push(value);
      paramIndex++;
    }
  });

  if (setClause.length === 0) {
    return findBookById(id);
  }

  values.push(id);
  const result = await query(`
    UPDATE Books 
    SET ${setClause.join(', ')} 
    WHERE id = $${paramIndex}
    RETURNING *
  `, values);

  return result.rows[0] || null;
};

export const deleteBook = async (id: number): Promise<boolean> => {
  const result = await query('DELETE FROM Books WHERE id = $1', [id]);
  return result.rowCount > 0;
};

export const searchBooks = async (searchTerm: string): Promise<Book[]> => {
  const result = await query(`
    SELECT * FROM Books 
    WHERE title ILIKE $1 
    ORDER BY uploaded_at DESC
  `, [`%${searchTerm}%`]);
  return result.rows;
};