import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Nexora Academy'**
  String get appTitle;

  /// No description provided for @primarySchool.
  ///
  /// In en, this message translates to:
  /// **'Primary School'**
  String get primarySchool;

  /// No description provided for @middleSchool.
  ///
  /// In en, this message translates to:
  /// **'Middle School'**
  String get middleSchool;

  /// No description provided for @highSchool.
  ///
  /// In en, this message translates to:
  /// **'High School'**
  String get highSchool;

  /// No description provided for @grade1.
  ///
  /// In en, this message translates to:
  /// **'Grade 1'**
  String get grade1;

  /// No description provided for @grade2.
  ///
  /// In en, this message translates to:
  /// **'Grade 2'**
  String get grade2;

  /// No description provided for @grade3.
  ///
  /// In en, this message translates to:
  /// **'Grade 3'**
  String get grade3;

  /// No description provided for @grade4.
  ///
  /// In en, this message translates to:
  /// **'Grade 4'**
  String get grade4;

  /// No description provided for @grade5.
  ///
  /// In en, this message translates to:
  /// **'Grade 5'**
  String get grade5;

  /// No description provided for @grade6.
  ///
  /// In en, this message translates to:
  /// **'Grade 6'**
  String get grade6;

  /// No description provided for @commonCore.
  ///
  /// In en, this message translates to:
  /// **'Common Core'**
  String get commonCore;

  /// No description provided for @firstBac.
  ///
  /// In en, this message translates to:
  /// **'11th Grade'**
  String get firstBac;

  /// No description provided for @secondBac.
  ///
  /// In en, this message translates to:
  /// **'12th Grade'**
  String get secondBac;

  /// No description provided for @selectLevel.
  ///
  /// In en, this message translates to:
  /// **'Select Educational Level'**
  String get selectLevel;

  /// No description provided for @selectSubject.
  ///
  /// In en, this message translates to:
  /// **'Select Subject'**
  String get selectSubject;

  /// No description provided for @joinLive.
  ///
  /// In en, this message translates to:
  /// **'Join Live Session'**
  String get joinLive;

  /// No description provided for @levels.
  ///
  /// In en, this message translates to:
  /// **'Levels'**
  String get levels;

  /// No description provided for @enterEmailToAccess.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to access the live class'**
  String get enterEmailToAccess;

  /// No description provided for @userExample.
  ///
  /// In en, this message translates to:
  /// **'user@example.com'**
  String get userExample;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// No description provided for @joiningLiveSession.
  ///
  /// In en, this message translates to:
  /// **'Joining live session...'**
  String get joiningLiveSession;

  /// No description provided for @joinNow.
  ///
  /// In en, this message translates to:
  /// **'Join Now'**
  String get joinNow;

  /// No description provided for @continueWatching.
  ///
  /// In en, this message translates to:
  /// **'Continue Watching'**
  String get continueWatching;

  /// No description provided for @continueLearning.
  ///
  /// In en, this message translates to:
  /// **'Continue Learning'**
  String get continueLearning;

  /// No description provided for @upNext.
  ///
  /// In en, this message translates to:
  /// **'Up Next'**
  String get upNext;

  /// No description provided for @noSubjectsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No subjects available yet'**
  String get noSubjectsAvailable;

  /// No description provided for @subjectsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Subjects will appear here once they are added.'**
  String get subjectsAppearHere;

  /// No description provided for @noLessonsYet.
  ///
  /// In en, this message translates to:
  /// **'No Lessons Yet'**
  String get noLessonsYet;

  /// No description provided for @lessonsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Lessons for this subject will appear here soon.'**
  String get lessonsAppearHere;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @failedToLoadSubjects.
  ///
  /// In en, this message translates to:
  /// **'Failed to load subjects'**
  String get failedToLoadSubjects;

  /// No description provided for @failedToLoadLessons.
  ///
  /// In en, this message translates to:
  /// **'Failed to load lessons'**
  String get failedToLoadLessons;

  /// No description provided for @completeProgress.
  ///
  /// In en, this message translates to:
  /// **'complete'**
  String get completeProgress;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back,'**
  String get welcomeBack;

  /// No description provided for @readyToLearn.
  ///
  /// In en, this message translates to:
  /// **'Ready to learn something new today?'**
  String get readyToLearn;

  /// No description provided for @dailyGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily Goal'**
  String get dailyGoal;

  /// No description provided for @featuredSubjects.
  ///
  /// In en, this message translates to:
  /// **'Featured Subjects'**
  String get featuredSubjects;

  /// No description provided for @exploreMore.
  ///
  /// In en, this message translates to:
  /// **'Explore more'**
  String get exploreMore;

  /// No description provided for @untitledLesson.
  ///
  /// In en, this message translates to:
  /// **'Untitled Lesson'**
  String get untitledLesson;

  /// No description provided for @loadingSubjects.
  ///
  /// In en, this message translates to:
  /// **'Loading subjects...'**
  String get loadingSubjects;

  /// No description provided for @loadingLessons.
  ///
  /// In en, this message translates to:
  /// **'Loading lessons...'**
  String get loadingLessons;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @helloUser.
  ///
  /// In en, this message translates to:
  /// **'Hello {userName}'**
  String helloUser(String userName);

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @lessons.
  ///
  /// In en, this message translates to:
  /// **'lessons'**
  String get lessons;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @startNow.
  ///
  /// In en, this message translates to:
  /// **'Start Now'**
  String get startNow;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @quizzes.
  ///
  /// In en, this message translates to:
  /// **'Quizzes'**
  String get quizzes;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @middleGrade1.
  ///
  /// In en, this message translates to:
  /// **'7th Grade'**
  String get middleGrade1;

  /// No description provided for @middleGrade2.
  ///
  /// In en, this message translates to:
  /// **'8th Grade'**
  String get middleGrade2;

  /// No description provided for @middleGrade3.
  ///
  /// In en, this message translates to:
  /// **'9th Grade'**
  String get middleGrade3;

  /// No description provided for @tapToExplore.
  ///
  /// In en, this message translates to:
  /// **'Tap to explore subjects'**
  String get tapToExplore;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @scientific.
  ///
  /// In en, this message translates to:
  /// **'Scientific'**
  String get scientific;

  /// No description provided for @literary.
  ///
  /// In en, this message translates to:
  /// **'Literary'**
  String get literary;

  /// No description provided for @sciMath.
  ///
  /// In en, this message translates to:
  /// **'Science Math'**
  String get sciMath;

  /// No description provided for @physics.
  ///
  /// In en, this message translates to:
  /// **'Physics'**
  String get physics;

  /// No description provided for @svt.
  ///
  /// In en, this message translates to:
  /// **'Life & Earth Sciences'**
  String get svt;

  /// No description provided for @economics.
  ///
  /// In en, this message translates to:
  /// **'Economics'**
  String get economics;

  /// No description provided for @humanities.
  ///
  /// In en, this message translates to:
  /// **'Humanities'**
  String get humanities;

  /// No description provided for @literature.
  ///
  /// In en, this message translates to:
  /// **'Literature'**
  String get literature;

  /// No description provided for @electricalTech.
  ///
  /// In en, this message translates to:
  /// **'Electrical Technology'**
  String get electricalTech;

  /// No description provided for @mechanicalTech.
  ///
  /// In en, this message translates to:
  /// **'Mechanical Technology'**
  String get mechanicalTech;

  /// No description provided for @technological.
  ///
  /// In en, this message translates to:
  /// **'Technological'**
  String get technological;

  /// No description provided for @original.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get original;

  /// No description provided for @selectOption.
  ///
  /// In en, this message translates to:
  /// **'Select an option'**
  String get selectOption;

  /// No description provided for @optionFrench.
  ///
  /// In en, this message translates to:
  /// **'French Option'**
  String get optionFrench;

  /// No description provided for @optionArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic Option'**
  String get optionArabic;

  /// No description provided for @optionFrenchDesc.
  ///
  /// In en, this message translates to:
  /// **'Study in French'**
  String get optionFrenchDesc;

  /// No description provided for @optionArabicDesc.
  ///
  /// In en, this message translates to:
  /// **'Study in Arabic'**
  String get optionArabicDesc;

  /// No description provided for @chooseStream.
  ///
  /// In en, this message translates to:
  /// **'Choose Stream'**
  String get chooseStream;

  /// No description provided for @failedToLoadStreams.
  ///
  /// In en, this message translates to:
  /// **'Failed to load streams'**
  String get failedToLoadStreams;

  /// No description provided for @noStreamsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No streams available yet'**
  String get noStreamsAvailable;

  /// No description provided for @streamsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Streams will appear here once they are added.'**
  String get streamsAppearHere;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
