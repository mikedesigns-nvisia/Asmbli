/**
 * Data Migration Utility
 * Migrates existing localStorage data to Neon database
 */

import { Database } from '../lib/database';
import { TemplateStorageDB } from './templateStorageDB';
import { AgentTemplate } from '../types/templates';
import { WizardData } from '../types/wizard';

// Keys used in localStorage
const STORAGE_KEYS = {
  TEMPLATES: 'agentengine_templates',
  CATEGORIES: 'agentengine_template_categories',
  USER_CONFIGS: 'agentengine_user_configs',
  USER_PREFERENCES: 'agentengine_user_preferences',
  WIZARD_DATA: 'agentengine_wizard_data',
  ONBOARDING: 'agentengine_onboarding_complete'
};

interface MigrationResult {
  success: boolean;
  migratedItems: number;
  errors: string[];
  summary: {
    templates: number;
    userConfigs: number;
    preferences: number;
    other: number;
  };
}

export class DataMigration {
  /**
   * Check if localStorage has data to migrate
   */
  static hasLocalStorageData(): boolean {
    try {
      const hasTemplates = localStorage.getItem(STORAGE_KEYS.TEMPLATES) !== null;
      const hasConfigs = localStorage.getItem(STORAGE_KEYS.USER_CONFIGS) !== null;
      const hasPreferences = localStorage.getItem(STORAGE_KEYS.USER_PREFERENCES) !== null;
      const hasWizardData = localStorage.getItem(STORAGE_KEYS.WIZARD_DATA) !== null;
      
      return hasTemplates || hasConfigs || hasPreferences || hasWizardData;
    } catch (error) {
      // Console output removed for production
      return false;
    }
  }

  /**
   * Get summary of data available for migration
   */
  static getLocalStorageSummary() {
    const summary = {
      templates: 0,
      userConfigs: 0,
      preferences: 0,
      wizardData: 0,
      onboardingComplete: false,
      totalSize: 0
    };

    try {
      // Count templates
      const templates = localStorage.getItem(STORAGE_KEYS.TEMPLATES);
      if (templates) {
        const templateData = JSON.parse(templates);
        summary.templates = Array.isArray(templateData) ? templateData.length : 0;
        summary.totalSize += templates.length;
      }

      // Check for user configs
      const configs = localStorage.getItem(STORAGE_KEYS.USER_CONFIGS);
      if (configs) {
        summary.userConfigs = 1;
        summary.totalSize += configs.length;
      }

      // Check for user preferences
      const preferences = localStorage.getItem(STORAGE_KEYS.USER_PREFERENCES);
      if (preferences) {
        summary.preferences = 1;
        summary.totalSize += preferences.length;
      }

      // Check for wizard data
      const wizardData = localStorage.getItem(STORAGE_KEYS.WIZARD_DATA);
      if (wizardData) {
        summary.wizardData = 1;
        summary.totalSize += wizardData.length;
      }

      // Check onboarding status
      summary.onboardingComplete = localStorage.getItem(STORAGE_KEYS.ONBOARDING) === 'true';

    } catch (error) {
      // Console output removed for production
    }

    return summary;
  }

  /**
   * Migrate all localStorage data to database
   */
  static async migrateAllData(userId: string): Promise<MigrationResult> {
    const result: MigrationResult = {
      success: true,
      migratedItems: 0,
      errors: [],
      summary: {
        templates: 0,
        userConfigs: 0,
        preferences: 0,
        other: 0
      }
    };

    try {
      // Console output removed for production

      // Migrate templates
      await this.migrateTemplates(userId, result);

      // Migrate user configurations
      await this.migrateUserConfigs(userId, result);

      // Migrate preferences
      await this.migratePreferences(userId, result);

      // Migrate other data
      await this.migrateOtherData(userId, result);

      // Console output removed for production
      
    } catch (error) {
      result.success = false;
      result.errors.push(`Migration failed: ${error instanceof Error ? error.message : String(error)}`);
      // Console output removed for production
    }

    return result;
  }

  /**
   * Migrate templates from localStorage to database
   */
  private static async migrateTemplates(userId: string, result: MigrationResult) {
    try {
      const templatesData = localStorage.getItem(STORAGE_KEYS.TEMPLATES);
      if (!templatesData) return;

      const templates: AgentTemplate[] = JSON.parse(templatesData);
      // Console output removed for production

      for (const template of templates) {
        try {
          if (!template.wizardData || !template.name) {
            result.errors.push(`Skipping invalid template: ${template.id || 'unknown'}`);
            continue;
          }

          await TemplateStorageDB.saveTemplate(
            template.wizardData,
            {
              name: template.name,
              description: template.description || '',
              category: template.category || 'custom',
              tags: template.tags || []
            },
            userId,
            template.isPublic || false
          );

          result.summary.templates++;
          result.migratedItems++;
          
          // Log usage if available
          if (template.usageCount && template.usageCount > 0) {
            await Database.logUserAction(userId, 'template_migrated', {
              templateName: template.name,
              originalUsageCount: template.usageCount
            });
          }

        } catch (error) {
          result.errors.push(`Failed to migrate template "${template.name}": ${error}`);
        }
      }

      // Console output removed for production

    } catch (error) {
      result.errors.push(`Template migration failed: ${error}`);
    }
  }

  /**
   * Migrate user configurations
   */
  private static async migrateUserConfigs(userId: string, result: MigrationResult) {
    try {
      const configsData = localStorage.getItem(STORAGE_KEYS.USER_CONFIGS);
      if (!configsData) return;

      const configs = JSON.parse(configsData);
      // Console output removed for production

      // If it's a wizard data object, save as agent config
      if (configs && typeof configs === 'object') {
        await Database.saveAgentConfig(userId, {
          ...configs,
          migratedFrom: 'localStorage',
          migratedAt: new Date().toISOString()
        });

        result.summary.userConfigs++;
        result.migratedItems++;
      }

      // Console output removed for production

    } catch (error) {
      result.errors.push(`User config migration failed: ${error}`);
    }
  }

  /**
   * Migrate user preferences
   */
  private static async migratePreferences(userId: string, result: MigrationResult) {
    try {
      const preferencesData = localStorage.getItem(STORAGE_KEYS.USER_PREFERENCES);
      if (!preferencesData) return;

      const preferences = JSON.parse(preferencesData);
      // Console output removed for production

      // Store preferences in key-value store
      await Database.set(`user_preferences_${userId}`, {
        ...preferences,
        migratedFrom: 'localStorage',
        migratedAt: new Date().toISOString()
      });

      result.summary.preferences++;
      result.migratedItems++;

      // Console output removed for production

    } catch (error) {
      result.errors.push(`Preferences migration failed: ${error}`);
    }
  }

  /**
   * Migrate other localStorage data
   */
  private static async migrateOtherData(userId: string, result: MigrationResult) {
    try {
      const otherItems = [];

      // Migrate wizard data
      const wizardData = localStorage.getItem(STORAGE_KEYS.WIZARD_DATA);
      if (wizardData) {
        await Database.set(`wizard_data_${userId}`, {
          data: JSON.parse(wizardData),
          migratedFrom: 'localStorage',
          migratedAt: new Date().toISOString()
        });
        otherItems.push('wizard_data');
      }

      // Migrate onboarding status
      const onboarding = localStorage.getItem(STORAGE_KEYS.ONBOARDING);
      if (onboarding) {
        await Database.set(`onboarding_${userId}`, {
          completed: onboarding === 'true',
          migratedFrom: 'localStorage',
          migratedAt: new Date().toISOString()
        });
        otherItems.push('onboarding');
      }

      // Migrate categories if customized
      const categories = localStorage.getItem(STORAGE_KEYS.CATEGORIES);
      if (categories) {
        await Database.set(`custom_categories_${userId}`, {
          categories: JSON.parse(categories),
          migratedFrom: 'localStorage',
          migratedAt: new Date().toISOString()
        });
        otherItems.push('categories');
      }

      result.summary.other = otherItems.length;
      result.migratedItems += otherItems.length;

      if (otherItems.length > 0) {
        // Console output removed for production
      }

    } catch (error) {
      result.errors.push(`Other data migration failed: ${error}`);
    }
  }

  /**
   * Create backup of localStorage data before migration
   */
  static createBackup(): string | null {
    try {
      const backup: Record<string, any> = {};
      
      Object.values(STORAGE_KEYS).forEach(key => {
        const value = localStorage.getItem(key);
        if (value !== null) {
          try {
            backup[key] = JSON.parse(value);
          } catch {
            backup[key] = value; // Store as string if not JSON
          }
        }
      });

      // Add metadata
      backup._metadata = {
        createdAt: new Date().toISOString(),
        version: '1.0.0',
        source: 'asmbli-localStorage'
      };

      return JSON.stringify(backup, null, 2);

    } catch (error) {
      // Console output removed for production
      return null;
    }
  }

  /**
   * Clear localStorage data after successful migration
   */
  static clearLocalStorageData(): void {
    try {
      Object.values(STORAGE_KEYS).forEach(key => {
        localStorage.removeItem(key);
      });
      // Console output removed for production
    } catch (error) {
      // Console output removed for production
    }
  }

  /**
   * Restore data from backup
   */
  static restoreFromBackup(backupJson: string): boolean {
    try {
      const backup = JSON.parse(backupJson);
      
      Object.entries(backup).forEach(([key, value]) => {
        if (key !== '_metadata') {
          localStorage.setItem(key, typeof value === 'string' ? value : JSON.stringify(value));
        }
      });

      // Console output removed for production
      return true;

    } catch (error) {
      // Console output removed for production
      return false;
    }
  }
}

/**
 * React hook for data migration
 */
export function useDataMigration() {
  const [isChecking, setIsChecking] = useState(false);
  const [needsMigration, setNeedsMigration] = useState<boolean | null>(null);
  const [migrationResult, setMigrationResult] = useState<MigrationResult | null>(null);

  // Check if migration is needed
  const checkMigrationStatus = useCallback(async () => {
    setIsChecking(true);
    try {
      const hasLocalData = DataMigration.hasLocalStorageData();
      setNeedsMigration(hasLocalData);
    } catch (error) {
      // Console output removed for production
      setNeedsMigration(false);
    } finally {
      setIsChecking(false);
    }
  }, []);

  // Perform migration
  const performMigration = useCallback(async (userId: string) => {
    setIsChecking(true);
    try {
      const result = await DataMigration.migrateAllData(userId);
      setMigrationResult(result);
      
      if (result.success) {
        setNeedsMigration(false);
      }
      
      return result;
    } catch (error) {
      const errorResult: MigrationResult = {
        success: false,
        migratedItems: 0,
        errors: [error instanceof Error ? error.message : String(error)],
        summary: { templates: 0, userConfigs: 0, preferences: 0, other: 0 }
      };
      setMigrationResult(errorResult);
      return errorResult;
    } finally {
      setIsChecking(false);
    }
  }, []);

  // Get migration summary
  const getMigrationSummary = useCallback(() => {
    return DataMigration.getLocalStorageSummary();
  }, []);

  return {
    isChecking,
    needsMigration,
    migrationResult,
    checkMigrationStatus,
    performMigration,
    getMigrationSummary
  };
}

import { useState, useCallback } from 'react';