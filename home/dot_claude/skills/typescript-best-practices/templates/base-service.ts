/**
 * Base Service Template
 *
 * A generic, reusable service class template with error handling,
 * type safety, and common CRUD operations.
 *
 * Usage:
 * 1. Copy this template
 * 2. Replace T with your entity type
 * 3. Implement the abstract methods
 * 4. Add domain-specific methods as needed
 */

import type { Result } from '../examples/error-handling';
import { success, failure, AppError, NotFoundError } from '../examples/error-handling';

/**
 * Base entity interface - all entities must have an id
 */
interface BaseEntity {
  id: string;
}

/**
 * Generic base service class for CRUD operations
 *
 * @template T - Entity type (must extend BaseEntity)
 */
export abstract class BaseService<T extends BaseEntity> {
  /**
   * The name of the resource (e.g., "User", "Post")
   * Used for error messages
   */
  protected abstract readonly resourceName: string;

  // ============================================================================
  // Abstract Methods - Must be implemented by subclasses
  // ============================================================================

  /**
   * Retrieve an entity by ID from the data store
   */
  protected abstract fetchById(id: string): Promise<T | null>;

  /**
   * Retrieve all entities from the data store
   */
  protected abstract fetchAll(): Promise<T[]>;

  /**
   * Create a new entity in the data store
   */
  protected abstract createEntity(data: Omit<T, 'id'>): Promise<T>;

  /**
   * Update an existing entity in the data store
   */
  protected abstract updateEntity(id: string, data: Partial<T>): Promise<T>;

  /**
   * Delete an entity from the data store
   */
  protected abstract deleteEntity(id: string): Promise<boolean>;

  // ============================================================================
  // Public Methods - Available to consumers
  // ============================================================================

  /**
   * Find entity by ID
   * Returns Result type for type-safe error handling
   */
  async findById(id: string): Promise<Result<T>> {
    try {
      const entity = await this.fetchById(id);

      if (!entity) {
        return failure(
          `${this.resourceName} with id ${id} not found`,
          'NOT_FOUND'
        );
      }

      return success(entity);
    } catch (error) {
      return this.handleError(error);
    }
  }

  /**
   * Find entity by ID or throw error
   * Use when you want to propagate errors
   */
  async findByIdOrThrow(id: string): Promise<T> {
    const result = await this.findById(id);

    if (result.status === 'error') {
      if (result.code === 'NOT_FOUND') {
        throw new NotFoundError(this.resourceName, id);
      }
      throw new AppError(result.code, 500, result.error);
    }

    return result.data;
  }

  /**
   * Find all entities
   */
  async findAll(): Promise<Result<T[]>> {
    try {
      const entities = await this.fetchAll();
      return success(entities);
    } catch (error) {
      return this.handleError(error);
    }
  }

  /**
   * Create a new entity
   */
  async create(data: Omit<T, 'id'>): Promise<Result<T>> {
    try {
      // Validate data before creating
      const validationError = this.validateCreate(data);
      if (validationError) {
        return failure(validationError, 'VALIDATION_ERROR');
      }

      const entity = await this.createEntity(data);
      return success(entity);
    } catch (error) {
      return this.handleError(error);
    }
  }

  /**
   * Update an existing entity
   */
  async update(id: string, data: Partial<T>): Promise<Result<T>> {
    try {
      // Check if entity exists
      const existingResult = await this.findById(id);
      if (existingResult.status === 'error') {
        return existingResult;
      }

      // Validate update data
      const validationError = this.validateUpdate(data);
      if (validationError) {
        return failure(validationError, 'VALIDATION_ERROR');
      }

      const updated = await this.updateEntity(id, data);
      return success(updated);
    } catch (error) {
      return this.handleError(error);
    }
  }

  /**
   * Delete an entity
   */
  async delete(id: string): Promise<Result<boolean>> {
    try {
      // Check if entity exists
      const existingResult = await this.findById(id);
      if (existingResult.status === 'error') {
        return existingResult as Result<boolean>;
      }

      const deleted = await this.deleteEntity(id);
      return success(deleted);
    } catch (error) {
      return this.handleError(error);
    }
  }

  // ============================================================================
  // Validation Methods - Override in subclasses
  // ============================================================================

  /**
   * Validate data before creating
   * Override in subclasses for custom validation
   *
   * @returns Error message if invalid, null if valid
   */
  protected validateCreate(data: Omit<T, 'id'>): string | null {
    return null; // Default: no validation
  }

  /**
   * Validate data before updating
   * Override in subclasses for custom validation
   *
   * @returns Error message if invalid, null if valid
   */
  protected validateUpdate(data: Partial<T>): string | null {
    return null; // Default: no validation
  }

  // ============================================================================
  // Error Handling
  // ============================================================================

  /**
   * Centralized error handling
   * Override in subclasses for custom error handling
   */
  protected handleError<R>(error: unknown): Result<R> {
    if (error instanceof AppError) {
      return failure(error.message, error.code);
    }

    // Log unexpected errors
    console.error(`[${this.resourceName}Service] Unexpected error:`, error);

    return failure(
      'An unexpected error occurred',
      'INTERNAL_ERROR'
    );
  }
}

// ============================================================================
// Example Implementation
// ============================================================================

/**
 * Example: User Service
 */
interface User extends BaseEntity {
  email: string;
  name: string;
  createdAt: Date;
}

class UserService extends BaseService<User> {
  protected readonly resourceName = 'User';

  // Implement abstract methods
  protected async fetchById(id: string): Promise<User | null> {
    // TODO: Implement actual database query
    // return prisma.user.findUnique({ where: { id } });
    return null;
  }

  protected async fetchAll(): Promise<User[]> {
    // TODO: Implement actual database query
    // return prisma.user.findMany();
    return [];
  }

  protected async createEntity(data: Omit<User, 'id'>): Promise<User> {
    // TODO: Implement actual database insert
    // return prisma.user.create({ data });
    return { ...data, id: crypto.randomUUID() };
  }

  protected async updateEntity(id: string, data: Partial<User>): Promise<User> {
    // TODO: Implement actual database update
    // return prisma.user.update({ where: { id }, data });
    return { id, ...data } as User;
  }

  protected async deleteEntity(id: string): Promise<boolean> {
    // TODO: Implement actual database delete
    // await prisma.user.delete({ where: { id } });
    return true;
  }

  // Custom validation
  protected validateCreate(data: Omit<User, 'id'>): string | null {
    if (!data.email || !data.email.includes('@')) {
      return 'Valid email is required';
    }
    if (!data.name || data.name.trim().length === 0) {
      return 'Name is required';
    }
    return null;
  }

  protected validateUpdate(data: Partial<User>): string | null {
    if (data.email !== undefined && !data.email.includes('@')) {
      return 'Valid email is required';
    }
    if (data.name !== undefined && data.name.trim().length === 0) {
      return 'Name cannot be empty';
    }
    return null;
  }

  // Add domain-specific methods
  async findByEmail(email: string): Promise<Result<User>> {
    try {
      // TODO: Implement actual database query
      // const user = await prisma.user.findUnique({ where: { email } });
      const user = null;

      if (!user) {
        return failure(`User with email ${email} not found`, 'NOT_FOUND');
      }

      return success(user);
    } catch (error) {
      return this.handleError(error);
    }
  }
}

// ============================================================================
// Usage Examples
// ============================================================================

async function usageExample() {
  const userService = new UserService();

  // Create a user
  const createResult = await userService.create({
    email: 'user@example.com',
    name: 'John Doe',
    createdAt: new Date()
  });

  if (createResult.status === 'success') {
    console.log('User created:', createResult.data);
  } else {
    console.error('Failed to create user:', createResult.error);
  }

  // Find a user
  const findResult = await userService.findById('123');

  if (findResult.status === 'success') {
    console.log('User found:', findResult.data);
  } else {
    console.error('Failed to find user:', findResult.error);
  }

  // Update a user
  const updateResult = await userService.update('123', {
    name: 'Jane Doe'
  });

  if (updateResult.status === 'success') {
    console.log('User updated:', updateResult.data);
  }

  // Or use the throwing version
  try {
    const user = await userService.findByIdOrThrow('123');
    console.log('User:', user);
  } catch (error) {
    if (error instanceof NotFoundError) {
      console.error('User not found');
    }
  }
}
