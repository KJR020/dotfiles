/**
 * Security Patterns Best Practices
 *
 * This file demonstrates security-focused TypeScript patterns,
 * including protecting sensitive data, input validation, and safe database queries.
 */

// ============================================================================
// CRITICAL: Never Expose Credential Keys
// ============================================================================

/**
 * Example 1: ❌ SECURITY VIOLATION - NEVER DO THIS
 */
/*
const user = await prisma.user.findFirst({
  select: {
    credentials: {
      select: {
        key: true, // ❌ SECURITY VIOLATION: Exposes sensitive credential keys
      }
    }
  }
});
*/

/**
 * Example 2: ✅ SECURE - Exclude sensitive fields
 */
interface UserCredential {
  id: string;
  userId: string;
  type: string;
  key: string; // Sensitive field
}

// Create a safe public type that excludes sensitive data
type PublicUserCredential = Omit<UserCredential, 'key'>;

/*
// Example with Prisma
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
*/

/**
 * Example 3: Type-safe sensitive data handling
 */
function sanitizeCredential(credential: UserCredential): PublicUserCredential {
  const { key, ...publicData } = credential;
  return publicData;
}

// ============================================================================
// Input Validation
// ============================================================================

/**
 * Example 4: Type guards for user input validation
 */
function isValidEmail(input: unknown): input is string {
  return (
    typeof input === 'string' &&
    input.length > 0 &&
    /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(input)
  );
}

function isValidUserId(input: unknown): input is string {
  return (
    typeof input === 'string' &&
    /^[a-zA-Z0-9-_]+$/.test(input) &&
    input.length <= 100
  );
}

/**
 * Example 5: Validate and sanitize user input
 */
interface UnsafeUserInput {
  email?: unknown;
  name?: unknown;
  age?: unknown;
}

interface SafeUserInput {
  email: string;
  name: string;
  age: number;
}

function validateUserInput(input: UnsafeUserInput): SafeUserInput | null {
  // Validate email
  if (!isValidEmail(input.email)) {
    return null;
  }

  // Validate name
  if (typeof input.name !== 'string' || input.name.length === 0 || input.name.length > 100) {
    return null;
  }

  // Validate age
  if (typeof input.age !== 'number' || input.age < 0 || input.age > 150) {
    return null;
  }

  return {
    email: input.email,
    name: input.name.trim(),
    age: input.age
  };
}

// ============================================================================
// SQL Injection Prevention
// ============================================================================

/**
 * Example 6: ❌ VULNERABLE - String concatenation in SQL
 */
/*
function getUserByEmail_UNSAFE(email: string) {
  // ❌ NEVER DO THIS - Vulnerable to SQL injection
  const query = `SELECT * FROM users WHERE email = '${email}'`;
  return db.query(query);
}
*/

/**
 * Example 7: ✅ SECURE - Use parameterized queries
 */
/*
function getUserByEmail_SAFE(email: string) {
  // ✅ Use parameterized queries
  return db.query('SELECT * FROM users WHERE email = $1', [email]);
}
*/

// ============================================================================
// XSS Prevention
// ============================================================================

/**
 * Example 8: Escape HTML to prevent XSS
 */
function escapeHtml(unsafe: string): string {
  return unsafe
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

/**
 * Example 9: Type-safe HTML sanitization
 */
type SafeHtml = string & { readonly __brand: unique symbol };

function sanitizeHtml(input: string): SafeHtml {
  const escaped = escapeHtml(input);
  return escaped as SafeHtml;
}

function renderHtml(html: SafeHtml): void {
  // Only SafeHtml can be rendered
  document.body.innerHTML = html;
}

// Usage
const userInput = '<script>alert("XSS")</script>';
const safe = sanitizeHtml(userInput);
renderHtml(safe); // ✅ Safe

// renderHtml(userInput); // ❌ Type error: string is not assignable to SafeHtml

// ============================================================================
// Authentication & Authorization
// ============================================================================

/**
 * Example 10: Type-safe role-based access control
 */
type UserRole = 'user' | 'admin' | 'moderator';

interface AuthenticatedUser {
  id: string;
  email: string;
  role: UserRole;
}

type Permission = 'read' | 'write' | 'delete' | 'admin';

const rolePermissions: Record<UserRole, Permission[]> = {
  user: ['read'],
  moderator: ['read', 'write'],
  admin: ['read', 'write', 'delete', 'admin']
};

function hasPermission(user: AuthenticatedUser, permission: Permission): boolean {
  return rolePermissions[user.role].includes(permission);
}

function requirePermission(user: AuthenticatedUser, permission: Permission): void {
  if (!hasPermission(user, permission)) {
    throw new Error(`Permission denied: ${permission}`);
  }
}

/**
 * Example 11: Secure API endpoint with type-safe authorization
 */
async function deletePost(user: AuthenticatedUser, postId: string): Promise<void> {
  // Check permission
  requirePermission(user, 'delete');

  // Validate input
  if (!isValidUserId(postId)) {
    throw new Error('Invalid post ID');
  }

  // Perform action
  // await db.post.delete({ where: { id: postId } });
}

// ============================================================================
// Password Handling
// ============================================================================

/**
 * Example 12: Never store or return plain-text passwords
 */
interface UserWithPassword {
  id: string;
  email: string;
  passwordHash: string; // Hashed, not plain-text
}

// Public user type excludes password entirely
type PublicUser = Omit<UserWithPassword, 'passwordHash'>;

/**
 * Example 13: Password validation
 */
function isStrongPassword(password: string): boolean {
  // At least 8 characters, contains uppercase, lowercase, number, and special char
  const minLength = password.length >= 8;
  const hasUppercase = /[A-Z]/.test(password);
  const hasLowercase = /[a-z]/.test(password);
  const hasNumber = /[0-9]/.test(password);
  const hasSpecial = /[!@#$%^&*(),.?":{}|<>]/.test(password);

  return minLength && hasUppercase && hasLowercase && hasNumber && hasSpecial;
}

// ============================================================================
// Rate Limiting Types
// ============================================================================

/**
 * Example 14: Type-safe rate limiting
 */
interface RateLimitConfig {
  maxRequests: number;
  windowMs: number;
}

interface RateLimitEntry {
  count: number;
  resetAt: Date;
}

class RateLimiter {
  private limits = new Map<string, RateLimitEntry>();

  constructor(private config: RateLimitConfig) {}

  isAllowed(identifier: string): boolean {
    const now = new Date();
    const entry = this.limits.get(identifier);

    if (!entry || entry.resetAt < now) {
      this.limits.set(identifier, {
        count: 1,
        resetAt: new Date(now.getTime() + this.config.windowMs)
      });
      return true;
    }

    if (entry.count >= this.config.maxRequests) {
      return false;
    }

    entry.count++;
    return true;
  }
}

// ============================================================================
// Secure Token Handling
// ============================================================================

/**
 * Example 15: Branded types for tokens
 */
type Brand<K, T> = K & { __brand: T };
type AccessToken = Brand<string, 'AccessToken'>;
type RefreshToken = Brand<string, 'RefreshToken'>;

function createAccessToken(payload: object): AccessToken {
  // Use proper JWT library
  // const token = jwt.sign(payload, SECRET, { expiresIn: '1h' });
  const token = 'simulated-token';
  return token as AccessToken;
}

function verifyAccessToken(token: AccessToken): object | null {
  try {
    // Use proper JWT library
    // return jwt.verify(token, SECRET);
    return {};
  } catch {
    return null;
  }
}

// Type system prevents mixing up token types
function authenticate(token: AccessToken): boolean {
  const payload = verifyAccessToken(token);
  return payload !== null;
}

const accessToken = createAccessToken({ userId: '123' });
authenticate(accessToken); // ✅ OK

// const refreshToken: RefreshToken = 'some-token' as RefreshToken;
// authenticate(refreshToken); // ❌ Error: RefreshToken is not assignable to AccessToken

// ============================================================================
// CORS Configuration
// ============================================================================

/**
 * Example 16: Type-safe CORS configuration
 */
interface CorsConfig {
  allowedOrigins: string[];
  allowedMethods: ('GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH' | 'OPTIONS')[];
  allowedHeaders: string[];
  credentials: boolean;
  maxAge?: number;
}

function isOriginAllowed(origin: string, config: CorsConfig): boolean {
  if (config.allowedOrigins.includes('*')) {
    return true;
  }
  return config.allowedOrigins.includes(origin);
}

const corsConfig: CorsConfig = {
  allowedOrigins: ['https://example.com', 'https://app.example.com'],
  allowedMethods: ['GET', 'POST'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
  maxAge: 86400
};

// ============================================================================
// Environment Variable Validation
// ============================================================================

/**
 * Example 17: Type-safe environment variable validation
 */
interface EnvironmentVariables {
  NODE_ENV: 'development' | 'production' | 'test';
  DATABASE_URL: string;
  API_SECRET: string;
  PORT: number;
}

function validateEnv(): EnvironmentVariables {
  const env = process.env;

  // Validate NODE_ENV
  const nodeEnv = env.NODE_ENV;
  if (nodeEnv !== 'development' && nodeEnv !== 'production' && nodeEnv !== 'test') {
    throw new Error('Invalid NODE_ENV');
  }

  // Validate DATABASE_URL
  if (!env.DATABASE_URL) {
    throw new Error('DATABASE_URL is required');
  }

  // Validate API_SECRET
  if (!env.API_SECRET || env.API_SECRET.length < 32) {
    throw new Error('API_SECRET must be at least 32 characters');
  }

  // Validate PORT
  const port = parseInt(env.PORT || '3000', 10);
  if (isNaN(port) || port < 0 || port > 65535) {
    throw new Error('Invalid PORT');
  }

  return {
    NODE_ENV: nodeEnv,
    DATABASE_URL: env.DATABASE_URL,
    API_SECRET: env.API_SECRET,
    PORT: port
  };
}

// Use at application startup
// const config = validateEnv();

// ============================================================================
// Best Practices Summary
// ============================================================================

/*
CRITICAL SECURITY RULES:

1. ❌ NEVER expose credential keys, passwords, or API secrets
2. ✅ ALWAYS use explicit select in database queries
3. ✅ ALWAYS validate and sanitize user input at system boundaries
4. ✅ ALWAYS use parameterized queries to prevent SQL injection
5. ✅ ALWAYS escape HTML output to prevent XSS
6. ✅ ALWAYS hash passwords (never store plain-text)
7. ✅ ALWAYS validate environment variables at startup
8. ✅ ALWAYS implement rate limiting for public endpoints
9. ✅ ALWAYS use HTTPS in production
10. ✅ ALWAYS validate JWT tokens before trusting claims
11. ✅ Use branded types to prevent token/ID confusion
12. ✅ Use type guards for runtime validation
13. ✅ Create separate types for public vs internal data
14. ✅ Implement role-based access control with type safety
15. ✅ Configure CORS properly with type-safe configuration

NEVER:
- Expose sensitive fields (password, apiKey, credentials.key)
- Trust user input without validation
- Use string concatenation for SQL queries
- Store passwords in plain text
- Skip authentication/authorization checks
- Allow unbounded rate limits
- Log sensitive information

ALWAYS:
- Validate input at boundaries
- Use parameterized queries
- Hash sensitive data
- Implement proper RBAC
- Sanitize output
- Use branded types for sensitive values
*/
