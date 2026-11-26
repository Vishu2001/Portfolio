package dev.vishal.portfolio.contact.entity;

import java.time.Instant;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * JPA entity = one row of the contact_messages table (created by Flyway V1).
 *
 * Kept separate from the domain model (model.ContactMessage) so database details
 * (annotations, no-arg constructor, column names) never leak into the service layer.
 * The repository implementation converts between the two.
 */
@Entity
@Table(name = "contact_messages")
public class ContactMessageEntity {

    @Id
    @Column(length = 36)
    private String id;

    @Column(nullable = false, length = 80)
    private String name;

    @Column(nullable = false, length = 120)
    private String email;

    @Column(nullable = false, length = 2000)
    private String message;

    @Column(name = "received_at", nullable = false)
    private Instant receivedAt;

    /** Required by JPA. */
    protected ContactMessageEntity() {
    }

    public ContactMessageEntity(String id, String name, String email, String message, Instant receivedAt) {
        this.id = id;
        this.name = name;
        this.email = email;
        this.message = message;
        this.receivedAt = receivedAt;
    }

    public String getId() { return id; }
    public String getName() { return name; }
    public String getEmail() { return email; }
    public String getMessage() { return message; }
    public Instant getReceivedAt() { return receivedAt; }
}
