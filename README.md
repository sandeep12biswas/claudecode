# claudecode

Claude Code practice project — a small Spring Boot REST API used to try out Jira-driven,
skill-based feature development with Claude Code.

## Tech stack

- Java 21
- Spring Boot 4.1.0 (Spring Framework 7)
- Maven

## Project structure

```
src/
├── api/
│   └── openapi.yaml                              # OpenAPI spec for the exposed endpoints
├── main/
│   ├── java/org/example/
│   │   ├── Application.java                       # Spring Boot entry point
│   │   └── controller/
│   │       └── GreetingController.java             # GET /api/greeting endpoints
│   └── resources/
│       └── application.properties
└── test/
    └── java/org/example/controller/
        └── GreetingControllerTest.java             # MockMvc tests for GreetingController
```

## Build & run

```bash
mvn spring-boot:run   # start the app (defaults to http://localhost:8080)
mvn test               # run the test suite
```

## API

See [`src/api/openapi.yaml`](src/api/openapi.yaml) for the full spec. Current endpoints:

| Method | Path                   | Description                                  |
| ------ | ---------------------- | -------------------------------------------- |
| GET    | `/api/greeting`        | Greeting via optional `name` query parameter |
| GET    | `/api/greeting/{name}` | Greeting via required `name` path variable   |

## Delivered Jira items

| Jira ID                                                     | Summary                                     | Type  | Status    |
| ----------------------------------------------------------- | ------------------------------------------- | ----- | --------- |
| [SBA-1](https://sandeep12biswas.atlassian.net/browse/SBA-1) | Add GET endpoint to the existing controller | Story | In Review |
