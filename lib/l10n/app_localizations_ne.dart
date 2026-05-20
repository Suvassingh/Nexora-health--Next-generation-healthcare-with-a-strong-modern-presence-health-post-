// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Nepali (`ne`).
class AppLocalizationsNe extends AppLocalizations {
  AppLocalizationsNe([String locale = 'ne']) : super(locale);

  @override
  String get appTitle => 'टेलिमेडिकल एप';

  @override
  String get login => 'लगइन ';

  @override
  String get email => 'ईमेल';

  @override
  String get password => 'पासवर्ड';

  @override
  String get donthaveanaccout => 'खाता छैन?';

  @override
  String get signup => 'साइन अप';

  @override
  String get bookAppointment => 'अपोइन्टमेन्ट बुक गर्नुहोस्';

  @override
  String get doctor => 'डाक्टर';

  @override
  String get patient => 'बिरामी';

  @override
  String get homeScreen => 'होम स्क्रिन';

  @override
  String get name => 'पूरा नाम ';

  @override
  String get phone => 'फोन';

  @override
  String get age => 'उमेर ';

  @override
  String get gender => 'लिङ्ग ';

  @override
  String get address => 'ठेगाना ';

  @override
  String get alreadyhaveanaccount => 'पहिले नै खाता छ ?';

  @override
  String get male => 'पुरुष';

  @override
  String get female => 'महिला';

  @override
  String get others => 'अन्य';

  @override
  String get confirmpassword => 'पासवर्ड पुष्टि गर्नुहोस्';

  @override
  String get next => 'अर्को';

  @override
  String get back => 'फिर्ता';

  @override
  String get loading => 'लोड हुँदै';

  @override
  String get namaste => 'नमस्ते';

  @override
  String get howareyoufeelingtoday => 'आज तपाईंलाई कस्तो महसुस भइरहेको छ?';

  @override
  String get edit => 'सम्पादन';

  @override
  String get appointments => 'अपोइन्टमेन्टहरू';

  @override
  String get updated => 'अपडेट भयो';

  @override
  String get statusUpdated => 'स्थिति अपडेट भयो';

  @override
  String get couldNotUpdate => 'अपडेट गर्न सकिएन';

  @override
  String get confirmAppointmentQ => 'अपोइन्टमेन्ट पुष्टि गर्नुहोस्?';

  @override
  String get confirm => 'पुष्टि गर्नुहोस्';

  @override
  String appointmentConfirmedFor(String name) {
    return '$name को अपोइन्टमेन्ट पुष्टि भयो';
  }

  @override
  String get declineAppointmentQ => 'अपोइन्टमेन्ट अस्वीकार गर्नुहोस्?';

  @override
  String get declineWarning => 'यसले बुकिङ रद्द गर्नेछ।';

  @override
  String get decline => 'अस्वीकार';

  @override
  String get appointmentDeclined => 'अपोइन्टमेन्ट अस्वीकार गरियो';

  @override
  String get markAsCompleted => 'सम्पन्न भएको चिन्ह लगाउनुहोस्?';

  @override
  String consultationEndedWith(String name) {
    return '$name सँगको परामर्श सकियो।';
  }

  @override
  String get complete => 'सम्पन्न';

  @override
  String get consultationMarkedComplete => 'परामर्श सम्पन्न भएको चिन्ह लगाइयो';

  @override
  String get markAsNoShow => 'नआएको चिन्ह लगाउनुहोस्?';

  @override
  String patientDidNotJoin(String name) {
    return '$name अपोइन्टमेन्टमा सहभागी भएनन्।';
  }

  @override
  String get noShow => 'नआएको';

  @override
  String get markedAsNoShow => 'नआएको चिन्ह लगाइयो';

  @override
  String get noPendingRequests => 'कुनै पर्खाइमा रहेका अनुरोध छैनन्';

  @override
  String get pendingAppearsHere => 'नयाँ अपोइन्टमेन्ट अनुरोधहरू यहाँ देखिनेछन्';

  @override
  String get todayAppearsHere => 'आजका पुष्टि भएका अपोइन्टमेन्टहरू यहाँ देखिन्छन्';

  @override
  String get upcomingAppearsHere => 'भविष्यका पुष्टि भएका अपोइन्टमेन्टहरू यहाँ देखिनेछन्';

  @override
  String get noCompletedConsultations => 'अहिलेसम्म कुनै सम्पन्न परामर्श छैन';

  @override
  String get completedAppearsHere => 'तपाईंले सकाएका परामर्शहरू यहाँ देखिनेछन्';

  @override
  String get couldNotLoadAppointments => 'अपोइन्टमेन्ट लोड गर्न सकिएन';

  @override
  String get patientMessages => 'बिरामीका सन्देशहरू';

  @override
  String get noPatientChatsYet => 'अहिलेसम्म कुनै बिरामीको च्याट छैन';

  @override
  String get error => 'त्रुटि';

  @override
  String get cancel => 'रद्द गर्नुहोस्';

  @override
  String get callFailed => 'कल असफल भयो';

  @override
  String get pending => 'पेन्डिङ';

  @override
  String get today => 'आज';

  @override
  String get upcoming => 'आगामी';

  @override
  String get completed => 'सम्पन्न';

  @override
  String get cancelled => 'रद्द गरिएको';

  @override
  String get noAppointmentsToday => 'आज कुनै अपोइन्टमेन्ट छैन';

  @override
  String get noUpcomingAppointments => 'कुनै आगामी अपोइन्टमेन्ट छैन';

  @override
  String get noCancelledAppointments => 'कुनै रद्द गरिएको अपोइन्टमेन्ट छैन';

  @override
  String get cancelledAppearsHere => 'रद्द गरिएका अपोइन्टमेन्टहरू यहाँ देखिनेछन्';

  @override
  String get retry => 'पुन: प्रयास गर्नुहोस्';

  @override
  String get connecting => 'जडान हुँदैछ...';

  @override
  String get connected => 'जडान भयो';

  @override
  String get ringing => 'कल बज्दैछ...';

  @override
  String get callError => 'कल त्रुटि';

  @override
  String get settingUpCall => 'कल सेटअप हुँदैछ...';

  @override
  String get mute => 'म्यूट';

  @override
  String get unmute => 'अनम्यूट';

  @override
  String get camOn => 'क्यामेरा खोल्नुहोस्';

  @override
  String get camOff => 'क्यामेरा बन्द गर्नुहोस्';

  @override
  String get speaker => 'स्पिकर';

  @override
  String get earpiece => 'इयरपिस';

  @override
  String get flip => 'क्यामेरा बदल्नुहोस्';

  @override
  String get typeAMessage => 'सन्देश लेख्नुहोस्';

  @override
  String get mediaUploadFailed => 'मिडिया अपलोड गर्न असफल';

  @override
  String get myPatients => 'मेरा बिरामीहरू';

  @override
  String get noPatientsYet => 'अहिलेसम्म कुनै बिरामी छैन।';

  @override
  String get unknown => 'अज्ञात';

  @override
  String get monday => 'सोमबार';

  @override
  String get tuesday => 'मंगलबार';

  @override
  String get wednesday => 'बुधबार';

  @override
  String get thursday => 'बिहिबार';

  @override
  String get friday => 'शुक्रबार';

  @override
  String get saturday => 'शनिबार';

  @override
  String get sunday => 'आइतबार';

  @override
  String get jan => 'जन';

  @override
  String get feb => 'फेब';

  @override
  String get mar => 'मार्च';

  @override
  String get apr => 'अप्रि';

  @override
  String get mayShort => 'मे';

  @override
  String get jun => 'जुन';

  @override
  String get jul => 'जुल';

  @override
  String get aug => 'अग';

  @override
  String get sep => 'सेप';

  @override
  String get oct => 'अक्ट';

  @override
  String get nov => 'नोभ';

  @override
  String get dec => 'डिस';

  @override
  String voiceSummary(int today, int pending, int completed) {
    return 'आज तपाईंका $today बिरामी छन्। $pending पर्खाइमा र $completed सम्पन्न छन्।';
  }

  @override
  String get nextPatient => 'अर्को बिरामी';

  @override
  String get start => 'सुरु';

  @override
  String get todaysAppointments => 'आजका अपोइन्टमेन्टहरू';

  @override
  String get seeAll => 'सबै हेर्नुहोस्';

  @override
  String get couldNotLoadHome => 'होम लोड गर्न सकिएन';

  @override
  String get scheduleIsClear => 'आज तपाईंको तालिका खाली छ';

  @override
  String get home => 'गृह';

  @override
  String get appointment => 'अपोइन्टमेन्ट';

  @override
  String get profile => 'प्रोफाइल';

  @override
  String get incomingVideoCall => 'भिडियो कल आउँदैछ';

  @override
  String get incomingVoiceCall => 'भ्वाइस कल आउँदैछ';

  @override
  String get videoCall => 'भिडियो कल';

  @override
  String get voiceCall => 'भ्वाइस कल';

  @override
  String get accept => 'स्वीकार';

  @override
  String get goodMorning => 'शुभ प्रभात';

  @override
  String get goodAfternoon => 'शुभ दिउँसो';

  @override
  String get goodEvening => 'शुभ साँझ';

  @override
  String get chat => 'च्याट';

  @override
  String get emailRequired => 'इमेल आवश्यक छ';

  @override
  String get passwordRequired => 'पासवर्ड आवश्यक छ';

  @override
  String get healthRecord => 'स्वास्थ्य रेकर्ड';

  @override
  String get noPatientSelected => 'कुनै बिरामी छानिएको छैन।';

  @override
  String patientRecord(String name) {
    return '$name को रेकर्ड';
  }

  @override
  String get switchPatient => 'बिरामी बदल्नुहोस्';

  @override
  String get couldNotLoadPatients => 'बिरामी लोड गर्न सकिएन';

  @override
  String get noPatientsAssigned => 'तपाईंलाई कुनै बिरामी तोकिएको छैन।';

  @override
  String get current => 'हालको';

  @override
  String get severeAllergyFlag => 'गम्भीर एलर्जी रेकर्डमा छ';

  @override
  String get lowSpo2Flag => 'SpO₂ ९४% भन्दा कम — अक्सिजन जाँच्नुहोस्';

  @override
  String get activeConditionFlag => 'सक्रिय दीर्घकालीन रोग';

  @override
  String get overdueVaccineFlag => 'बाँकी खोप';

  @override
  String get vitals => 'भाइटल्स';

  @override
  String get latestVitals => 'ताजा भाइटल्स';

  @override
  String get noVitalsRecorded => 'अहिलेसम्म कुनै भाइटल्स दर्ता छैन।';

  @override
  String get allergies => 'एलर्जीहरू';

  @override
  String get noneRecorded => 'कुनै दर्ता छैन।';

  @override
  String get chronicConditions => 'दीर्घकालीन रोगहरू';

  @override
  String get pastConsultations => 'विगतका परामर्शहरू';

  @override
  String get noHistoryYet => 'अहिलेसम्म कुनै इतिहास छैन।';

  @override
  String get immunisations => 'खोपहरू';

  @override
  String get familyHistory => 'पारिवारिक इतिहास';

  @override
  String get bloodPressure => 'रक्तचाप';

  @override
  String get heartRate => 'मुटुको गति';

  @override
  String get spo2 => 'SpO₂';

  @override
  String get temperature => 'तापक्रम';

  @override
  String get weight => 'तौल';

  @override
  String get bmi => 'BMI';

  @override
  String get couldNotLoadRecord => 'रेकर्ड लोड गर्न सकिएन';

  @override
  String get unknownDoctor => 'अज्ञात डाक्टर';

  @override
  String get fullNameRequired => 'पूरा नाम खाली हुन सक्दैन';

  @override
  String get nmcLicenseRequired => 'NMC लाइसेन्स नम्बर आवश्यक छ';

  @override
  String get profileUpdated => 'प्रोफाइल सफलतापूर्वक अपडेट भयो';

  @override
  String get failedToSave => 'सुरक्षित गर्न सकिएन';

  @override
  String get editModeHint => 'सम्पादन मोड — परिवर्तन गर्न कुनै पनि फिल्डमा थिच्नुहोस्';

  @override
  String get editing => 'सम्पादन गर्दै';

  @override
  String get personalDetails => 'व्यक्तिगत विवरण';

  @override
  String get professionalDetails => 'व्यावसायिक विवरण';

  @override
  String get municipality => 'नगरपालिका';

  @override
  String get nmcLicense => 'NMC लाइसेन्स';

  @override
  String get specialty => 'विशेषज्ञता';

  @override
  String get experience => 'अनुभव';

  @override
  String get healthPost => 'स्वास्थ्य चौकी';

  @override
  String get doctorSince => 'डाक्टर भएदेखि';

  @override
  String get readOnly => 'पढ्न मात्र';

  @override
  String get enterFullName => 'पूरा नाम लेख्नुहोस्';

  @override
  String get selectGender => 'लिङ्ग छान्नुहोस्';

  @override
  String get emailReadOnlyNote => 'ईमेल तपाईंको खातासँग जोडिएको छ';

  @override
  String get dobReadOnlyNote => 'जन्म मिति अपडेट गर्न एडमिनलाई सम्पर्क गर्नुहोस्';

  @override
  String get selectSpecialty => 'विशेषज्ञता छान्नुहोस्';

  @override
  String get doctorSinceNote => 'दर्ताका बखत स्वतः सेट हुन्छ';

  @override
  String get provinceRequired => 'प्रदेश आवश्यक छ';

  @override
  String get districtRequired => 'जिल्ला आवश्यक छ';

  @override
  String get specialtyRequired => 'विशेषज्ञता आवश्यक छ';

  @override
  String get qualificationRequired => 'योग्यता आवश्यक छ';

  @override
  String get selectHealthpost => 'स्वास्थ्य चौकी छान्नुहोस्';

  @override
  String get doctorAccountCreated => 'डाक्टर खाता सफलतापूर्वक बनाइयो!';

  @override
  String get completeDoctorProfileHint => 'कृपया सेटिङमा आफ्नो डाक्टर प्रोफाइल पूरा गर्नुहोस्।';

  @override
  String get loadingHealthposts => 'स्वास्थ्य चौकीहरू लोड हुँदै…';

  @override
  String get couldNotLoadHealthposts => 'स्वास्थ्य चौकी लोड गर्न सकिएन। पुन: प्रयास गर्न थिच्नुहोस्।';

  @override
  String get noHealthpostsFound => 'कुनै स्वास्थ्य चौकी भेटिएन';

  @override
  String get searchHealthpost => 'नाम वा जिल्लाले खोज्नुहोस्…';

  @override
  String get found => 'भेटियो';

  @override
  String get notifications => 'सूचनाहरू';

  @override
  String get markAllRead => 'सबै पढिएको चिन्ह लगाउनुहोस्';

  @override
  String get noNotifications => 'अहिलेसम्म कुनै सूचना छैन';

  @override
  String get success => 'सफलता';

  @override
  String get save => 'सुरक्षित गरियो';

  @override
  String get dateOfBirth => 'जन्म मिति';

  @override
  String get qualification => 'योग्यता';

  @override
  String get healthpostRequired => 'स्वास्थ्य संस्था आवश्यक छ';

  @override
  String get googleSignInFailed => 'गुगल साइन-इन असफल भयो';

  @override
  String get emailAlreadyRegistered => 'यो इमेल पहिले नै दर्ता भइसकेको छ। कृपया लगइन गर्नुहोस्।';

  @override
  String get invalidEmail => 'कृपया सही इमेल ठेगाना हाल्नुहोस्।';

  @override
  String get personalInfo => 'व्यक्तिगत जानकारी';

  @override
  String get doctorInfo => 'डाक्टर जानकारी';

  @override
  String get accountInfo => 'खाता जानकारी';

  @override
  String get signUpFailed => 'साइन अप असफल भयो';

  @override
  String get incompleteProfile => 'कृपया सबै आवश्यक विवरणहरू भर्नुहोस्।';

  @override
  String get nameRequired => 'नाम आवश्यक छ';

  @override
  String get phoneRequired => 'फोन नम्बर आवश्यक छ';

  @override
  String get ageRequired => 'उमेर आवश्यक छ';

  @override
  String get genderRequired => 'लिङ्ग आवश्यक छ';

  @override
  String get passwordMinSix => 'पासवर्ड कम्तीमा ६ अक्षरको हुनुपर्छ';

  @override
  String get passwordMismatch => 'पासवर्ड मिलेन';
}
