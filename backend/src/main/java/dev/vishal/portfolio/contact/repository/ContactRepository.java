package dev.vishal.portfolio.contact.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import dev.vishal.portfolio.contact.model.ContactMessage;

/**
 * DAO / repository contract: how contact messages are stored and read.
 *
 * The service depends on this interface, not on a concrete class. Today the
 * implementation is in-memory; later a Postgres/JPA implementation can replace it
 * without touching the service or controller (Dependency Inversion).
 */
public interface ContactRepository {

    ContactMessage save(ContactMessage message);

    Optional<ContactMessage> findById(UUID id);

    /** Newest first. */
    List<ContactMessage> findRecent(int limit);

    long count();
}
