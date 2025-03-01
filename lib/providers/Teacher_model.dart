class TeacherData {
  final String id;
  final String avatarUrl;
  final String teacherName;
  final String email;
  final String phoneNumber;
  final String dateOfBirth;
  final String gender;
  final String qualification;
  final String currentAddress;
  final String permanentAddress;

  TeacherData({
    required this.avatarUrl,
    required this.teacherName,
    required this.id,
    required this.email,
    required this.phoneNumber,
    required this.dateOfBirth,
    required this.gender,
    required this.qualification,
    required this.currentAddress,
    required this.permanentAddress,
  });

  factory TeacherData.fromMap(Map<String, dynamic> data) {
    return TeacherData(

      avatarUrl: data['avatarUrl'] ?? '',
      teacherName: data['teacherName'] ?? '',
      id: data['uid'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      dateOfBirth: data['dateOfBirth'] ?? '',
      gender: data['gender'] ?? '',
      qualification: data['qualification'] ?? '',
      currentAddress: data['currentAddress'] ?? '',
      permanentAddress: data['permanentAddress'] ?? '',
    );
  }
}
