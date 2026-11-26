package dev.vishal.portfolio.contact.repository.jpa;

import java.util.List;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import dev.vishal.portfolio.contact.entity.ContactMessageEntity;

/**
 * Spring Data generates the implementation at runtime (save, findById, count, ...).
 * Only used inside the repository layer; the service never sees it.
 */
public interface ContactMessageJpaRepository extends JpaRepository<ContactMessageEntity, String> {

    /** Derived query: ORDER BY received_at DESC, limited by the Pageable. */
    List<ContactMessageEntity> findAllByOrderByReceivedAtDesc(Pageable pageable);
}
