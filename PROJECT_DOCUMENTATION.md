# Nexora Academy - Developer Documentation 📚

Welcome to the Nexora Academy project! This documentation is designed to help ANY developer quickly understand the project structure, architecture, and data flow so you can start contributing بسهولة (easily).

## 1. Architecture Overview 🏛️
This project follows a **Feature-First Clean Architecture**. Instead of grouping by technical layers (like putting all models together in one root folder), we group by **features** (like putting everything related to `auth` together). This makes the app highly scalable and easier to maintain.

### 🔄 Data Flow (How data moves)
The data flows in a single, predictable direction:
`UI (Screen)` ➔ `Provider (State)` ➔ `Repository (Data Access)` ➔ `Supabase (Backend)`

1. **UI (Screens & Widgets):** The user interface (e.g., `login_screen.dart`). Screens use `ConsumerWidget` to listen to Providers and update when data changes.
2. **Provider (State Management):** Uses **Riverpod** (e.g., `auth_controller.dart`). It holds the business logic, triggers repositories, and updates the UI state (Loading, Success, Error).
3. **Domain (Models):** Simple Dart classes representing the data structure (e.g., `user_profile_model.dart`).
4. **Repository (Data Layer):** The only layer that talks to the outside world (Supabase). E.g., `supabase_auth_repository.dart`.
5. **Supabase (Backend):** Handles Authentication, PostgreSQL database, and Storage (videos/pdfs).

---

## 2. Full Folder Structure 📂
Here is the complete view of the `lib` directory:

```text
lib/
├── main.dart
│
├── core/
│   ├── constants/
│   ├── providers/ (e.g., fullscreen_provider.dart)
│   ├── router/ (e.g., app_router.dart)
│   ├── theme/
│   └── utils/
│
├── features/
│   ├── admin/
│   ├── authentication/
│   ├── courses/
│   ├── dashboard/
│   ├── notifications/
│   ├── profile/
│   ├── quizzes/
│   └── video_progress/
│
└── shared/
    ├── services/
    └── widgets/
```

### Folder Explanations
*   `core/`: 
    * **What it contains:** Essential, app-wide configurations like routing, theme, and global providers. 
    * **Why it exists:** To keep global configs separate from specific feature logic.
*   `features/`: 
    * **What it contains:** The core logic of the app, broken down into independent modules (auth, courses, etc.). 
    * **Why it exists:** To make the codebase scalable. If you need to fix a bug in quizzes, you only look inside the `quizzes` folder without touching other features.
*   `features/[feature_name]/data/`: 
    * **What it contains:** Repositories. 
    * **Why it exists:** To isolate database and API calls.
*   `features/[feature_name]/domain/`: 
    * **What it contains:** Models/Entities. 
    * **Why it exists:** To define how the data is structured securely.
*   `features/[feature_name]/presentation/`: 
    * **What it contains:** Screens, Widgets, and Providers. 
    * **Why it exists:** To handle what the user sees and interacts with.
*   `shared/`: 
    * **What it contains:** Reusable UI widgets and independent services. 
    * **Why it exists:** To prevent code duplication across features.

---

## 3. Core Features Breakdown 🧩

### 🔐 Authentication (`features/authentication/`)
*   **What it does:** Handles user sign-up, login, and session management.
*   **Important Files:**
    *   `supabase_auth_repository.dart`: 
        * **Role:** Talks directly to Supabase Auth to register or log users in/out. 
        * **Dependencies:** Supabase client.
    *   `auth_controller.dart`: 
        * **Role:** Manages the UI state during auth actions (shows loaders, displays error messages). 
        * **Who uses it:** `login_screen.dart` and `register_screen.dart`.

### 📚 Subjects & Courses (`features/courses/`)
*   **What it does:** Fetches and displays subjects and their respective lessons (videos/PDFs).
*   **Important Files:**
    *   `courses_repository.dart`: 
        * **Role:** Runs Postgres queries to fetch subjects and lessons data.
    *   `courses_provider.dart`: 
        * **Role:** Holds the list of subjects so the UI can display them instantly. 
        * **Who uses it:** `subjects_screen.dart` and `dashboard_screen.dart`.
    *   `lesson_video_player.dart`: 
        * **Role:** The custom video player interface inside the app.

### 📝 Quizzes (`features/quizzes/`)
*   **What it does:** Allows users to take quizzes related to lessons and calculates their scores.
*   **Important Files:**
    *   `quiz_repository.dart`: 
        * **Role:** Fetches quiz questions and pushes final scores to the backend `results` table.
    *   `quiz_provider.dart`: 
        * **Role:** Manages the active, live state of a quiz (which question is active, current score counter). 
        * **Who uses it:** `quiz_screen.dart`.

### 📊 Profile & Progress (`features/profile/` & `features/video_progress/`)
*   **What it does:** Tracks user statistics, quiz results, and how far they've watched a specific video.
*   **Important Files:**
    *   `video_progress_repository.dart`: 
        * **Role:** Constantly saves and fetches the exact timestamp a user stopped watching a video.
    *   `profile_providers.dart`: 
        * **Role:** Aggregates database data to show "Total Quizzes Taken" and "Average Scores". 
        * **Who uses it:** `profile_screen.dart`.

### 🔔 Notifications (`features/notifications/`)
*   **What it does:** Notifies users alerts about new lessons and platform updates.
*   **Important Files:**
    *   `notifications_repository.dart`: 
        * **Role:** Fetches the user's notification feed from the `notifications` table.

### 🛠️ Admin Dashboard (`features/admin/`)
*   **What it does:** A restricted area for admins to easily add new subjects, lessons, and quizzes to the platform without touching the database directly.
*   **Important Files:**
    *   `admin_repository.dart`: 
        * **Role:** Contains all the insert/upload logic.

---

## 4. Key Global Files ⚙️

### `lib/main.dart`
*   **Role:** The absolute entry point of the app. It initializes the Supabase connection, wraps the app in Riverpod's `ProviderScope`, and kicks off the UI.
*   **Dependencies:** Supabase, Riverpod, Flutter UI.
*   **Who uses it:** Dart execution engine starts here.

### `lib/core/router/app_router.dart`
*   **Role:** The central nervous system for screen navigation. Built with `go_router`, it defines all URLs/paths (e.g., `/login`, `/dashboard`). It also protects routes (redirects to login if not authenticated).
*   **Dependencies:** `go_router`, Authentication state.
*   **Who uses it:** Every single screen or button that navigates uses it (`context.go(...)` or `context.push(...)`).

---

## 5. Quick Developer Guidelines 💡

1.  **State Management:** Always use **Riverpod**. Replace stful widgets with `ConsumerStatefulWidget` or `ConsumerWidget` to read providers efficiently.
2.  **Database Models:** Supabase uses `snake_case` (e.g., `lesson_id`). When parsing JSON in Dart, map the `snake_case` keys accurately in factory methods to prevent null errors.
3.  **No Logic in UI:** Never run database queries directly inside a `build()` method. Put the API call in a Repository, manage it via a Provider, and read the Provider in the UI.
