import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _walletAddressKey = 'wallet_address';
  static const String _recentBountiesKey = 'recent_bounties';

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