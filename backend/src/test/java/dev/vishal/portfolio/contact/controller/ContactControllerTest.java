package dev.vishal.portfolio.contact.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.notNullValue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import dev.vishal.portfolio.TestcontainersConfiguration;
import dev.vishal.portfolio.contact.repository.ContactRepository;

/** Full-stack HTTP tests: controller → service → repository → MySQL, plus error handling and CORS. */
@Import(TestcontainersConfiguration.class)
@SpringBootTest
@AutoConfigureMockMvc
class ContactControllerTest {

    @Autowired
    MockMvc mvc;

    @Autowired
    ContactRepository repository;

    private static final String VALID = """
            {"name": "Asha", "email": "asha@example.com", "message": "Hi Vishal, let's talk about a role."}
            """;

    @Test
    void acceptsAValidMessage() throws Exception {
        mvc.perform(post("/api/contact").contentType(MediaType.APPLICATION_JSON).content(VALID))
                .andExpect(status().isAccepted())
                .andExpect(jsonPath("$.status").value("received"))
                .andExpect(jsonPath("$.id", notNullValue()));

        // It's really in MySQL now: read it back through the repository
        assertThat(repository.findRecent(100))
                .anySatisfy(m -> {
                    assertThat(m.email()).isEqualTo("asha@example.com");
                    assertThat(m.receivedAt()).isNotNull();
                });
    }

    @Test
    void persistedMessageCanBeFoundById() throws Exception {
        String json = mvc.perform(post("/api/contact").contentType(MediaType.APPLICATION_JSON).content(VALID))
                .andExpect(status().isAccepted())
                .andReturn().getResponse().getContentAsString();
        String id = json.replaceAll(".*\"id\":\"([^\"]+)\".*", "$1");

        assertThat(repository.findById(java.util.UUID.fromString(id)))
                .hasValueSatisfying(m -> assertThat(m.name()).isEqualTo("Asha"));
    }

    @Test
    void returnsFieldErrorsForInvalidInput() throws Exception {
        String body = """
                {"name": "", "email": "not-an-email", "message": "short"}
                """;
        mvc.perform(post("/api/contact").contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.title").value("Invalid request"))
                .andExpect(jsonPath("$.errors.name").value("Please tell me your name"))
                .andExpect(jsonPath("$.errors.email").value("That doesn't look like a valid email"))
                .andExpect(jsonPath("$.errors.message").value("Message must be between 10 and 2000 characters"));
    }

    @Test
    void rejectsMalformedJson() throws Exception {
        mvc.perform(post("/api/contact").contentType(MediaType.APPLICATION_JSON).content("{oops"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.title").value("Malformed request"));
    }

    @Test
    void wrongMethodStays405NotA500() throws Exception {
        mvc.perform(get("/api/contact")).andExpect(status().isMethodNotAllowed());
    }

    @Test
    void unknownRouteStays404NotA500() throws Exception {
        mvc.perform(get("/api/nope")).andExpect(status().isNotFound());
    }

    @Test
    void allowsTheFrontendOriginViaCors() throws Exception {
        mvc.perform(options("/api/contact")
                        .header("Origin", "http://localhost:3000")
                        .header("Access-Control-Request-Method", "POST"))
                .andExpect(status().isOk())
                .andExpect(header().string("Access-Control-Allow-Origin", "http://localhost:3000"));
    }

    @Test
    void blocksUnknownOriginsViaCors() throws Exception {
        mvc.perform(options("/api/contact")
                        .header("Origin", "https://evil.example")
                        .header("Access-Control-Request-Method", "POST"))
                .andExpect(status().isForbidden());
    }
}
