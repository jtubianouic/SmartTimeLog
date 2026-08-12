import 'package:smarttimelog/domain/models/employee_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class EmployeeRepository {
  Future<List<EmployeeModel>> getUsers();
  Future<void> addUser(EmployeeModel employee);
}

class SupabaseEmployeeRepository implements EmployeeRepository {
  final SupabaseClient client;
  SupabaseEmployeeRepository(this.client);

  @override
  Future<List<EmployeeModel>> getUsers() async {
    final response = await client.from('employee').select();
    return (response as List).map((e) => EmployeeModel.fromJson(e)).toList();
  }

  @override
  Future<void> addUser(EmployeeModel employee) async {
    await client.from('users').insert(employee.toJson());
  }
}