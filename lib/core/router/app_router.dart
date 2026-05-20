import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/authentication/data/supabase_auth_repository.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/screens/register_screen.dart';
import '../../features/dashboard/presentation/screens/main_shell_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/courses/presentation/screens/lessons_screen.dart';
import '../../features/courses/presentation/screens/lesson_details_screen.dart';
import '../../features/courses/presentation/screens/pdf_viewer_screen.dart';
import '../../features/quizzes/presentation/screens/quizzes_screen.dart';
import '../../features/quizzes/presentation/screens/quiz_screen.dart';
import '../../features/quizzes/presentation/screens/quiz_result_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/add_lesson_screen.dart';
import '../../features/admin/presentation/screens/add_subject_screen.dart';
import '../../features/admin/presentation/screens/add_quiz_screen.dart';
import '../../features/admin/presentation/screens/manage_subjects_screen.dart';
import '../../features/admin/presentation/screens/manage_lessons_screen.dart';
import '../../features/admin/presentation/screens/manage_quizzes_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/courses/domain/models/lesson_model.dart';
import '../../features/courses/domain/models/subject_model.dart';
import '../../features/courses/presentation/screens/level_subjects_screen.dart';
import '../../features/courses/presentation/screens/primary_levels_screen.dart';
import '../../features/courses/presentation/screens/middle_levels_screen.dart';
import '../../features/courses/presentation/screens/high_levels_screen.dart';
import '../../features/streams/presentation/screens/streams_screen.dart';
import '../../features/streams/presentation/screens/stream_selection_screen.dart';
import '../../features/courses/presentation/screens/option_selection_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isAuthenticated = authState.value != null;
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToRegister = state.matchedLocation == '/register';

      if (!isAuthenticated) {
        if (!isGoingToLogin && !isGoingToRegister) {
          return '/login';
        }
      } else {
        if (isGoingToLogin || isGoingToRegister) {
          return '/dashboard';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/dashboard',
      ),
      GoRoute(path: '/login', builder: (context, state) => LoginScreen(key: state.pageKey)),
      GoRoute(
        path: '/register',
        builder: (context, state) => RegisterScreen(key: state.pageKey),
      ),

      // ==========================================
      // Main Shell with Bottom Navigation Bar
      // ==========================================
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScreen(navigationShell: navigationShell);
        },
        branches: [
          // ── Branch 0: Home / Dashboard ──
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => DashboardScreen(key: state.pageKey),
                routes: [
                  // Level selection screens (pushed from dashboard)
                  GoRoute(
                    path: 'primary',
                    builder: (context, state) => PrimaryLevelsScreen(key: state.pageKey),
                  ),
                  GoRoute(
                    path: 'middle',
                    builder: (context, state) => MiddleLevelsScreen(key: state.pageKey),
                  ),
                  GoRoute(
                    path: 'high',
                    builder: (context, state) => HighLevelsScreen(key: state.pageKey),
                  ),
                ],
              ),
              // Level → Streams Screen
              GoRoute(
                path: '/streams',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>? ?? {};
                  final levelId = extra['levelId'] as String? ?? '';
                  final levelName = extra['levelName'] as String? ?? 'Level';
                  return StreamsScreen(
                    key: state.pageKey,
                    levelId: levelId,
                    levelName: levelName,
                  );
                },
              ),
              // High School Level → Stream Selection Screen
              GoRoute(
                path: '/stream-selection',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>? ?? {};
                  final levelId = extra['levelId'] as String? ?? '';
                  final levelName = extra['levelName'] as String? ?? '';
                  return StreamSelectionScreen(
                    key: state.pageKey,
                    levelId: levelId,
                    levelName: levelName,
                  );
                },
              ),
              // Level → Option Selection Screen
              GoRoute(
                path: '/option-selection',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>? ?? {};
                  final levelId = extra['levelId'] as String? ?? '';
                  final levelName = extra['levelName'] as String? ?? '';
                  final streamId = extra['streamId'] as String?;
                  return OptionSelectionScreen(
                    key: state.pageKey,
                    levelId: levelId,
                    levelName: levelName,
                    streamId: streamId,
                  );
                },
              ),
              // Level → Streams → Subjects screen
              GoRoute(
                path: '/level-subjects',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>? ?? {};
                  final levelId = extra['levelId'] as String? ?? '';
                  final levelName = extra['levelName'] as String? ?? 'Subjects';
                  final streamId = extra['streamId'] as String?;
                  final optionLang = extra['optionLang'] as String?;
                  return LevelSubjectsScreen(
                    key: state.pageKey,
                    levelId: levelId,
                    levelName: levelName,
                    streamId: streamId,
                    optionLang: optionLang,
                  );
                },
              ),
              // Level → Subject → Lessons screen
              GoRoute(
                path: '/levels/:levelId/subjects/:subjectId/lessons',
                builder: (context, state) {
                  final levelId = Uri.decodeComponent(state.pathParameters['levelId']!);
                  final subjectId = Uri.decodeComponent(state.pathParameters['subjectId']!);
                  final extra = state.extra as Map<String, dynamic>? ?? {};
                  final levelName = extra['levelName'] as String? ?? 'Level';
                  final subject = extra['subject'] as SubjectModel?;

                  return LessonsScreen(
                    key: state.pageKey,
                    levelId: levelId,
                    levelName: levelName,
                    subjectId: subjectId,
                    subject: subject,
                  );
                },
                routes: [
                  GoRoute(
                    path: ':lessonId',
                    builder: (context, state) {
                      final levelId = Uri.decodeComponent(state.pathParameters['levelId']!);
                      final subjectId = Uri.decodeComponent(state.pathParameters['subjectId']!);
                      final lessonId = Uri.decodeComponent(state.pathParameters['lessonId']!);
                      final extra = state.extra as Map<String, dynamic>? ?? {};

                      double? startPosition;
                      if (extra.containsKey('startPositionSeconds')) {
                        startPosition = extra['startPositionSeconds'] as double?;
                      }
                      final levelName = extra['levelName'] as String? ?? '';

                      return LessonDetailsScreen(
                        key: state.pageKey,
                        levelId: levelId,
                        levelName: levelName,
                        subjectId: subjectId,
                        lessonId: lessonId,
                        startPositionSeconds: startPosition,
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'details',
                        builder: (context, state) {
                          final levelId = Uri.decodeComponent(state.pathParameters['levelId']!);
                          final subjectId = Uri.decodeComponent(state.pathParameters['subjectId']!);
                          final lessonId = Uri.decodeComponent(state.pathParameters['lessonId']!);
                          final extra = state.extra as Map<String, dynamic>? ?? {};

                          double? startPosition;
                          if (extra.containsKey('startPositionSeconds')) {
                            startPosition = extra['startPositionSeconds'] as double?;
                          }
                          final levelName = extra['levelName'] as String? ?? '';

                          return LessonDetailsScreen(
                            key: state.pageKey,
                            levelId: levelId,
                            levelName: levelName,
                            subjectId: subjectId,
                            lessonId: lessonId,
                            startPositionSeconds: startPosition,
                          );
                        },
                      ),
                      GoRoute(
                        path: 'quiz',
                        builder: (context, state) {
                          final subjectId = Uri.decodeComponent(state.pathParameters['subjectId']!);
                          final lessonId = Uri.decodeComponent(state.pathParameters['lessonId']!);
                          return QuizScreen(
                            key: state.pageKey,
                            subjectId: subjectId,
                            lessonId: lessonId,
                          );
                        },
                        routes: [
                          GoRoute(
                            path: 'result',
                            builder: (context, state) {
                              final subjectId = Uri.decodeComponent(state.pathParameters['subjectId']!);
                              final lessonId = Uri.decodeComponent(state.pathParameters['lessonId']!);
                              return QuizResultScreen(
                                key: state.pageKey,
                                subjectId: subjectId,
                                lessonId: lessonId,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              // Subjects alias route (for continue learning cards)
              GoRoute(
                path: '/subjects',
                redirect: (context, state) => '/dashboard',
              ),
              // Legacy deep-link for lesson details from continue learning
              GoRoute(
                path: '/subjects/:subjectId/lessons/:lessonId/details',
                builder: (context, state) {
                  final subjectId = Uri.decodeComponent(state.pathParameters['subjectId']!);
                  final lessonId = Uri.decodeComponent(state.pathParameters['lessonId']!);
                  final extra = state.extra as Map<String, dynamic>? ?? {};

                  double? startPosition;
                  if (extra.containsKey('startPositionSeconds')) {
                    startPosition = extra['startPositionSeconds'] as double?;
                  }

                  return LessonDetailsScreen(
                    key: state.pageKey,
                    levelId: '',
                    levelName: '',
                    subjectId: subjectId,
                    lessonId: lessonId,
                    startPositionSeconds: startPosition,
                  );
                },
              ),
              // PDF Viewer
              GoRoute(
                path: '/pdf-viewer',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>? ?? {};
                  final pdfUrl = extra['pdfUrl'] as String? ?? '';
                  final title = extra['title'] as String? ?? 'PDF Document';
                  final lessonId = extra['lessonId'] as String? ?? 'unknown';
                  return PdfViewerScreen(
                    key: state.pageKey,
                    pdfUrl: pdfUrl,
                    title: title,
                    lessonId: lessonId,
                  );
                },
              ),
            ],
          ),

          // ── Branch 1: Quizzes ──
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/quizzes',
                builder: (context, state) => QuizzesScreen(key: state.pageKey),
              ),
            ],
          ),

          // ── Branch 2: Profile ──
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => ProfileScreen(key: state.pageKey),
              ),
            ],
          ),
        ],
      ),

      // ==========================================
      // Routes outside the shell (no bottom bar)
      // ==========================================
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const NotificationsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        ),
      ),
      GoRoute(
        path: '/admin',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AdminDashboardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        ),
        routes: [
          GoRoute(
            path: 'manage-subjects',
            builder: (context, state) => ManageSubjectsScreen(key: state.pageKey),
          ),
          GoRoute(
            path: 'manage-lessons',
            builder: (context, state) => ManageLessonsScreen(key: state.pageKey),
          ),
          GoRoute(
            path: 'manage-quizzes',
            builder: (context, state) => ManageQuizzesScreen(key: state.pageKey),
          ),
          GoRoute(
            path: 'add-lesson',
            builder: (context, state) {
              final lesson = state.extra as LessonModel?;
              return AddLessonScreen(key: state.pageKey, lessonToEdit: lesson);
            },
          ),
          GoRoute(
            path: 'add-subject',
            builder: (context, state) => AddSubjectScreen(key: state.pageKey),
          ),
          GoRoute(
            path: 'add-quiz',
            builder: (context, state) => AddQuizScreen(key: state.pageKey),
          ),
        ],
      ),
    ],
  );
});
