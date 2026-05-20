# AI PROJECT CONTEXT — Nexora Academy

You are working on a Flutter learning platform called Nexora Academy.

STACK:

* Flutter
* Riverpod
* GoRouter
* Supabase (Auth + Postgres + Storage)

ARCHITECTURE:

* Feature-first Clean Architecture
* Layers:

    * presentation
    * data
    * domain

IMPORTANT RULES:

* Use Riverpod providers
* Keep clean architecture
* Do NOT break existing architecture
* Modify only necessary files
* Reuse existing widgets/services/providers whenever possible
* Keep naming conventions consistent
* Use snake_case for database fields
* Avoid unnecessary refactoring
* Do not change database schema unless required

PROJECT STRUCTURE:

* core/

    * router
    * providers
    * widgets
    * utils
* features/

    * authentication
    * dashboard
    * courses
    * quizzes
    * profile
    * notifications
    * admin
    * video_progress
    * discussion
    * lessons
    * notes
    * discussion
    * streams

CURRENT FEATURES:

* Authentication
* Subjects & lessons
* Video player
* PDF viewer
* Quizzes
* Progress tracking
* Continue watching
* Notifications
* Profile analytics
* Admin dashboard

STATE MANAGEMENT:

* Riverpod
* AsyncValue
* FutureProvider
* StreamProvider
* StateNotifierProvider

BACKEND:

* Supabase Auth
* PostgreSQL
* Supabase Storage
* Realtime subscriptions

DATABASE TABLES:

* subjects
* lessons
* quizzes
* results
* video_progress
* notifications
* assignments
* class_students
* classes
* comments
* dashboard_stats
* levels
* notes
* streams
* user_progress
* users
* profiles

CODING STYLE:

* Small reusable widgets
* Minimal rebuilds
* Use const constructors
* No business logic inside UI
* Repository pattern only
* Providers handle app state

WHEN MODIFYING CODE:

1. First analyze existing architecture
2. Respect current structure
3. Avoid duplicate logic
4. Return COMPLETE modified code
5. Explain modified files only
6. Never rewrite unrelated code

YOUR TASK:
Understand the existing codebase first before generating modifications.
