package dev.vishal.portfolio.contact.service;

import dev.vishal.portfolio.contact.dto.ContactRequest;
import dev.vishal.portfolio.contact.dto.ContactResponse;

/**
 * Service contract for the contact feature. The controller depends on this interface,
 * so the business logic behind it can change (add Redis rate limiting, publish to Kafka)
 * without the controller knowing.
 */
public interface ContactService {

    /**
     * Accepts a validated contact request.
     * Spam (honeypot filled) is dropped silently but still reported as received.
     */
    ContactResponse submit(ContactRequest request);
}
