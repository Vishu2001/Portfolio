package dev.vishal.portfolio.contact.repository.impl;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Repository;

import dev.vishal.portfolio.contact.entity.ContactMessageEntity;
import dev.vishal.portfolio.contact.model.ContactMessage;
import dev.vishal.portfolio.contact.repository.ContactRepository;
import dev.vishal.portfolio.contact.repository.jpa.ContactMessageJpaRepository;

/**
 * MySQL-backed implementation of the ContactRepository contract.
 * Replaces the old in-memory version; the service and controller didn't change.
 * Converts domain model ⇄ JPA entity and delegates to Spring Data.
 */
@Repository
public class JpaContactRepository implements ContactRepository {

    private final ContactMessageJpaRepository jpa;

    public JpaContactRepository(ContactMessageJpaRepository jpa) {
        this.jpa = jpa;
    }

    @Override
    public ContactMessage save(ContactMessage message) {
        return toModel(jpa.save(toEntity(message)));
    }

    @Override
    public Optional<ContactMessage> findById(UUID id) {
        return jpa.findById(id.toString()).map(JpaContactRepository::toModel);
    }

    @Override
    public List<ContactMessage> findRecent(int limit) {
        return jpa.findAllByOrderByReceivedAtDesc(PageRequest.of(0, limit)).stream()
                .map(JpaContactRepository::toModel)
                .toList();
    }

    @Override
    public long count() {
        return jpa.count();
    }

    private static ContactMessageEntity toEntity(ContactMessage m) {
        return new ContactMessageEntity(m.id().toString(), m.name(), m.email(), m.message(), m.receivedAt());
    }

    private static ContactMessage toModel(ContactMessageEntity e) {
        return new ContactMessage(UUID.fromString(e.getId()), e.getName(), e.getEmail(), e.getMessage(), e.getReceivedAt());
    }
}
