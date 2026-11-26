package dev.vishal.portfolio.contact.service.impl;

import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import dev.vishal.portfolio.contact.dto.ContactRequest;
import dev.vishal.portfolio.contact.dto.ContactResponse;
import dev.vishal.portfolio.contact.mapper.ContactMapper;
import dev.vishal.portfolio.contact.model.ContactMessage;
import dev.vishal.portfolio.contact.repository.ContactRepository;
import dev.vishal.portfolio.contact.service.ContactService;

/**
 * Business rules for contact messages:
 *   1. drop spam (honeypot) without telling the sender
 *   2. map DTO → model, store it, map model → response DTO
 *
 * Next steps plug in here, not in the controller:
 *   - Redis: rate limit per IP before accepting
 *   - Kafka: publish "contact.received" so a consumer sends the email
 */
@Service
public class ContactServiceImpl implements ContactService {

    private static final Logger log = LoggerFactory.getLogger(ContactServiceImpl.class);

    private final ContactRepository repository;
    private final ContactMapper mapper;

    public ContactServiceImpl(ContactRepository repository, ContactMapper mapper) {
        this.repository = repository;
        this.mapper = mapper;
    }

    @Override
    public ContactResponse submit(ContactRequest request) {
        if (isSpam(request)) {
            // Pretend it worked so the bot doesn't learn it was caught; store nothing.
            log.info("Dropped contact message from a likely bot (honeypot filled)");
            return new ContactResponse(UUID.randomUUID(), ContactResponse.RECEIVED);
        }

        ContactMessage saved = repository.save(mapper.toModel(request));
        // Log the id and length only: names, emails and message text are personal data.
        log.info("Contact message {} received ({} chars)", saved.id(), saved.message().length());
        return mapper.toResponse(saved);
    }

    private boolean isSpam(ContactRequest request) {
        return request.website() != null && !request.website().isBlank();
    }
}
