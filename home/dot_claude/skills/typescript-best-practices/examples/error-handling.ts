/**
 * Error Handling Best Practices
 *
 * This file demonstrates proper error handling patterns in TypeScript,
 * including custom error classes and Result type patterns.
 */

// ============================================================================
// Custom Error Classes
// ============================================================================

/**
 * Base application error class
 * Extends Error with additional context like error codes and HTTP status
 */
export class AppError extends Error {
  constructor(
    public code: string,
    public statusCode: number = 500,
    message?: string
  ) {
    super(message || code);
    this.name = 'AppError';
    // Maintains proper prototype chain for instanceof checks
    Object.setPrototypeOf(this, AppError.prototype);
  }
}

/**
 * Validation-specific error
 */
export class ValidationError extends AppError {
  constructor(
    public field: string,
    message: string
  ) {
    super('VALIDATION_ERROR', 400, message);
    this.name = 'ValidationError';
    Object.setPrototypeOf(this, ValidationError.prototype);
  }
}

/**
 * Authentication-specific error
 */
export class AuthenticationError extends AppError {
  constructor(message: string = 'Authentication required') {
    super('AUTH_ERROR', 401, message);
    this.name = 'AuthenticationError';
    Object.setPrototypeOf(this, AuthenticationError.prototype);
  }
}

/**
 * Not found error
 */
export class NotFoundError extends AppError {
  constructor(resource: string, id: string) {
    super('NOT_FOUND', 404, `${resource} with id ${id} not found`);
    this.name = 'NotFoundError';
    Object.setPrototypeOf(this, NotFoundError.prototype);
  }
}

// ============================================================================
// Result Type Pattern
// ============================================================================

type Success<T> = { status: 'success'; data: T };
type Failure = { status: 'error'; error: string; code: string };
export type Result<T> = Success<T> | Failure;

/**
 * Helper to create success result
 */
export function success<T>(data: T): Success<T> {
  return { status: 'success', data };
}

/**
 * Helper to create failure result
 */
export function failure(error: string, code: string): Failure {
  return { status: 'error', error, code };
}

// ============================================================================
// Usage Examples
// ============================================================================

interface User {
  id: string;
  email: string;
  name: string;
}

/**
 * Example 1: Using custom error classes
 */
function validateEmail(email: string): void {
  if (!email) {
    throw new ValidationError('email', 'Email is required');
  }
  if (!email.includes('@')) {
    throw new ValidationError('email', 'Email must be a valid email address');
  }
}

/**
 * Example 2: Using Result type for recoverable errors
 */
async function findUser(id: string): Promise<Result<User>> {
  try {
    // Simulate database call
    const user = await fetchUserFromDatabase(id);

    if (!user) {
      return failure(`User with id ${id} not found`, 'NOT_FOUND');
    }

    return success(user);
  } catch (error) {
    return failure(
      error instanceof Error ? error.message : 'Unknown error occurred',
      'DATABASE_ERROR'
    );
  }
}

/**
 * Example 3: Handling Result type
 */
async function getUserProfile(userId: string): Promise<void> {
  const result = await findUser(userId);

  // TypeScript ensures we handle both cases
  if (result.status === 'success') {
    console.log('User found:', result.data.name);
    // result.data is typed as User here
  } else {
    console.error('Error:', result.error);
    console.error('Code:', result.code);
    // result.error and result.code are available here
  }
}

/**
 * Example 4: Converting between error styles
 */
async function getUserOrThrow(id: string): Promise<User> {
  const result = await findUser(id);

  if (result.status === 'error') {
    switch (result.code) {
      case 'NOT_FOUND':
        throw new NotFoundError('User', id);
      case 'DATABASE_ERROR':
        throw new AppError('DATABASE_ERROR', 500, result.error);
      default:
        throw new AppError('UNKNOWN_ERROR', 500, result.error);
    }
  }

  return result.data;
}

/**
 * Example 5: Error handling in API routes
 */
async function handleApiRequest(userId: string): Promise<Response> {
  try {
    const user = await getUserOrThrow(userId);

    return new Response(JSON.stringify(user), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    if (error instanceof AppError) {
      return new Response(
        JSON.stringify({ error: error.message, code: error.code }),
        {
          status: error.statusCode,
          headers: { 'Content-Type': 'application/json' }
        }
      );
    }

    // Unexpected error
    console.error('Unexpected error:', error);
    return new Response(
      JSON.stringify({ error: 'Internal server error', code: 'INTERNAL_ERROR' }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      }
    );
  }
}

/**
 * Example 6: Async error aggregation
 */
async function processMultipleUsers(
  userIds: string[]
): Promise<{ succeeded: User[]; failed: Array<{ id: string; error: string }> }> {
  const results = await Promise.all(
    userIds.map(id => findUser(id))
  );

  const succeeded: User[] = [];
  const failed: Array<{ id: string; error: string }> = [];

  results.forEach((result, index) => {
    if (result.status === 'success') {
      succeeded.push(result.data);
    } else {
      failed.push({ id: userIds[index], error: result.error });
    }
  });

  return { succeeded, failed };
}

// ============================================================================
// Mock Functions (for demonstration purposes)
// ============================================================================

async function fetchUserFromDatabase(id: string): Promise<User | null> {
  // This would be your actual database call
  return null;
}

// ============================================================================
// Best Practices Summary
// ============================================================================

/*
1. Use custom error classes for different error types
2. Always extend Error properly and fix prototype chain
3. Include context in errors (codes, status codes, fields)
4. Use Result type for expected, recoverable errors
5. Use throw for unexpected, unrecoverable errors
6. Always handle both success and error cases with Result type
7. Convert Result to exceptions at API boundaries if needed
8. Aggregate errors when processing multiple async operations
9. Never silently catch and ignore errors
10. Log unexpected errors before re-throwing or returning generic errors
*/
