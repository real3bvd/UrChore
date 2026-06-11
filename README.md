# UrChore

UrChore is a Flutter household chore management application. It helps household
members create or join a home, organize chores, assign responsibilities, use
recurring schedules, and follow weekly progress.

## Main Features

- Local registration, sign-in, and persistent sessions
- Create a household or join one with an invite code
- Custom profile names, colors, hedgehog avatars, camera photos, and gallery
  photos
- Create, edit, assign, complete, undo, and delete chores
- Chore categories, priorities, due dates, and recurring schedules
- Ready-made chore templates
- Weekly calendar indicators for assigned chores
- Household progress and unassigned chore sections
- Member management
- Persistent light and dark themes
- Compact notifications with automatic dismissal and Undo support

## Screens

The project contains distinct screens with different responsibilities:

- Welcome
- Sign In
- Register
- Household Setup
- Home Dashboard
- Chore List
- Add/Edit Chore
- Chore Templates
- Template Category
- Members
- Settings
- Edit Profile
- Profile Picture Picker

## Architecture

The project follows a layered structure:

```text
UI Screen / Controller
        |
        v
Domain Service
        |
        v
Repository
        |
        v
DAO
        |
        v
SQLite or local platform store
```

### UI Layer

`lib/ui/` contains screens, focused widgets, presentation controllers, themes,
and model-to-visual style mappings.

- Screens handle navigation, dialogs, and screen composition.
- Controllers manage loading, form selections, and UI state.
- Widgets render reusable sections and receive data through parameters.
- Presentation colors and icons stay in the UI layer.

### Domain Layer

`lib/domain/` contains application rules and coordinates repository operations.
Examples include recurring chore generation, household filtering, completion
undo, authentication, and member operations.

### Data Layer

`lib/data/` contains:

- Pure data models
- DAO classes for low-level storage operations
- Repository classes that provide clean data-access interfaces
- SQLite database creation, upgrades, and table definitions
- A persistent local store used by web and Windows

The UI does not access DAOs or SQLite directly.

## State Management

The app uses Flutter state tools intentionally:

- `ChangeNotifier` controllers for Home, Chores, Members, and chore-form state
- `AnimatedBuilder` for controller-driven UI updates
- `StatefulWidget` for screen lifecycle and local interactions
- `ValueNotifier` and `ValueListenableBuilder` for theme changes
- `FutureBuilder` for application initialization

After create, update, delete, assign, or complete operations, controllers reload
the required data and notify the UI.

## Database

Android uses `sqflite` with the following tables:

| Table | Purpose |
|---|---|
| `app_users` | Local accounts, profile settings, role, and household links |
| `app_session` | Persisted signed-in user |
| `households` | Household names and invite codes |
| `members` | Household members and avatars |
| `chore_categories` | Category names, icon identifiers, and colors |
| `chores` | Chore details, assignment, status, priority, recurrence, and dates |

DAO classes implement create, read, update, and delete operations. Repositories
abstract those DAOs from the domain services.

## Project Structure

```text
lib/
  data/
    dao/
    database/
    models/
    repository/
  domain/
  ui/
    controllers/
    screens/
    theme/
    widgets/
```

## Supported Targets

- Android: primary mobile target with SQLite persistence
- Web: persistent local browser storage
- Windows: persistent local application storage

Each installation stores its own local data. The project does not use a remote
server or cloud database.

## Run the Project

1. Install Flutter and configure an Android emulator or supported target.
2. Open a terminal in the project directory.
3. Run:

```bash
flutter pub get
flutter run
```

To run specifically on Android:

```bash
flutter devices
flutter run -d <android-device-id>
```

## Verification

```bash
flutter analyze
flutter test
flutter build apk --debug
```

The automated tests cover models, profile widgets, mobile layout, recurrence,
completion and undo, household invite codes, controller state, Home behavior,
member avatars, and notification dismissal.
