// import 'package:healthpost_app/models/doctor_model.dart';

// Future<void> _fetchProfile() async {
//   setState(() {
//     _loading = true;
//     _error = null;
//   });
//   try {
//     final userId = supabase.auth.currentUser?.id;
//     if (userId == null)
//       throw Exception('Not authenticated. Please login again.');

//     final results = await Future.wait([
//       supabase.from('user_profiles').select().eq('id', userId).maybeSingle(),
//       supabase.from('doctors').select().eq('user_id', userId).maybeSingle(),
//     ]);

//     final profileMap = results[0] as Map<String, dynamic>?;
//     final doctorMap = results[1] as Map<String, dynamic>?;

//     if (profileMap == null && doctorMap == null) throw Exception('no_profile');
//     if (profileMap == null) throw Exception('no_user_profile:$userId');
//     if (doctorMap == null) throw Exception('no_doctor_profile');

//     final lang = profileMap['preferred_language'] ?? 'english';
//     localeCtrl.setLocale(lang == 'nepali' ? 'np' : 'en');

//     final model = DoctorProfileModel.fromMaps(
//       profile: profileMap,
//       doctor: doctorMap,
//     );
//     _populateControllers(model);

//     setState(() {
//       _doctor = model;
//       _loading = false;
//     });
//     _animController.forward();
//   } catch (e) {
//     setState(() {
//       _error = e.toString();
//       _loading = false;
//     });
//   }
// }
