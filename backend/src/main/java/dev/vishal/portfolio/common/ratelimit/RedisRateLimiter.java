package dev.vishal.portfolio.common.ratelimit;

import java.time.Clock;
import java.time.Duration;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

/**
 * Fixed-window rate limiter on Redis.
 *
 * For each key and time window there's one Redis counter, e.g.
 *   ratelimit:contact:203.0.113.7:29475012   (last part = window number since the epoch)
 * INCR bumps it atomically (safe with several backend instances sharing one Redis); the first
 * increment sets an expiry, so old counters delete themselves.
 *
 * Fail-open: if Redis can't be reached, the request is allowed and a warning is logged. For a
 * contact form, staying available matters more than strict limiting.
 */
@Component
public class RedisRateLimiter implements RateLimiter {

    private static final Logger log = LoggerFactory.getLogger(RedisRateLimiter.class);
    private static final String PREFIX = "ratelimit:";

    private final StringRedisTemplate redis;
    private final Clock clock;

    public RedisRateLimiter(StringRedisTemplate redis, Clock clock) {
        this.redis = redis;
        this.clock = clock;
    }

    @Override
    public Decision tryAcquire(String key, int maxRequests, Duration window) {
        long nowSeconds = clock.instant().getEpochSecond();
        long windowSeconds = window.toSeconds();
        long windowNumber = nowSeconds / windowSeconds;
        String redisKey = PREFIX + key + ":" + windowNumber;

        try {
            Long count = redis.opsForValue().increment(redisKey);
            if (count != null && count == 1) {
                // First request in this window: let Redis delete the counter when the window ends
                redis.expire(redisKey, window.plusSeconds(1));
            }
            if (count != null && count > maxRequests) {
                long secondsLeft = windowSeconds - (nowSeconds % windowSeconds);
                return Decision.deny(Math.max(secondsLeft, 1));
            }
            return Decision.allow();
        } catch (RuntimeException e) {
            log.warn("Rate limiter unavailable, allowing request (fail-open): {}", e.getMessage());
            return Decision.allow();
        }
    }
}
