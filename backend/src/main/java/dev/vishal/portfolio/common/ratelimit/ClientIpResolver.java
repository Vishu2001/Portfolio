package dev.vishal.portfolio.common.ratelimit;

import jakarta.servlet.http.HttpServletRequest;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Finds the visitor's real IP address.
 *
 * Behind proxies (AWS load balancer, later CloudFront) the TCP connection comes from the
 * proxy, so the client IP is in the X-Forwarded-For header: "client, proxy1, proxy2".
 * Each proxy APPENDS the address it received the request from, which means a visitor can
 * fake the left-hand entries but not the ones our own proxies added on the right.
 *
 * So we count from the right: with N trusted proxies in front of the app, the client is the
 * N-th entry from the end. N comes from config (app.rate-limit.trusted-proxies):
 *   0 = no proxy (local dev)  1 = load balancer  2 = CloudFront + load balancer
 */
@Component
public class ClientIpResolver {

    private final int trustedProxies;

    public ClientIpResolver(@Value("${app.rate-limit.trusted-proxies:0}") int trustedProxies) {
        this.trustedProxies = trustedProxies;
    }

    public String resolve(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (trustedProxies <= 0 || forwarded == null || forwarded.isBlank()) {
            return request.getRemoteAddr();
        }
        String[] hops = forwarded.split(",");
        int index = hops.length - trustedProxies;
        // Fewer entries than expected proxies: use the left-most one we have
        return hops[Math.max(index, 0)].strip();
    }
}
