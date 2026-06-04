import 'package:healthpost_app/fcm_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorService {
  final _supabase = Supabase.instance.client;

  Future<void> signOut() async {
    await FcmService.onUserLogout(); 
    await _supabase.auth.signOut(); 
  }
}
