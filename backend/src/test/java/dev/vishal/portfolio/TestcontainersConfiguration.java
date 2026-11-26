package dev.vishal.portfolio;

import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.context.annotation.Bean;
import org.testcontainers.mysql.MySQLContainer;
import org.testcontainers.utility.DockerImageName;

/**
 * Starts a throwaway MySQL (same version as docker-compose and, later, RDS) in Docker
 * for the tests. @ServiceConnection points spring.datasource.* at it automatically,
 * and Flyway runs V1 on it just like it does on the real database.
 */
@TestConfiguration(proxyBeanMethods = false)
public class TestcontainersConfiguration {

    @Bean
    @ServiceConnection
    MySQLContainer mysqlContainer() {
        return new MySQLContainer(DockerImageName.parse("mysql:8.4"));
    }
}
