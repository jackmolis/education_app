Project: Nexora Academy

Mobile learning platform built with Flutter.

Stack:
Flutter
Riverpod
GoRouter
Supabase (Auth + Postgres + Storage)

Architecture:
Clean Architecture with feature-based structure.

Main features implemented:
- Authentication (Supabase Auth)
- Subjects and Lessons system
- Video player for lessons
- PDF viewer for summaries
- Quiz system with results
- Progress tracking per subject
- Continue watching videos
- Dashboard with progress bars
- Notifications screen
- Profile screen

Database tables:
users
subjects
lessons
quizzes
results
progress
video_progress
notifications

Supabase Storage buckets:
videos
pdf

Rules:
- Use Riverpod providers
- Keep clean architecture
- Use snake_case database columns
- Modify only necessary files
- Do not change database schema unless required

Current goal:
Continue improving the learning platform and add new features.