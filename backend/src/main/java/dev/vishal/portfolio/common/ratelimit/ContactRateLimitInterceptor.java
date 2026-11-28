package dev.vishal.portfolio.common.ratelimit;

import java.io.IOException;
import java.time.Duration;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

/**
 * Runs BEFORE ContactController for POST /api/contact (registered in WebConfig).
 * Over the limit → 429 Too Many Requests with a Retry-After header and a problem-details body,
 * and the controller is never called. Keeps rate limiting out of the controller/service.
 */
@Component
public class ContactRateLimitInterceptor implements HandlerInterceptor {

    private static final Logger log = LoggerFactory.getLogger(ContactRateLimitInterceptor.class);

    private final RateLimiter rateLimiter;
    private final ClientIpResolver ipResolver;
    private final int maxRequests;
    private final Duration window;

    public ContactRateLimitInterceptor(
            RateLimiter rateLimiter,
            ClientIpResolver ipResolver,
            @Value("${app.rate-limit.contact.max-requests:5}") int maxRequests,
            @Value("${app.rate-limit.contact.window:1m}") Duration window) {
        this.rateLimiter = rateLimiter;
        this.ipResolver = ipResolver;
        this.maxRequests = maxRequests;
        this.window = window;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler)
            throws IOException {
        if (!"POST".equalsIgnoreCase(request.getMethod())) {
            return true; // only submissions count (CORS preflight OPTIONS etc. pass through)
        }
        String ip = ipResolver.resolve(request);
        RateLimiter.Decision decision = rateLimiter.tryAcquire("contact:" + ip, maxRequests, window);
        if (decision.allowed()) {
            return true;
        }

        log.info("Rate limit hit for contact form ({} requests per {})", maxRequests, window);
        response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
        response.setHeader(HttpHeaders.RETRY_AFTER, String.valueOf(decision.retryAfterSeconds()));
        response.setContentType(MediaType.APPLICATION_PROBLEM_JSON_VALUE);
        response.getWriter().write("""
                {"status":429,"title":"Too many requests",\
                "detail":"You've sent several messages in a short time. Please try again in %d seconds."}"""
                .formatted(decision.retryAfterSeconds()));
        return false; // stop here: the controller is not called
    }
}
