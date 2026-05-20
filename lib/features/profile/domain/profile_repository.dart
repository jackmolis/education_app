import 'models/user_profile_model.dart';
import 'models/quiz_result_model.dart';

abstract class ProfileRepository {
  Future<UserProfileModel> getUserProfile(String userId);
  Future<List<QuizResultModel>> getUserQuizResults(String userId);
}
