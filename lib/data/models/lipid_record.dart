import 'package:intl/intl.dart';

class LipidRecord {
  final int? id;
  final int profileId;
  final int cholesterolTotal;
  final int triglycerides;
  final int hdl;
  final int nonHdl;
  final int ldl;
  final int vldl;
  final double cholHdlRatio;
  final DateTime recordDate;
  final DateTime createdAt;

  LipidRecord({
    this.id,
    required this.profileId,
    required this.cholesterolTotal,
    required this.triglycerides,
    required this.hdl,
    required this.nonHdl,
    required this.ldl,
    required this.vldl,
    required this.cholHdlRatio,
    required this.recordDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  LipidRecord copyWith({
    int? id,
    int? profileId,
    int? cholesterolTotal,
    int? triglycerides,
    int? hdl,
    int? nonHdl,
    int? ldl,
    int? vldl,
    double? cholHdlRatio,
    DateTime? recordDate,
    DateTime? createdAt,
  }) {
    return LipidRecord(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      cholesterolTotal: cholesterolTotal ?? this.cholesterolTotal,
      triglycerides: triglycerides ?? this.triglycerides,
      hdl: hdl ?? this.hdl,
      nonHdl: nonHdl ?? this.nonHdl,
      ldl: ldl ?? this.ldl,
      vldl: vldl ?? this.vldl,
      cholHdlRatio: cholHdlRatio ?? this.cholHdlRatio,
      recordDate: recordDate ?? this.recordDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profile_id': profileId,
      'cholesterol_total': cholesterolTotal,
      'triglycerides': triglycerides,
      'hdl': hdl,
      'non_hdl': nonHdl,
      'ldl': ldl,
      'vldl': vldl,
      'chol_hdl_ratio': cholHdlRatio,
      'record_date': DateFormat('yyyy-MM-dd').format(recordDate),
      'created_at': DateFormat('yyyy-MM-dd HH:mm:ss').format(createdAt),
    };
  }

  factory LipidRecord.fromMap(Map<String, dynamic> map) {
    return LipidRecord(
      id: map['id']?.toInt(),
      profileId: map['profile_id']?.toInt() ?? 0,
      cholesterolTotal: map['cholesterol_total']?.toInt() ?? 0,
      triglycerides: map['triglycerides']?.toInt() ?? 0,
      hdl: map['hdl']?.toInt() ?? 0,
      nonHdl: map['non_hdl']?.toInt() ?? 0,
      ldl: map['ldl']?.toInt() ?? 0,
      vldl: map['vldl']?.toInt() ?? 0,
      cholHdlRatio: map['chol_hdl_ratio']?.toDouble() ?? 0.0,
      recordDate: DateTime.parse(map['record_date']),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  String get formattedDate => DateFormat('MMM dd, yyyy').format(recordDate);

  // Status checks for each parameter
  bool get isCholesterolNormal => cholesterolTotal < 200;
  bool get isTriglyceridesNormal => triglycerides < 150;
  bool get isHdlNormal => hdl >= 40 && hdl <= 60;
  bool get isNonHdlNormal => nonHdl < 130;
  bool get isLdlNormal => ldl <= 159;
  bool get isVldlNormal => vldl <= 40;
  bool get isCholHdlRatioNormal => cholHdlRatio <= 5.0;

  String getCholesterolStatus() {
    if (cholesterolTotal < 200) return 'Desirable';
    if (cholesterolTotal < 240) return 'Borderline High';
    return 'High';
  }

  String getTriglyceridesStatus() {
    if (triglycerides < 150) return 'Normal';
    if (triglycerides < 200) return 'Borderline High';
    if (triglycerides < 500) return 'High';
    return 'Very High';
  }

  String getHdlStatus() {
    if (hdl < 40) return 'Low';
    if (hdl <= 60) return 'Normal';
    return 'High';
  }

  String getLdlStatus() {
    if (ldl < 100) return 'Optimal';
    if (ldl < 130) return 'Near Optimal';
    if (ldl < 160) return 'Borderline High';
    if (ldl < 190) return 'High';
    return 'Very High';
  }

  Map<String, dynamic> getParameterValues() {
    return {
      'Total Cholesterol': cholesterolTotal,
      'Triglycerides': triglycerides,
      'HDL': hdl,
      'Non-HDL': nonHdl,
      'LDL': ldl,
      'VLDL': vldl,
      'Chol/HDL Ratio': cholHdlRatio,
    };
  }

  @override
  String toString() {
    return 'LipidRecord{id: $id, profileId: $profileId, cholesterolTotal: $cholesterolTotal, recordDate: $recordDate}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LipidRecord &&
        other.id == id &&
        other.profileId == profileId &&
        other.cholesterolTotal == cholesterolTotal &&
        other.triglycerides == triglycerides &&
        other.hdl == hdl &&
        other.nonHdl == nonHdl &&
        other.ldl == ldl &&
        other.vldl == vldl &&
        other.cholHdlRatio == cholHdlRatio &&
        other.recordDate == recordDate;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        profileId.hashCode ^
        cholesterolTotal.hashCode ^
        triglycerides.hashCode ^
        hdl.hashCode ^
        nonHdl.hashCode ^
        ldl.hashCode ^
        vldl.hashCode ^
        cholHdlRatio.hashCode ^
        recordDate.hashCode;
  }
}
