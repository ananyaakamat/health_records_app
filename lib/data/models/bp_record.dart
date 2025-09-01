import 'package:intl/intl.dart';

class BPRecord {
  final int? id;
  final int profileId;
  final int systolic;
  final int diastolic;
  final DateTime recordDate;
  final DateTime createdAt;

  BPRecord({
    this.id,
    required this.profileId,
    required this.systolic,
    required this.diastolic,
    required this.recordDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  BPRecord copyWith({
    int? id,
    int? profileId,
    int? systolic,
    int? diastolic,
    DateTime? recordDate,
    DateTime? createdAt,
  }) {
    return BPRecord(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      recordDate: recordDate ?? this.recordDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profile_id': profileId,
      'systolic': systolic,
      'diastolic': diastolic,
      'record_date': DateFormat('yyyy-MM-dd').format(recordDate),
      'created_at': DateFormat('yyyy-MM-dd HH:mm:ss').format(createdAt),
    };
  }

  factory BPRecord.fromMap(Map<String, dynamic> map) {
    return BPRecord(
      id: map['id']?.toInt(),
      profileId: map['profile_id']?.toInt() ?? 0,
      systolic: map['systolic']?.toInt() ?? 0,
      diastolic: map['diastolic']?.toInt() ?? 0,
      recordDate: DateTime.parse(map['record_date']),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  String get formattedDate => DateFormat('MMM dd, yyyy').format(recordDate);
  String get formattedBP => '$systolic/$diastolic mmHg';

  bool get isNormal => systolic < 120 && diastolic < 80;
  bool get isElevated => systolic >= 120 && systolic < 130 && diastolic < 80;
  bool get isHighStage1 =>
      (systolic >= 130 && systolic < 140) ||
      (diastolic >= 80 && diastolic < 90);
  bool get isHighStage2 => systolic >= 140 || diastolic >= 90;
  bool get isHypertensiveCrisis => systolic > 180 || diastolic > 120;

  String get status {
    if (isNormal) return 'Normal';
    if (isElevated) return 'Elevated';
    if (isHighStage1) return 'High Stage 1';
    if (isHighStage2) return 'High Stage 2';
    if (isHypertensiveCrisis) return 'Hypertensive Crisis';
    return 'Unknown';
  }

  String get statusColor {
    if (isNormal) return 'green';
    if (isElevated) return 'yellow';
    if (isHighStage1) return 'orange';
    if (isHighStage2) return 'red';
    if (isHypertensiveCrisis) return 'darkred';
    return 'gray';
  }

  @override
  String toString() {
    return 'BPRecord{id: $id, profileId: $profileId, systolic: $systolic, diastolic: $diastolic, recordDate: $recordDate}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BPRecord &&
        other.id == id &&
        other.profileId == profileId &&
        other.systolic == systolic &&
        other.diastolic == diastolic &&
        other.recordDate == recordDate;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        profileId.hashCode ^
        systolic.hashCode ^
        diastolic.hashCode ^
        recordDate.hashCode;
  }
}
