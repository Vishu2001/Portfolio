package dev.vishal.portfolio.common.config;

import java.time.Clock;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * One shared Clock instead of calling Instant.now() everywhere: tests can swap in
 * Clock.fixed(...) to get predictable timestamps.
 */
@Configuration
public class TimeConfig {

    @Bean
    Clock clock() {
        return Clock.systemUTC();
    }
}
