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
import '../../features/admin/presentation/screens/manage_exams_screen.dart';
import '../../features/admin/presentation/screens/add_exam_screen.dart';
import '../../features/admin/presentation/screens/manage_exam_models_screen.dart';
import '../../features/admin/presentation/screens/add_exam_model_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/courses/domain/models/lesson_model.dart';
import '../../features/courses/domain/models/subject_model.dart';
import '../../features/courses/presentation/screens/level_subjects_screen.dart';
import '../../features/courses/presentation/screens/subject_sections_screen.dart';
import '../../features/courses/presentation/screens/section_placeholder_screen.dart';
import '../../features/courses/presentation/screens/solved_exercises_screen.dart';
import '../../features/courses/presentation/screens/lesson_exercises_screen.dart';
import '../../features/courses/presentation/screens/semester_exams_screen.dart';
import '../../features/courses/presentation/screens/exam_models_screen.dart';
import '../../features/courses/domain/models/exam_model.dart';
import '../../features/courses/domain/models/exam_model_entity.dart';
import '../../features/courses/presentation/screens/primary_levels_screen.dart';
import '../../features/courses/presentation/screens/middle_levels_screen.dart';
import '../../features/courses/presentation/screens/high_levels_screen.dart';
import '../../features/streams/presentation/screens/streams_screen.dart';
import '../../features/streams/presentation/screens/stream_selection_screen.dart';
import '../../features/courses/presentation/screens/option_selection_screen.dart';
import '../../features/courses/presentation/screens/home_assignments_screen.dart';
import '../../features/courses/presentation/screens/homework_submission_screen.dart';
import '../../features/admin/presentation/screens/manage_assignments_screen.dart';
import '../../features/admin/presentation/screens/add_assignment_screen.dart';
import '../../features/admin/presentation/screens/manage_submissions_screen.dart';
import '../../features/admin/presentation/screens/grade_submission_screen.dart';
import '../../features/courses/domain/models/home_assignment_model.dart';

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
              // Subject → Sections screen (Level → Subject → Sections → Content)
              GoRoute(
                path: '/levels/:levelId/subjects/:subjectId/sections',
                builder: (context, state) {
                  final levelId = Uri.decodeComponent(state.pathParameters['levelId']!);
                  final subjectId = Uri.decodeComponent(state.pathParameters['subjectId']!);
                  final extra = state.extra as Map<String, dynamic>? ?? {};
                  final levelName = extra['levelName'] as String? ?? 'Level';
                  final subject = extra['subject'] as SubjectModel?;

                  return SubjectSectionsScreen(
                    key: state.pageKey,
                    levelId: levelId,
                    levelName: levelName,
                    subjectId: subjectId,
                    subject: subject,
                  );
                },
              ),
              // Placeholder for sections without content yet
              GoRoute(
                path: '/section-placeholder',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>? ?? {};
                  final title = extra['title'] as String? ?? '';
                  return SectionPlaceholderScreen(
                    key: state.pageKey,
                    title: title,
                  );
                },
              ),
              // Solved Exercises → lesson list for the subject
              GoRoute(
                path: '/levels/:levelId/subjects/:subjectId/solved-exercises',
                builder: (context, state) {
                  final levelId = Uri.decodeComponent(state.pathParameters['levelId']!);
                  final subjectId = Uri.decodeComponent(state.pathParameters['subjectId']!);
                  final extra = state.extra as Map<String, dynamic>? ?? {};
                  final levelName = extra['levelName'] as String? ?? 'Level';
                  final subject = extra['subject'] as SubjectModel?;

                  return SolvedExercisesScreen(
                    key: state.pageKey,
                    levelId: levelId,
                    levelName: levelName,
                    subjectId: subjectId,
                    subject: subject,
                  );
                },
              ),
              // Exercises belonging to a specific lesson (Solved Exercises → lesson)
              GoRoute(
                path: '/levels/:levelId/subjects/:subjectId/exercises/:lessonId',
                builder: (context, state) {
                  final lessonId = Uri.decodeComponent(state.pathParameters['lessonId']!);
                  final extra = state.extra as Map<String, dynamic>? ?? {};
                  final lessonTitle = extra['lessonTitle'] as String? ?? '';
                  return LessonExercisesScreen(
                    key: state.pageKey,
                    lessonId: lessonId,
                    lessonTitle: lessonTitle,
                  );
                },
              ),
              // Semester exams list (semester passed via query: ?semester=1|2)
              GoRoute(
                path: '/levels/:levelId/subjects/:subjectId/exams',
                builder: (context, state) {
                  final levelId = Uri.decodeComponent(state.pathParameters['levelId']!);
                  final subjectId = Uri.decodeComponent(state.pathParameters['subjectId']!);
                  final extra = state.extra as Map<String, dynamic>? ?? {};
                  final levelName = extra['levelName'] as String? ?? 'Level';
                  final subject = extra['subject'] as SubjectModel?;
                  final semester =
                      int.tryParse(state.uri.queryParameters['semester'] ?? '1') ?? 1;

                  return SemesterExamsScreen(
                    key: state.pageKey,
                    levelId: levelId,
                    levelName: levelName,
                    subjectId: subjectId,
                    semester: semester,
                    subject: subject,
                  );
                },
              ),
              // Exam → Models list (each model has exam + correction PDF)
              GoRoute(
                path: '/levels/:levelId/subjects/:subjectId/exams/:examId',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>? ?? {};
                  final exam = extra['exam'] as ExamModel?;
                  if (exam == null) {
                    // No exam payload (e.g. cold deep-link) — show placeholder.
                    return const SectionPlaceholderScreen(title: '');
                  }
                  return ExamModelsScreen(key: state.pageKey, exam: exam);
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
              // Legacy deep-link for lesson details (from notifications / continue learning)
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

              // ── Home Assignments list for a subject ──
              GoRoute(
                path: '/levels/:levelId/subjects/:subjectId/assignments',
                builder: (context, state) {
                  final levelId = Uri.decodeComponent(state.pathParameters['levelId']!);
                  final subjectId = Uri.decodeComponent(state.pathParameters['subjectId']!);
                  final extra = state.extra as Map<String, dynamic>? ?? {};
                  final levelName = extra['levelName'] as String? ?? '';
                  final subject = extra['subject'] as SubjectModel?;
                  return HomeAssignmentsScreen(
                    key: state.pageKey,
                    levelId: levelId,
                    levelName: levelName,
                    subjectId: subjectId,
                    subject: subject,
                  );
                },
              ),

              // ── Student submission screen for one assignment ──
              GoRoute(
                path: '/levels/:levelId/subjects/:subjectId/assignments/:assignmentId/submit',
                builder: (context, state) {
                  final levelId = Uri.decodeComponent(state.pathParameters['levelId']!);
                  final subjectId = Uri.decodeComponent(state.pathParameters['subjectId']!);
                  final assignmentId = Uri.decodeComponent(state.pathParameters['assignmentId']!);
                  return HomeworkSubmissionScreen(
                    key: state.pageKey,
                    levelId: levelId,
                    subjectId: subjectId,
                    assignmentId: assignmentId,
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
          GoRoute(
            path: 'manage-exams',
            builder: (context, state) => ManageExamsScreen(key: state.pageKey),
          ),
          GoRoute(
            path: 'add-exam',
            builder: (context, state) {
              final exam = state.extra as ExamModel?;
              return AddExamScreen(key: state.pageKey, examToEdit: exam);
            },
          ),
          GoRoute(
            path: 'exam-models',
            builder: (context, state) {
              final exam = state.extra as ExamModel?;
              if (exam == null) {
                return const SectionPlaceholderScreen(title: '');
              }
              return ManageExamModelsScreen(key: state.pageKey, exam: exam);
            },
          ),
          GoRoute(
            path: 'add-exam-model',
            builder: (context, state) {
              // extra can be:
              //   null                  → Add mode, no preselected exam
              //   ExamModel             → Add mode with preselected exam
              //   ExamModelEntity       → Edit mode (no exam locked)
              //   Map with both keys    → Edit mode with preselected exam
              final extra = state.extra;
              ExamModelEntity? modelToEdit;
              ExamModel? preselectedExam;
              if (extra is Map<String, dynamic>) {
                modelToEdit = extra['model'] as ExamModelEntity?;
                preselectedExam = extra['exam'] as ExamModel?;
              } else if (extra is ExamModelEntity) {
                modelToEdit = extra;
              } else if (extra is ExamModel) {
                preselectedExam = extra;
              }
              return AddExamModelScreen(
                key: state.pageKey,
                modelToEdit: modelToEdit,
                preselectedExam: preselectedExam,
              );
            },
          ),

          // ── Assignments ──
          GoRoute(
            path: 'manage-assignments',
            builder: (context, state) =>
                ManageAssignmentsScreen(key: state.pageKey),
            routes: [
              GoRoute(
                path: ':assignmentId/submissions',
                builder: (context, state) {
                  final assignmentId = Uri.decodeComponent(
                      state.pathParameters['assignmentId']!);
                  return ManageSubmissionsScreen(
                    key: state.pageKey,
                    assignmentId: assignmentId,
                  );
                },
                routes: [
                  GoRoute(
                    path: ':submissionId/grade',
                    builder: (context, state) {
                      final submissionId = Uri.decodeComponent(
                          state.pathParameters['submissionId']!);
                      final data =
                          state.extra as Map<String, dynamic>? ?? {};
                      return GradeSubmissionScreen(
                        key: state.pageKey,
                        submissionId: submissionId,
                        submissionData: data,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: 'add-assignment',
            builder: (context, state) {
              final assignment = state.extra as HomeAssignmentModel?;
              return AddAssignmentScreen(
                  key: state.pageKey, assignmentToEdit: assignment);
            },
          ),
        ],
      ),
    ],
  );
});
