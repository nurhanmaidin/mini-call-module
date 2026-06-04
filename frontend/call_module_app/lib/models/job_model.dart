class JobModel {
  final int id;
  final String title;
  final String description;
  final String location;
  final String status;
  final String? photoPath;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic>? createdBy;
  final Map<String, dynamic>? assignedTo;
  final String? createdAt;
  final String? assignedAt;
  final String? completedAt;

  JobModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.status,
    this.photoPath,
    this.latitude,
    this.longitude,
    this.createdBy,
    this.assignedTo,
    this.createdAt,
    this.assignedAt,
    this.completedAt,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      location: json['location'] ?? '',
      status: json['status'],
      photoPath: json['photo_path'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      createdBy: json['created_by'],
      assignedTo: json['assigned_to'],
      createdAt: json['created_at'],
      assignedAt: json['assigned_at'],
      completedAt: json['completed_at'],
    );
  }

  // Readable status label
  String get statusLabel {
    switch (status) {
      case 'pending':
        return '⏳ Pending';
      case 'assigned':
        return '📋 Assigned';
      case 'on_the_way':
        return '🚗 On The Way';
      case 'on_site':
        return '📍 On Site';
      case 'completed':
        return '✅ Completed';
      default:
        return status;
    }
  }

  // What status comes next for this job
  String? get nextStatus {
    switch (status) {
      case 'assigned':
        return 'on_the_way';
      case 'on_the_way':
        return 'on_site';
      case 'on_site':
        return 'completed';
      default:
        return null;
    }
  }

  // Button label for the next action
  String? get nextStatusLabel {
    switch (status) {
      case 'assigned':
        return 'Start Driving';
      case 'on_the_way':
        return 'Arrived On Site';
      case 'on_site':
        return 'Mark Completed';
      default:
        return null;
    }
  }
}
