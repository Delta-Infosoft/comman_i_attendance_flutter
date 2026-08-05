import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../flavor_config.dart';
import '../model/tour_advance_expense_model.dart';

class TourAdvanceExpenseRepository {
  String get baseUrl => FlavorConfig.instance.baseUrl;

  /// Clean any HTML wrapper from API responses
  String _cleanResponse(String body) {
    try {
      final first = body.indexOf('{');
      final last = body.lastIndexOf('}');
      if (first != -1 && last != -1 && last > first) {
        return body.substring(first, last + 1);
      }
    } catch (_) {}
    return body;
  }

  /// Fetch list of Tour Advance Expenses
  Future<List<TourAdvanceExpenseItem>> fetchExpenses({
    required String fromDt,
    required String toDt,
  }) async {
    try {
      final uri = Uri.parse('${baseUrl}API_ViewTourAdvancedExpense.aspx');
      final request = http.MultipartRequest('POST', uri);
      request.fields['FromDt'] = fromDt;
      request.fields['ToDt'] = toDt;

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      final cleaned = _cleanResponse(body);
      debugPrint('TourAdvanceExpense View Response: $cleaned');

      final data = json.decode(cleaned);
      if (data['result'] is List) {
        return (data['result'] as List)
            .map((e) => TourAdvanceExpenseItem.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching tour advance expenses: $e');
    }
    return [];
  }

  /// Insert a new Tour Advance Expense record
  Future<Map<String, dynamic>> insertExpense({
    required String empId,
    required String requestDt,
    required String advanceAmount,
    required String remarks,
  }) async {
    try {
      final uri = Uri.parse('${baseUrl}API_InsertTourAdvancedExpense.aspx');
      final request = http.MultipartRequest('POST', uri);
      request.fields['EmpId'] = empId;
      request.fields['RequestDt'] = requestDt;
      request.fields['AdvanceAmount'] = advanceAmount;
      request.fields['Remarks'] = remarks;

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      final cleaned = _cleanResponse(body);
      debugPrint('TourAdvanceExpense Insert Response: $cleaned');

      final data = json.decode(cleaned);
      return data is Map<String, dynamic>
          ? data
          : {'status': '500', 'message': 'Unexpected response'};
    } catch (e) {
      debugPrint('Error inserting tour advance expense: $e');
      return {'status': '500', 'message': 'Error: $e'};
    }
  }

  /// Update an existing Tour Advance Expense record
  Future<Map<String, dynamic>> updateExpense({
    required String advanceExpenseId,
    required String empId,
    required String requestDt,
    required String advanceAmount,
    required String remarks,
  }) async {
    try {
      final uri = Uri.parse('${baseUrl}API_UpdateTourAdvancedExpense.aspx');
      final request = http.MultipartRequest('POST', uri);
      request.fields['AdvanceExpenseId'] = advanceExpenseId;
      request.fields['EmpId'] = empId;
      request.fields['RequestDt'] = requestDt;
      request.fields['AdvanceAmount'] = advanceAmount;
      request.fields['Remarks'] = remarks;

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      final cleaned = _cleanResponse(body);
      debugPrint('TourAdvanceExpense Update Response: $cleaned');

      final data = json.decode(cleaned);
      return data is Map<String, dynamic>
          ? data
          : {'status': '500', 'message': 'Unexpected response'};
    } catch (e) {
      debugPrint('Error updating tour advance expense: $e');
      return {'status': '500', 'message': 'Error: $e'};
    }
  }
}
