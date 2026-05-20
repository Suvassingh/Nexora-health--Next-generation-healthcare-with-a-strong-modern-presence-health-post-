import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ne.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ne')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Telemedical App'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @donthaveanaccout.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account ?'**
  String get donthaveanaccout;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup;

  /// No description provided for @bookAppointment.
  ///
  /// In en, this message translates to:
  /// **'Book Appointment'**
  String get bookAppointment;

  /// No description provided for @doctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctor;

  /// No description provided for @patient.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patient;

  /// No description provided for @homeScreen.
  ///
  /// In en, this message translates to:
  /// **'Home Screen'**
  String get homeScreen;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @alreadyhaveanaccount.
  ///
  /// In en, this message translates to:
  /// **'Already Have An Account ?'**
  String get alreadyhaveanaccount;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @others.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get others;

  /// No description provided for @confirmpassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmpassword;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @namaste.
  ///
  /// In en, this message translates to:
  /// **'Namaste'**
  String get namaste;

  /// No description provided for @howareyoufeelingtoday.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling today?'**
  String get howareyoufeelingtoday;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @appointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get appointments;

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updated;

  /// No description provided for @statusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Status updated'**
  String get statusUpdated;

  /// No description provided for @couldNotUpdate.
  ///
  /// In en, this message translates to:
  /// **'Could not update'**
  String get couldNotUpdate;

  /// No description provided for @confirmAppointmentQ.
  ///
  /// In en, this message translates to:
  /// **'Confirm appointment?'**
  String get confirmAppointmentQ;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @appointmentConfirmedFor.
  ///
  /// In en, this message translates to:
  /// **'Appointment confirmed for {name}'**
  String appointmentConfirmedFor(String name);

  /// No description provided for @declineAppointmentQ.
  ///
  /// In en, this message translates to:
  /// **'Decline appointment?'**
  String get declineAppointmentQ;

  /// No description provided for @declineWarning.
  ///
  /// In en, this message translates to:
  /// **'This will cancel the booking.'**
  String get declineWarning;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @appointmentDeclined.
  ///
  /// In en, this message translates to:
  /// **'Appointment declined'**
  String get appointmentDeclined;

  /// No description provided for @markAsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark as completed?'**
  String get markAsCompleted;

  /// No description provided for @consultationEndedWith.
  ///
  /// In en, this message translates to:
  /// **'Consultation with {name} has ended.'**
  String consultationEndedWith(String name);

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @consultationMarkedComplete.
  ///
  /// In en, this message translates to:
  /// **'Consultation marked complete'**
  String get consultationMarkedComplete;

  /// No description provided for @markAsNoShow.
  ///
  /// In en, this message translates to:
  /// **'Mark as no-show?'**
  String get markAsNoShow;

  /// No description provided for @patientDidNotJoin.
  ///
  /// In en, this message translates to:
  /// **'{name} did not join the appointment.'**
  String patientDidNotJoin(String name);

  /// No description provided for @noShow.
  ///
  /// In en, this message translates to:
  /// **'No Show'**
  String get noShow;

  /// No description provided for @markedAsNoShow.
  ///
  /// In en, this message translates to:
  /// **'Marked as no-show'**
  String get markedAsNoShow;

  /// No description provided for @noPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending requests'**
  String get noPendingRequests;

  /// No description provided for @pendingAppearsHere.
  ///
  /// In en, this message translates to:
  /// **'New appointment requests will appear here'**
  String get pendingAppearsHere;

  /// No description provided for @todayAppearsHere.
  ///
  /// In en, this message translates to:
  /// **'Your confirmed appointments for today appear here'**
  String get todayAppearsHere;

  /// No description provided for @upcomingAppearsHere.
  ///
  /// In en, this message translates to:
  /// **'Future confirmed appointments will appear here'**
  String get upcomingAppearsHere;

  /// No description provided for @noCompletedConsultations.
  ///
  /// In en, this message translates to:
  /// **'No completed consultations yet'**
  String get noCompletedConsultations;

  /// No description provided for @completedAppearsHere.
  ///
  /// In en, this message translates to:
  /// **'Consultations you finish will appear here'**
  String get completedAppearsHere;

  /// No description provided for @couldNotLoadAppointments.
  ///
  /// In en, this message translates to:
  /// **'Could not load appointments'**
  String get couldNotLoadAppointments;

  /// No description provided for @patientMessages.
  ///
  /// In en, this message translates to:
  /// **'Patient Messages'**
  String get patientMessages;

  /// No description provided for @noPatientChatsYet.
  ///
  /// In en, this message translates to:
  /// **'No patient chats yet'**
  String get noPatientChatsYet;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @callFailed.
  ///
  /// In en, this message translates to:
  /// **'Call Failed'**
  String get callFailed;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @noAppointmentsToday.
  ///
  /// In en, this message translates to:
  /// **'No appointments today'**
  String get noAppointmentsToday;

  /// No description provided for @noUpcomingAppointments.
  ///
  /// In en, this message translates to:
  /// **'No upcoming appointments'**
  String get noUpcomingAppointments;

  /// No description provided for @noCancelledAppointments.
  ///
  /// In en, this message translates to:
  /// **'No cancelled appointments'**
  String get noCancelledAppointments;

  /// No description provided for @cancelledAppearsHere.
  ///
  /// In en, this message translates to:
  /// **'Cancelled appointments will appear here'**
  String get cancelledAppearsHere;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @ringing.
  ///
  /// In en, this message translates to:
  /// **'Ringing...'**
  String get ringing;

  /// No description provided for @callError.
  ///
  /// In en, this message translates to:
  /// **'Call Error'**
  String get callError;

  /// No description provided for @settingUpCall.
  ///
  /// In en, this message translates to:
  /// **'Setting up call...'**
  String get settingUpCall;

  /// No description provided for @mute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mute;

  /// No description provided for @unmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmute;

  /// No description provided for @camOn.
  ///
  /// In en, this message translates to:
  /// **'Camera On'**
  String get camOn;

  /// No description provided for @camOff.
  ///
  /// In en, this message translates to:
  /// **'Camera Off'**
  String get camOff;

  /// No description provided for @speaker.
  ///
  /// In en, this message translates to:
  /// **'Speaker'**
  String get speaker;

  /// No description provided for @earpiece.
  ///
  /// In en, this message translates to:
  /// **'Earpiece'**
  String get earpiece;

  /// No description provided for @flip.
  ///
  /// In en, this message translates to:
  /// **'Flip'**
  String get flip;

  /// No description provided for @typeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message'**
  String get typeAMessage;

  /// No description provided for @mediaUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Media upload failed'**
  String get mediaUploadFailed;

  /// No description provided for @myPatients.
  ///
  /// In en, this message translates to:
  /// **'My Patients'**
  String get myPatients;

  /// No description provided for @noPatientsYet.
  ///
  /// In en, this message translates to:
  /// **'No patients yet.'**
  String get noPatientsYet;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @jan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get jan;

  /// No description provided for @feb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get feb;

  /// No description provided for @mar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get mar;

  /// No description provided for @apr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get apr;

  /// No description provided for @mayShort.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get mayShort;

  /// No description provided for @jun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get jun;

  /// No description provided for @jul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get jul;

  /// No description provided for @aug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get aug;

  /// No description provided for @sep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get sep;

  /// No description provided for @oct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get oct;

  /// No description provided for @nov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get nov;

  /// No description provided for @dec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get dec;

  /// No description provided for @voiceSummary.
  ///
  /// In en, this message translates to:
  /// **'Today you have {today} patients. {pending} are pending and {completed} are completed.'**
  String voiceSummary(int today, int pending, int completed);

  /// No description provided for @nextPatient.
  ///
  /// In en, this message translates to:
  /// **'Next patient'**
  String get nextPatient;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @todaysAppointments.
  ///
  /// In en, this message translates to:
  /// **'Today\'s appointments'**
  String get todaysAppointments;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @couldNotLoadHome.
  ///
  /// In en, this message translates to:
  /// **'Could not load home'**
  String get couldNotLoadHome;

  /// No description provided for @scheduleIsClear.
  ///
  /// In en, this message translates to:
  /// **'Your schedule is clear for today'**
  String get scheduleIsClear;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @appointment.
  ///
  /// In en, this message translates to:
  /// **'Appointment'**
  String get appointment;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @incomingVideoCall.
  ///
  /// In en, this message translates to:
  /// **'Incoming Video Call'**
  String get incomingVideoCall;

  /// No description provided for @incomingVoiceCall.
  ///
  /// In en, this message translates to:
  /// **'Incoming Voice Call'**
  String get incomingVoiceCall;

  /// No description provided for @videoCall.
  ///
  /// In en, this message translates to:
  /// **'Video Call'**
  String get videoCall;

  /// No description provided for @voiceCall.
  ///
  /// In en, this message translates to:
  /// **'Voice Call'**
  String get voiceCall;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

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

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @healthRecord.
  ///
  /// In en, this message translates to:
  /// **'Health Record'**
  String get healthRecord;

  /// No description provided for @noPatientSelected.
  ///
  /// In en, this message translates to:
  /// **'No patient selected.'**
  String get noPatientSelected;

  /// No description provided for @patientRecord.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s Record'**
  String patientRecord(String name);

  /// No description provided for @switchPatient.
  ///
  /// In en, this message translates to:
  /// **'Switch patient'**
  String get switchPatient;

  /// No description provided for @couldNotLoadPatients.
  ///
  /// In en, this message translates to:
  /// **'Could not load patients'**
  String get couldNotLoadPatients;

  /// No description provided for @noPatientsAssigned.
  ///
  /// In en, this message translates to:
  /// **'No patients assigned to you.'**
  String get noPatientsAssigned;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @severeAllergyFlag.
  ///
  /// In en, this message translates to:
  /// **'Severe allergy on record'**
  String get severeAllergyFlag;

  /// No description provided for @lowSpo2Flag.
  ///
  /// In en, this message translates to:
  /// **'SpO₂ below 94% — check oxygen'**
  String get lowSpo2Flag;

  /// No description provided for @activeConditionFlag.
  ///
  /// In en, this message translates to:
  /// **'Active chronic condition'**
  String get activeConditionFlag;

  /// No description provided for @overdueVaccineFlag.
  ///
  /// In en, this message translates to:
  /// **'Overdue vaccine'**
  String get overdueVaccineFlag;

  /// No description provided for @vitals.
  ///
  /// In en, this message translates to:
  /// **'Vitals'**
  String get vitals;

  /// No description provided for @latestVitals.
  ///
  /// In en, this message translates to:
  /// **'Latest vitals'**
  String get latestVitals;

  /// No description provided for @noVitalsRecorded.
  ///
  /// In en, this message translates to:
  /// **'No vitals recorded yet.'**
  String get noVitalsRecorded;

  /// No description provided for @allergies.
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get allergies;

  /// No description provided for @noneRecorded.
  ///
  /// In en, this message translates to:
  /// **'None recorded.'**
  String get noneRecorded;

  /// No description provided for @chronicConditions.
  ///
  /// In en, this message translates to:
  /// **'Chronic conditions'**
  String get chronicConditions;

  /// No description provided for @pastConsultations.
  ///
  /// In en, this message translates to:
  /// **'Past consultations'**
  String get pastConsultations;

  /// No description provided for @noHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No history yet.'**
  String get noHistoryYet;

  /// No description provided for @immunisations.
  ///
  /// In en, this message translates to:
  /// **'Immunisations'**
  String get immunisations;

  /// No description provided for @familyHistory.
  ///
  /// In en, this message translates to:
  /// **'Family history'**
  String get familyHistory;

  /// No description provided for @bloodPressure.
  ///
  /// In en, this message translates to:
  /// **'Blood pressure'**
  String get bloodPressure;

  /// No description provided for @heartRate.
  ///
  /// In en, this message translates to:
  /// **'Heart rate'**
  String get heartRate;

  /// No description provided for @spo2.
  ///
  /// In en, this message translates to:
  /// **'SpO₂'**
  String get spo2;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @bmi.
  ///
  /// In en, this message translates to:
  /// **'BMI'**
  String get bmi;

  /// No description provided for @couldNotLoadRecord.
  ///
  /// In en, this message translates to:
  /// **'Could not load record'**
  String get couldNotLoadRecord;

  /// No description provided for @unknownDoctor.
  ///
  /// In en, this message translates to:
  /// **'Unknown doctor'**
  String get unknownDoctor;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name cannot be empty'**
  String get fullNameRequired;

  /// No description provided for @nmcLicenseRequired.
  ///
  /// In en, this message translates to:
  /// **'NMC license number is required'**
  String get nmcLicenseRequired;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @failedToSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save'**
  String get failedToSave;

  /// No description provided for @editModeHint.
  ///
  /// In en, this message translates to:
  /// **'Edit mode — tap any field to change it'**
  String get editModeHint;

  /// No description provided for @editing.
  ///
  /// In en, this message translates to:
  /// **'Editing'**
  String get editing;

  /// No description provided for @personalDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal Details'**
  String get personalDetails;

  /// No description provided for @professionalDetails.
  ///
  /// In en, this message translates to:
  /// **'Professional Details'**
  String get professionalDetails;

  /// No description provided for @municipality.
  ///
  /// In en, this message translates to:
  /// **'Municipality'**
  String get municipality;

  /// No description provided for @nmcLicense.
  ///
  /// In en, this message translates to:
  /// **'NMC License'**
  String get nmcLicense;

  /// No description provided for @specialty.
  ///
  /// In en, this message translates to:
  /// **'Specialty'**
  String get specialty;

  /// No description provided for @experience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experience;

  /// No description provided for @healthPost.
  ///
  /// In en, this message translates to:
  /// **'Health Post'**
  String get healthPost;

  /// No description provided for @doctorSince.
  ///
  /// In en, this message translates to:
  /// **'Doctor Since'**
  String get doctorSince;

  /// No description provided for @readOnly.
  ///
  /// In en, this message translates to:
  /// **'read-only'**
  String get readOnly;

  /// No description provided for @enterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter full name'**
  String get enterFullName;

  /// No description provided for @selectGender.
  ///
  /// In en, this message translates to:
  /// **'Select Gender'**
  String get selectGender;

  /// No description provided for @emailReadOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'Email is tied to your auth account'**
  String get emailReadOnlyNote;

  /// No description provided for @dobReadOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'Contact admin to update DOB'**
  String get dobReadOnlyNote;

  /// No description provided for @selectSpecialty.
  ///
  /// In en, this message translates to:
  /// **'Select Specialty'**
  String get selectSpecialty;

  /// No description provided for @doctorSinceNote.
  ///
  /// In en, this message translates to:
  /// **'Set automatically on registration'**
  String get doctorSinceNote;

  /// No description provided for @provinceRequired.
  ///
  /// In en, this message translates to:
  /// **'Province is required'**
  String get provinceRequired;

  /// No description provided for @districtRequired.
  ///
  /// In en, this message translates to:
  /// **'District is required'**
  String get districtRequired;

  /// No description provided for @specialtyRequired.
  ///
  /// In en, this message translates to:
  /// **'Specialty is required'**
  String get specialtyRequired;

  /// No description provided for @qualificationRequired.
  ///
  /// In en, this message translates to:
  /// **'Qualification is required'**
  String get qualificationRequired;

  /// No description provided for @selectHealthpost.
  ///
  /// In en, this message translates to:
  /// **'Select Healthpost'**
  String get selectHealthpost;

  /// No description provided for @doctorAccountCreated.
  ///
  /// In en, this message translates to:
  /// **'Doctor account created successfully!'**
  String get doctorAccountCreated;

  /// No description provided for @completeDoctorProfileHint.
  ///
  /// In en, this message translates to:
  /// **'Please complete your doctor profile in settings.'**
  String get completeDoctorProfileHint;

  /// No description provided for @loadingHealthposts.
  ///
  /// In en, this message translates to:
  /// **'Loading healthposts…'**
  String get loadingHealthposts;

  /// No description provided for @couldNotLoadHealthposts.
  ///
  /// In en, this message translates to:
  /// **'Could not load healthposts. Tap to retry.'**
  String get couldNotLoadHealthposts;

  /// No description provided for @noHealthpostsFound.
  ///
  /// In en, this message translates to:
  /// **'No healthposts found'**
  String get noHealthpostsFound;

  /// No description provided for @searchHealthpost.
  ///
  /// In en, this message translates to:
  /// **'Search by name or district…'**
  String get searchHealthpost;

  /// No description provided for @found.
  ///
  /// In en, this message translates to:
  /// **'found'**
  String get found;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllRead;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date Of Birth'**
  String get dateOfBirth;

  /// No description provided for @qualification.
  ///
  /// In en, this message translates to:
  /// **'Qualification'**
  String get qualification;

  /// No description provided for @healthpostRequired.
  ///
  /// In en, this message translates to:
  /// **'Healthpost is required'**
  String get healthpostRequired;

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In Failed'**
  String get googleSignInFailed;

  /// No description provided for @emailAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered. Please login instead.'**
  String get emailAlreadyRegistered;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get invalidEmail;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Info'**
  String get personalInfo;

  /// No description provided for @doctorInfo.
  ///
  /// In en, this message translates to:
  /// **'Doctor Info'**
  String get doctorInfo;

  /// No description provided for @accountInfo.
  ///
  /// In en, this message translates to:
  /// **'Account Info'**
  String get accountInfo;

  /// No description provided for @signUpFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign up failed'**
  String get signUpFailed;

  /// No description provided for @incompleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Incomplete profile'**
  String get incompleteProfile;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone is required'**
  String get phoneRequired;

  /// No description provided for @ageRequired.
  ///
  /// In en, this message translates to:
  /// **'Age is required'**
  String get ageRequired;

  /// No description provided for @genderRequired.
  ///
  /// In en, this message translates to:
  /// **'Gender is required'**
  String get genderRequired;

  /// No description provided for @passwordMinSix.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinSix;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// No description provided for @confirmAppointment.
  ///
  /// In en, this message translates to:
  /// **'Confirm appointment?'**
  String get confirmAppointment;

  /// No description provided for @declineAppointment.
  ///
  /// In en, this message translates to:
  /// **'Decline appointment?'**
  String get declineAppointment;

  /// No description provided for @patientNoShow.
  ///
  /// In en, this message translates to:
  /// **'Patient did not show'**
  String get patientNoShow;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String minutesAgo(Object count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(Object count);

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired'**
  String get sessionExpired;

  /// No description provided for @profileSetupIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Profile setup incomplete'**
  String get profileSetupIncomplete;

  /// No description provided for @doctorDetailsMissing.
  ///
  /// In en, this message translates to:
  /// **'Doctor details missing'**
  String get doctorDetailsMissing;

  /// No description provided for @couldNotLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Could not load profile'**
  String get couldNotLoadProfile;

  /// No description provided for @profileNotSavedDuringSignup.
  ///
  /// In en, this message translates to:
  /// **'Your profile was not saved during signup.'**
  String get profileNotSavedDuringSignup;

  /// No description provided for @doctorRegistrationIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Doctor registration is incomplete.'**
  String get doctorRegistrationIncomplete;

  /// No description provided for @sessionExpiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please login again.'**
  String get sessionExpiredMessage;

  /// No description provided for @goToLogin.
  ///
  /// In en, this message translates to:
  /// **'Go to Login'**
  String get goToLogin;

  /// No description provided for @signOutAndReregister.
  ///
  /// In en, this message translates to:
  /// **'Sign out & re-register'**
  String get signOutAndReregister;

  /// No description provided for @nmcPrefix.
  ///
  /// In en, this message translates to:
  /// **'NMC #'**
  String get nmcPrefix;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get notAvailable;

  /// No description provided for @generalSpecialty.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get generalSpecialty;

  /// No description provided for @statusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get statusConfirmed;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @unknownInitial.
  ///
  /// In en, this message translates to:
  /// **'?'**
  String get unknownInitial;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @todaysPatients.
  ///
  /// In en, this message translates to:
  /// **'Today\'s patients'**
  String get todaysPatients;

  /// No description provided for @statPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statPending;

  /// No description provided for @statCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statCompleted;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @noNoticesToday.
  ///
  /// In en, this message translates to:
  /// **'No notices today'**
  String get noNoticesToday;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout\nof your doctor account?'**
  String get logoutConfirmMessage;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @readAloud.
  ///
  /// In en, this message translates to:
  /// **'Read aloud'**
  String get readAloud;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @nmcVerified.
  ///
  /// In en, this message translates to:
  /// **'NMC Verified'**
  String get nmcVerified;

  /// No description provided for @years.
  ///
  /// In en, this message translates to:
  /// **'yrs'**
  String get years;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @langNepali.
  ///
  /// In en, this message translates to:
  /// **'नेपाली'**
  String get langNepali;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appDisplayLanguage.
  ///
  /// In en, this message translates to:
  /// **'App display language'**
  String get appDisplayLanguage;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @passwordChangeSoon.
  ///
  /// In en, this message translates to:
  /// **'Password change will be available soon.'**
  String get passwordChangeSoon;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get aboutApp;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get appVersion;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ne'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ne': return AppLocalizationsNe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
