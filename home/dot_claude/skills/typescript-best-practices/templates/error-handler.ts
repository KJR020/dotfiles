/**
 * Error Handler Template
 *
 * Centralized error handling utilities for API routes, Express middleware,
 * and Next.js API handlers.
 *
 * Usage:
 * 1. Import the error handler
 * 2. Wrap your route handlers with asyncHandler
 * 3. Throw AppError instances for expected errors
 * 4. Let the global error handler catch everything
 */

import type { Request, Response, NextFunction } from 'express';
import type { NextApiRequest, NextApiResponse } from 'next';

// ============================================================================
// Error Classes
// ============================================================================

/**
 * Base application error
 */
export class AppError extends Error {
  constructor(
    public code: string,
    public statusCode: number = 500,
    message?: string,
    public details?: Record<string, any>
  ) {
    super(message || code);
    this.name = 'AppError';
    Object.setPrototypeOf(this, AppError.prototype);
  }

  toJSON() {
    return {
      error: this.message,
      code: this.code,
      ...(this.details && { details: this.details })
    };
  }
}

export class ValidationError extends AppError {
  constructor(message: string, details?: Record<string, any>) {
    super('VALIDATION_ERROR', 400, message, details);
    this.name = 'ValidationError';
  }
}

export class AuthenticationError extends AppError {
  constructor(message: string = 'Authentication required') {
    super('AUTH_ERROR', 401, message);
    this.name = 'AuthenticationError';
  }
}

export class AuthorizationError extends AppError {
  constructor(message: string = 'Permission denied') {
    super('AUTHORIZATION_ERROR', 403, message);
    this.name = 'AuthorizationError';
  }
}

export class NotFoundError extends AppError {
  constructor(resource: string, id?: string) {
    const message = id
      ? `${resource} with id ${id} not found`
      : `${resource} not found`;
    super('NOT_FOUND', 404, message);
    this.name = 'NotFoundError';
  }
}

export class ConflictError extends AppError {
  constructor(message: string) {
    super('CONFLICT', 409, message);
    this.name = 'ConflictError';
  }
}

export class RateLimitError extends AppError {
  constructor(message: string = 'Too many requests') {
    super('RATE_LIMIT', 429, message);
    this.name = 'RateLimitError';
  }
}

// ============================================================================
// Express Error Handler
// ============================================================================

/**
 * Async handler wrapper for Express routes
 * Catches async errors and passes them to error middleware
 */
export function asyncHandler(
  fn: (req: Request, res: Response, next: NextFunction) => Promise<any>
) {
  return (req: Request, res: Response, next: NextFunction) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}

/**
 * Global error handler middleware for Express
 */
export function errorHandler(
  error: Error,
  req: Request,
  res: Response,
  next: NextFunction
): void {
  // Log error
  console.error('[Error Handler]', {
    name: error.name,
    message: error.message,
    stack: error.stack,
    url: req.url,
    method: req.method
  });

  // Handle AppError instances
  if (error instanceof AppError) {
    res.status(error.statusCode).json(error.toJSON());
    return;
  }

  // Handle validation errors from libraries
  if (error.name === 'ValidationError') {
    res.status(400).json({
      error: error.message,
      code: 'VALIDATION_ERROR'
    });
    return;
  }

  // Handle JWT errors
  if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
    res.status(401).json({
      error: 'Invalid or expired token',
      code: 'AUTH_ERROR'
    });
    return;
  }

  // Default: Internal Server Error
  res.status(500).json({
    error: 'Internal server error',
    code: 'INTERNAL_ERROR',
    ...(process.env.NODE_ENV === 'development' && { message: error.message })
  });
}

// ============================================================================
// Express Usage Example
// ============================================================================

/*
import express from 'express';
import { asyncHandler, errorHandler, NotFoundError, ValidationError } from './error-handler';

const app = express();

// Regular route with async handler
app.get('/users/:id', asyncHandler(async (req, res) => {
  const user = await getUserById(req.params.id);

  if (!user) {
    throw new NotFoundError('User', req.params.id);
  }

  res.json(user);
}));

// Route with validation
app.post('/users', asyncHandler(async (req, res) => {
  const { email, name } = req.body;

  if (!email || !email.includes('@')) {
    throw new ValidationError('Valid email is required', { field: 'email' });
  }

  const user = await createUser({ email, name });
  res.status(201).json(user);
}));

// 404 handler
app.use((req, res, next) => {
  throw new NotFoundError('Route');
});

// Global error handler (must be last)
app.use(errorHandler);
*/

// ============================================================================
// Next.js API Handler
// ============================================================================

/**
 * Async handler wrapper for Next.js API routes
 */
export function nextApiHandler(
  handler: (req: NextApiRequest, res: NextApiResponse) => Promise<void>
) {
  return async (req: NextApiRequest, res: NextApiResponse) => {
    try {
      await handler(req, res);
    } catch (error) {
      handleNextApiError(error, req, res);
    }
  };
}

/**
 * Error handler for Next.js API routes
 */
function handleNextApiError(
  error: unknown,
  req: NextApiRequest,
  res: NextApiResponse
): void {
  // Log error
  console.error('[Next.js API Error]', {
    error: error instanceof Error ? error.message : 'Unknown error',
    stack: error instanceof Error ? error.stack : undefined,
    url: req.url,
    method: req.method
  });

  // Handle AppError instances
  if (error instanceof AppError) {
    res.status(error.statusCode).json(error.toJSON());
    return;
  }

  // Handle validation errors
  if (error instanceof Error && error.name === 'ValidationError') {
    res.status(400).json({
      error: error.message,
      code: 'VALIDATION_ERROR'
    });
    return;
  }

  // Default: Internal Server Error
  res.status(500).json({
    error: 'Internal server error',
    code: 'INTERNAL_ERROR',
    ...(process.env.NODE_ENV === 'development' && {
      message: error instanceof Error ? error.message : 'Unknown error'
    })
  });
}

// ============================================================================
// Next.js Usage Example
// ============================================================================

/*
import type { NextApiRequest, NextApiResponse } from 'next';
import { nextApiHandler, NotFoundError, ValidationError } from './error-handler';

export default nextApiHandler(async (req, res) => {
  if (req.method !== 'GET') {
    throw new ValidationError('Method not allowed');
  }

  const { id } = req.query;

  if (!id || typeof id !== 'string') {
    throw new ValidationError('User ID is required');
  }

  const user = await getUserById(id);

  if (!user) {
    throw new NotFoundError('User', id);
  }

  res.status(200).json(user);
});
*/

// ============================================================================
// Generic Try-Catch Wrapper
// ============================================================================

/**
 * Generic try-catch wrapper for any async function
 * Returns Result type instead of throwing
 */
type Result<T> =
  | { status: 'success'; data: T }
  | { status: 'error'; error: string; code: string };

export async function tryCatch<T>(
  fn: () => Promise<T>
): Promise<Result<T>> {
  try {
    const data = await fn();
    return { status: 'success', data };
  } catch (error) {
    if (error instanceof AppError) {
      return {
        status: 'error',
        error: error.message,
        code: error.code
      };
    }

    return {
      status: 'error',
      error: error instanceof Error ? error.message : 'Unknown error',
      code: 'INTERNAL_ERROR'
    };
  }
}

// Usage
/*
const result = await tryCatch(() => fetchUser('123'));

if (result.status === 'success') {
  console.log('User:', result.data);
} else {
  console.error('Error:', result.error);
}
*/

// ============================================================================
// Error Response Builder
// ============================================================================

/**
 * Build consistent error response objects
 */
export function buildErrorResponse(
  error: unknown,
  includeStack: boolean = false
): { error: string; code: string; stack?: string; details?: any } {
  if (error instanceof AppError) {
    return {
      error: error.message,
      code: error.code,
      ...(error.details && { details: error.details }),
      ...(includeStack && error.stack && { stack: error.stack })
    };
  }

  if (error instanceof Error) {
    return {
      error: error.message,
      code: 'INTERNAL_ERROR',
      ...(includeStack && error.stack && { stack: error.stack })
    };
  }

  return {
    error: 'An unexpected error occurred',
    code: 'UNKNOWN_ERROR'
  };
}

// ============================================================================
// Logging Helper
// ============================================================================

/**
 * Log errors with context
 */
export function logError(
  error: unknown,
  context?: Record<string, any>
): void {
  const errorInfo = {
    timestamp: new Date().toISOString(),
    ...(error instanceof Error && {
      name: error.name,
      message: error.message,
      stack: error.stack
    }),
    ...(error instanceof AppError && {
      code: error.code,
      statusCode: error.statusCode,
      details: error.details
    }),
    ...context
  };

  console.error('[Error]', JSON.stringify(errorInfo, null, 2));

  // TODO: Send to error tracking service (Sentry, Rollbar, etc.)
  // if (process.env.NODE_ENV === 'production') {
  //   Sentry.captureException(error, { extra: context });
  // }
}

// ============================================================================
// Best Practices Summary
// ============================================================================

/*
ERROR HANDLING BEST PRACTICES:

1. ✅ Create specific error classes for different error types
2. ✅ Use asyncHandler/nextApiHandler to catch async errors
3. ✅ Throw AppError instances for expected errors
4. ✅ Include error codes for client-side handling
5. ✅ Add details object for validation errors
6. ✅ Log all errors with context
7. ✅ Return appropriate HTTP status codes
8. ✅ Hide sensitive information in production
9. ✅ Use Result types for recoverable errors
10. ✅ Implement global error handler as last middleware

NEVER:
- Expose sensitive information in error messages
- Return stack traces in production
- Ignore or silently catch errors
- Mix error handling strategies (pick one: throw or Result)

ALWAYS:
- Use custom error classes
- Include error codes
- Log errors with context
- Return consistent error response structure
- Validate input before processing
- Handle async errors properly
*/
