import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Change this to your machine's local IP when testing on a physical device
  // For iOS simulator, localhost works. For Android emulator, use 10.0.2.2
  static const String _baseUrl = 'http://localhost:8000';

  static Future<Map<String, dynamic>> simulate({
    required double s0,
    required double mu,
    required double sigma,
    required int horizon,
    required int paths,
    required double investment,
    String assetClass = 'stock',
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/simulate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'S0': s0,
        'mu': mu,
        'sigma': sigma,
        'H': horizon,
        'N': paths,
        'inv': investment,
        'asset_class': assetClass,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Simulation failed: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> stressTest({
    required double s0,
    required double mu,
    required double sigma,
    required double shockPct,
    double volShockFactor = 2.0,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/stress'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'S0': s0,
        'mu': mu,
        'sigma': sigma,
        'shock_pct': shockPct,
        'vol_shock_factor': volShockFactor,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Stress test failed: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> portfolioSim({
    required List<Map<String, dynamic>> assets,
    required double investment,
    int paths = 5000,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/portfolio'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'assets': assets,
        'inv': investment,
        'N': paths,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Portfolio sim failed: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> fetchNews({
    String region = 'all',
    String topic = '',
    int limit = 30,
  }) async {
    final uri = Uri.parse('$_baseUrl/news').replace(queryParameters: {
      'region': region,
      'limit': limit.toString(),
      if (topic.isNotEmpty) 'topic': topic,
    });

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('News fetch failed: ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> sentimentSummary() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/news/sentiment-summary'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Sentiment fetch failed: ${response.statusCode}');
  }
}
