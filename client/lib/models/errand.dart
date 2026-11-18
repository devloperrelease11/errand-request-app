class ErrandStatus {
  const ErrandStatus._(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static const open = ErrandStatus._('Open', 'Open');
  static const accepted = ErrandStatus._('Accepted', 'Accepted');
  static const inProgress = ErrandStatus._('In Progress', 'In progress');
  static const completed = ErrandStatus._('Completed', 'Completed');
  static const cancelled = ErrandStatus._('Cancelled', 'Cancelled');

  static const values = [open, accepted, inProgress, completed, cancelled];

  static ErrandStatus fromWire(String value) {
    for (final status in values) {
      if (status.wireValue == value) return status;
    }
    return open;
  }

  bool get isFinal => identical(this, completed) || identical(this, cancelled);
}

class Errand {
  const Errand({
    required this.id,
    required this.requesterId,
    required this.runnerId,
    required this.title,
    required this.description,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.acceptedAt,
    this.completedAt,
  });

  final String id;
  final String requesterId;
  final String? runnerId;
  final String title;
  final String description;
  final String pickupAddress;
  final String dropoffAddress;
  final ErrandStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;

  factory Errand.fromJson(Map<String, dynamic> json) {
    return Errand(
      id: json['id'] as String,
      requesterId: json['requester_id'] as String,
      runnerId: json['runner_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      pickupAddress: json['pickup_address'] as String,
      dropoffAddress: json['dropoff_address'] as String,
      status: ErrandStatus.fromWire(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      acceptedAt: _nullableDate(json['accepted_at']),
      completedAt: _nullableDate(json['completed_at']),
    );
  }

  static DateTime? _nullableDate(Object? value) =>
      value == null ? null : DateTime.parse(value as String);

  Errand copyWith({ErrandStatus? status}) {
    return Errand(
      id: id,
      requesterId: requesterId,
      runnerId: runnerId,
      title: title,
      description: description,
      pickupAddress: pickupAddress,
      dropoffAddress: dropoffAddress,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      acceptedAt: acceptedAt,
      completedAt: completedAt,
    );
  }
}
