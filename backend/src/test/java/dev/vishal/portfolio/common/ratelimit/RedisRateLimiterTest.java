package dev.vishal.portfolio.common.ratelimit;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;

import org.junit.jupiter.api.Test;
import org.springframework.data.redis.RedisConnectionFailureException;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

/** Unit tests with a mocked Redis: decisions and the fail-open behaviour. */
class RedisRateLimiterTest {

    // 00:00:45 into a minute → 15 seconds left in a 1-minute window
    private final Clock clock = Clock.fixed(Instant.parse("2026-11-28T10:00:45Z"), ZoneOffset.UTC);

    @SuppressWarnings("unchecked")
    private RedisRateLimiter limiterReturning(Long count) {
        StringRedisTemplate redis = mock(StringRedisTemplate.class);
        ValueOperations<String, String> ops = mock(ValueOperations.class);
        when(redis.opsForValue()).thenReturn(ops);
        when(ops.increment(anyString())).thenReturn(count);
        return new RedisRateLimiter(redis, clock);
    }

    @Test
    void allowsUpToTheLimit() {
        assertThat(limiterReturning(5L).tryAcquire("k", 5, Duration.ofMinutes(1)).allowed()).isTrue();
    }

    @Test
    void deniesAboveTheLimitWithSecondsUntilTheWindowResets() {
        var decision = limiterReturning(6L).tryAcquire("k", 5, Duration.ofMinutes(1));
        assertThat(decision.allowed()).isFalse();
        assertThat(decision.retryAfterSeconds()).isEqualTo(15);
    }

    @Test
    void failsOpenWhenRedisIsDown() {
        StringRedisTemplate redis = mock(StringRedisTemplate.class);
        when(redis.opsForValue()).thenThrow(new RedisConnectionFailureException("Connection refused"));
        var limiter = new RedisRateLimiter(redis, clock);

        assertThat(limiter.tryAcquire("k", 5, Duration.ofMinutes(1)).allowed()).isTrue();
    }
}
