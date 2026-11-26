package dev.vishal.portfolio.contact.dto;

import java.util.UUID;

/** DTO: what the API returns after accepting a message. */
public record ContactResponse(UUID id, String status) {

    public static final String RECEIVED = "received";
}
