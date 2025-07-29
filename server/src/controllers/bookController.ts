import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { 
  createBook, 
  findBookById, 
  findAllPublishedBooks, 
  findBooksByCreator,
  searchBooks,
  findBooksByGenre,
  findBooksByTag,
  updateBook,
  deleteBook,
  canUserModifyBook,
  getPopularBooks,
  getRecentBooks,
  getAllGenres,
  getAllTags
} from '../models/Book';
import { createError } from '../middleware/errorHandler';
import { AuthenticatedRequestWithRole } from '../middleware/roleAuth';

const createBookSchema = z.object({
  title: z.string().min(1).max(500),
  author: z.string().max(300).optional(),
  description: z.string().optional(),
  file_path: z.string(),
  file_size: z.number().optional(),
  file_type: z.string(),
  cover_image_url: z.string().url().optional(),
  isbn: z.string().max(20).optional(),
  language: z.string().max(10).optional(),
  page_count: z.number().min(1).optional(),
  word_count: z.number().min(1).optional(),
  tags: z.array(z.string()).optional(),
  genre: z.string().max(100).optional()
});

const updateBookSchema = z.object({
  title: z.string().min(1).max(500).optional(),
  author: z.string().max(300).optional(),
  description: z.string().optional(),
  cover_image_url: z.string().url().optional(),
  isbn: z.string().max(20).optional(),
  language: z.string().max(10).optional(),
  page_count: z.number().min(1).optional(),
  word_count: z.number().min(1).optional(),
  is_published: z.boolean().optional(),
  tags: z.array(z.string()).optional(),
  genre: z.string().max(100).optional()
});

const searchQuerySchema = z.object({
  q: z.string().optional(),
  genre: z.string().optional(),
  tag: z.string().optional(),
  page: z.string().transform(Number).optional(),
  limit: z.string().transform(Number).optional()
});

export const createBookRecord = async (req: AuthenticatedRequestWithRole, res: Response, next: NextFunction) => {
  try {
    if (!req.user) {
      throw createError('User not authenticated', 401);
    }

    // Only creators and admins can create books
    if (!['creator', 'admin'].includes(req.user.role)) {
      throw createError('Only creators can upload books', 403);
    }

    const validatedData = createBookSchema.parse(req.body);
    const book = await createBook({
      ...validatedData,
      creator_id: req.user.userId
    });
    
    res.status(201).json({
      message: 'Book created successfully',
      data: book
    });
  } catch (error) {
    next(error);
  }
};

export const uploadBook = async (req: AuthenticatedRequestWithRole, res: Response, next: NextFunction) => {
  try {
    if (!req.user) {
      throw createError('User not authenticated', 401);
    }

    // Only creators and admins can upload books
    if (!['creator', 'admin'].includes(req.user.role)) {
      throw createError('Only creators can upload books', 403);
    }

    if (!req.file) {
      throw createError('No file uploaded', 400);
    }

    const { 
      title, 
      author, 
      description, 
      isbn, 
      language, 
      page_count, 
      word_count, 
      tags, 
      genre 
    } = req.body;

    if (!title) {
      throw createError('Title is required', 400);
    }

    // Create book record with uploaded file
    const book = await createBook({
      creator_id: req.user.userId,
      title,
      author,
      description,
      file_path: req.file.path,
      file_size: req.file.size,
      file_type: req.file.mimetype,
      isbn,
      language: language || 'en',
      page_count: page_count ? parseInt(page_count) : undefined,
      word_count: word_count ? parseInt(word_count) : undefined,
      tags: tags ? (Array.isArray(tags) ? tags : JSON.parse(tags)) : [],
      genre
    });
    
    res.status(201).json({
      message: 'Book uploaded successfully',
      data: book
    });
  } catch (error) {
    next(error);
  }
};

export const getBook = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const bookId = req.params.id;
    if (!bookId) {
      throw createError('Book ID is required', 400);
    }

    const book = await findBookById(bookId);
    if (!book) {
      throw createError('Book not found', 404);
    }

    // Only return published books to general users
    if (!book.is_published) {
      throw createError('Book not available', 404);
    }

    res.json({
      message: 'Book retrieved successfully',
      data: book
    });
  } catch (error) {
    next(error);
  }
};

export const getBooks = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { q, genre, tag, page = 1, limit = 20 } = searchQuerySchema.parse(req.query);
    
    let books;
    if (q) {
      books = await searchBooks(q);
    } else if (genre) {
      books = await findBooksByGenre(genre);
    } else if (tag) {
      books = await findBooksByTag(tag);
    } else {
      books = await findAllPublishedBooks();
    }

    // Simple pagination
    const startIndex = (page - 1) * limit;
    const endIndex = startIndex + limit;
    const paginatedBooks = books.slice(startIndex, endIndex);

    res.json({
      message: 'Books retrieved successfully',
      data: {
        books: paginatedBooks,
        pagination: {
          page,
          limit,
          total: books.length,
          hasMore: endIndex < books.length
        }
      }
    });
  } catch (error) {
    next(error);
  }
};

// Get creator's own books (includes unpublished)
export const getCreatorBooks = async (req: AuthenticatedRequestWithRole, res: Response, next: NextFunction) => {
  try {
    if (!req.user) {
      throw createError('User not authenticated', 401);
    }

    if (!['creator', 'admin'].includes(req.user.role)) {
      throw createError('Only creators can view their book management', 403);
    }

    const books = await findBooksByCreator(req.user.userId);
    
    res.json({
      message: 'Creator books retrieved successfully',
      data: books
    });
  } catch (error) {
    next(error);
  }
};

export const updateBookRecord = async (req: AuthenticatedRequestWithRole, res: Response, next: NextFunction) => {
  try {
    if (!req.user) {
      throw createError('User not authenticated', 401);
    }

    const bookId = req.params.id;
    if (!bookId) {
      throw createError('Book ID is required', 400);
    }

    const canModify = await canUserModifyBook(bookId, req.user.userId);
    if (!canModify) {
      throw createError('You can only modify your own books', 403);
    }

    const validatedData = updateBookSchema.parse(req.body);
    const book = await updateBook(bookId, validatedData);
    
    if (!book) {
      throw createError('Book not found', 404);
    }

    res.json({
      message: 'Book updated successfully',
      data: book
    });
  } catch (error) {
    next(error);
  }
};

export const deleteBookRecord = async (req: AuthenticatedRequestWithRole, res: Response, next: NextFunction) => {
  try {
    if (!req.user) {
      throw createError('User not authenticated', 401);
    }

    const bookId = req.params.id;
    if (!bookId) {
      throw createError('Book ID is required', 400);
    }

    const canModify = await canUserModifyBook(bookId, req.user.userId);
    if (!canModify) {
      throw createError('You can only delete your own books', 403);
    }

    const deleted = await deleteBook(bookId);
    
    if (!deleted) {
      throw createError('Book not found', 404);
    }

    res.json({
      message: 'Book deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

// Get popular books
export const getPopular = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const limit = parseInt(req.query.limit as string) || 10;
    const books = await getPopularBooks(limit);
    
    res.json({
      message: 'Popular books retrieved successfully',
      data: books
    });
  } catch (error) {
    next(error);
  }
};

// Get recent books
export const getRecent = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const limit = parseInt(req.query.limit as string) || 20;
    const books = await getRecentBooks(limit);
    
    res.json({
      message: 'Recent books retrieved successfully',
      data: books
    });
  } catch (error) {
    next(error);
  }
};

// Get all genres
export const getGenres = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const genres = await getAllGenres();
    
    res.json({
      message: 'Genres retrieved successfully',
      data: genres
    });
  } catch (error) {
    next(error);
  }
};

// Get all tags
export const getTags = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const tags = await getAllTags();
    
    res.json({
      message: 'Tags retrieved successfully',
      data: tags
    });
  } catch (error) {
    next(error);
  }
};