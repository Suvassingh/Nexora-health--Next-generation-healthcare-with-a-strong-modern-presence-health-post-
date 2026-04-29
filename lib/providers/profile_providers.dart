import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:healthpost_app/models/doctor_model.dart';

final supabaseProvider = Provider((ref) => Supabase.instance.client);

final doctorProfileProvider = FutureProvider<DoctorProfileModel>((ref) async {
  final supabase = ref.read(supabaseProvider);
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) throw Exception('Not authenticated. Please login again.');

  final results = await Future.wait([
    supabase.from('user_profiles').select().eq('id', userId).maybeSingle(),
    supabase.from('doctors').select().eq('user_id', userId).maybeSingle(),
  ]);

  final profileMap = results[0] as Map<String, dynamic>?;
  final doctorMap = results[1] as Map<String, dynamic>?;

  if (profileMap == null && doctorMap == null) throw Exception('no_profile');
  if (profileMap == null) throw Exception('no_user_profile:$userId');
  if (doctorMap == null) throw Exception('no_doctor_profile');

  return DoctorProfileModel.fromMaps(
    profile: profileMap,
    doctor: doctorMap,
  );
});