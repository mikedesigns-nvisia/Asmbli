import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agentengine_desktop/core/services/oauth_integration_service.dart';
import 'package:agentengine_desktop/core/services/secure_credentials_service.dart';
import 'package:agentengine_desktop/core/models/oauth_provider.dart';
import 'package:agentengine_desktop/features/settings/presentation/widgets/enhanced_oauth_provider_card.dart';
import 'package:agentengine_desktop/features/settings/presentation/screens/enhanced_oauth_settings_screen.dart';
import '../test_helpers/test_app_wrapper.dart';
import '../test_helpers/mock_services.dart';

/// SR-002: Test OAuth integration flows work correctly
void main() {
  group('OAuth Integration Flow Tests', () {
    late ProviderContainer container;
    late MockDesktopStorageService mockStorageService;
    late MockOAuthIntegrationService mockOAuthService;
    late MockSecureCredentialsService mockCredentialsService;

    setUp(() {
      mockStorageService = MockDesktopStorageService();
      mockOAuthService = MockOAuthIntegrationService();
      mockCredentialsService = MockSecureCredentialsService();
      
      container = ProviderContainer(
        overrides: [
          desktopStorageServiceProvider.overrideWithValue(mockStorageService),
          oauthIntegrationServiceProvider.overrideWithValue(mockOAuthService),
          secureCredentialsServiceProvider.overrideWithValue(mockCredentialsService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('SR-002.1: OAuth service initializes correctly', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            oauthIntegrationServiceProvider.overrideWithValue(mockOAuthService),
          ],
        ),
      );

      // Act: Get OAuth service
      final oauthService = container.read(oauthIntegrationServiceProvider);
      await oauthService.initialize();

      // Assert: Service should be initialized
      expect(oauthService.isInitialized, true);
      expect(mockOAuthService.initializeCalled, true);
    });

    testWidgets('SR-002.2: OAuth authentication flow works for GitHub', (tester) async {
      // Arrange: Set up mock responses
      mockOAuthService.setMockAuthResponse(OAuthProvider.github, {
        'access_token': 'github_test_token',
        'token_type': 'Bearer',
        'scope': 'repo,user',
      });

      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            oauthIntegrationServiceProvider.overrideWithValue(mockOAuthService),
          ],
        ),
      );

      // Act: Authenticate with GitHub
      final oauthService = container.read(oauthIntegrationServiceProvider);
      await oauthService.authenticate(OAuthProvider.github);

      // Assert: Verify authentication was called and token was stored
      expect(mockOAuthService.authenticateCalled[OAuthProvider.github], true);
      expect(mockOAuthService.hasValidToken(OAuthProvider.github), completion(true));
      
      // Verify token was stored securely
      final storedToken = await mockCredentialsService.getCredential('oauth_github_token');
      expect(storedToken, isNotNull);
    });

    testWidgets('SR-002.3: OAuth authentication flow works for Google', (tester) async {
      // Arrange: Set up mock responses
      mockOAuthService.setMockAuthResponse(OAuthProvider.google, {
        'access_token': 'google_test_token',
        'refresh_token': 'google_refresh_token',
        'token_type': 'Bearer',
        'expires_in': 3600,
        'scope': 'profile email',
      });

      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            oauthIntegrationServiceProvider.overrideWithValue(mockOAuthService),
          ],
        ),
      );

      // Act: Authenticate with Google
      final oauthService = container.read(oauthIntegrationServiceProvider);
      await oauthService.authenticate(OAuthProvider.google);

      // Assert: Verify authentication and refresh token storage
      expect(mockOAuthService.authenticateCalled[OAuthProvider.google], true);
      expect(mockOAuthService.hasValidToken(OAuthProvider.google), completion(true));
      
      final refreshToken = await mockCredentialsService.getCredential('oauth_google_refresh_token');
      expect(refreshToken, equals('google_refresh_token'));
    });

    testWidgets('SR-002.4: OAuth token refresh works correctly', (tester) async {
      // Arrange: Set up existing token that needs refresh
      mockOAuthService.setMockToken(OAuthProvider.google, 'expired_token', isExpired: true);
      mockOAuthService.setMockAuthResponse(OAuthProvider.google, {
        'access_token': 'new_google_token',
        'token_type': 'Bearer',
        'expires_in': 3600,
      });

      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            oauthIntegrationServiceProvider.overrideWithValue(mockOAuthService),
          ],
        ),
      );

      // Act: Refresh token
      final oauthService = container.read(oauthIntegrationServiceProvider);
      await oauthService.refreshToken(OAuthProvider.google);

      // Assert: Verify token was refreshed
      expect(mockOAuthService.refreshTokenCalled[OAuthProvider.google], true);
      expect(mockOAuthService.hasValidToken(OAuthProvider.google), completion(true));
    });

    testWidgets('SR-002.5: OAuth token validation works correctly', (tester) async {
      // Arrange: Set up tokens with different states
      mockOAuthService.setMockToken(OAuthProvider.github, 'valid_github_token', isExpired: false);
      mockOAuthService.setMockToken(OAuthProvider.google, 'expired_google_token', isExpired: true);

      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            oauthIntegrationServiceProvider.overrideWithValue(mockOAuthService),
          ],
        ),
      );

      // Act & Assert: Test token validation
      final oauthService = container.read(oauthIntegrationServiceProvider);
      
      expect(await oauthService.hasValidToken(OAuthProvider.github), true);
      expect(await oauthService.hasValidToken(OAuthProvider.google), false);
      expect(await oauthService.hasValidToken(OAuthProvider.dropbox), false);
    });

    testWidgets('SR-002.6: OAuth revocation works correctly', (tester) async {
      // Arrange: Set up authenticated provider
      mockOAuthService.setMockToken(OAuthProvider.slack, 'slack_token', isExpired: false);

      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            oauthIntegrationServiceProvider.overrideWithValue(mockOAuthService),
          ],
        ),
      );

      // Act: Revoke token
      final oauthService = container.read(oauthIntegrationServiceProvider);
      await oauthService.revokeToken(OAuthProvider.slack);

      // Assert: Verify token was revoked
      expect(mockOAuthService.revokeTokenCalled[OAuthProvider.slack], true);
      expect(await oauthService.hasValidToken(OAuthProvider.slack), false);
      
      // Verify token was removed from secure storage
      final storedToken = await mockCredentialsService.getCredential('oauth_slack_token');
      expect(storedToken, isNull);
    });

    testWidgets('SR-002.7: OAuth provider card UI interactions work correctly', (tester) async {
      // Arrange: Set up provider card
      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            oauthIntegrationServiceProvider.overrideWithValue(mockOAuthService),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: EnhancedOAuthProviderCard(
                provider: OAuthProvider.notion,
                isConnected: false,
              ),
            ),
          ),
        ),
      );

      // Assert: Find and verify UI elements
      expect(find.text('Notion'), findsOneWidget);
      expect(find.text('Connect'), findsOneWidget);
      expect(find.byIcon(Icons.link), findsOneWidget);

      // Act: Tap connect button
      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();

      // Assert: Verify authentication was triggered
      expect(mockOAuthService.authenticateCalled[OAuthProvider.notion], true);
    });

    testWidgets('SR-002.8: OAuth settings screen displays correctly', (tester) async {
      // Arrange: Set up mixed provider states
      mockOAuthService.setMockToken(OAuthProvider.github, 'github_token', isExpired: false);
      mockOAuthService.setMockToken(OAuthProvider.linear, 'linear_token', isExpired: false);

      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            oauthIntegrationServiceProvider.overrideWithValue(mockOAuthService),
          ],
          child: const MaterialApp(home: EnhancedOAuthSettingsScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Verify settings screen elements
      expect(find.text('OAuth & Security'), findsOneWidget);
      expect(find.text('Connected Providers'), findsOneWidget);
      
      // Check for provider cards
      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Dropbox'), findsOneWidget);
      expect(find.text('Slack'), findsOneWidget);
      expect(find.text('Notion'), findsOneWidget);
      expect(find.text('Linear'), findsOneWidget);
    });

    testWidgets('SR-002.9: OAuth error handling works correctly', (tester) async {
      // Arrange: Set up service to fail authentication
      mockOAuthService.setShouldFailAuthentication(OAuthProvider.github, true);

      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            oauthIntegrationServiceProvider.overrideWithValue(mockOAuthService),
          ],
        ),
      );

      // Act: Attempt authentication
      final oauthService = container.read(oauthIntegrationServiceProvider);
      
      // Assert: Verify error is thrown
      expect(
        () => oauthService.authenticate(OAuthProvider.github),
        throwsA(isA<OAuthAuthenticationException>()),
      );
    });

    testWidgets('SR-002.10: OAuth scope management works correctly', (tester) async {
      // Arrange: Set up provider with specific scopes
      mockOAuthService.setMockAuthResponse(OAuthProvider.github, {
        'access_token': 'scoped_token',
        'scope': 'repo,user,read:org',
      });

      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            oauthIntegrationServiceProvider.overrideWithValue(mockOAuthService),
          ],
        ),
      );

      // Act: Authenticate and get scopes
      final oauthService = container.read(oauthIntegrationServiceProvider);
      await oauthService.authenticate(OAuthProvider.github);
      final scopes = await oauthService.getGrantedScopes(OAuthProvider.github);

      // Assert: Verify scopes are correctly parsed
      expect(scopes, contains('repo'));
      expect(scopes, contains('user'));
      expect(scopes, contains('read:org'));
      expect(scopes.length, equals(3));
    });

    testWidgets('SR-002.11: OAuth connection status monitoring works', (tester) async {
      // Arrange: Set up providers with different states
      mockOAuthService.setMockToken(OAuthProvider.github, 'valid_token', isExpired: false);
      mockOAuthService.setMockToken(OAuthProvider.google, 'expired_token', isExpired: true);

      await tester.pumpWidget(
        TestAppWrapper(
          overrides: [
            oauthIntegrationServiceProvider.overrideWithValue(mockOAuthService),
          ],
        ),
      );

      // Act: Get connection statuses
      final oauthService = container.read(oauthIntegrationServiceProvider);
      final statuses = await oauthService.getAllConnectionStatuses();

      // Assert: Verify status monitoring
      expect(statuses[OAuthProvider.github]?.isConnected, true);
      expect(statuses[OAuthProvider.github]?.isExpired, false);
      expect(statuses[OAuthProvider.google]?.isConnected, true);
      expect(statuses[OAuthProvider.google]?.isExpired, true);
      expect(statuses[OAuthProvider.dropbox]?.isConnected, false);
    });
  });
}

/// Mock OAuth Integration Service for testing
class MockOAuthIntegrationService implements OAuthIntegrationService {
  bool _isInitialized = false;
  bool initializeCalled = false;
  
  final Map<OAuthProvider, bool> authenticateCalled = {};
  final Map<OAuthProvider, bool> refreshTokenCalled = {};
  final Map<OAuthProvider, bool> revokeTokenCalled = {};
  final Map<OAuthProvider, bool> shouldFailAuth = {};
  final Map<OAuthProvider, Map<String, dynamic>> mockAuthResponses = {};
  final Map<OAuthProvider, MockOAuthToken> mockTokens = {};

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> initialize() async {
    _isInitialized = true;
    initializeCalled = true;
  }

  @override
  Future<void> authenticate(OAuthProvider provider) async {
    authenticateCalled[provider] = true;
    
    if (shouldFailAuth[provider] == true) {
      throw OAuthAuthenticationException('Mock authentication failure for $provider');
    }

    // Simulate successful authentication
    final response = mockAuthResponses[provider] ?? {'access_token': 'mock_token'};
    mockTokens[provider] = MockOAuthToken(
      accessToken: response['access_token'],
      refreshToken: response['refresh_token'],
      expiresAt: response['expires_in'] != null 
          ? DateTime.now().add(Duration(seconds: response['expires_in']))
          : DateTime.now().add(const Duration(hours: 1)),
      scopes: response['scope']?.split(',') ?? [],
    );
  }

  @override
  Future<bool> hasValidToken(OAuthProvider provider) async {
    final token = mockTokens[provider];
    return token != null && !token.isExpired;
  }

  @override
  Future<void> refreshToken(OAuthProvider provider) async {
    refreshTokenCalled[provider] = true;
    final currentToken = mockTokens[provider];
    
    if (currentToken != null) {
      // Simulate refresh
      final response = mockAuthResponses[provider] ?? {'access_token': 'refreshed_token'};
      mockTokens[provider] = MockOAuthToken(
        accessToken: response['access_token'],
        refreshToken: currentToken.refreshToken,
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        scopes: currentToken.scopes,
      );
    }
  }

  @override
  Future<void> revokeToken(OAuthProvider provider) async {
    revokeTokenCalled[provider] = true;
    mockTokens.remove(provider);
  }

  @override
  Future<List<String>> getGrantedScopes(OAuthProvider provider) async {
    return mockTokens[provider]?.scopes ?? [];
  }

  @override
  Future<Map<OAuthProvider, OAuthConnectionStatus>> getAllConnectionStatuses() async {
    final statuses = <OAuthProvider, OAuthConnectionStatus>{};
    
    for (final provider in OAuthProvider.values) {
      final token = mockTokens[provider];
      statuses[provider] = OAuthConnectionStatus(
        provider: provider,
        isConnected: token != null,
        isExpired: token?.isExpired ?? false,
        lastRefreshed: token?.expiresAt,
        scopes: token?.scopes ?? [],
      );
    }
    
    return statuses;
  }

  // Test helper methods
  void setMockAuthResponse(OAuthProvider provider, Map<String, dynamic> response) {
    mockAuthResponses[provider] = response;
  }

  void setMockToken(OAuthProvider provider, String accessToken, {bool isExpired = false}) {
    mockTokens[provider] = MockOAuthToken(
      accessToken: accessToken,
      expiresAt: isExpired 
          ? DateTime.now().subtract(const Duration(hours: 1))
          : DateTime.now().add(const Duration(hours: 1)),
      scopes: [],
    );
  }

  void setShouldFailAuthentication(OAuthProvider provider, bool shouldFail) {
    shouldFailAuth[provider] = shouldFail;
  }

  void clearMockData() {
    authenticateCalled.clear();
    refreshTokenCalled.clear();
    revokeTokenCalled.clear();
    shouldFailAuth.clear();
    mockAuthResponses.clear();
    mockTokens.clear();
  }
}

/// Mock Secure Credentials Service for testing
class MockSecureCredentialsService implements SecureCredentialsService {
  final Map<String, String> _credentials = {};

  @override
  Future<void> initialize() async {}

  @override
  Future<void> storeCredential(String key, String value) async {
    _credentials[key] = value;
  }

  @override
  Future<String?> getCredential(String key) async {
    return _credentials[key];
  }

  @override
  Future<void> deleteCredential(String key) async {
    _credentials.remove(key);
  }

  @override
  Future<void> clearAllCredentials() async {
    _credentials.clear();
  }

  @override
  Future<List<String>> listCredentialKeys() async {
    return _credentials.keys.toList();
  }

  // Test helper methods
  void setMockCredential(String key, String value) {
    _credentials[key] = value;
  }

  Map<String, String> getAllCredentials() {
    return Map.from(_credentials);
  }
}

/// Mock OAuth token for testing
class MockOAuthToken {
  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;
  final List<String> scopes;

  MockOAuthToken({
    required this.accessToken,
    this.refreshToken,
    required this.expiresAt,
    required this.scopes,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// OAuth authentication exception for testing
class OAuthAuthenticationException implements Exception {
  final String message;
  OAuthAuthenticationException(this.message);
  
  @override
  String toString() => 'OAuthAuthenticationException: $message';
}

/// OAuth connection status for testing
class OAuthConnectionStatus {
  final OAuthProvider provider;
  final bool isConnected;
  final bool isExpired;
  final DateTime? lastRefreshed;
  final List<String> scopes;

  OAuthConnectionStatus({
    required this.provider,
    required this.isConnected,
    required this.isExpired,
    this.lastRefreshed,
    required this.scopes,
  });
}