package dev.vishal.portfolio;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;

@Import(TestcontainersConfiguration.class)
@SpringBootTest
class PortfolioApiApplicationTests {

    /** Starts the whole app against MySQL: proves Flyway ran and Hibernate validated the schema. */
    @Test
    void contextLoads() {
    }
}
