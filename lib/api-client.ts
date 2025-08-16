// API client for frontend to communicate with Netlify functions
// This replaces direct database calls which don't work in browser

const API_BASE = '/.netlify/functions';

interface ApiResponse<T> {
  data?: T;
  error?: string;
}

// Generic API call wrapper with error handling
async function apiCall<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
  try {
    const response = await fetch(`${API_BASE}${endpoint}`, {
      headers: {
        'Content-Type': 'application/json',
        ...options.headers,
      },
      ...options,
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      throw new Error(errorData.error || `HTTP ${response.status}: ${response.statusText}`);
    }

    const data = await response.json();
    return data;
  } catch (error) {
    console.error(`API call failed for ${endpoint}:`, error);
    // In development, if API fails, fall back to static data
    if (process.env.NODE_ENV === 'development' || window.location.hostname === 'localhost') {
      console.warn('API failed, falling back to static extensions library for development');
      throw new Error('API_FALLBACK_NEEDED');
    }
    throw error;
  }
}

// Extensions API client
export class ExtensionsAPI {
  // Get all extensions with optional role filtering
  static async getAllExtensions(userRole?: string) {
    try {
      const params = userRole ? `?role=${encodeURIComponent(userRole)}` : '';
      const response = await apiCall<{ extensions: any[] }>(`/extensions${params}`);
      return response.extensions;
    } catch (error) {
      if (error instanceof Error && error.message === 'API_FALLBACK_NEEDED') {
        // Development fallback - import and use static extensions library
        console.log('🔧 Development Mode: Using static extensions library');
        const { extensionsLibrary } = await import('../data/extensions-library');
        
        // Apply role filtering like the database would
        let filteredExtensions = extensionsLibrary;
        if (userRole === 'beginner') {
          filteredExtensions = extensionsLibrary
            .filter(ext => ext.complexity === 'low' && ext.pricing !== 'paid')
            .slice(0, 10);
        }
        
        return filteredExtensions;
      }
      throw error;
    }
  }

  // Get extensions by category
  static async getExtensionsByCategory(category: string, userRole?: string) {
    try {
      const params = new URLSearchParams({ category });
      if (userRole) params.set('role', userRole);
      const response = await apiCall<{ extensions: any[] }>(`/extensions/category?${params}`);
      return response.extensions;
    } catch (error) {
      if (error instanceof Error && error.message === 'API_FALLBACK_NEEDED') {
        console.log('🔧 Development Mode: Using static extensions for category', category);
        const { extensionsLibrary } = await import('../data/extensions-library');
        
        // Filter by category
        let filteredExtensions = extensionsLibrary.filter(ext => ext.category === category);
        
        // Apply role filtering
        if (userRole === 'beginner') {
          filteredExtensions = filteredExtensions
            .filter(ext => ext.complexity === 'low' && ext.pricing !== 'paid');
        }
        
        return filteredExtensions;
      }
      throw error;
    }
  }

  // Get featured extensions
  static async getFeaturedExtensions(limit = 10) {
    try {
      const response = await apiCall<{ extensions: any[] }>(`/extensions/featured?limit=${limit}`);
      return response.extensions;
    } catch (error) {
      if (error instanceof Error && error.message === 'API_FALLBACK_NEEDED') {
        console.log('🔧 Development Mode: Using static featured extensions');
        const { extensionsLibrary } = await import('../data/extensions-library');
        
        // Return first few extensions as "featured"
        return extensionsLibrary.slice(0, limit);
      }
      throw error;
    }
  }

  // Get specific extension
  static async getExtensionById(extensionId: string) {
    const response = await apiCall<{ extension: any }>(`/extensions?id=${encodeURIComponent(extensionId)}`);
    return response.extension;
  }

  // Save user extension preference
  static async saveUserExtension(userId: string, extensionId: string, config: {
    isEnabled?: boolean;
    selectedPlatforms?: string[];
    configuration?: any;
    status?: string;
    configProgress?: number;
  }) {
    try {
      const response = await apiCall<{ result: any }>('/extensions', {
        method: 'POST',
        body: JSON.stringify({ userId, extensionId, config })
      });
      return response.result;
    } catch (error) {
      if (error instanceof Error && error.message === 'API_FALLBACK_NEEDED') {
        console.log('🔧 Development Mode: Skipping user extension save to database');
        console.log(`Would save extension ${extensionId} for user ${userId}:`, config);
        return { success: true, fallback: true };
      }
      throw error;
    }
  }

  // Remove user extension
  static async removeUserExtension(userId: string, extensionId: string) {
    try {
      await apiCall('/extensions', {
        method: 'DELETE',
        body: JSON.stringify({ userId, extensionId })
      });
    } catch (error) {
      if (error instanceof Error && error.message === 'API_FALLBACK_NEEDED') {
        console.log('🔧 Development Mode: Skipping user extension removal from database');
        console.log(`Would remove extension ${extensionId} for user ${userId}`);
        return;
      }
      throw error;
    }
  }
}

// User Extensions API client
export class UserExtensionsAPI {
  // Get user's extensions
  static async getUserExtensions(userId: string) {
    try {
      const response = await apiCall<{ userExtensions: any[] }>(`/user-extensions?userId=${encodeURIComponent(userId)}`);
      return response.userExtensions;
    } catch (error) {
      if (error instanceof Error && error.message === 'API_FALLBACK_NEEDED') {
        console.log('🔧 Development Mode: Using empty user extensions array');
        // In development, return empty array since no database is available
        return [];
      }
      throw error;
    }
  }

  // Log extension usage
  static async logExtensionUsage(userId: string, extensionId: string, action: string, metadata?: any, sessionId?: string) {
    try {
      await apiCall('/user-extensions', {
        method: 'POST',
        body: JSON.stringify({ extensionId, action, metadata, sessionId })
      });
    } catch (error) {
      if (error instanceof Error && error.message === 'API_FALLBACK_NEEDED') {
        console.log('🔧 Development Mode: Skipping extension usage logging');
        // In development, just log to console instead of database
        console.log(`Extension Usage: ${action} ${extensionId}`, { metadata, sessionId });
        return;
      }
      throw error;
    }
  }
}

// For backward compatibility, create a Database-like interface that calls APIs
export class DatabaseAPI {
  static getAllExtensions = ExtensionsAPI.getAllExtensions;
  static getExtensionsByCategory = ExtensionsAPI.getExtensionsByCategory;
  static getFeaturedExtensions = ExtensionsAPI.getFeaturedExtensions;
  static getExtensionById = ExtensionsAPI.getExtensionById;
  static saveUserExtension = ExtensionsAPI.saveUserExtension;
  static removeUserExtension = ExtensionsAPI.removeUserExtension;
  static getUserExtensions = UserExtensionsAPI.getUserExtensions;
  static logExtensionUsage = UserExtensionsAPI.logExtensionUsage;

  // Analytics placeholders (implement these endpoints later if needed)
  static async getExtensionUsageStats(extensionId: string, days = 30) {
    console.warn('getExtensionUsageStats not implemented yet');
    return [];
  }

  static async getUserExtensionUsage(userId: string, days = 30) {
    console.warn('getUserExtensionUsage not implemented yet');
    return [];
  }

  // Reviews placeholders (implement these endpoints later if needed)
  static async getExtensionReviews(extensionId: string, limit = 10) {
    console.warn('getExtensionReviews not implemented yet');
    return [];
  }

  static async saveExtensionReview(userId: string, extensionId: string, rating: number, reviewText?: string) {
    console.warn('saveExtensionReview not implemented yet');
    return null;
  }
}