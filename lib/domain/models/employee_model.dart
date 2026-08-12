import 'package:smarttimelog/domain/data/employee.dart';

class EmployeeModel extends Employee {
  const EmployeeModel({
    required super.employeeId,
    required super.username,
    required super.password,
    required super.firstname,
    required super.lastname,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      employeeId: json['employee_id'] as int,
      username: json['username'] as String,
      password: json['password'] as String,
      firstname: json['firstname'] as String,
      lastname: json['lastname'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'username': username,
      'password': password,
      'firstname': firstname,
      'lastname': lastname,
    };
  }
}