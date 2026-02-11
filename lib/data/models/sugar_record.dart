import 'package:intl/intl.dart';

class SugarRecord {
  final int? id;
  final int profileId;
  final double? fbs;
  final double? ppbs;
  final double? rbs;
  final double hba1c;
  final DateTime recordDate;
  final DateTime createdAt;

  SugarRecord({
    this.id,
    required this.profileId,
    this.fbs,
    this.ppbs,
    this.rbs,
    required this.hba1c,
    required this.recordDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  SugarRecord copyWith({
    int? id,
    int? profileId,
    double? fbs,
    double? ppbs,
    double? rbs,
    double? hba1c,
    DateTime? recordDate,
    DateTime? createdAt,
  }) {
    return SugarRecord(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      fbs: fbs ?? this.fbs,
      ppbs: ppbs ?? this.ppbs,
      rbs: rbs ?? this.rbs,
      hba1c: hba1c ?? this.hba1c,
      recordDate: recordDate ?? this.recordDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profile_id': profileId,
      'fbs': fbs,
      'ppbs': ppbs,
      'rbs': rbs,
      'hba1c': hba1c,
      'record_date': DateFormat('yyyy-MM-dd').format(recordDate),
      'created_at': DateFormat('yyyy-MM-dd HH:mm:ss').format(createdAt),
    };
  }

  factory SugarRecord.fromMap(Map<String, dynamic> map) {
    return SugarRecord(
      id: map['id']?.toInt(),
      profileId: map['profile_id']?.toInt() ?? 0,
      fbs: map['fbs']?.toDouble(),
      ppbs: map['ppbs']?.toDouble(),
      rbs: map['rbs']?.toDouble(),
      hba1c: map['hba1c']?.toDouble() ?? 0.0,
      recordDate: DateTime.parse(map['record_date']),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  String get formattedDate => DateFormat('MMM dd, yyyy').format(recordDate);
  String get formattedHbA1c => '${hba1c.toStringAsFixed(1)}%';

  bool get isNormal => hba1c >= 4.0 && hba1c <= 5.6;
  bool get isPreDiabetic => hba1c >= 5.7 && hba1c <= 6.4;
  bool get isDiabetic => hba1c >= 6.5;

  String get status {
    if (isNormal) return 'Normal';
    if (isPreDiabetic) return 'Pre-diabetic';
    return 'Diabetic';
  }

  @override
  String toString() {
    return 'SugarRecord{id: $id, profileId: $profileId, hba1c: $hba1c, recordDate: $recordDate}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SugarRecord &&
        other.id == id &&
        other.profileId == profileId &&
        other.fbs == fbs &&
        other.ppbs == ppbs &&
        other.rbs == rbs &&
        other.hba1c == hba1c &&
        other.recordDate == recordDate;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        profileId.hashCode ^
        (fbs?.hashCode ?? 0) ^
        (ppbs?.hashCode ?? 0) ^
        (rbs?.hashCode ?? 0) ^
        hba1c.hashCode ^
        recordDate.hashCode;
  }
}
