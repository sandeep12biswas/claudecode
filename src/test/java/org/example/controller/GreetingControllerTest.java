package org.example.controller;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.test.web.servlet.MockMvc;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(GreetingController.class)
class GreetingControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void greeting_withNoNameParam_defaultsToWorld() throws Exception {
        mockMvc.perform(get("/api/greeting"))
                .andExpect(status().isOk())
                .andExpect(content().string("Hello, World!"));
    }

    @Test
    void greeting_withNameQueryParam_usesGivenName() throws Exception {
        mockMvc.perform(get("/api/greeting").param("name", "Sandeep"))
                .andExpect(status().isOk())
                .andExpect(content().string("Hello, Sandeep!"));
    }

    @Test
    void greetingByName_withPathVariable_usesGivenName() throws Exception {
        mockMvc.perform(get("/api/greeting/{name}", "Sandeep"))
                .andExpect(status().isOk())
                .andExpect(content().string("Hello, Sandeep!"));
    }

    @Test
    void greetingByName_withBlankPathVariable_returnsBadRequest() throws Exception {
        mockMvc.perform(get("/api/greeting/{name}", " "))
                .andExpect(status().isBadRequest());
    }
}
