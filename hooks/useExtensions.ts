import { useState, useEffect, useCallback } from 'react';
import { DatabaseAPI } from '../lib/api-client';
import { Extension } from '../types/wizard';
import { useAuth } from '../contexts/AuthContext';

// Hook for getting all extensions
export function useExtensions(userRole?: string) {
  const [extensions, setExtensions] = useState<Extension[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadExtensions = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await DatabaseAPI.getAllExtensions(userRole);
      
      // Convert database format to Extension interface
      const formattedExtensions: Extension[] = data.map(ext => ({
        id: ext.id,
        name: ext.name,
        description: ext.description,
        category: ext.category,
        provider: ext.provider,
        icon: ext.icon,
        complexity: ext.complexity as 'low' | 'medium' | 'high',
        enabled: ext.enabled,
        connectionType: ext.connection_type as 'mcp' | 'api' | 'extension' | 'webhook',
        authMethod: ext.auth_method,
        pricing: ext.pricing as 'free' | 'freemium' | 'paid',
        features: ext.features || [],
        capabilities: ext.capabilities || [],
        requirements: ext.requirements || [],
        documentation: ext.documentation,
        setupComplexity: ext.setup_complexity,
        configuration: ext.configuration || {},
        supportedConnectionTypes: ext.supported_connection_types || [],
        // Add missing fields from database schema
        securityLevel: ext.security_level as 'low' | 'medium' | 'high' || 'medium',
        version: ext.version || '1.0.0',
        isOfficial: ext.is_official || false,
        isFeatured: ext.is_featured || false,
        isVerified: ext.is_verified || false,
        usageCount: ext.usage_count || 0,
        rating: ext.rating || 0
      }));
      
      setExtensions(formattedExtensions);
    } catch (err) {
      // Console output removed for production
      setError(err instanceof Error ? err.message : 'Failed to load extensions');
    } finally {
      setLoading(false);
    }
  }, [userRole]);

  useEffect(() => {
    loadExtensions();
  }, [loadExtensions]);

  return {
    extensions,
    loading,
    error,
    refetch: loadExtensions
  };
}

// Hook for getting extensions by category
export function useExtensionsByCategory(category: string, userRole?: string) {
  const [extensions, setExtensions] = useState<Extension[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadExtensions = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await DatabaseAPI.getExtensionsByCategory(category, userRole);
      
      const formattedExtensions: Extension[] = data.map(ext => ({
        id: ext.id,
        name: ext.name,
        description: ext.description,
        category: ext.category,
        provider: ext.provider,
        icon: ext.icon,
        complexity: ext.complexity as 'low' | 'medium' | 'high',
        enabled: ext.enabled,
        connectionType: ext.connection_type as 'mcp' | 'api' | 'extension' | 'webhook',
        authMethod: ext.auth_method,
        pricing: ext.pricing as 'free' | 'freemium' | 'paid',
        features: ext.features || [],
        capabilities: ext.capabilities || [],
        requirements: ext.requirements || [],
        documentation: ext.documentation,
        setupComplexity: ext.setup_complexity,
        configuration: ext.configuration || {},
        supportedConnectionTypes: ext.supported_connection_types || [],
        securityLevel: ext.security_level as 'low' | 'medium' | 'high' || 'medium',
        version: ext.version || '1.0.0',
        isOfficial: ext.is_official || false,
        isFeatured: ext.is_featured || false,
        isVerified: ext.is_verified || false,
        usageCount: ext.usage_count || 0,
        rating: ext.rating || 0
      }));
      
      setExtensions(formattedExtensions);
    } catch (err) {
      // Console output removed for production
      setError(err instanceof Error ? err.message : 'Failed to load extensions');
    } finally {
      setLoading(false);
    }
  }, [category, userRole]);

  useEffect(() => {
    loadExtensions();
  }, [loadExtensions]);

  return {
    extensions,
    loading,
    error,
    refetch: loadExtensions
  };
}

// Hook for getting featured extensions
export function useFeaturedExtensions(limit = 10) {
  const [extensions, setExtensions] = useState<Extension[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadExtensions = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await DatabaseAPI.getFeaturedExtensions(limit);
      
      const formattedExtensions: Extension[] = data.map(ext => ({
        id: ext.id,
        name: ext.name,
        description: ext.description,
        category: ext.category,
        provider: ext.provider,
        icon: ext.icon,
        complexity: ext.complexity as 'low' | 'medium' | 'high',
        enabled: ext.enabled,
        connectionType: ext.connection_type as 'mcp' | 'api' | 'extension' | 'webhook',
        authMethod: ext.auth_method,
        pricing: ext.pricing as 'free' | 'freemium' | 'paid',
        features: ext.features || [],
        capabilities: ext.capabilities || [],
        requirements: ext.requirements || [],
        documentation: ext.documentation,
        setupComplexity: ext.setup_complexity,
        configuration: ext.configuration || {},
        supportedConnectionTypes: ext.supported_connection_types || [],
        securityLevel: ext.security_level as 'low' | 'medium' | 'high' || 'medium',
        version: ext.version || '1.0.0',
        isOfficial: ext.is_official || false,
        isFeatured: ext.is_featured || false,
        isVerified: ext.is_verified || false,
        usageCount: ext.usage_count || 0,
        rating: ext.rating || 0
      }));
      
      setExtensions(formattedExtensions);
    } catch (err) {
      // Console output removed for production
      setError(err instanceof Error ? err.message : 'Failed to load featured extensions');
    } finally {
      setLoading(false);
    }
  }, [limit]);

  useEffect(() => {
    loadExtensions();
  }, [loadExtensions]);

  return {
    extensions,
    loading,
    error,
    refetch: loadExtensions
  };
}

// Hook for managing user extensions
export function useUserExtensions() {
  const { user } = useAuth();
  const [userExtensions, setUserExtensions] = useState<Extension[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadUserExtensions = useCallback(async () => {
    if (!user?.id) {
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      setError(null);
      const data = await DatabaseAPI.getUserExtensions(user.id);
      setUserExtensions(data);
    } catch (err) {
      // Console output removed for production
      setError(err instanceof Error ? err.message : 'Failed to load user extensions');
    } finally {
      setLoading(false);
    }
  }, [user?.id]);

  const saveUserExtension = useCallback(async (
    extensionId: string,
    config: {
      isEnabled?: boolean;
      selectedPlatforms?: string[];
      configuration?: any;
      status?: string;
      configProgress?: number;
    }
  ) => {
    if (!user?.id) {
      throw new Error('User not authenticated');
    }

    try {
      await DatabaseAPI.saveUserExtension(user.id, extensionId, config);
      await loadUserExtensions(); // Refresh the list
      
      // Log usage analytics
      await DatabaseAPI.logExtensionUsage(
        user.id, 
        extensionId, 
        config.isEnabled ? 'selected' : 'deselected',
        { platforms: config.selectedPlatforms, status: config.status }
      );
    } catch (err) {
      // Console output removed for production
      throw err;
    }
  }, [user?.id, loadUserExtensions]);

  const removeUserExtension = useCallback(async (extensionId: string) => {
    if (!user?.id) {
      throw new Error('User not authenticated');
    }

    try {
      await DatabaseAPI.removeUserExtension(user.id, extensionId);
      await loadUserExtensions(); // Refresh the list
      
      // Log usage analytics
      await DatabaseAPI.logExtensionUsage(
        user.id, 
        extensionId, 
        'removed'
      );
    } catch (err) {
      // Console output removed for production
      throw err;
    }
  }, [user?.id, loadUserExtensions]);

  const logExtensionUsage = useCallback(async (
    extensionId: string, 
    action: string, 
    metadata?: any
  ) => {
    if (!user?.id) return;

    try {
      await DatabaseAPI.logExtensionUsage(user.id, extensionId, action, metadata);
    } catch (err) {
      // Console output removed for production
    }
  }, [user?.id]);

  useEffect(() => {
    loadUserExtensions();
  }, [loadUserExtensions]);

  return {
    userExtensions,
    loading,
    error,
    saveUserExtension,
    removeUserExtension,
    logExtensionUsage,
    refetch: loadUserExtensions
  };
}

// Hook for extension analytics
export function useExtensionAnalytics(extensionId?: string) {
  const { user } = useAuth();
  const [stats, setStats] = useState<any>(null);
  const [userUsage, setUserUsage] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadAnalytics = useCallback(async () => {
    if (!user?.id) {
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      setError(null);
      
      const [statsData, userUsageData] = await Promise.all([
        extensionId ? Database.getExtensionUsageStats(extensionId) : Promise.resolve(null),
        Database.getUserExtensionUsage(user.id)
      ]);
      
      setStats(statsData);
      setUserUsage(userUsageData);
    } catch (err) {
      // Console output removed for production
      setError(err instanceof Error ? err.message : 'Failed to load analytics');
    } finally {
      setLoading(false);
    }
  }, [user?.id, extensionId]);

  useEffect(() => {
    loadAnalytics();
  }, [loadAnalytics]);

  return {
    stats,
    userUsage,
    loading,
    error,
    refetch: loadAnalytics
  };
}

// Hook for extension reviews
export function useExtensionReviews(extensionId: string) {
  const { user } = useAuth();
  const [reviews, setReviews] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadReviews = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await DatabaseAPI.getExtensionReviews(extensionId);
      setReviews(data);
    } catch (err) {
      // Console output removed for production
      setError(err instanceof Error ? err.message : 'Failed to load reviews');
    } finally {
      setLoading(false);
    }
  }, [extensionId]);

  const saveReview = useCallback(async (rating: number, reviewText?: string) => {
    if (!user?.id) {
      throw new Error('User not authenticated');
    }

    try {
      await DatabaseAPI.saveExtensionReview(user.id, extensionId, rating, reviewText);
      await loadReviews(); // Refresh the list
    } catch (err) {
      // Console output removed for production
      throw err;
    }
  }, [user?.id, extensionId, loadReviews]);

  useEffect(() => {
    loadReviews();
  }, [loadReviews]);

  return {
    reviews,
    loading,
    error,
    saveReview,
    refetch: loadReviews
  };
}