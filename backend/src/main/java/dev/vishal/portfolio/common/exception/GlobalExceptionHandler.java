package dev.vishal.portfolio.common.exception;

import java.util.LinkedHashMap;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.FieldError;
import org.springframework.web.ErrorResponse;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * One place that turns exceptions into RFC 9457 "problem details" JSON, so no controller
 * needs try/catch. Example:
 * <pre>
 * { "status": 400, "title": "Invalid request", "detail": "...",
 *   "errors": { "email": "That doesn't look like a valid email" } }
 * </pre>
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    /** @Valid failed → 400 with one message per field. */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    ProblemDetail handleValidation(MethodArgumentNotValidException ex) {
        Map<String, String> errors = new LinkedHashMap<>();
        for (FieldError fe : ex.getBindingResult().getFieldErrors()) {
            errors.putIfAbsent(fe.getField(), fe.getDefaultMessage()); // first error per field
        }
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, "Some fields need fixing.");
        problem.setTitle("Invalid request");
        problem.setProperty("errors", errors);
        return problem;
    }

    /** Missing body / broken JSON → 400. */
    @ExceptionHandler(HttpMessageNotReadableException.class)
    ProblemDetail handleUnreadable(HttpMessageNotReadableException ex) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
                HttpStatus.BAD_REQUEST, "The request body is missing or isn't valid JSON.");
        problem.setTitle("Malformed request");
        return problem;
    }

    /** Anything unexpected → 500 without leaking internals to the client (details go to the log). */
    @ExceptionHandler(Exception.class)
    ProblemDetail handleUnexpected(Exception ex) {
        // Spring's own HTTP errors (404 no such route, 405 wrong method, ...) already carry the
        // right status; keep it instead of turning them into a 500.
        if (ex instanceof ErrorResponse errorResponse) {
            return errorResponse.getBody();
        }
        log.error("Unhandled error", ex);
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
                HttpStatus.INTERNAL_SERVER_ERROR, "Something went wrong on our side. Please try again.");
        problem.setTitle("Internal error");
        return problem;
    }
}
