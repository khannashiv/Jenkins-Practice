package com.example.demo;

import com.example.demo.controller.HelloController;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

public class HelloControllerTests {

    HelloController controller = new HelloController();

    @Test
    void testHelloReturnsCorrectString() {
        assertEquals("Hello, World!", controller.hello());
    }

    @Test
    void testHealthReturnsOK() {
        assertEquals("OK", controller.health());
    }

    @Test
    void testHelloShouldFail() {
        // Intentionally failing test
        assertEquals("Hi World", controller.hello());
    }
}

