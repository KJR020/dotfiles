/**
 * Type Safety Best Practices
 *
 * This file demonstrates advanced type safety patterns in TypeScript,
 * including discriminated unions, type guards, and utility types.
 */

// ============================================================================
// Type Imports (CRITICAL)
// ============================================================================

// ✅ Always use type imports for types
// import type { User } from "@prisma/client";
// import type { NextApiRequest, NextApiResponse } from "next";

// ❌ Never use regular imports for types
// import { User } from "@prisma/client";

// ============================================================================
// Discriminated Unions
// ============================================================================

/**
 * Example 1: API Response type with discriminated union
 */
type ApiResponse<T> =
  | { status: 'success'; data: T }
  | { status: 'error'; error: string; code: string }
  | { status: 'loading' }
  | { status: 'idle' };

function handleApiResponse<T>(response: ApiResponse<T>): string {
  // TypeScript ensures exhaustive checking
  switch (response.status) {
    case 'success':
      return `Success: ${JSON.stringify(response.data)}`;
    case 'error':
      return `Error [${response.code}]: ${response.error}`;
    case 'loading':
      return 'Loading...';
    case 'idle':
      return 'Not started';
  }
}

/**
 * Example 2: Form validation state
 */
type FormField<T> =
  | { status: 'pristine' }
  | { status: 'validating' }
  | { status: 'valid'; value: T }
  | { status: 'invalid'; value: T; error: string };

function getFieldValue<T>(field: FormField<T>): T | undefined {
  // TypeScript knows which fields have 'value'
  if (field.status === 'valid' || field.status === 'invalid') {
    return field.value;
  }
  return undefined;
}

// ============================================================================
// Type Guards
// ============================================================================

/**
 * Example 3: Custom type guards
 */
interface User {
  id: string;
  email: string;
  name: string;
}

interface AdminUser extends User {
  role: 'admin';
  permissions: string[];
}

// Type guard function
function isAdminUser(user: User): user is AdminUser {
  return 'role' in user && user.role === 'admin';
}

function getUserPermissions(user: User): string[] {
  if (isAdminUser(user)) {
    // TypeScript knows user is AdminUser here
    return user.permissions;
  }
  return [];
}

/**
 * Example 4: Array type guards
 */
function isStringArray(value: unknown): value is string[] {
  return Array.isArray(value) && value.every(item => typeof item === 'string');
}

function processInput(input: unknown): void {
  if (isStringArray(input)) {
    // TypeScript knows input is string[] here
    input.forEach(str => console.log(str.toUpperCase()));
  }
}

// ============================================================================
// Utility Types
// ============================================================================

interface UserWithPassword {
  id: string;
  email: string;
  name: string;
  password: string;
  apiKey: string;
  createdAt: Date;
}

/**
 * Example 5: Omit sensitive fields
 */
type PublicUser = Omit<UserWithPassword, 'password' | 'apiKey'>;

const publicUser: PublicUser = {
  id: '1',
  email: 'user@example.com',
  name: 'John Doe',
  createdAt: new Date()
  // password and apiKey cannot be added here
};

/**
 * Example 6: Pick only needed fields
 */
type UserSummary = Pick<UserWithPassword, 'id' | 'name'>;

const summary: UserSummary = {
  id: '1',
  name: 'John Doe'
  // Only id and name are allowed
};

/**
 * Example 7: Make fields optional
 */
type UserUpdate = Partial<Omit<UserWithPassword, 'id'>>;

const update: UserUpdate = {
  name: 'Jane Doe'
  // All fields except id are optional
};

/**
 * Example 8: Make fields required
 */
type RequiredUser = Required<Partial<User>>;

/**
 * Example 9: Make fields readonly
 */
type ImmutableUser = Readonly<User>;

const immutableUser: ImmutableUser = {
  id: '1',
  email: 'user@example.com',
  name: 'John Doe'
};

// immutableUser.name = 'Jane'; // ❌ Error: Cannot assign to 'name' because it is a read-only property

// ============================================================================
// Conditional Types
// ============================================================================

/**
 * Example 10: Extract function return type
 */
type ReturnTypeOf<T> = T extends (...args: any[]) => infer R ? R : never;

async function fetchUser(): Promise<User> {
  return { id: '1', email: 'user@example.com', name: 'John' };
}

type FetchUserReturn = ReturnTypeOf<typeof fetchUser>; // Promise<User>
type UserType = Awaited<FetchUserReturn>; // User

/**
 * Example 11: Exclude null and undefined
 */
type NonNullable<T> = T extends null | undefined ? never : T;

type MaybeString = string | null | undefined;
type DefinitelyString = NonNullable<MaybeString>; // string

// ============================================================================
// Mapped Types
// ============================================================================

/**
 * Example 12: Create nullable version of all fields
 */
type Nullable<T> = {
  [K in keyof T]: T[K] | null;
};

type NullableUser = Nullable<User>;
// {
//   id: string | null;
//   email: string | null;
//   name: string | null;
// }

/**
 * Example 13: Deep partial type
 */
type DeepPartial<T> = {
  [K in keyof T]?: T[K] extends object ? DeepPartial<T[K]> : T[K];
};

interface Address {
  street: string;
  city: string;
  country: string;
}

interface UserWithAddress {
  id: string;
  name: string;
  address: Address;
}

type PartialUserWithAddress = DeepPartial<UserWithAddress>;
// All fields including nested Address fields are optional

// ============================================================================
// Const Assertions
// ============================================================================

/**
 * Example 14: Const assertions for literal types
 */
const routes = {
  home: '/',
  about: '/about',
  contact: '/contact'
} as const;

type Route = typeof routes[keyof typeof routes]; // "/" | "/about" | "/contact"

function navigate(route: Route): void {
  console.log(`Navigating to ${route}`);
}

navigate(routes.home); // ✅ OK
// navigate('/unknown'); // ❌ Error: Argument of type '"/unknown"' is not assignable to parameter of type Route

/**
 * Example 15: Readonly arrays with const assertion
 */
const statusCodes = [200, 400, 404, 500] as const;
type StatusCode = typeof statusCodes[number]; // 200 | 400 | 404 | 500

// ============================================================================
// Template Literal Types
// ============================================================================

/**
 * Example 16: Event naming pattern
 */
type EventName = 'click' | 'hover' | 'focus';
type EventHandler = `on${Capitalize<EventName>}`; // "onClick" | "onHover" | "onFocus"

type Events = {
  [K in EventHandler]: () => void;
};

const events: Events = {
  onClick: () => console.log('clicked'),
  onHover: () => console.log('hovered'),
  onFocus: () => console.log('focused')
};

/**
 * Example 17: API route typing
 */
type HttpMethod = 'GET' | 'POST' | 'PUT' | 'DELETE';
type ApiRoute = '/users' | '/posts' | '/comments';
type ApiEndpoint = `${HttpMethod} ${ApiRoute}`; // "GET /users" | "POST /users" | ...

// ============================================================================
// Branded Types (Nominal Typing)
// ============================================================================

/**
 * Example 18: Branded types for stronger type safety
 */
type Brand<K, T> = K & { __brand: T };

type UserId = Brand<string, 'UserId'>;
type PostId = Brand<string, 'PostId'>;

function createUserId(id: string): UserId {
  return id as UserId;
}

function createPostId(id: string): PostId {
  return id as PostId;
}

function getUser(userId: UserId): void {
  console.log(`Getting user ${userId}`);
}

const userId = createUserId('user-123');
const postId = createPostId('post-456');

getUser(userId); // ✅ OK
// getUser(postId); // ❌ Error: PostId is not assignable to UserId

// ============================================================================
// Best Practices Summary
// ============================================================================

/*
1. ✅ Always use `type` imports for TypeScript types
2. ✅ Use discriminated unions for type-safe state management
3. ✅ Create custom type guards for runtime type checking
4. ✅ Use Omit to exclude sensitive fields from public types
5. ✅ Use Pick to create focused types with only needed fields
6. ✅ Use Partial for update operations
7. ✅ Use Readonly to prevent accidental mutations
8. ✅ Use const assertions for literal types
9. ✅ Use template literal types for pattern-based strings
10. ✅ Use branded types to prevent ID confusion
11. ✅ Never use `any` - use `unknown` instead and narrow with type guards
12. ✅ Leverage TypeScript's inference where it improves clarity
13. ✅ Use utility types instead of writing boilerplate
14. ✅ Create domain-specific types to catch bugs at compile time
15. ✅ Make impossible states unrepresentable with discriminated unions
*/
