package dev.vishal.portfolio.common.ratelimit;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;

class ClientIpResolverTest {

    private static MockHttpServletRequest request(String remoteAddr, String forwardedFor) {
        MockHttpServletRequest r = new MockHttpServletRequest();
        r.setRemoteAddr(remoteAddr);
        if (forwardedFor != null) r.addHeader("X-Forwarded-For", forwardedFor);
        return r;
    }

    @Test
    void noTrustedProxiesUsesTheConnectionAddressAndIgnoresTheHeader() {
        var resolver = new ClientIpResolver(0);
        assertThat(resolver.resolve(request("127.0.0.1", "6.6.6.6"))).isEqualTo("127.0.0.1");
    }

    @Test
    void oneTrustedProxyTakesTheLastEntry() {
        var resolver = new ClientIpResolver(1);
        // "fake" was sent by the visitor; the load balancer appended the real client IP
        assertThat(resolver.resolve(request("10.0.1.5", "6.6.6.6, 203.0.113.7"))).isEqualTo("203.0.113.7");
    }

    @Test
    void twoTrustedProxiesSkipTheInnerProxy() {
        var resolver = new ClientIpResolver(2);
        // client → CloudFront (appends client) → load balancer (appends CloudFront edge IP)
        assertThat(resolver.resolve(request("10.0.1.5", "203.0.113.7, 130.176.0.1"))).isEqualTo("203.0.113.7");
    }

    @Test
    void missingHeaderFallsBackToTheConnectionAddress() {
        var resolver = new ClientIpResolver(1);
        assertThat(resolver.resolve(request("198.51.100.20", null))).isEqualTo("198.51.100.20");
    }
}
