import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _walletAddressKey = 'wallet_address';
  static const String _recentBountiesKey = 'recent_bounties';
  static const String _authTokenKey = 'auth_token'; // Key for JWT

  // Save wallet address
  Future<bool> saveWalletAddress(String walletAddress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_walletAddressKey, walletAddress);
    } catch (e) {
      // Silently fail but return false
      return false;
    }
  }

  // Get saved wallet address
  Future<String?> getWalletAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_walletAddressKey);
    } catch (e) {
      // Return null if there's an error
      return null;
    }
  }

  // Save the authentication token (JWT)
  Future<bool> saveAuthToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_authTokenKey, token);
    } catch (e) {
      return false;
    }
  }

  // Get the saved authentication token (JWT)
  Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_authTokenKey);
    } catch (e) {
      return null;
    }
  }

  // Delete the saved authentication token (JWT)
  Future<bool> deleteAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_authTokenKey);
    } catch (e) {
      return false;
    }
  }

  // Save a recently viewed bounty ID
  Future<bool> saveRecentBounty(String bountyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentBounties = prefs.getStringList(_recentBountiesKey) ?? [];

      // Remove if already exists (to avoid duplicates)
      recentBounties.remove(bountyId);

      // Add to the beginning
      recentBounties.insert(0, bountyId);

      // Keep only the most recent 5
      final limitedList = recentBounties.take(5).toList();

      return await prefs.setStringList(_recentBountiesKey, limitedList);
    } catch (e) {
      return false;
    }
  }

  // Get recent bounty IDs
  Future<List<String>> getRecentBounties() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_recentBountiesKey) ?? [];
    } catch (e) {
      return [];
    }
  }
}
