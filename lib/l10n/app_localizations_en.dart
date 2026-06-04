// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Telemedical App';

  @override
  String get login => 'Login';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get donthaveanaccout => 'Don\'t have an account ?';

  @override
  String get signup => 'Sign Up';

  @override
  String get bookAppointment => 'Book Appointment';

  @override
  String get doctor => 'Doctor';

  @override
  String get patient => 'Patient';

  @override
  String get homeScreen => 'Home Screen';

  @override
  String get name => 'Full Name';

  @override
  String get phone => 'Phone';

  @override
  String get age => 'Age';

  @override
  String get gender => 'Gender';

  @override
  String get address => 'Address';

  @override
  String get alreadyhaveanaccount => 'Already Have An Account ?';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get others => 'Other';

  @override
  String get confirmpassword => 'Confirm Password';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get loading => 'Loading';

  @override
  String get namaste => 'Namaste';

  @override
  String get howareyoufeelingtoday => 'How are you feeling today?';

  @override
  String get edit => 'Edit';

  @override
  String get appointments => 'Appointments';

  @override
  String get updated => 'Updated';

  @override
  String get statusUpdated => 'Status updated';

  @override
  String get couldNotUpdate => 'Could not update';

  @override
  String get confirmAppointmentQ => 'Confirm appointment?';

  @override
  String get confirm => 'Confirm';

  @override
  String appointmentConfirmedFor(String name) {
    return 'Appointment confirmed for $name';
  }

  @override
  String get declineAppointmentQ => 'Decline appointment?';

  @override
  String get declineWarning => 'This will cancel the booking.';

  @override
  String get decline => 'Decline';

  @override
  String get appointmentDeclined => 'Appointment declined';

  @override
  String get markAsCompleted => 'Mark as completed?';

  @override
  String consultationEndedWith(String name) {
    return 'Consultation with $name has ended.';
  }

  @override
  String get complete => 'Complete';

  @override
  String get consultationMarkedComplete => 'Consultation marked complete';

  @override
  String get markAsNoShow => 'Mark as no-show?';

  @override
  String patientDidNotJoin(String name) {
    return '$name did not join the appointment.';
  }

  @override
  String get noShow => 'No Show';

  @override
  String get markedAsNoShow => 'Marked as no-show';

  @override
  String get noPendingRequests => 'No pending requests';

  @override
  String get pendingAppearsHere => 'New appointment requests will appear here';

  @override
  String get todayAppearsHere => 'Your confirmed appointments for today appear here';

  @override
  String get upcomingAppearsHere => 'Future confirmed appointments will appear here';

  @override
  String get noCompletedConsultations => 'No completed consultations yet';

  @override
  String get completedAppearsHere => 'Consultations you finish will appear here';

  @override
  String get couldNotLoadAppointments => 'Could not load appointments';

  @override
  String get patientMessages => 'Patient Messages';

  @override
  String get noPatientChatsYet => 'No patient chats yet';

  @override
  String get error => 'Error';

  @override
  String get cancel => 'Cancel';

  @override
  String get callFailed => 'Call Failed';

  @override
  String get pending => 'Pending';

  @override
  String get today => 'Today';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get completed => 'Completed';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get noAppointmentsToday => 'No appointments today';

  @override
  String get noUpcomingAppointments => 'No upcoming appointments';

  @override
  String get noCancelledAppointments => 'No cancelled appointments';

  @override
  String get cancelledAppearsHere => 'Cancelled appointments will appear here';

  @override
  String get retry => 'Retry';

  @override
  String get connecting => 'Connecting...';

  @override
  String get connected => 'Connected';

  @override
  String get ringing => 'Ringing...';

  @override
  String get callError => 'Call Error';

  @override
  String get settingUpCall => 'Setting up call...';

  @override
  String get mute => 'Mute';

  @override
  String get unmute => 'Unmute';

  @override
  String get camOn => 'Camera On';

  @override
  String get camOff => 'Camera Off';

  @override
  String get speaker => 'Speaker';

  @override
  String get earpiece => 'Earpiece';

  @override
  String get flip => 'Flip';

  @override
  String get typeAMessage => 'Type a message';

  @override
  String get mediaUploadFailed => 'Media upload failed';

  @override
  String get myPatients => 'My Patients';

  @override
  String get noPatientsYet => 'No patients yet.';

  @override
  String get unknown => 'Unknown';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get jan => 'Jan';

  @override
  String get feb => 'Feb';

  @override
  String get mar => 'Mar';

  @override
  String get apr => 'Apr';

  @override
  String get mayShort => 'May';

  @override
  String get jun => 'Jun';

  @override
  String get jul => 'Jul';

  @override
  String get aug => 'Aug';

  @override
  String get sep => 'Sep';

  @override
  String get oct => 'Oct';

  @override
  String get nov => 'Nov';

  @override
  String get dec => 'Dec';

  @override
  String voiceSummary(int today, int pending, int completed) {
    return 'Today you have $today patients. $pending are pending and $completed are completed.';
  }

  @override
  String get nextPatient => 'Next patient';

  @override
  String get start => 'Start';

  @override
  String get todaysAppointments => 'Today\'s appointments';

  @override
  String get seeAll => 'See all';

  @override
  String get couldNotLoadHome => 'Could not load home';

  @override
  String get scheduleIsClear => 'Your schedule is clear for today';

  @override
  String get home => 'Home';

  @override
  String get appointment => 'Appointment';

  @override
  String get profile => 'Profile';

  @override
  String get incomingVideoCall => 'Incoming Video Call';

  @override
  String get incomingVoiceCall => 'Incoming Voice Call';

  @override
  String get videoCall => 'Video Call';

  @override
  String get voiceCall => 'Voice Call';

  @override
  String get accept => 'Accept';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get chat => 'Chat';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get healthRecord => 'Health Record';

  @override
  String get noPatientSelected => 'No patient selected.';

  @override
  String patientRecord(String name) {
    return '$name\'s Record';
  }

  @override
  String get switchPatient => 'Switch patient';

  @override
  String get couldNotLoadPatients => 'Could not load patients';

  @override
  String get noPatientsAssigned => 'No patients assigned to you.';

  @override
  String get current => 'Current';

  @override
  String get severeAllergyFlag => 'Severe allergy on record';

  @override
  String get lowSpo2Flag => 'SpO₂ below 94% — check oxygen';

  @override
  String get activeConditionFlag => 'Active chronic condition';

  @override
  String get overdueVaccineFlag => 'Overdue vaccine';

  @override
  String get vitals => 'Vitals';

  @override
  String get latestVitals => 'Latest vitals';

  @override
  String get noVitalsRecorded => 'No vitals recorded yet.';

  @override
  String get allergies => 'Allergies';

  @override
  String get noneRecorded => 'None recorded.';

  @override
  String get chronicConditions => 'Chronic conditions';

  @override
  String get pastConsultations => 'Past consultations';

  @override
  String get noHistoryYet => 'No history yet.';

  @override
  String get immunisations => 'Immunisations';

  @override
  String get familyHistory => 'Family history';

  @override
  String get bloodPressure => 'Blood pressure';

  @override
  String get heartRate => 'Heart rate';

  @override
  String get spo2 => 'SpO₂';

  @override
  String get temperature => 'Temperature';

  @override
  String get weight => 'Weight';

  @override
  String get bmi => 'BMI';

  @override
  String get couldNotLoadRecord => 'Could not load record';

  @override
  String get unknownDoctor => 'Unknown doctor';

  @override
  String get fullNameRequired => 'Full name cannot be empty';

  @override
  String get nmcLicenseRequired => 'NMC license number is required';

  @override
  String get profileUpdated => 'Profile updated successfully';

  @override
  String get failedToSave => 'Failed to save';

  @override
  String get editModeHint => 'Edit mode — tap any field to change it';

  @override
  String get editing => 'Editing';

  @override
  String get personalDetails => 'Personal Details';

  @override
  String get professionalDetails => 'Professional Details';

  @override
  String get municipality => 'Municipality';

  @override
  String get nmcLicense => 'NMC License';

  @override
  String get specialty => 'Specialty';

  @override
  String get experience => 'Experience';

  @override
  String get healthPost => 'Health Post';

  @override
  String get doctorSince => 'Doctor Since';

  @override
  String get readOnly => 'read-only';

  @override
  String get enterFullName => 'Enter full name';

  @override
  String get selectGender => 'Select Gender';

  @override
  String get emailReadOnlyNote => 'Email is tied to your auth account';

  @override
  String get dobReadOnlyNote => 'Contact admin to update DOB';

  @override
  String get selectSpecialty => 'Select Specialty';

  @override
  String get doctorSinceNote => 'Set automatically on registration';

  @override
  String get provinceRequired => 'Province is required';

  @override
  String get districtRequired => 'District is required';

  @override
  String get specialtyRequired => 'Specialty is required';

  @override
  String get qualificationRequired => 'Qualification is required (e.g. MBBS, MD)';

  @override
  String get selectHealthpost => 'Select Healthpost';

  @override
  String get doctorAccountCreated => 'Doctor account created successfully!';

  @override
  String get completeDoctorProfileHint => 'Please complete your doctor profile in settings.';

  @override
  String get loadingHealthposts => 'Loading healthposts…';

  @override
  String get couldNotLoadHealthposts => 'Could not load healthposts. Tap to retry.';

  @override
  String get noHealthpostsFound => 'No healthposts found';

  @override
  String get searchHealthpost => 'Search by name or district…';

  @override
  String get found => 'found';

  @override
  String get notifications => 'Notifications';

  @override
  String get markAllRead => 'Mark all as read';

  @override
  String get noNotifications => 'No notifications yet';

  @override
  String get success => 'Success';

  @override
  String get save => 'Save';

  @override
  String get dateOfBirth => 'Date Of Birth';

  @override
  String get qualification => 'Qualification';

  @override
  String get healthpostRequired => 'Healthpost is required';

  @override
  String get googleSignInFailed => 'Google Sign-In Failed';

  @override
  String get emailAlreadyRegistered => 'This email is already registered. Please login instead.';

  @override
  String get invalidEmail => 'Please enter a valid email address.';

  @override
  String get personalInfo => 'Personal Info';

  @override
  String get doctorInfo => 'Doctor Info';

  @override
  String get accountInfo => 'Account Info';

  @override
  String get signUpFailed => 'Sign up failed';

  @override
  String get incompleteProfile => 'Please complete all required fields.';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get phoneRequired => 'Phone number is required';

  @override
  String get ageRequired => 'Age is required';

  @override
  String get genderRequired => 'Gender is required';

  @override
  String get passwordMinSix => 'Password must be at least 6 characters';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get confirmAppointment => 'Confirm appointment?';

  @override
  String get declineAppointment => 'Decline appointment?';

  @override
  String get patientNoShow => 'Patient did not show';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get type => 'Type';

  @override
  String get reason => 'Reason';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(Object count) {
    return '$count min ago';
  }

  @override
  String daysAgo(Object count) {
    return '$count days ago';
  }

  @override
  String get sessionExpired => 'Session expired';

  @override
  String get profileSetupIncomplete => 'Profile setup incomplete';

  @override
  String get doctorDetailsMissing => 'Doctor details missing';

  @override
  String get couldNotLoadProfile => 'Could not load profile';

  @override
  String get profileNotSavedDuringSignup => 'Your profile was not saved during signup.';

  @override
  String get doctorRegistrationIncomplete => 'Doctor registration is incomplete.';

  @override
  String get sessionExpiredMessage => 'Your session has expired. Please login again.';

  @override
  String get goToLogin => 'Go to Login';

  @override
  String get signOutAndReregister => 'Sign out & re-register';

  @override
  String get nmcPrefix => 'NMC #';

  @override
  String get notAvailable => '—';

  @override
  String get generalSpecialty => 'General';

  @override
  String get statusConfirmed => 'Confirmed';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusPending => 'Pending';

  @override
  String get unknownInitial => '?';

  @override
  String get view => 'View';

  @override
  String get todaysPatients => 'Today\'s patients';

  @override
  String get statPending => 'Pending';

  @override
  String get statCompleted => 'Completed';

  @override
  String get thisMonth => 'This month';

  @override
  String get noNoticesToday => 'No notices today';

  @override
  String get logout => 'Logout';

  @override
  String get logoutConfirmMessage => 'Are you sure you want to logout\nof your doctor account?';

  @override
  String get stop => 'Stop';

  @override
  String get readAloud => 'Read aloud';

  @override
  String get thisWeek => 'This week';

  @override
  String get nmcVerified => 'NMC Verified';

  @override
  String get years => 'yrs';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get status => 'Status';

  @override
  String get language => 'Language';

  @override
  String get langNepali => 'नेपाली';

  @override
  String get langEnglish => 'English';

  @override
  String get settings => 'Settings';

  @override
  String get appDisplayLanguage => 'App display language';

  @override
  String get changePassword => 'Change Password';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get passwordChangeSoon => 'Password change will be available soon.';

  @override
  String get aboutApp => 'About App';

  @override
  String get appVersion => 'Version 1.0.0';

  @override
  String get medicalHistory => 'Medical History';

  @override
  String get phoneInvalid => 'Invalid phone number';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get signInFailed => 'Sign in failed';

  @override
  String get enterEmailForReset => 'Enter your email to reset password';

  @override
  String get invalidCredentials => 'Invalid email or password';

  @override
  String get emailNotVerified => 'Email not verified';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get noInternetConnection => 'No internet connection. Please check your network.';

  @override
  String get emailNotVerifiedTitle => 'Email Not Verified';

  @override
  String get emailNotVerifiedMessage => 'Please verify your email address before logging in. Check your inbox for a verification link.';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get passwordResetSent => 'Password reset link has been sent to your email.';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get send => 'send';

  @override
  String get ageMinimum18 => 'ageMinimum18';

  @override
  String get verifyEmailTitle => 'verifyEmailTitle';

  @override
  String get verifyEmailMessage => 'verifyEmailMessage';

  @override
  String get orSignInWith => 'Or SignIn With';

  @override
  String get google => 'Google';
}
