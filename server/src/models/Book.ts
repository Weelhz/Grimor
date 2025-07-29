import { query } from '../config/db';

export interface Book {
  id: string;
  creator_id: string;
  title: string;
  author?: string;
  description?: string;
  file_path: string;
  file_size?: number;
  file_type: string;
  cover_image_url?: string;
  isbn?: string;
  language: string;
  page_count?: number;
  word_count?: number;
  uploaded_at: Date;
  last_accessed?: Date;
  metadata: any;
  is_published: boolean;
  tags: string[];
  genre?: string;
}

export interface CreateBookData {
  creator_id: string;
  title: string;
  author?: string;
  description?: string;
  file_path: string;
  file_size?: number;
  file_type: string;
  cover_image_url?: string;
  isbn?: string;
  language?: string;
  page_count?: number;
  word_count?: number;
  metadata?: any;
  tags?: string[];
  genre?: string;
}

export interface UpdateBookData {
  title?: string;
  author?: string;
  description?: string;
  cover_image_url?: string;
  isbn?: string;
  language?: string;
  page_count?: number;
  word_count?: number;
  metadata?: any;
  is_published?: boolean;
  tags?: string[];
  genre?: string;
}

export const createBook = async (bookData: CreateBookData): Promise<Book> => {
  const result = await query(`
    INSERT INTO books (
      creator_id, title, author, description, file_path, file_size, file_type,
      cover_image_url, isbn, language, page_count, word_count, metadata, tags, genre
    )
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
    RETURNING *
  `, [
    bookData.creator_id,
    bookData.title,
    bookData.author,
    bookData.description,
    bookData.file_path,
    bookData.file_size,
    bookData.file_type,
    bookData.cover_image_url,
    bookData.isbn,
    bookData.language || 'en',
    bookData.page_count,
    bookData.word_count,
    bookData.metadata || {},
    bookData.tags || [],
    bookData.genre
  ]);

  return result.rows[0];
};

export const findBookById = async (id: string): Promise<Book | null> => {
  const result = await query('SELECT * FROM books WHERE id = $1', [id]);
  return result.rows[0] || null;
};

// Get all published books (public library)
export const findAllPublishedBooks = async (): Promise<Book[]> => {
  const result = await query(`
    SELECT b.*, u.username as creator_username, u.display_name as creator_display_name
    FROM books b
    JOIN users u ON b.creator_id = u.id
    WHERE b.is_published = true
    ORDER BY b.uploaded_at DESC
  `);
  return result.rows;
};

// Get books by creator (for creator management)
export const findBooksByCreator = async (creatorId: string): Promise<Book[]> => {
  const result = await query(`
    SELECT * FROM books 
    WHERE creator_id = $1 
    ORDER BY uploaded_at DESC
  `, [creatorId]);
  return result.rows;
};

// Search books by title, author, or description
export const searchBooks = async (query_text: string): Promise<Book[]> => {
  const result = await query(`
    SELECT b.*, u.username as creator_username, u.display_name as creator_display_name
    FROM books b
    JOIN users u ON b.creator_id = u.id
    WHERE b.is_published = true 
    AND (
      b.title ILIKE $1 OR 
      b.author ILIKE $1 OR 
      b.description ILIKE $1 OR
      b.genre ILIKE $1 OR
      $1 = ANY(b.tags)
    )
    ORDER BY b.uploaded_at DESC
  `, [`%${query_text}%`]);
  return result.rows;
};

// Filter books by genre
export const findBooksByGenre = async (genre: string): Promise<Book[]> => {
  const result = await query(`
    SELECT b.*, u.username as creator_username, u.display_name as creator_display_name
    FROM books b
    JOIN users u ON b.creator_id = u.id
    WHERE b.is_published = true AND b.genre = $1
    ORDER BY b.uploaded_at DESC
  `, [genre]);
  return result.rows;
};

// Filter books by tags
export const findBooksByTag = async (tag: string): Promise<Book[]> => {
  const result = await query(`
    SELECT b.*, u.username as creator_username, u.display_name as creator_display_name
    FROM books b
    JOIN users u ON b.creator_id = u.id
    WHERE b.is_published = true AND $1 = ANY(b.tags)
    ORDER BY b.uploaded_at DESC
  `, [tag]);
  return result.rows;
};

export const updateBook = async (id: string, bookData: UpdateBookData): Promise<Book | null> => {
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
    UPDATE books 
    SET ${setClause.join(', ')}, updated_at = CURRENT_TIMESTAMP
    WHERE id = $${paramIndex}
    RETURNING *
  `, values);

  return result.rows[0] || null;
};

export const deleteBook = async (id: string): Promise<boolean> => {
  const result = await query('DELETE FROM books WHERE id = $1', [id]);
  return result.rowCount > 0;
};

// Check if user can modify book (creator or admin)
export const canUserModifyBook = async (bookId: string, userId: string): Promise<boolean> => {
  const result = await query(`
    SELECT b.creator_id, u.user_role
    FROM books b
    JOIN users u ON u.id = $2
    WHERE b.id = $1
  `, [bookId, userId]);

  if (result.rows.length === 0) return false;

  const { creator_id, user_role } = result.rows[0];
  return creator_id === userId || user_role === 'admin';
};

// Get popular books (most read)
export const getPopularBooks = async (limit: number = 10): Promise<Book[]> => {
  const result = await query(`
    SELECT b.*, u.username as creator_username, u.display_name as creator_display_name,
           COUNT(rp.id) as read_count
    FROM books b
    JOIN users u ON b.creator_id = u.id
    LEFT JOIN reading_progress rp ON b.id = rp.book_id
    WHERE b.is_published = true
    GROUP BY b.id, u.username, u.display_name
    ORDER BY read_count DESC, b.uploaded_at DESC
    LIMIT $1
  `, [limit]);
  return result.rows;
};

// Get recently uploaded books
export const getRecentBooks = async (limit: number = 20): Promise<Book[]> => {
  const result = await query(`
    SELECT b.*, u.username as creator_username, u.display_name as creator_display_name
    FROM books b
    JOIN users u ON b.creator_id = u.id
    WHERE b.is_published = true
    ORDER BY b.uploaded_at DESC
    LIMIT $1
  `, [limit]);
  return result.rows;
};

// Get all unique genres
export const getAllGenres = async (): Promise<string[]> => {
  const result = await query(`
    SELECT DISTINCT genre
    FROM books
    WHERE is_published = true AND genre IS NOT NULL
    ORDER BY genre
  `);
  return result.rows.map(row => row.genre);
};

// Get all unique tags
export const getAllTags = async (): Promise<string[]> => {
  const result = await query(`
    SELECT DISTINCT unnest(tags) as tag
    FROM books
    WHERE is_published = true
    ORDER BY tag
  `);
  return result.rows.map(row => row.tag);
};