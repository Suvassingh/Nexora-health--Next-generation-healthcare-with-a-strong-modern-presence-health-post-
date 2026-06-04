class PrescriptionItem {
  final String medicineName;
  final String? dosage;
  final String? frequency;
  final int? durationDays;
  final String? instructions;

  const PrescriptionItem({
    required this.medicineName,
    this.dosage,
    this.frequency,
    this.durationDays,
    this.instructions,
  });

  Map<String, dynamic> toJson() => {
    'medicine_name': medicineName,
    if (dosage != null) 'dosage': dosage,
    if (frequency != null) 'frequency': frequency,
    if (durationDays != null) 'duration_days': durationDays,
    if (instructions != null) 'instructions': instructions,
  };
}
