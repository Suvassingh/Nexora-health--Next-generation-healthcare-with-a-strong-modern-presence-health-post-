class DoctorProfileModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String? gender;
  final String? dateOfBirth;
  final String? municipality;
  final String? avatarUrl;
  final String preferredLanguage;
  final bool isVerified;
  final String licenseNumber;
  final String specialty;
  final String qualification;
  final int? experienceYears;
  final String healthpostName;
  final bool doctorIsVerified;
  final bool isActive;
  final String? doctorSince;

  const DoctorProfileModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.gender,
    this.dateOfBirth,
    this.municipality,
    this.avatarUrl,
    required this.preferredLanguage,
    required this.isVerified,
    required this.licenseNumber,
    required this.specialty,
    required this.qualification,
    this.experienceYears,
    required this.healthpostName,
    required this.doctorIsVerified,
    required this.isActive,
    this.doctorSince,
  });

  factory DoctorProfileModel.fromMaps({
    required Map<String, dynamic> profile,
    required Map<String, dynamic> doctor,
  }) => DoctorProfileModel(
    id: profile['id'] ?? '',
    fullName: profile['full_name'] ?? '',
    email: profile['email'] ?? '',
    phone: profile['phone'] ?? '',
    gender: profile['gender'],
    dateOfBirth: profile['date_of_birth'],
    municipality: profile['municipality'],
    avatarUrl: profile['avatar_url'],
    preferredLanguage: profile['preferred_language'] ?? 'english',
    isVerified: profile['is_verified'] ?? false,
    licenseNumber: doctor['license_number'] ?? '',
    specialty: doctor['specialty'] ?? '',
    qualification: doctor['qualification'] ?? '',
    experienceYears: doctor['experience_years'],
    healthpostName: doctor['healthpost_name'] ?? '',
    doctorIsVerified: doctor['is_verified'] ?? false,
    isActive: doctor['is_active'] ?? true,
    doctorSince: doctor['created_at'],
  );
}
