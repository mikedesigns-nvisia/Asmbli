import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

// Import only models and enums that don't require services
import 'package:agentengine_desktop/core/models/oauth_provider.dart';

/// Basic Integration Test Suite
/// 
/// This test suite validates that core models and enums work correctly
/// without requiring complex service initialization.
void main() {
  group('🧪 Basic Integration Tests', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      print('🚀 Starting Basic Integration Tests');
    });

    tearDownAll(() {
      print('✅ Basic Integration Tests Complete');
    });

    group('OAuth Model Integration', () {
      test('OAuth provider enum has expected values and functionality', () {
        // Test OAuth provider enum
        expect(OAuthProvider.values, isNotEmpty);
        expect(OAuthProvider.values.length, greaterThanOrEqualTo(6));
        
        // Test specific providers exist
        expect(OAuthProvider.values.contains(OAuthProvider.github), true);
        expect(OAuthProvider.values.contains(OAuthProvider.slack), true);
        expect(OAuthProvider.values.contains(OAuthProvider.notion), true);
        expect(OAuthProvider.values.contains(OAuthProvider.linear), true);
        expect(OAuthProvider.values.contains(OAuthProvider.microsoft), true);
        expect(OAuthProvider.values.contains(OAuthProvider.braveSearch), true);

        // Test provider properties
        expect(OAuthProvider.github.displayName, 'GitHub');
        expect(OAuthProvider.slack.displayName, 'Slack');
        expect(OAuthProvider.notion.displayName, 'Notion');
        expect(OAuthProvider.linear.displayName, 'Linear');
        expect(OAuthProvider.microsoft.displayName, 'Microsoft');
        expect(OAuthProvider.braveSearch.displayName, 'Brave Search');
        
        // Test provider domains
        expect(OAuthProvider.github.domain, 'github.com');
        expect(OAuthProvider.slack.domain, 'slack.com');
        expect(OAuthProvider.notion.domain, 'notion.so');
        
        // Test provider info access
        expect(OAuthProvider.github.info, isNotNull);
        expect(OAuthProvider.github.info.name, 'GitHub');
        expect(OAuthProvider.github.info.capabilities, isNotEmpty);
        expect(OAuthProvider.github.info.description, isNotEmpty);
        expect(OAuthProvider.github.info.iconPath, isNotEmpty);
        expect(OAuthProvider.github.info.documentationUrl, isNotEmpty);
      });

      test('OAuth connection status enum works correctly', () {
        // Test OAuth connection status enum
        expect(OAuthConnectionStatus.values, isNotEmpty);
        expect(OAuthConnectionStatus.values.length, equals(5));
        
        // Test all statuses exist
        expect(OAuthConnectionStatus.values.contains(OAuthConnectionStatus.disconnected), true);
        expect(OAuthConnectionStatus.values.contains(OAuthConnectionStatus.connecting), true);
        expect(OAuthConnectionStatus.values.contains(OAuthConnectionStatus.connected), true);
        expect(OAuthConnectionStatus.values.contains(OAuthConnectionStatus.expired), true);
        expect(OAuthConnectionStatus.values.contains(OAuthConnectionStatus.error), true);
        
        // Test status properties
        expect(OAuthConnectionStatus.connected.displayName, 'Connected');
        expect(OAuthConnectionStatus.disconnected.displayName, 'Disconnected');
        expect(OAuthConnectionStatus.expired.displayName, 'Expired');
        expect(OAuthConnectionStatus.error.displayName, 'Error');
        expect(OAuthConnectionStatus.connecting.displayName, 'Connecting');
        
        // Test status descriptions
        expect(OAuthConnectionStatus.connected.description, isNotEmpty);
        expect(OAuthConnectionStatus.disconnected.description, isNotEmpty);
        
        // Test active states
        expect(OAuthConnectionStatus.connected.isActive, true);
        expect(OAuthConnectionStatus.disconnected.isActive, false);
        expect(OAuthConnectionStatus.expired.isActive, false);
        expect(OAuthConnectionStatus.error.isActive, false);
        expect(OAuthConnectionStatus.connecting.isActive, false);
        
        // Test needs action
        expect(OAuthConnectionStatus.expired.needsAction, true);
        expect(OAuthConnectionStatus.error.needsAction, true);
        expect(OAuthConnectionStatus.disconnected.needsAction, true);
        expect(OAuthConnectionStatus.connected.needsAction, false);
        expect(OAuthConnectionStatus.connecting.needsAction, false);
      });

      test('OAuth provider state model works correctly', () {
        final now = DateTime.now();
        
        // Test OAuth provider state creation
        final providerState = OAuthProviderState(
          provider: OAuthProvider.github,
          status: OAuthConnectionStatus.connected,
          connectedAt: now,
          grantedScopes: ['repo', 'user'],
        );
        
        expect(providerState.provider, OAuthProvider.github);
        expect(providerState.status, OAuthConnectionStatus.connected);
        expect(providerState.isConnected, true);
        expect(providerState.grantedScopes, ['repo', 'user']);
        expect(providerState.connectedAt, now);
        
        // Test copyWith functionality
        final updatedState = providerState.copyWith(
          status: OAuthConnectionStatus.expired,
        );
        
        expect(updatedState.provider, OAuthProvider.github);
        expect(updatedState.status, OAuthConnectionStatus.expired);
        expect(updatedState.isConnected, false);
        expect(updatedState.grantedScopes, ['repo', 'user']); // Should be preserved
        expect(updatedState.connectedAt, now); // Should be preserved
        
        // Test with expiration dates
        final expiredState = OAuthProviderState(
          provider: OAuthProvider.slack,
          status: OAuthConnectionStatus.expired,
          expiresAt: now.subtract(const Duration(days: 1)),
        );
        
        expect(expiredState.isConnected, false);
        expect(expiredState.isExpired, true);
        
        // Test expiring soon
        final expiringSoonState = OAuthProviderState(
          provider: OAuthProvider.notion,
          status: OAuthConnectionStatus.connected,
          expiresAt: now.add(const Duration(days: 3)),
        );
        
        expect(expiringSoonState.isConnected, true);
        expect(expiringSoonState.isExpiringSoon, true);
        
        // Test not expiring soon
        final notExpiringSoonState = OAuthProviderState(
          provider: OAuthProvider.linear,
          status: OAuthConnectionStatus.connected,
          expiresAt: now.add(const Duration(days: 30)),
        );
        
        expect(notExpiringSoonState.isConnected, true);
        expect(notExpiringSoonState.isExpiringSoon, false);
      });
    });

    group('OAuth Provider Comprehensive Tests', () {
      test('All OAuth providers have complete information', () {
        // Test that each provider has complete information
        for (final provider in OAuthProvider.values) {
          final info = provider.info;
          
          // Basic information
          expect(info.name, isNotEmpty, reason: '${provider.name} should have a name');
          expect(info.description, isNotEmpty, reason: '${provider.name} should have a description');
          expect(info.capabilities, isNotEmpty, reason: '${provider.name} should have capabilities');
          expect(info.iconPath, isNotEmpty, reason: '${provider.name} should have an icon path');
          expect(info.documentationUrl, isNotEmpty, reason: '${provider.name} should have documentation URL');
          
          // Validate URL format (basic check)
          expect(info.documentationUrl.startsWith('http'), true, reason: '${provider.name} documentation URL should start with http');
          
          // Validate icon path format
          expect(info.iconPath.startsWith('assets/'), true, reason: '${provider.name} icon path should start with assets/');
          expect(info.iconPath.endsWith('.png'), true, reason: '${provider.name} icon path should be a PNG file');
          
          // Test that provider and info provider match
          expect(info.provider, provider, reason: 'Provider info should reference correct provider');
        }
      });

      test('OAuth provider state handles edge cases', () {
        final now = DateTime.now();
        
        // Test with minimal required fields
        final minimalState = OAuthProviderState(
          provider: OAuthProvider.github,
          status: OAuthConnectionStatus.disconnected,
        );
        
        expect(minimalState.provider, OAuthProvider.github);
        expect(minimalState.status, OAuthConnectionStatus.disconnected);
        expect(minimalState.connectedAt, isNull);
        expect(minimalState.lastUsed, isNull);
        expect(minimalState.expiresAt, isNull);
        expect(minimalState.grantedScopes, isEmpty);
        expect(minimalState.isRefreshable, false);
        
        // Test with all optional fields
        final fullState = OAuthProviderState(
          provider: OAuthProvider.slack,
          status: OAuthConnectionStatus.connected,
          connectedAt: now,
          lastUsed: now.subtract(const Duration(hours: 1)),
          expiresAt: now.add(const Duration(days: 30)),
          lastRefresh: now.subtract(const Duration(minutes: 30)),
          grantedScopes: ['channels:read', 'chat:write', 'files:write'],
          isRefreshable: true,
          error: null,
        );
        
        expect(fullState.provider, OAuthProvider.slack);
        expect(fullState.status, OAuthConnectionStatus.connected);
        expect(fullState.connectedAt, now);
        expect(fullState.grantedScopes.length, 3);
        expect(fullState.isRefreshable, true);
        
        // Test equality via props
        final identicalState = OAuthProviderState(
          provider: OAuthProvider.slack,
          status: OAuthConnectionStatus.connected,
          connectedAt: now,
          lastUsed: now.subtract(const Duration(hours: 1)),
          expiresAt: now.add(const Duration(days: 30)),
          lastRefresh: now.subtract(const Duration(minutes: 30)),
          grantedScopes: ['channels:read', 'chat:write', 'files:write'],
          isRefreshable: true,
          error: null,
        );
        
        expect(fullState == identicalState, true);
      });
    });

    group('Provider Container Integration', () {
      testWidgets('Provider container can be created and disposed without services', (tester) async {
        // Test that provider containers work without complex services
        final container = ProviderContainer();
        
        // Test basic provider container functionality
        expect(container, isNotNull);
        
        // Test disposal
        expect(() => container.dispose(), returnsNormally);
      });

      testWidgets('Multiple provider containers work independently', (tester) async {
        // Create multiple containers
        final containers = List.generate(3, (_) => ProviderContainer());
        
        // Verify all containers are independent
        for (int i = 0; i < containers.length; i++) {
          expect(containers[i], isNotNull);
          expect(containers[i], isNot(same(containers[(i + 1) % containers.length])));
        }
        
        // Dispose all containers
        for (final container in containers) {
          expect(() => container.dispose(), returnsNormally);
        }
      });
    });

    group('Integration Scenarios', () {
      test('OAuth models work together in complex scenarios', () {
        final now = DateTime.now();
        
        // Create multiple provider states
        final providerStates = [
          // Active GitHub connection
          OAuthProviderState(
            provider: OAuthProvider.github,
            status: OAuthConnectionStatus.connected,
            connectedAt: now.subtract(const Duration(hours: 2)),
            lastUsed: now.subtract(const Duration(minutes: 15)),
            grantedScopes: ['repo', 'user', 'notifications'],
            isRefreshable: true,
          ),
          
          // Expired Slack connection
          OAuthProviderState(
            provider: OAuthProvider.slack,
            status: OAuthConnectionStatus.expired,
            connectedAt: now.subtract(const Duration(days: 30)),
            expiresAt: now.subtract(const Duration(days: 1)),
            grantedScopes: ['channels:read', 'chat:write'],
          ),
          
          // Disconnected Notion
          OAuthProviderState(
            provider: OAuthProvider.notion,
            status: OAuthConnectionStatus.disconnected,
          ),
          
          // Expiring soon Linear connection
          OAuthProviderState(
            provider: OAuthProvider.linear,
            status: OAuthConnectionStatus.connected,
            connectedAt: now.subtract(const Duration(days: 25)),
            expiresAt: now.add(const Duration(days: 5)),
            grantedScopes: ['read', 'write'],
            isRefreshable: true,
          ),
        ];
        
        // Test filtering active connections
        final activeConnections = providerStates.where((state) => state.isConnected).toList();
        expect(activeConnections.length, 2);
        expect(activeConnections.any((state) => state.provider == OAuthProvider.github), true);
        expect(activeConnections.any((state) => state.provider == OAuthProvider.linear), true);
        
        // Test filtering expired connections
        final expiredConnections = providerStates.where((state) => state.isExpired).toList();
        expect(expiredConnections.length, 1);
        expect(expiredConnections.first.provider, OAuthProvider.slack);
        
        // Test filtering connections needing attention
        final needAttention = providerStates.where((state) => state.status.needsAction).toList();
        expect(needAttention.length, 2);
        expect(needAttention.any((state) => state.provider == OAuthProvider.slack), true); // expired
        expect(needAttention.any((state) => state.provider == OAuthProvider.notion), true); // disconnected
        
        // Test filtering expiring soon
        final expiringSoon = providerStates.where((state) => state.isExpiringSoon).toList();
        expect(expiringSoon.length, greaterThanOrEqualTo(1));
        expect(expiringSoon.any((state) => state.provider == OAuthProvider.linear), true);
        
        // Test total granted scopes count
        final totalScopes = providerStates
            .expand((state) => state.grantedScopes)
            .toSet()
            .length;
        expect(totalScopes, greaterThan(0));
        
        // Test refreshable connections
        final refreshableConnections = providerStates.where((state) => state.isRefreshable).toList();
        expect(refreshableConnections.length, 2);
      });
    });

    group('Model Validation', () {
      test('OAuth provider info is consistent with provider properties', () {
        for (final provider in OAuthProvider.values) {
          final info = provider.info;
          
          // Test that info name matches display name
          expect(info.name, provider.displayName);
          
          // Test that info provider matches
          expect(info.provider, provider);
          
          // Test domain consistency in description or capabilities
          final domainMentioned = info.description.toLowerCase().contains(provider.domain.split('.').first) ||
              info.capabilities.any((cap) => cap.toLowerCase().contains(provider.domain.split('.').first));
          expect(domainMentioned, true, reason: '${provider.name} info should mention the service');
        }
      });
    });
  });
}