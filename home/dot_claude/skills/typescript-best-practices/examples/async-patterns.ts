/**
 * Async/Promise Best Practices
 *
 * This file demonstrates proper async/await and Promise patterns in TypeScript,
 * including error handling, parallel execution, and cancellation.
 */

// ============================================================================
// Basic Async Patterns
// ============================================================================

/**
 * Example 1: ✅ Always return Promises consistently
 */
async function fetchUser_GOOD(id: string): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  return response.json();
}

/**
 * Example 2: ❌ Inconsistent Promise returns
 */
async function fetchUser_BAD(id: string) {
  // ❌ Mixing sync and async returns
  if (cache.has(id)) {
    return cache.get(id); // Not wrapped in Promise
  }
  const response = await fetch(`/api/users/${id}`);
  return response.json();
}

/**
 * Example 3: ✅ Fix: Wrap all returns consistently
 */
async function fetchUser_FIXED(id: string): Promise<User> {
  if (cache.has(id)) {
    return Promise.resolve(cache.get(id)!);
  }
  const response = await fetch(`/api/users/${id}`);
  return response.json();
}

// ============================================================================
// Error Handling
// ============================================================================

/**
 * Example 4: Proper async error handling
 */
async function fetchUserSafe(id: string): Promise<User | null> {
  try {
    const response = await fetch(`/api/users/${id}`);

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    return await response.json();
  } catch (error) {
    console.error('Failed to fetch user:', error);
    return null;
  }
}

/**
 * Example 5: Error propagation with Result type
 */
type Result<T> =
  | { status: 'success'; data: T }
  | { status: 'error'; error: string };

async function fetchUserWithResult(id: string): Promise<Result<User>> {
  try {
    const response = await fetch(`/api/users/${id}`);

    if (!response.ok) {
      return {
        status: 'error',
        error: `HTTP error! status: ${response.status}`
      };
    }

    const data = await response.json();
    return { status: 'success', data };
  } catch (error) {
    return {
      status: 'error',
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

// ============================================================================
// Parallel Execution
// ============================================================================

/**
 * Example 6: ❌ Sequential execution (slow)
 */
async function fetchMultipleUsers_SLOW(ids: string[]): Promise<User[]> {
  const users: User[] = [];

  // ❌ Each fetch waits for the previous one to complete
  for (const id of ids) {
    const user = await fetchUser_GOOD(id);
    users.push(user);
  }

  return users;
}

/**
 * Example 7: ✅ Parallel execution (fast)
 */
async function fetchMultipleUsers_FAST(ids: string[]): Promise<User[]> {
  // ✅ All fetches start simultaneously
  const promises = ids.map(id => fetchUser_GOOD(id));
  return Promise.all(promises);
}

/**
 * Example 8: Parallel with error handling
 */
async function fetchMultipleUsersSafe(
  ids: string[]
): Promise<{ succeeded: User[]; failed: string[] }> {
  const results = await Promise.allSettled(
    ids.map(id => fetchUser_GOOD(id))
  );

  const succeeded: User[] = [];
  const failed: string[] = [];

  results.forEach((result, index) => {
    if (result.status === 'fulfilled') {
      succeeded.push(result.value);
    } else {
      failed.push(ids[index]);
    }
  });

  return { succeeded, failed };
}

// ============================================================================
// Promise Combinators
// ============================================================================

/**
 * Example 9: Promise.all - Wait for all to complete
 */
async function fetchUserProfile(userId: string): Promise<UserProfile> {
  const [user, posts, comments] = await Promise.all([
    fetchUser_GOOD(userId),
    fetchUserPosts(userId),
    fetchUserComments(userId)
  ]);

  return { user, posts, comments };
}

/**
 * Example 10: Promise.race - Use first to complete
 */
async function fetchWithTimeout<T>(
  promise: Promise<T>,
  timeoutMs: number
): Promise<T> {
  const timeout = new Promise<never>((_, reject) =>
    setTimeout(() => reject(new Error('Timeout')), timeoutMs)
  );

  return Promise.race([promise, timeout]);
}

/**
 * Example 11: Promise.any - Use first successful result
 */
async function fetchFromMultipleSources(id: string): Promise<User> {
  return Promise.any([
    fetch(`https://api1.example.com/users/${id}`).then(r => r.json()),
    fetch(`https://api2.example.com/users/${id}`).then(r => r.json()),
    fetch(`https://api3.example.com/users/${id}`).then(r => r.json())
  ]);
}

// ============================================================================
// Cancellation with AbortController
// ============================================================================

/**
 * Example 12: Cancellable fetch request
 */
class CancellableRequest<T> {
  private controller = new AbortController();

  async fetch(url: string): Promise<T> {
    const response = await fetch(url, {
      signal: this.controller.signal
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    return response.json();
  }

  cancel(): void {
    this.controller.abort();
  }
}

// Usage
const request = new CancellableRequest<User>();
request.fetch('/api/users/123');

// Later, if needed
request.cancel();

/**
 * Example 13: Timeout with AbortController
 */
async function fetchWithAbortTimeout<T>(
  url: string,
  timeoutMs: number
): Promise<T> {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const response = await fetch(url, { signal: controller.signal });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    return await response.json();
  } finally {
    clearTimeout(timeoutId);
  }
}

// ============================================================================
// Retry Logic
// ============================================================================

/**
 * Example 14: Exponential backoff retry
 */
async function fetchWithRetry<T>(
  fn: () => Promise<T>,
  maxRetries: number = 3,
  delayMs: number = 1000
): Promise<T> {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      if (attempt === maxRetries) {
        throw error;
      }

      // Exponential backoff
      const delay = delayMs * Math.pow(2, attempt - 1);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }

  throw new Error('All retries failed');
}

// Usage
const user = await fetchWithRetry(() => fetchUser_GOOD('123'), 3, 1000);

// ============================================================================
// Debouncing & Throttling
// ============================================================================

/**
 * Example 15: Async debounce
 */
function debounce<T extends (...args: any[]) => Promise<any>>(
  fn: T,
  delayMs: number
): (...args: Parameters<T>) => Promise<ReturnType<T>> {
  let timeoutId: NodeJS.Timeout | null = null;

  return (...args: Parameters<T>): Promise<ReturnType<T>> => {
    return new Promise((resolve) => {
      if (timeoutId) {
        clearTimeout(timeoutId);
      }

      timeoutId = setTimeout(async () => {
        resolve(await fn(...args));
      }, delayMs);
    });
  };
}

// Usage
const debouncedSearch = debounce(
  async (query: string) => {
    const response = await fetch(`/api/search?q=${query}`);
    return response.json();
  },
  300
);

/**
 * Example 16: Async throttle
 */
function throttle<T extends (...args: any[]) => Promise<any>>(
  fn: T,
  delayMs: number
): (...args: Parameters<T>) => Promise<ReturnType<T>> | null {
  let isThrottled = false;

  return async (...args: Parameters<T>): Promise<ReturnType<T>> | null => {
    if (isThrottled) {
      return null;
    }

    isThrottled = true;

    setTimeout(() => {
      isThrottled = false;
    }, delayMs);

    return fn(...args);
  };
}

// ============================================================================
// Queue Processing
// ============================================================================

/**
 * Example 17: Process items with concurrency limit
 */
async function processBatch<T, R>(
  items: T[],
  processor: (item: T) => Promise<R>,
  concurrency: number
): Promise<R[]> {
  const results: R[] = [];
  const queue = [...items];

  async function processNext(): Promise<void> {
    const item = queue.shift();
    if (!item) return;

    const result = await processor(item);
    results.push(result);

    return processNext();
  }

  // Start concurrent workers
  const workers = Array(Math.min(concurrency, items.length))
    .fill(null)
    .map(() => processNext());

  await Promise.all(workers);

  return results;
}

// Usage
const userIds = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'];
const users = await processBatch(userIds, fetchUser_GOOD, 3);

// ============================================================================
// Async Iterators
// ============================================================================

/**
 * Example 18: Async generator for pagination
 */
async function* fetchPaginatedUsers(
  pageSize: number = 10
): AsyncGenerator<User[], void, undefined> {
  let page = 1;
  let hasMore = true;

  while (hasMore) {
    const response = await fetch(`/api/users?page=${page}&size=${pageSize}`);
    const data = await response.json();

    if (data.users.length === 0) {
      hasMore = false;
    } else {
      yield data.users;
      page++;
    }
  }
}

// Usage
async function processAllUsers(): Promise<void> {
  for await (const userBatch of fetchPaginatedUsers(10)) {
    console.log(`Processing ${userBatch.length} users`);
    // Process batch
  }
}

// ============================================================================
// Helper Types & Interfaces
// ============================================================================

interface User {
  id: string;
  email: string;
  name: string;
}

interface Post {
  id: string;
  userId: string;
  title: string;
  content: string;
}

interface Comment {
  id: string;
  postId: string;
  userId: string;
  content: string;
}

interface UserProfile {
  user: User;
  posts: Post[];
  comments: Comment[];
}

// Mock functions
async function fetchUserPosts(userId: string): Promise<Post[]> {
  return [];
}

async function fetchUserComments(userId: string): Promise<Comment[]> {
  return [];
}

// Mock cache
const cache = new Map<string, User>();

// ============================================================================
// Best Practices Summary
// ============================================================================

/*
ASYNC/AWAIT BEST PRACTICES:

1. ✅ Always return Promises consistently (wrap sync returns)
2. ✅ Use try-catch for error handling in async functions
3. ✅ Prefer Result types over throwing errors for expected failures
4. ✅ Use Promise.all() for parallel execution
5. ✅ Use Promise.allSettled() when some failures are acceptable
6. ✅ Use Promise.race() for timeout patterns
7. ✅ Use Promise.any() for fallback/redundancy
8. ✅ Implement AbortController for cancellable operations
9. ✅ Add timeout mechanisms for external API calls
10. ✅ Implement retry logic with exponential backoff
11. ✅ Use debounce/throttle for user-triggered async operations
12. ✅ Limit concurrency when processing batches
13. ✅ Use async generators for pagination/streaming
14. ✅ Always await Promises (don't forget await)
15. ✅ Properly propagate errors up the call stack

NEVER:
- Mix sync and async returns in the same function
- Forget to await Promises
- Use Promise constructor when async/await is clearer
- Ignore errors in async functions
- Process arrays sequentially when parallel is possible
- Miss cleaning up resources (use finally blocks)
- Create unhandled Promise rejections

ALWAYS:
- Add timeout mechanisms for external calls
- Implement proper error handling
- Use appropriate Promise combinators
- Consider cancellation for long-running operations
- Limit concurrency for resource-intensive operations
- Use type-safe Result types for expected errors
- Clean up resources (timers, connections, etc.)
*/
