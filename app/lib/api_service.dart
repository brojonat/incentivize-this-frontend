import 'dart:convert';
import 'package:http/http.dart' as http;
import 'bounty.dart';

class ApiService {
  // Base URL for the API - replace with your actual backend URL
  final String baseUrl;
  final http.Client _client;
  final String? _authToken; // Changed to final, set by constructor

  ApiService({
    required this.baseUrl,
    http.Client? client,
    String? authToken, // Add authToken to constructor
  })  : _client = client ?? http.Client(),
        _authToken = authToken; // Initialize _authToken

  // Helper method to get headers
  Map<String, String> _getHeaders() {
    final headers = {'Content-Type': 'application/json'};
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // Fetch all bounties
  Future<List<Bounty>> fetchBounties() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/bounties'),
        headers: _getHeaders(), // Use helper to add headers
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) {
          return Bounty.fromJson(json);
        }).toList();
      } else {
        throw Exception('Failed to load bounties: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching bounties: $e');
    }
  }

  // Submit a claim for a bounty
  Future<Map<String, dynamic>> submitClaim({
    required String bountyId,
    required String contentId,
    required String walletAddress,
    required String platformType,
    required String contentKind,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/bounties/assess'),
        headers: _getHeaders(), // Use helper to add headers
        body: json.encode({
          'bounty_id': bountyId,
          'content_id': contentId,
          'payout_wallet': walletAddress,
          'platform': platformType,
          'content_kind': contentKind,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return responseData;
      } else {
        throw Exception(
            'Failed to submit claim: ${responseData['reason'] ?? response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error submitting claim: $e');
    }
  }
}
