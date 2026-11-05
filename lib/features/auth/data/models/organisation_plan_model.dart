import 'package:zedu/features/features.dart';

class OrganisationPlanModel {
  const OrganisationPlanModel({
    required this.startedAt,
    required this.endedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.planDetails,
  });

  final DateTime startedAt;
  final DateTime endedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PlanDetailsModel planDetails;

  factory OrganisationPlanModel.fromJson(Map<String, dynamic> json) {
    return OrganisationPlanModel(
      startedAt: DateTime.tryParse(json['started_at'] as String? ?? '') ??
          DateTime.utc(1),
      endedAt: DateTime.tryParse(json['ended_at'] as String? ?? '') ??
          DateTime.utc(1),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.utc(1),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.utc(1),
      planDetails: PlanDetailsModel.fromJson(
        json['plan_details'] as Map<String, dynamic>,
      ),
    );
  }
}
