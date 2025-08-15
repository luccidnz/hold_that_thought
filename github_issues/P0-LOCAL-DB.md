---
title: "[P0] Set Up Local Persistence with Isar"
labels: P0, feature, database
---

## Description

Configure and set up the Isar database for local, offline-first storage of thoughts. This is a core requirement for the app to function without a network connection.

## Acceptance Criteria

- [ ] Add `isar` and `isar_flutter_libs` dependencies if not already present.
- [ ] Add `build_runner` and `isar_generator` dev dependencies.
- [ ] Define a `Thought` data class (schema) in `lib/models/thought.dart` that will be stored in Isar. It should include fields like `id`, `title`, `content`, `createdAt`, `audioFilePath`, etc.
- [ ] Annotate the schema with `@collection` and run the build runner to generate the necessary Isar files.
- [ ] Create a "database service" or "repository" class that initializes the Isar instance.
- [ ] Implement methods in the service to perform CRUD operations:
    - `addThought(Thought t)`
    - `getThought(int id)`
    - `getAllThoughts()` (returns a `Future<List<Thought>>`)
    - `updateThought(Thought t)`
    - `deleteThought(int id)`
