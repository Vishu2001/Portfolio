package dev.vishal.portfolio.contact.controller;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import dev.vishal.portfolio.contact.dto.ContactRequest;
import dev.vishal.portfolio.contact.dto.ContactResponse;
import dev.vishal.portfolio.contact.service.ContactService;

/**
 * HTTP layer only: route, status code, validation trigger (@Valid), delegate.
 * No business logic, no mapping, no try/catch (errors are handled in
 * common.exception.GlobalExceptionHandler).
 */
@RestController
@RequestMapping("/api/contact")
public class ContactController {

    private final ContactService contactService;

    public ContactController(ContactService contactService) {
        this.contactService = contactService;
    }

    /** 202 Accepted: the message is accepted now and processed (emailed) asynchronously later. */
    @PostMapping
    @ResponseStatus(HttpStatus.ACCEPTED)
    public ContactResponse submit(@Valid @RequestBody ContactRequest request) {
        return contactService.submit(request);
    }
}
