import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'bounty.dart';
import 'paid_bounty_item.dart';

class ApiService {
  // Base URL for the API - replace with your actual backend URL
  final String baseUrl;
  final http.Client _client;

  ApiService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  // Helper method to get headers - now async
  Future<Map<String, String>> _getHeaders() async {
    final headers = {'Content-Type': 'application/json'};
    try {
      // Directly get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      // Handle error if needed, e.g., log it
      print('Error fetching auth token for headers: $e');
    }
    return headers;
  }

  // Fetch all bounties
  Future<List<Bounty>> fetchBounties() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/bounties'),
        headers: await _getHeaders(), // Await the headers
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

  // Fetch recently paid bounties
  Future<List<PaidBountyItem>> fetchPaidBounties({int limit = 10}) async {
    try {
      final response = await _client.get(
        // Assuming the endpoint is /bounties/paid
        Uri.parse('$baseUrl/bounties/paid?limit=$limit'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => PaidBountyItem.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load paid bounties: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching paid bounties: $e');
    }
  }

  // Fetch paid bounties for a specific workflow
  Future<List<PaidBountyItem>> fetchPaidBountiesForWorkflow(
      {required String bountyId, int? limit}) async {
    try {
      String url = '$baseUrl/bounties/$bountyId/paid';
      if (limit != null) {
        url += '?limit=$limit';
      }
      final response = await _client.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => PaidBountyItem.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to load paid bounties for workflow $bountyId: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(
          'Error fetching paid bounties for workflow $bountyId: $e');
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
        headers: await _getHeaders(), // Await the headers
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
