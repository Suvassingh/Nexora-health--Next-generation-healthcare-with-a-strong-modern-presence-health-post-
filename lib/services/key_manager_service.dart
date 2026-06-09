import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'encryption_service.dart';

class KeyManagerService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: false,
    ),
  );

  static final _supabase = Supabase.instance.client;
  static String get _currentUserId =>
      _supabase.auth.currentUser!.id;

  static Future<void> ensureKeyPair() async {
    final stored = await _storage.read(
      key: 'private_key_$_currentUserId',
    );

    if (stored == null) {
      print('No private key — regenerating for DOCTOR...');
      await _regenerateAndReEncrypt();
    }
  }

  static Future<void> _regenerateAndReEncrypt() async {
    // 1. Generate new key pair
    final keyPair = EncryptionService.generateRSAKeyPair();
    final publicPem = EncryptionService.publicKeyToPem(keyPair.publicKey);
    final privatePem = EncryptionService.privateKeyToPem(keyPair.privateKey);

    // 2. Save locally
    await _storage.write(
      key: 'private_key_$_currentUserId',
      value: privatePem,
    );

    // 3. Upload public key
    await _supabase
        .from('user_profiles')
        .update({'public_key': publicPem})
        .eq('id', _currentUserId);

    // 4. Get doctor's integer id first
    // (conversations table uses int doctor_id, not UUID)
    final doctorRecord = await _supabase
        .from('doctors')
        .select('id')
        .eq('user_id', _currentUserId)
        .maybeSingle();

    final doctorIntId = doctorRecord?['id'] as int?;
    if (doctorIntId == null) {
      print('Doctor record not found');
      return;
    }

    // 5. Re-encrypt conversations
    await _reEncryptConversations(keyPair, doctorIntId);
  }

  static Future<void> _reEncryptConversations(
      AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> keyPair,
      int doctorIntId,
      ) async {
    // DOCTOR: fetch by doctor_id (integer)
    // patient_id here is UUID
    final conversations = await _supabase
        .from('conversations')
        .select('id, patient_id')
        .eq('doctor_id', _currentUserId); // UUID in conversations

    for (final conv in conversations) {
      try {
        final newAesKey = EncryptionService.generateAESKey();
        final newAesB64 = newAesKey.base64;

        // patient_id = patient's user_id (UUID)
        final patientProfile = await _supabase
            .from('user_profiles')
            .select('public_key')
            .eq('id', conv['patient_id'])
            .maybeSingle();

        final patientKeyPem = patientProfile?['public_key'] as String?;

        final encForDoctor = EncryptionService.encryptWithRSA(
          newAesB64, keyPair.publicKey,
        );

        if (patientKeyPem != null) {
          final encForPatient = EncryptionService.encryptWithRSA(
            newAesB64,
            EncryptionService.parsePublicKeyFromPem(patientKeyPem),
          );

          await _supabase
              .from('conversations')
              .update({
            'aes_key_encrypted_for_doctor': encForDoctor,
            'aes_key_encrypted_for_patient': encForPatient,
          })
              .eq('id', conv['id']);
        } else {
          // Patient key not available
          // Only update doctor's key
          await _supabase
              .from('conversations')
              .update({
            'aes_key_encrypted_for_doctor': encForDoctor,
          })
              .eq('id', conv['id']);
        }

        print('Re-encrypted conv ${conv['id']}');
      } catch (e) {
        print('Failed conv ${conv['id']}: $e');
      }
    }
  }

  static Future<RSAPrivateKey?> getPrivateKey() async {
    final pem = await _storage.read(
      key: 'private_key_$_currentUserId',
    );
    if (pem == null) return null;
    return EncryptionService.parsePrivateKeyFromPem(pem);
  }
}