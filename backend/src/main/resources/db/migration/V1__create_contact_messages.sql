-- V1: table for messages sent through the portfolio's contact form.
-- Flyway runs this once per database and records it in flyway_schema_history.
-- Never edit this file after it has run anywhere: add V2__... instead.

CREATE TABLE contact_messages (
    id          CHAR(36)      NOT NULL,          -- UUID as readable text
    name        VARCHAR(80)   NOT NULL,
    email       VARCHAR(120)  NOT NULL,
    message     VARCHAR(2000) NOT NULL,
    received_at DATETIME(6)   NOT NULL,          -- stored in UTC
    CONSTRAINT pk_contact_messages PRIMARY KEY (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- "Latest messages first" queries sort by this column.
CREATE INDEX idx_contact_messages_received_at ON contact_messages (received_at);
