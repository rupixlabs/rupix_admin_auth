import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class RupixUser {
  final String id;
  final String email;
  final String name;
  final DateTime createdAt;

  RupixUser({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
  });

  factory RupixUser.fromJson(Map<String, dynamic> json) {
    return RupixUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

// Keeping the old User class for backward compatibility
class User {
  final String id;
  final String email;
  final String name;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Constructor to listen for auth state changes
  AuthService() {
    _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        // No stitching for admin
      }
    });
  }

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Get the current authenticated user
  Future<User?> getCurrentUser() async {
    final session = _supabase.auth.currentSession;
    if (session?.user != null) {
      final userMetadata = session!.user.userMetadata ?? {};
      final userName =
          userMetadata['name']?.toString() ??
          userMetadata['full_name']?.toString() ??
          '';

      DateTime createdAt;
      try {
        final createdAtRaw = session.user.createdAt;
        createdAt = DateTime.parse(createdAtRaw);
      } catch (e) {
        createdAt = DateTime.now();
      }

      return User(
        id: session.user.id,
        email: session.user.email ?? '',
        name: userName,
        createdAt: createdAt,
      );
    }
    return null;
  }

  /// Get the current user's role
  Future<String?> getCurrentUserRole() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return null;

      final List<dynamic> response = await _supabase
          .from('user_roles')
          .select('role')
          .eq('user_id', currentUser.id);

      if (response.isEmpty) return null;
      return response.first['role'] as String;
    } catch (e) {
      debugPrint('Exception while fetching user role: $e');
      return null;
    }
  }

  /// Check if the user is authorized for a specific partner
  /// Returns null if authorized, or an error message if not.
  Future<String?> validatePartnerAccess(String expectedPartnerId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return 'No authenticated user found.';

      final roleData = await _supabase
          .from('user_roles')
          .select('role, partner_id')
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (roleData == null) return 'User role not found.';

      final String role = roleData['role'];
      final String? assignedPartnerId = roleData['partner_id'];

      // Super Admins can access everything
      if (role == 'super_admin') return null;

      // Check if partner ID matches
      if (assignedPartnerId == expectedPartnerId) {
        return null;
      } else {
        // Fetch partner name for a better error message if possible
        return 'Access Denied: Your account is not authorized for this application.';
      }
    } catch (e) {
      debugPrint('Partner validation error: $e');
      return 'An error occurred while validating your access.';
    }
  }

  /// Check if the current user's profile is complete
  Future<bool> isProfileComplete() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return false;

      final response = await _supabase
          .from('user_profiles')
          .select('full_name, date_of_birth, gender')
          .eq('id', currentUser.id)
          .maybeSingle();

      if (response == null) return false;

      return response['full_name'] != null &&
          response['full_name'].toString().isNotEmpty &&
          response['date_of_birth'] != null &&
          response['gender'] != null;
    } catch (e) {
      debugPrint('Error checking profile completion: $e');
      return false;
    }
  }

  /// Get the current user's profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return null;

      return await _supabase
          .from('user_profiles')
          .select()
          .eq('id', currentUser.id)
          .maybeSingle();
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  /// Complete user profile and award bonus points
  Future<void> completeUserProfile({
    required String fullName,
    required String dateOfBirth,
    required String gender,
    String? email,
    String? phone,
    String? referralCode,
  }) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) throw Exception('No authenticated user');

    try {
      // 1. Update Public Profile Table
      await _supabase.from('user_profiles').upsert({
        'id': currentUser.id,
        'full_name': fullName,
        if (email != null) 'email': email,
        'date_of_birth': dateOfBirth,
        'gender': gender,
        // Note: phone/email are kept in auth.users primarily, but we mirror email for display
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 2. Update Auth Metadata and Email for Dashboard visibility
      await _supabase.auth.updateUser(
        UserAttributes(
          email: email,
          data: {'full_name': fullName, 'displayName': fullName},
        ),
      );

      if (referralCode != null && referralCode.trim().isNotEmpty) {
        await redeemReferralCode(referralCode.trim());
      }
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  /// Explicitly update user email in Auth and Profile
  Future<void> updateEmail(String newEmail) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) throw Exception('No authenticated user');

    try {
      // Update in Supabase Auth (This may send a confirmation email)
      await _supabase.auth.updateUser(UserAttributes(email: newEmail));

      // Mirror in public profile
      await _supabase
          .from('user_profiles')
          .update({
            'email': newEmail,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', currentUser.id);

      debugPrint('Email update initiated for: $newEmail');
    } catch (e) {
      debugPrint('Error updating email: $e');
      rethrow;
    }
  }

  /// Redeem a referral code
  Future<Map<String, dynamic>> redeemReferralCode(String code) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) throw Exception('No authenticated user');

    try {
      final response = await _supabase.rpc(
        'process_referral',
        params: {'user_id': currentUser.id, 'ref_code': code.toUpperCase()},
      );
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      debugPrint('Error redeeming referral code: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Get the current user's referral code
  Future<String?> getCurrentUserReferralCode() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return null;

      final response = await _supabase
          .from('user_profiles')
          .select('referral_code')
          .eq('id', currentUser.id)
          .maybeSingle();

      return response?['referral_code'] as String?;
    } catch (e) {
      debugPrint('Error fetching referral code: $e');
      return null;
    }
  }

  /// Get referral statistics
  Future<Map<String, dynamic>> getReferralStats() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return {};

      final profile = await _supabase
          .from('user_profiles')
          .select('referral_code, referred_by')
          .eq('id', currentUser.id)
          .maybeSingle();

      final referralsData = await _supabase
          .from('referrals')
          .select('id')
          .eq('referrer_id', currentUser.id);

      final history = await _supabase
          .from('referrals')
          .select('created_at, reward_points, referred:referred_id(full_name)')
          .eq('referrer_id', currentUser.id)
          .order('created_at', ascending: false);

      return {
        'referral_code': profile?['referral_code'],
        'has_referrer': profile?['referred_by'] != null,
        'total_referrals': referralsData.length,
        'history': history,
      };
    } catch (e) {
      debugPrint('Error fetching referral stats: $e');
      return {};
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
    String? captchaToken,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
      captchaToken: captchaToken,
    );
  }

  Future<void> resetPasswordForEmail(
    String email, {
    String? captchaToken,
  }) async {
    await _supabase.auth.resetPasswordForEmail(
      email,
      captchaToken: captchaToken,
    );
  }
}
