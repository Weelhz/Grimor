import { createBook, findBookById, findAllBooks, updateBook, deleteBook, searchBooks, CreateBookData } from '../models/Book';
import { createAuditLog } from '../models/AuditLog';
import { generateSignedUrl } from './signedUrlService';
import { generateFileName, getUploadPath, deleteFile } from '../utils/fileUtils';
import { createError } from '../middleware/errorHandler';
import logger from '../utils/logger';

export interface BookWithSignedUrl {
  id: number;
  creator_id?: number;
  title: string;
  filepath: string;
  uploaded_at: Date;
  fileUrl: string;
}

export const createNewBook = async (userId: number, bookData: CreateBookData): Promise<BookWithSignedUrl> => {
  try {
    const book = await createBook({
      ...bookData,
      creator_id: userId
    });

    // Generate signed URL for file access
    const fileUrl = generateSignedUrl(book.filepath, userId);

    // Log book creation
    await createAuditLog({
      user_id: userId,
      action: 'BOOK_CREATED',
      entity_type: 'book',
      entity_id: book.id,
      details: { title: book.title, filepath: book.filepath }
    });

    logger.info('Book created successfully', { bookId: book.id, title: book.title, userId });

    return {
      ...book,
      fileUrl
    };
  } catch (error) {
    logger.error('Failed to create book', { error, bookData });
    throw error;
  }
};

export const getBookById = async (bookId: number, userId?: number): Promise<BookWithSignedUrl | null> => {
  const book = await findBookById(bookId);
  
  if (!book) {
    return null;
  }

  // Generate signed URL for file access
  const fileUrl = generateSignedUrl(book.filepath, userId);

  return {
    ...book,
    fileUrl
  };
};

export const getAllBooks = async (userId?: number): Promise<BookWithSignedUrl[]> => {
  const books = await findAllBooks();
  
  return books.map(book => ({
    ...book,
    fileUrl: generateSignedUrl(book.filepath, userId)
  }));
};

export const searchBooksService = async (searchTerm: string, userId?: number): Promise<BookWithSignedUrl[]> => {
  const books = await searchBooks(searchTerm);
  
  return books.map(book => ({
    ...book,
    fileUrl: generateSignedUrl(book.filepath, userId)
  }));
};

export const updateBookService = async (bookId: number, userId: number, updateData: { title?: string }): Promise<BookWithSignedUrl | null> => {
  // First check if book exists and user has permission
  const existingBook = await findBookById(bookId);
  if (!existingBook) {
    throw createError('Book not found', 404);
  }

  if (existingBook.creator_id !== userId) {
    throw createError('Unauthorized to update this book', 403);
  }

  const updatedBook = await updateBook(bookId, updateData);
  
  if (!updatedBook) {
    return null;
  }

  // Generate signed URL for file access
  const fileUrl = generateSignedUrl(updatedBook.filepath, userId);

  // Log book update
  await createAuditLog({
    user_id: userId,
    action: 'BOOK_UPDATED',
    entity_type: 'book',
    entity_id: bookId,
    details: { title: updatedBook.title, changes: updateData }
  });

  logger.info('Book updated successfully', { bookId, title: updatedBook.title, userId });

  return {
    ...updatedBook,
    fileUrl
  };
};

export const deleteBookService = async (bookId: number, userId: number): Promise<boolean> => {
  // First check if book exists and user has permission
  const existingBook = await findBookById(bookId);
  if (!existingBook) {
    throw createError('Book not found', 404);
  }

  if (existingBook.creator_id !== userId) {
    throw createError('Unauthorized to delete this book', 403);
  }

  // Delete the book from database
  const deleted = await deleteBook(bookId);
  
  if (deleted) {
    // Delete the actual file
    try {
      deleteFile(existingBook.filepath);
    } catch (error) {
      logger.warn('Failed to delete book file', { filepath: existingBook.filepath, error });
    }

    // Log book deletion
    await createAuditLog({
      user_id: userId,
      action: 'BOOK_DELETED',
      entity_type: 'book',
      entity_id: bookId,
      details: { title: existingBook.title, filepath: existingBook.filepath }
    });

    logger.info('Book deleted successfully', { bookId, title: existingBook.title, userId });
  }

  return deleted;
};

export const handleBookUpload = async (
  file: Express.Multer.File,
  userId: number,
  title: string
): Promise<BookWithSignedUrl> => {
  const bookDir = getUploadPath('books');
  const fileName = generateFileName(file.originalname);
  const filePath = `${bookDir}/${fileName}`;

  // Move uploaded file to final location
  require('fs').renameSync(file.path, filePath);

  // Create book record
  const book = await createNewBook(userId, {
    title,
    filepath: filePath
  });

  logger.info('Book uploaded successfully', { bookId: book.id, title, userId, filepath: filePath });

  return book;
};