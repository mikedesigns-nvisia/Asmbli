import { useState, useEffect, useCallback } from 'react';
import { Database } from '../lib/database';

// Custom hook for user data
export function useUser(userId?: string) {
  const [user, setUser] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchUser = useCallback(async (id: string) => {
    if (!id) return;
    
    setLoading(true);
    setError(null);
    
    try {
      const userData = await Database.getUserById(id);
      setUser(userData);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch user');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (userId) {
      fetchUser(userId);
    }
  }, [userId, fetchUser]);

  const updateUser = useCallback(async (updates: Partial<{ name: string; role: string }>) => {
    if (!userId) return;
    
    setLoading(true);
    setError(null);
    
    try {
      const updatedUser = await Database.updateUser(userId, updates);
      setUser(updatedUser);
      return updatedUser;
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update user');
      throw err;
    } finally {
      setLoading(false);
    }
  }, [userId]);

  return { user, loading, error, refetch: () => fetchUser(userId!), updateUser };
}

// Custom hook for agent configurations
export function useAgentConfigs(userId?: string) {
  const [configs, setConfigs] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchConfigs = useCallback(async (id: string) => {
    if (!id) return;
    
    setLoading(true);
    setError(null);
    
    try {
      const configData = await Database.getAgentConfigs(id);
      setConfigs(configData);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch configurations');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (userId) {
      fetchConfigs(userId);
    }
  }, [userId, fetchConfigs]);

  const saveConfig = useCallback(async (config: any) => {
    if (!userId) return;
    
    setLoading(true);
    setError(null);
    
    try {
      const newConfig = await Database.saveAgentConfig(userId, config);
      setConfigs(prev => [newConfig, ...prev]);
      await Database.logUserAction(userId, 'agent_config_saved', { configId: newConfig.id });
      return newConfig;
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save configuration');
      throw err;
    } finally {
      setLoading(false);
    }
  }, [userId]);

  const updateConfig = useCallback(async (configId: string, config: any) => {
    setLoading(true);
    setError(null);
    
    try {
      const updatedConfig = await Database.updateAgentConfig(configId, config);
      setConfigs(prev => prev.map(c => c.id === configId ? updatedConfig : c));
      if (userId) {
        await Database.logUserAction(userId, 'agent_config_updated', { configId });
      }
      return updatedConfig;
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update configuration');
      throw err;
    } finally {
      setLoading(false);
    }
  }, [userId]);

  const deleteConfig = useCallback(async (configId: string) => {
    setLoading(true);
    setError(null);
    
    try {
      await Database.deleteAgentConfig(configId);
      setConfigs(prev => prev.filter(c => c.id !== configId));
      if (userId) {
        await Database.logUserAction(userId, 'agent_config_deleted', { configId });
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete configuration');
      throw err;
    } finally {
      setLoading(false);
    }
  }, [userId]);

  return { 
    configs, 
    loading, 
    error, 
    refetch: () => fetchConfigs(userId!), 
    saveConfig, 
    updateConfig, 
    deleteConfig 
  };
}

// Custom hook for templates
export function useTemplates(userId?: string, publicOnly = false) {
  const [templates, setTemplates] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchTemplates = useCallback(async () => {
    setLoading(true);
    setError(null);
    
    try {
      let templateData;
      if (publicOnly) {
        templateData = await Database.getPublicTemplates();
      } else if (userId) {
        templateData = await Database.getUserTemplates(userId);
      } else {
        templateData = [];
      }
      setTemplates(templateData);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch templates');
    } finally {
      setLoading(false);
    }
  }, [userId, publicOnly]);

  useEffect(() => {
    fetchTemplates();
  }, [fetchTemplates]);

  const saveTemplate = useCallback(async (
    name: string, 
    description: string, 
    config: any, 
    isPublic = false
  ) => {
    setLoading(true);
    setError(null);
    
    try {
      const newTemplate = await Database.saveTemplate(name, description, config, isPublic, userId);
      if (!publicOnly || isPublic) {
        setTemplates(prev => [newTemplate, ...prev]);
      }
      if (userId) {
        await Database.logUserAction(userId, 'template_saved', { 
          templateId: newTemplate.id, 
          isPublic 
        });
      }
      return newTemplate;
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save template');
      throw err;
    } finally {
      setLoading(false);
    }
  }, [userId, publicOnly]);

  return { 
    templates, 
    loading, 
    error, 
    refetch: fetchTemplates, 
    saveTemplate 
  };
}

// Custom hook for key-value store
export function useKVStore() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const set = useCallback(async (key: string, value: any) => {
    setLoading(true);
    setError(null);
    
    try {
      await Database.set(key, value);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to set value');
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  const get = useCallback(async (key: string) => {
    setLoading(true);
    setError(null);
    
    try {
      const value = await Database.get(key);
      return value;
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to get value');
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  const remove = useCallback(async (key: string) => {
    setLoading(true);
    setError(null);
    
    try {
      await Database.delete(key);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete value');
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  const getByPrefix = useCallback(async (prefix: string) => {
    setLoading(true);
    setError(null);
    
    try {
      const values = await Database.getByPrefix(prefix);
      return values;
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to get values by prefix');
      throw err;
    } finally {
      setLoading(false);
    }
  }, []);

  return { loading, error, set, get, remove, getByPrefix };
}

// Custom hook for user analytics
export function useUserAnalytics(userId?: string, days = 30) {
  const [stats, setStats] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchStats = useCallback(async (id: string) => {
    if (!id) return;
    
    setLoading(true);
    setError(null);
    
    try {
      const statsData = await Database.getUserActionStats(id, days);
      setStats(statsData);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch analytics');
    } finally {
      setLoading(false);
    }
  }, [days]);

  useEffect(() => {
    if (userId) {
      fetchStats(userId);
    }
  }, [userId, fetchStats]);

  const logAction = useCallback(async (action: string, metadata?: any) => {
    if (!userId) return;
    
    try {
      await Database.logUserAction(userId, action, metadata);
    } catch (err) {
      console.error('Failed to log user action:', err);
    }
  }, [userId]);

  return { stats, loading, error, refetch: () => fetchStats(userId!), logAction };
}