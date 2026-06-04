import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:healthpost_app/services/encryption_service.dart';   

class UserKeyService {
  static const _secureStorage = FlutterSecureStorage();

  /// Ensures the current user has a valid RSA key pair.
  static Future<void> ensureUserKeyPair(String userId) async {
    final supabase = Supabase.instance.client;

    // 1. Fetch existing public key from DB
    final profile = await supabase
        .from('user_profiles')
        .select('public_key')
        .eq('id', userId)
        .maybeSingle();

    // 2. Check if private key exists in secure storage
    final storedPrivateKey = await _secureStorage.read(key: 'rsa_private_key_$userId');

    // 3. If both keys exist and are valid, do nothing
    if (profile != null &&
        profile['public_key'] != null &&
        storedPrivateKey != null &&
        _isValidKeyFormat(profile['public_key'] as String)) {
      return;
    }

    // 4. Generate a new RSA key pair
    final kp = EncryptionService.generateRSAKeyPair();
    final publicKeyPem = EncryptionService.publicKeyToPem(kp.publicKey);
    final privateKeyPem = EncryptionService.privateKeyToPem(kp.privateKey);

    // 5. Save private key securely
    await _secureStorage.write(key: 'rsa_private_key_$userId', value: privateKeyPem);

    // 6. Save public key to user_profiles (upsert)
    await supabase
        .from('user_profiles')
        .update({'public_key': publicKeyPem}).eq('id', userId);
  }

  static bool _isValidKeyFormat(String pem) {
    try {
      final bytes = base64Decode(pem);
      final decoded = utf8.decode(bytes);
      if (decoded.startsWith('{')) {
        final map = jsonDecode(decoded) as Map;
        return map.containsKey('n') && map.containsKey('e');
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}