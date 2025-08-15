/**
 * Deployment Status Utilities
 * Check deployment status and database connectivity
 */

export interface DeploymentStatus {
  deployed: boolean;
  databaseConnected: boolean;
  migrationsRun: boolean;
  lastChecked: string;
  errors: string[];
}

export class DeploymentChecker {
  /**
   * Check if the application is deployed and database is accessible
   */
  static async checkDeploymentStatus(): Promise<DeploymentStatus> {
    const status: DeploymentStatus = {
      deployed: false,
      databaseConnected: false,
      migrationsRun: false,
      lastChecked: new Date().toISOString(),
      errors: []
    };

    try {
      // Check if we're running in production
      status.deployed = process.env.NODE_ENV === 'production' || 
                       window.location.hostname !== 'localhost';

      // Check if database URL is available
      const hasDatabaseUrl = process.env.NETLIFY_DATABASE_URL || 
                            window.location.hostname.includes('netlify');
      
      if (hasDatabaseUrl) {
        // Test database connectivity
        try {
          const { Database } = await import('../lib/database');
          
          // Try a simple operation
          await Database.get('connection_test');
          status.databaseConnected = true;

          // Check if migrations have been run by testing for users table
          try {
            await Database.createUser(
              'test@example.com', 
              'Test User', 
              'beginner'
            );
            // If this succeeds, migrations are likely run
            status.migrationsRun = true;
          } catch (error) {
            // Check if it's a "user already exists" error vs table doesn't exist
            const errorMessage = error instanceof Error ? error.message : String(error);
            if (errorMessage.includes('already exists') || errorMessage.includes('duplicate')) {
              status.migrationsRun = true;
            } else if (errorMessage.includes('does not exist') || errorMessage.includes('relation')) {
              status.errors.push('Database tables not found - migrations may not have been run');
            }
          }

        } catch (error) {
          status.errors.push(`Database connection failed: ${error}`);
        }
      } else {
        status.errors.push('Database URL not configured');
      }

    } catch (error) {
      status.errors.push(`Deployment check failed: ${error}`);
    }

    return status;
  }

  /**
   * Wait for deployment to be ready
   */
  static async waitForDeployment(
    maxWaitTime = 300000, // 5 minutes
    checkInterval = 10000 // 10 seconds
  ): Promise<DeploymentStatus> {
    const startTime = Date.now();
    
    while (Date.now() - startTime < maxWaitTime) {
      const status = await this.checkDeploymentStatus();
      
      if (status.deployed && status.databaseConnected && status.migrationsRun) {
        return status;
      }
      
      // Wait before next check
      await new Promise(resolve => setTimeout(resolve, checkInterval));
    }
    
    // Return final status after timeout
    const finalStatus = await this.checkDeploymentStatus();
    finalStatus.errors.push('Deployment readiness check timed out');
    return finalStatus;
  }

  /**
   * Check if migrations need to be run
   */
  static async needsMigrations(): Promise<boolean> {
    try {
      const { getMigrationStatus } = await import('../lib/migrations/runner');
      const status = await getMigrationStatus();
      return status.pending > 0;
    } catch (error) {
      console.warn('Could not check migration status:', error);
      return false;
    }
  }

  /**
   * Run migrations if needed
   */
  static async runMigrationsIfNeeded(): Promise<{ success: boolean; message: string }> {
    try {
      const needsMigrations = await this.needsMigrations();
      
      if (!needsMigrations) {
        return { success: true, message: 'No migrations needed' };
      }

      const { runMigrations } = await import('../lib/migrations/runner');
      await runMigrations();
      
      return { success: true, message: 'Migrations completed successfully' };
      
    } catch (error) {
      return { 
        success: false, 
        message: `Migration failed: ${error instanceof Error ? error.message : String(error)}` 
      };
    }
  }
}

/**
 * React hook for monitoring deployment status
 */
import { useState, useEffect, useCallback } from 'react';

export function useDeploymentStatus(autoCheck = true, checkInterval = 30000) {
  const [status, setStatus] = useState<DeploymentStatus | null>(null);
  const [isChecking, setIsChecking] = useState(false);

  const checkStatus = useCallback(async () => {
    setIsChecking(true);
    try {
      const newStatus = await DeploymentChecker.checkDeploymentStatus();
      setStatus(newStatus);
    } catch (error) {
      console.error('Error checking deployment status:', error);
      setStatus(prev => prev ? {
        ...prev,
        errors: [...prev.errors, `Status check failed: ${error}`],
        lastChecked: new Date().toISOString()
      } : null);
    } finally {
      setIsChecking(false);
    }
  }, []);

  useEffect(() => {
    if (autoCheck) {
      checkStatus();
      
      const interval = setInterval(checkStatus, checkInterval);
      return () => clearInterval(interval);
    }
  }, [autoCheck, checkInterval, checkStatus]);

  const runMigrations = useCallback(async () => {
    setIsChecking(true);
    try {
      const result = await DeploymentChecker.runMigrationsIfNeeded();
      
      // Recheck status after migrations
      await checkStatus();
      
      return result;
    } finally {
      setIsChecking(false);
    }
  }, [checkStatus]);

  return {
    status,
    isChecking,
    checkStatus,
    runMigrations,
    isReady: status ? (status.deployed && status.databaseConnected && status.migrationsRun) : false,
    hasErrors: status ? status.errors.length > 0 : false
  };
}