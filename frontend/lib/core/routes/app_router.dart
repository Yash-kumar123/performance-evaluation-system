import 'package:go_router/go_router.dart';
import '../../screens/splash_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/employee_dashboard_screen.dart';
import '../../screens/manager_dashboard_screen.dart';
import '../../screens/team_screen.dart';
import '../../screens/create_evaluation_screen.dart';
import '../../screens/submitted_evaluations_screen.dart';
import '../../screens/hr_dashboard_screen.dart';
import '../../screens/managers_progress_screen.dart';
import '../../screens/pending_reviews_screen.dart';
import '../../screens/completed_reviews_screen.dart';
import '../../screens/hr_teams_screen.dart';
import '../../screens/profile_screen.dart';
import '../../screens/evaluation_details_screen.dart';
import '../../screens/history_screen.dart';
import '../../screens/review_cycles_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/employee',
        name: 'employee_dashboard',
        builder: (context, state) => const EmployeeDashboardScreen(),
      ),

      // Manager Routes
      GoRoute(
        path: '/manager',
        name: 'manager_dashboard',
        builder: (context, state) => const ManagerDashboardScreen(),
      ),
      GoRoute(
        path: '/manager/team',
        name: 'manager_team',
        builder: (context, state) => const TeamScreen(),
      ),
      GoRoute(
        path: '/manager/create-evaluation',
        name: 'create_evaluation',
        builder: (context, state) {
          final query = state.uri.queryParameters;
          return CreateEvaluationScreen(
            employeeId: query['employeeId'] ?? '',
            employeeName: query['employeeName'] ?? 'Employee',
            cycleId: query['cycleId'] ?? '',
            evaluationId: query['evaluationId'],
          );
        },
      ),
      GoRoute(
        path: '/manager/submitted',
        name: 'submitted_evaluations',
        builder: (context, state) => const SubmittedEvaluationsScreen(),
      ),

      // HR Routes
      GoRoute(
        path: '/hr',
        name: 'hr_dashboard',
        builder: (context, state) => const HRDashboardScreen(),
      ),
      GoRoute(
        path: '/hr/teams',
        name: 'hr_teams',
        builder: (context, state) => const HRTeamsScreen(),
      ),
      GoRoute(
        path: '/hr/managers',
        name: 'managers_progress',
        builder: (context, state) => const ManagersProgressScreen(),
      ),
      GoRoute(
        path: '/hr/pending',
        name: 'pending_reviews',
        builder: (context, state) => const PendingReviewsScreen(),
      ),
      GoRoute(
        path: '/hr/completed',
        name: 'completed_reviews',
        builder: (context, state) => const CompletedReviewsScreen(),
      ),

      // Shared Navigation Routes
      GoRoute(
        path: '/cycles',
        name: 'review_cycles',
        builder: (context, state) => const ReviewCyclesScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/evaluation/:id',
        name: 'evaluation_details',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return EvaluationDetailsScreen(evaluationId: id);
        },
      ),
    ],
  );
}
