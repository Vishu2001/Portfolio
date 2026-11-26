package dev.vishal.portfolio.contact.mapper;

import java.time.Clock;
import java.time.Instant;
import java.util.UUID;

import org.springframework.stereotype.Component;

import dev.vishal.portfolio.contact.dto.ContactRequest;
import dev.vishal.portfolio.contact.dto.ContactResponse;
import dev.vishal.portfolio.contact.model.ContactMessage;

/**
 * Converts between DTOs (API layer) and the domain model (service/repository layers).
 * Keeping conversions here stops controllers and services from filling up with
 * field-by-field copying.
 */
@Component
public class ContactMapper {

    private final Clock clock;

    public ContactMapper(Clock clock) {
        this.clock = clock;
    }

    /** Request DTO → new domain object (fresh id + timestamp, trimmed input). */
    public ContactMessage toModel(ContactRequest request) {
        return new ContactMessage(
                UUID.randomUUID(),
                request.name().strip(),
                request.email().strip(),
                request.message().strip(),
                Instant.now(clock));
    }

    /** Domain object → response DTO. */
    public ContactResponse toResponse(ContactMessage message) {
        return new ContactResponse(message.id(), ContactResponse.RECEIVED);
    }
}
