import 'dart:async';
import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:student_fin_os/models/auth_user.dart';

class CognitoAuthService {
  CognitoAuthService() {
    final String userPoolId = dotenv.env['AWS_COGNITO_USER_POOL_ID'] ?? '';
    final String clientId = dotenv.env['AWS_COGNITO_CLIENT_ID'] ?? '';

    if (userPoolId.isNotEmpty && clientId.isNotEmpty) {
      _userPool = CognitoUserPool(userPoolId, clientId);
      _isConfigured = true;
      debugPrint('[CognitoAuthService] Real AWS Cognito configured successfully.');
    } else {
      debugPrint('[CognitoAuthService] AWS Cognito settings not found in .env. Running in Mock Auth mode.');
    }
  }

  CognitoUserPool? _userPool;
  bool _isConfigured = false;

  final StreamController<AuthUser?> _authController = StreamController<AuthUser?>.broadcast();
  AuthUser? _currentUser;

  AuthUser? get currentUser => _currentUser;

  Stream<AuthUser?> authStateChanges() {
    // Emit initial value after delay
    Future.delayed(const Duration(milliseconds: 100), () {
      _authController.add(_currentUser);
    });
    return _authController.stream;
  }

  Future<void> signOut() async {
    _currentUser = null;
    _authController.add(null);
    debugPrint('[CognitoAuthService] Signed out.');
  }

  Future<AuthUser> signInDemo() async {
    _currentUser = AuthUser(
      uid: 'demo_user_123',
      email: 'demo@wealthadvisor.in',
      displayName: 'Demo Builder',
    );
    _authController.add(_currentUser);
    debugPrint('[CognitoAuthService] Signed in with Demo Bypass.');
    return _currentUser!;
  }

  Future<void> requestEmailOtp({required String email}) async {
    final String cleanEmail = email.trim().toLowerCase();
    if (!_isConfigured) {
      debugPrint('[CognitoAuthService Mock] OTP requested for $cleanEmail. (Mock OTP is 123456)');
      return;
    }

    try {
      final CognitoUser user = CognitoUser(cleanEmail, _userPool!);
      
      try {
        final List<AttributeArg> attributes = <AttributeArg>[
          AttributeArg(name: 'email', value: cleanEmail),
        ];
        await _userPool!.signUp(cleanEmail, 'Password123!', userAttributes: attributes);
        debugPrint('[CognitoAuthService] Signed up new user: $cleanEmail');
      } catch (signUpError) {
        debugPrint('[CognitoAuthService] User already exists: $cleanEmail');
      }

      final AuthenticationDetails authDetails = AuthenticationDetails(
        username: cleanEmail,
      );

      user.setAuthenticationFlowType('CUSTOM_AUTH');
      await user.initiateAuth(authDetails);
      debugPrint('[CognitoAuthService] Real OTP challenge initiated for $cleanEmail.');
    } catch (e) {
      debugPrint('[CognitoAuthService] Error requesting OTP: $e');
      rethrow;
    }
  }

  Future<AuthUser> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    final String cleanEmail = email.trim().toLowerCase();
    final String cleanOtp = otp.trim();

    if (!_isConfigured) {
      if (cleanOtp == '123456' || cleanOtp.length == 6) {
        _currentUser = AuthUser(
          uid: 'mock_user_${cleanEmail.hashCode}',
          email: cleanEmail,
          displayName: cleanEmail.split('@').first,
        );
        _authController.add(_currentUser);
        return _currentUser!;
      } else {
        throw Exception('Invalid OTP. Use 123456 for Mock authentication.');
      }
    }

    try {
      final CognitoUser user = CognitoUser(cleanEmail, _userPool!);
      user.setAuthenticationFlowType('CUSTOM_AUTH');
      
      final CognitoUserSession? session = await user.sendCustomChallengeAnswer(cleanOtp);
      
      if (session != null && session.isValid()) {
        _currentUser = AuthUser(
          uid: cleanEmail,
          email: cleanEmail,
          displayName: cleanEmail.split('@').first,
        );
        _authController.add(_currentUser);
        return _currentUser!;
      } else {
        throw Exception('Invalid verification code.');
      }
    } catch (e) {
      debugPrint('[CognitoAuthService] OTP verification failed: $e');
      rethrow;
    }
  }
}
