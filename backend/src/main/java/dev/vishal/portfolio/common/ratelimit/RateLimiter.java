package dev.vishal.portfolio.common.ratelimit;

import java.time.Duration;

/**
 * Counts requests per key (e.g. per client IP) inside a fixed time window.
 * Interface + implementation, so the storage (Redis today) can be swapped without
 * touching the code that uses it.
 */
public interface RateLimiter {

    /**
     * Records one request for {@code key} and says whether it's within the limit.
     *
     * @param key         who is being limited, e.g. "contact:203.0.113.7"
     * @param maxRequests allowed requests per window
     * @param window      window length, e.g. 1 minute
     */
    Decision tryAcquire(String key, int maxRequests, Duration window);

    /**
     * @param allowed           true if the request may proceed
     * @param retryAfterSeconds when not allowed: seconds until the window resets
     */
    record Decision(boolean allowed, long retryAfterSeconds) {

        public static Decision allow() {
            return new Decision(true, 0);
        }

        public static Decision deny(long retryAfterSeconds) {
            return new Decision(false, retryAfterSeconds);
        }
    }
}
