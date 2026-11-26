# syntax=docker/dockerfile:1
# Multi-stage build: stage 1 compiles with Maven + full JDK; stage 2 runs on a small JRE.
# The final image contains only the runtime and the app, not Maven or source code.
#
# Build:  docker build -t portfolio-api ./backend
# Run:    docker compose up -d backend   (see docker-compose.yml)

############################ Stage 1: build ############################
FROM maven:3.9.11-eclipse-temurin-21 AS build
WORKDIR /workspace

# 1) Download dependencies first, using only the pom. Docker caches this layer, so it is
#    reused on every build until pom.xml changes. Code edits don't re-download anything.
COPY pom.xml .
RUN --mount=type=cache,target=/root/.m2 mvn -B -q dependency:go-offline

# 2) Then copy the source and package the jar. Tests are skipped here: they run in CI
#    (they need Docker for Testcontainers, which isn't available inside a build).
COPY src ./src
RUN --mount=type=cache,target=/root/.m2 mvn -B -q package -DskipTests

# 3) Split the fat jar into layers (dependencies / Spring loader / your code), so that
#    after a code change only the small "application" layer changes in the final image.
RUN java -Djarmode=tools -jar target/*.jar extract --layers --launcher --destination /workspace/extracted

############################ Stage 2: run ############################
FROM eclipse-temurin:21-jre-alpine AS runtime
WORKDIR /app

# Don't run as root inside the container
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

# Copy layers from least to most frequently changing (best cache reuse)
COPY --from=build /workspace/extracted/dependencies/ ./
COPY --from=build /workspace/extracted/spring-boot-loader/ ./
COPY --from=build /workspace/extracted/snapshot-dependencies/ ./
COPY --from=build /workspace/extracted/application/ ./

# The JVM reads the container's memory limit; use 75% of it for the heap.
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75 -XX:+ExitOnOutOfMemoryError"

EXPOSE 8080

# Docker marks the container "healthy" only when Spring Boot reports UP
HEALTHCHECK --interval=10s --timeout=3s --start-period=40s --retries=5 \
  CMD wget -qO- http://localhost:8080/actuator/health/readiness | grep -q '"UP"' || exit 1

ENTRYPOINT ["java", "org.springframework.boot.loader.launch.JarLauncher"]
