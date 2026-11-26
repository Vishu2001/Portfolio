package dev.vishal.portfolio.contact.service.impl;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import dev.vishal.portfolio.contact.dto.ContactRequest;
import dev.vishal.portfolio.contact.dto.ContactResponse;
import dev.vishal.portfolio.contact.mapper.ContactMapper;
import dev.vishal.portfolio.contact.model.ContactMessage;
import dev.vishal.portfolio.contact.repository.ContactRepository;

/**
 * Pure unit test: no Spring context, the repository is a Mockito mock.
 * Possible only because the service depends on the ContactRepository interface.
 */
@ExtendWith(MockitoExtension.class)
class ContactServiceImplTest {

    private static final Instant NOW = Instant.parse("2026-11-26T10:00:00Z");

    @Mock
    ContactRepository repository;

    ContactServiceImpl service;

    @BeforeEach
    void setUp() {
        ContactMapper mapper = new ContactMapper(Clock.fixed(NOW, ZoneOffset.UTC));
        service = new ContactServiceImpl(repository, mapper);
    }

    @Test
    void storesTrimmedMessageAndReturnsItsId() {
        when(repository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        ContactResponse response = service.submit(
                new ContactRequest("  Asha ", " asha@example.com ", "  Hello there, Vishal!  ", null));

        ArgumentCaptor<ContactMessage> saved = ArgumentCaptor.forClass(ContactMessage.class);
        verify(repository).save(saved.capture());
        assertThat(saved.getValue().name()).isEqualTo("Asha");
        assertThat(saved.getValue().email()).isEqualTo("asha@example.com");
        assertThat(saved.getValue().message()).isEqualTo("Hello there, Vishal!");
        assertThat(saved.getValue().receivedAt()).isEqualTo(NOW);

        assertThat(response.id()).isEqualTo(saved.getValue().id());
        assertThat(response.status()).isEqualTo(ContactResponse.RECEIVED);
    }

    @Test
    void dropsSpamWithoutStoringButStillReportsReceived() {
        ContactResponse response = service.submit(
                new ContactRequest("Bot", "bot@spam.test", "Buy cheap followers now!!!", "http://spam.test"));

        verify(repository, never()).save(any());
        assertThat(response.status()).isEqualTo(ContactResponse.RECEIVED);
        assertThat(response.id()).isNotNull();
    }
}
