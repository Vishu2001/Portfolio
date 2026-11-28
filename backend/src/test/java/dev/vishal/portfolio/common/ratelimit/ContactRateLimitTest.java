package dev.vishal.portfolio.common.ratelimit;

import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import dev.vishal.portfolio.TestcontainersConfiguration;

/** End-to-end: real Redis (Testcontainers), limit lowered to 3 per minute, 1 trusted proxy. */
@Import(TestcontainersConfiguration.class)
@SpringBootTest(properties = {
        "app.rate-limit.contact.max-requests=3",
        "app.rate-limit.trusted-proxies=1"
})
@AutoConfigureMockMvc
class ContactRateLimitTest {

    @Autowired
    MockMvc mvc;

    @Autowired
    StringRedisTemplate redis;

    @BeforeEach
    void clearCounters() {
        redis.keys("ratelimit:*").forEach(redis::delete);
    }

    private static MockHttpServletRequestBuilder contactFrom(String clientIp) {
        return post("/api/contact")
                .contentType(MediaType.APPLICATION_JSON)
                // As the AWS load balancer would send it: the client IP it saw, appended last
                .header("X-Forwarded-For", clientIp)
                .content("""
                        {"name": "Asha", "email": "asha@example.com", "message": "Hello, testing the rate limit."}
                        """);
    }

    @Test
    void fourthRequestInAMinuteIsRejectedWith429() throws Exception {
        for (int i = 1; i <= 3; i++) {
            mvc.perform(contactFrom("203.0.113.7")).andExpect(status().isAccepted());
        }
        mvc.perform(contactFrom("203.0.113.7"))
                .andExpect(status().isTooManyRequests())
                .andExpect(header().exists("Retry-After"))
                .andExpect(jsonPath("$.title").value("Too many requests"))
                .andExpect(jsonPath("$.detail", containsString("try again")));
    }

    @Test
    void differentVisitorsHaveSeparateLimits() throws Exception {
        for (int i = 1; i <= 3; i++) {
            mvc.perform(contactFrom("203.0.113.7")).andExpect(status().isAccepted());
        }
        mvc.perform(contactFrom("203.0.113.7")).andExpect(status().isTooManyRequests());
        // Someone else isn't affected by the first visitor hitting the limit
        mvc.perform(contactFrom("198.51.100.20")).andExpect(status().isAccepted());
    }

    @Test
    void fakedForwardedForEntriesDontBypassTheLimit() throws Exception {
        // An attacker adds a random fake IP on the left each time; the load balancer still
        // appends their real IP on the right, and that's the one we use.
        for (int i = 1; i <= 3; i++) {
            mvc.perform(contactFrom("10.0.0." + i + ", 203.0.113.7")).andExpect(status().isAccepted());
        }
        mvc.perform(contactFrom("10.0.0.99, 203.0.113.7")).andExpect(status().isTooManyRequests());
    }
}
