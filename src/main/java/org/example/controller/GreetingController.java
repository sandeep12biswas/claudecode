package org.example.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
public class GreetingController {

    private static final Logger logger = LoggerFactory.getLogger(GreetingController.class);

    @GetMapping("/api/greeting")
    public String greeting(@RequestParam(defaultValue = "World") String name) {
        logger.info("Received greeting request via query param, name={}", name);
        String greeting = buildGreeting(name);
        logger.debug("Resolved greeting: {}", greeting);
        return greeting;
    }

    @GetMapping("/api/greeting/{name}")
    public String greetingByName(@PathVariable String name) {
        logger.info("Received greeting request via path variable, name={}", name);
        if (name == null || name.isBlank()) {
            logger.error("Rejected greeting request: name path variable is blank");
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "name must not be blank");
        }
        String greeting = buildGreeting(name);
        logger.debug("Resolved greeting: {}", greeting);
        return greeting;
    }

    private String buildGreeting(String name) {
        return "Hello, " + name + "!";
    }
}
