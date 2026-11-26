package dev.vishal.portfolio.contact.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * DTO: the JSON body of POST /api/contact, exactly as the client sends it.
 * Only shape + validation rules live here; no behaviour.
 *
 * @param website honeypot field. Hidden in the form, so people leave it empty; bots fill it.
 */
public record ContactRequest(
        @NotBlank(message = "Please tell me your name")
        @Size(max = 80, message = "Name must be at most 80 characters")
        String name,

        @NotBlank(message = "Please add your email so I can reply")
        @Email(message = "That doesn't look like a valid email")
        @Size(max = 120, message = "Email must be at most 120 characters")
        String email,

        @NotBlank(message = "Please write a message")
        @Size(min = 10, max = 2000, message = "Message must be between 10 and 2000 characters")
        String message,

        String website
) {
}
