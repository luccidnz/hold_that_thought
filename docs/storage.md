# Local Storage with Hive

This document provides an overview of the local storage setup using Hive.

## Setup

The app uses the following Hive packages:
- `hive`: The core Hive database.
- `hive_flutter`: For Flutter-specific utilities.
- `hive_generator`: For generating `TypeAdapter`s.
- `build_runner`: For running the code generator.

Hive is initialized in `main.dart` before the app starts. The following boxes are opened:
- `notes`: Stores the `Note` objects.
- `pendingOps`: Stores the pending `NoteChange` objects for syncing.

## Adapters

`TypeAdapter`s are used to store custom objects in Hive. We have adapters for:
- `Note`: The main note model.
- `NoteChange`: Represents a change to a note (create, update, delete).
- `ChangeType`: An enum for the type of change.

The adapters are generated using `hive_generator` and `build_runner`. To re-generate the adapters, run:
```sh
flutter pub run build_runner build --delete-conflicting-outputs
```

## Limitations

- **Queries:** Hive is a key-value store and has limited support for complex queries. Filtering and searching are done in memory in the `NotesRepository`. For a larger dataset, a more powerful database like Isar or a relational database might be needed.
- **Indexing:** We are not currently using indexes. If performance becomes an issue with a large number of notes, we should consider adding indexes to the fields that are frequently used for filtering.
