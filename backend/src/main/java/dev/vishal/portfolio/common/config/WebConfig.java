package dev.vishal.portfolio.common.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import dev.vishal.portfolio.common.ratelimit.ContactRateLimitInterceptor;

/** Registers request interceptors (code that runs before controllers). */
@Configuration
public class WebConfig implements WebMvcConfigurer {

    private final ContactRateLimitInterceptor contactRateLimit;

    public WebConfig(ContactRateLimitInterceptor contactRateLimit) {
        this.contactRateLimit = contactRateLimit;
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(contactRateLimit).addPathPatterns("/api/contact");
    }
}
