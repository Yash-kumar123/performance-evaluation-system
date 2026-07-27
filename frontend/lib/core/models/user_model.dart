class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String role; // 'HR', 'MANAGER', 'EMPLOYEE'
  final String companyId;
  final String? companyName;
  final String? companySlug;
  final String? jobTitle;
  final String? department;
  final String? managerId;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.companyId,
    this.companyName,
    this.companySlug,
    this.jobTitle,
    this.department,
    this.managerId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? json['full_name'] ?? '',
      role: json['role'] ?? 'EMPLOYEE',
      companyId: json['companyId'] ?? json['company_id'] ?? '',
      companyName: json['companyName'] ?? json['company_name'],
      companySlug: json['companySlug'] ?? json['company_slug'],
      jobTitle: json['jobTitle'] ?? json['job_title'],
      department: json['department'],
      managerId: json['managerId'] ?? json['manager_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'role': role,
      'companyId': companyId,
      'companyName': companyName,
      'companySlug': companySlug,
      'jobTitle': jobTitle,
      'department': department,
      'managerId': managerId,
    };
  }

  bool get isHR => role == 'HR';
  bool get isManager => role == 'MANAGER';
  bool get isEmployee => role == 'EMPLOYEE';
}
