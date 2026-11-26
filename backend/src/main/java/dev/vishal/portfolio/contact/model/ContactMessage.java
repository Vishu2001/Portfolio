package dev.vishal.portfolio.contact.model;

import java.time.Instant;
import java.util.UUID;

/**
 * Domain model: a contact message as the application stores it.
 * Separate from the DTOs, so the API's JSON shape and the storage shape can change
 * independently. (When a database is added this becomes a JPA @Entity.)
 */
public record ContactMessage(
        UUID id,
        String name,
        String email,
        String message,
        Instant receivedAt
) {
}
