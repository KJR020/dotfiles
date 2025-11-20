---
name: typescript-best-practices
description: Comprehensive TypeScript best practices including type imports, security patterns, code structure, and early returns. Use when writing TypeScript code, reviewing for quality, implementing error handling, or ensuring type safety.
allowed-tools: Read, Grep, Glob
---

# TypeScript Best Practices

Enterprise-grade TypeScript patterns and practices for maintainable, type-safe, and secure code.

## When to Use This Skill

- Writing new TypeScript code or modules
- Code reviews focusing on TypeScript quality
- Implementing type-safe patterns
- Ensuring security best practices
- Refactoring for better code structure
- Setting up imports and dependencies

## Core Principles

### 1. Type Safety First
TypeScript's type system is your first line of defense against bugs. Use it fully:
- Always prefer explicit types over inference when it improves clarity
- Use `type` imports for TypeScript types
- Leverage discriminated unions for type narrowing
- Use `never` type for exhaustiveness checking

### 2. Security is Non-Negotiable
Security vulnerabilities can be prevented at the type level:
- **NEVER** expose sensitive credential fields
- Use proper type guards for user input validation
- Sanitize all external data at system boundaries
- Follow principle of least privilege in type definitions

### 3. Code Structure Matters
Well-structured code is easier to maintain and debug:
- Prefer early returns to reduce nesting
- Use composition over prop drilling
- Keep functions focused and single-purpose
- Organize imports consistently

## Import Guidelines

### Type Imports (CRITICAL)

Always use `type` imports for TypeScript types to improve build performance and clearly separate type-only imports from runtime imports.

**✅ Good - Use type imports:**
```typescript
import type { User } from "@prisma/client";
import type { NextApiRequest, NextApiResponse } from "next";
import type { ReactNode } from "react";
```

**❌ Bad - Regular import for types:**
```typescript
import { User } from "@prisma/client";
import { NextApiRequest, NextApiResponse } from "next";
```

**Why?** Type imports:
- Are erased at compile time (no runtime overhead)
- Make it clear what's type-only vs runtime code
- Enable better tree-shaking
- Prevent circular dependency issues

### Mixed Imports

When importing both types and values:

```typescript
// ✅ Good - Separate type and value imports
import type { ComponentProps } from "react";
import { useState, useEffect } from "react";

// ✅ Also acceptable - inline type imports
import { useState, useEffect, type ComponentProps } from "react";
```

## Security Rules

### NEVER Expose Credential Keys

**❌ CRITICAL ERROR - NEVER do this:**
```typescript
const user = await prisma.user.findFirst({
  select: {
    credentials: {
      select: {
        key: true, // ❌ SECURITY VIOLATION: Exposes sensitive data
      }
    }
  }
});
```

**✅ Good - Exclude sensitive fields:**
```typescript
const user = await prisma.user.findFirst({
  select: {
    id: true,
    email: true,
    credentials: {
      select: {
        id: true,
        type: true,
        // key field is intentionally excluded for security
      }
    }
  }
});
```

**Security checklist:**
- ✅ Never select `credential.key`, `password`, `secret`, or similar sensitive fields
- ✅ Always use explicit `select` instead of returning all fields
- ✅ Create dedicated types for public-safe data structures
- ✅ Use type guards to validate external input

### Type-Safe Sensitive Data Handling

```typescript
// Define separate types for internal and external use
type UserCredential = {
  id: string;
  userId: string;
  type: string;
  key: string; // Only exists in internal type
};

type PublicUserCredential = Omit<UserCredential, 'key'>;

// Use utility type to enforce exclusion
function getPublicCredential(cred: UserCredential): PublicUserCredential {
  const { key, ...publicData } = cred;
  return publicData;
}
```

## Code Structure

### Early Returns

Reduce nesting and improve readability with early returns.

**✅ Good - Early returns:**
```typescript
function processBooking(booking: Booking | null) {
  if (!booking) return null;
  if (!booking.isConfirmed) return null;
  if (booking.isCancelled) return null;

  return formatBooking(booking);
}
```

**❌ Bad - Nested conditions:**
```typescript
function processBooking(booking: Booking | null) {
  if (booking) {
    if (booking.isConfirmed) {
      if (!booking.isCancelled) {
        return formatBooking(booking);
      }
    }
  }
  return null;
}
```

### Composition Over Prop Drilling

**✅ Good - Use React children and context:**
```typescript
// Instead of passing props through multiple layers
function App() {
  return (
    <ThemeProvider>
      <UserProvider>
        <Dashboard />
      </UserProvider>
    </ThemeProvider>
  );
}

function Dashboard() {
  const user = useUser(); // From context
  const theme = useTheme(); // From context
  return <div>...</div>;
}
```

**❌ Bad - Prop drilling:**
```typescript
function App() {
  const user = getUser();
  const theme = getTheme();
  return <Layout user={user} theme={theme} />;
}

function Layout({ user, theme }) {
  return <Sidebar user={user} theme={theme} />;
}

function Sidebar({ user, theme }) {
  return <UserMenu user={user} theme={theme} />;
}
```

## Error Handling Patterns

### Custom Error Classes

```typescript
// ✅ Good - Typed error classes
export class AppError extends Error {
  constructor(
    public code: string,
    public statusCode: number = 500,
    message?: string
  ) {
    super(message || code);
    this.name = 'AppError';
    Object.setPrototypeOf(this, AppError.prototype);
  }
}

// Usage
function validateEmail(email: string): void {
  if (!email.includes('@')) {
    throw new AppError('INVALID_EMAIL', 400, 'Email must contain @');
  }
}
```

### Result Type Pattern

```typescript
type Success<T> = { status: 'success'; data: T };
type Failure = { status: 'error'; error: string; code: string };
type Result<T> = Success<T> | Failure;

async function fetchUser(id: string): Promise<Result<User>> {
  try {
    const user = await db.user.findUnique({ where: { id } });
    if (!user) {
      return { status: 'error', error: 'User not found', code: 'NOT_FOUND' };
    }
    return { status: 'success', data: user };
  } catch (error) {
    return {
      status: 'error',
      error: error instanceof Error ? error.message : 'Unknown error',
      code: 'FETCH_FAILED'
    };
  }
}

// Usage with discriminated union
const result = await fetchUser('123');
if (result.status === 'success') {
  console.log(result.data); // TypeScript knows this is User
} else {
  console.error(result.error); // TypeScript knows this is error
}
```

## Type System Best Practices

### Discriminated Unions

```typescript
// ✅ Good - Type-safe state management
type RequestState<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: Error };

function handleRequest<T>(state: RequestState<T>) {
  switch (state.status) {
    case 'idle':
      return 'Not started';
    case 'loading':
      return 'Loading...';
    case 'success':
      return state.data; // TypeScript knows data exists
    case 'error':
      return state.error.message; // TypeScript knows error exists
  }
}
```

### Utility Types

```typescript
// Omit sensitive fields
type PublicUser = Omit<User, 'password' | 'apiKey'>;

// Pick only needed fields
type UserSummary = Pick<User, 'id' | 'name' | 'email'>;

// Make all properties optional
type PartialUser = Partial<User>;

// Make all properties required
type RequiredUser = Required<User>;

// Make all properties readonly
type ImmutableUser = Readonly<User>;
```

## Async/Promise Best Practices

### Always Return Promises

```typescript
// ✅ Good - Consistent promise return
async function fetchData(): Promise<Data> {
  const response = await fetch('/api/data');
  return response.json();
}

// ❌ Bad - Mixed sync/async
async function fetchData() {
  if (cache.has('data')) {
    return cache.get('data'); // Not wrapped in Promise
  }
  const response = await fetch('/api/data');
  return response.json();
}
```

### Error Propagation

```typescript
// ✅ Good - Proper error handling
async function processData(id: string): Promise<Result<Data>> {
  try {
    const data = await fetchData(id);
    const validated = validateData(data);
    return { status: 'success', data: validated };
  } catch (error) {
    return {
      status: 'error',
      error: error instanceof Error ? error.message : 'Unknown error',
      code: 'PROCESS_FAILED'
    };
  }
}
```

## Examples Reference

See the `examples/` directory for complete, working examples:
- `error-handling.ts` - Custom error classes and Result types
- `type-safety.ts` - Advanced type patterns
- `security-patterns.ts` - Secure data handling
- `async-patterns.ts` - Promise and async/await best practices

## Templates Reference

See the `templates/` directory for reusable code templates:
- `base-service.ts` - Generic service class template
- `error-handler.ts` - Centralized error handling

## AI Assistant Instructions

When this skill is activated:

**Always:**
- Use `type` imports for TypeScript types
- Check for security violations (credential.key exposure)
- Suggest early returns for better code structure
- Provide complete, working examples
- Reference specific example files when relevant
- Explain the "why" behind each pattern

**Never:**
- Use regular imports for types
- Suggest exposing sensitive credential fields
- Skip error handling in examples
- Use `any` without strong justification
- Create deeply nested conditionals

**Security Review Checklist:**
1. Are we selecting credential.key or other sensitive fields? ❌
2. Are we using explicit `select` for database queries? ✅
3. Are we validating external input? ✅
4. Are we using type guards for user data? ✅

**Code Quality Checklist:**
1. Are we using `type` imports? ✅
2. Are we using early returns? ✅
3. Are we avoiding prop drilling? ✅
4. Is error handling comprehensive? ✅
5. Are types explicit and clear? ✅

## Additional Resources

- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [TypeScript Deep Dive](https://basarat.gitbook.io/typescript/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Google TypeScript Style Guide](https://google.github.io/styleguide/tsguide.html)
