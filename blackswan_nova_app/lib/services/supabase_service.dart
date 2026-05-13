import 'dart:convert';
import 'package:http/http.dart' as http;

class SupabaseService {
  static const String _url = 'https://pnjfbhgztzjkuhowbayu.supabase.co';
  static const String _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBuamZiaGd6dHpqa3Vob3diYXl1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY5NTk2NjUsImV4cCI6MjA5MjUzNTY2NX0.ZgDU6wkgBu5oQu8CYvCzpxIGXQMc6qG3v39RKFeNsQg';

  static Map<String, String> get _headers => {
        'apikey': _anonKey,
        'Authorization': 'Bearer $_anonKey',
        'Content-Type': 'application/json',
      };

  /// Fetch all instruments from Supabase
  static Future<List<Map<String, dynamic>>> fetchInstruments() async {
    final response = await http.get(
      Uri.parse('$_url/rest/v1/instruments?select=*&order=name'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    throw Exception('Failed to fetch instruments: ${response.statusCode}');
  }

  /// Fetch instruments by class type
  static Future<List<Map<String, dynamic>>> fetchByClass(String cls) async {
    final response = await http.get(
      Uri.parse(
          '$_url/rest/v1/instruments?select=*&cls=eq.$cls&order=name'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    throw Exception('Failed to fetch instruments: ${response.statusCode}');
  }

  /// Fetch financials for a specific instrument
  static Future<List<Map<String, dynamic>>> fetchFinancials(
      String instrumentId) async {
    final response = await http.get(
      Uri.parse(
          '$_url/rest/v1/financials?select=*&instrument_id=eq.$instrumentId&order=year'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    throw Exception('Failed to fetch financials: ${response.statusCode}');
  }
}
