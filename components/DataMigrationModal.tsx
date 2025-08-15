import { useState, useEffect } from 'react';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from './ui/dialog';
import { Button } from './ui/button';
import { Alert, AlertDescription } from './ui/alert';
import { CheckCircle, AlertCircle, Upload, Database } from 'lucide-react';
import { DataMigration, useDataMigration } from '../utils/dataMigration';

interface DataMigrationModalProps {
  isOpen: boolean;
  onClose: () => void;
  userId?: string;
  onMigrationComplete?: () => void;
}

export function DataMigrationModal({ 
  isOpen, 
  onClose, 
  userId,
  onMigrationComplete 
}: DataMigrationModalProps) {
  const [step, setStep] = useState<'check' | 'summary' | 'backup' | 'migrate' | 'complete'>('check');
  const [backup, setBackup] = useState<string | null>(null);
  const [isProcessing, setIsProcessing] = useState(false);
  
  const {
    needsMigration,
    migrationResult,
    checkMigrationStatus,
    performMigration,
    getMigrationSummary
  } = useDataMigration();

  const summary = getMigrationSummary();

  useEffect(() => {
    if (isOpen && step === 'check') {
      checkMigrationStatus();
    }
  }, [isOpen, step, checkMigrationStatus]);

  useEffect(() => {
    if (needsMigration === true && step === 'check') {
      setStep('summary');
    } else if (needsMigration === false && step === 'check') {
      setStep('complete');
    }
  }, [needsMigration, step]);

  const handleCreateBackup = () => {
    setIsProcessing(true);
    try {
      const backupData = DataMigration.createBackup();
      if (backupData) {
        setBackup(backupData);
        setStep('migrate');
      }
    } catch (error) {
      console.error('Backup failed:', error);
    } finally {
      setIsProcessing(false);
    }
  };

  const handleDownloadBackup = () => {
    if (!backup) return;
    
    const blob = new Blob([backup], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `asmbli-backup-${new Date().toISOString().split('T')[0]}.json`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  const handleMigrate = async () => {
    if (!userId) {
      console.error('User ID is required for migration');
      return;
    }

    setIsProcessing(true);
    try {
      const result = await performMigration(userId);
      
      if (result.success) {
        // Clear localStorage after successful migration
        DataMigration.clearLocalStorageData();
        setStep('complete');
        onMigrationComplete?.();
      }
    } catch (error) {
      console.error('Migration failed:', error);
    } finally {
      setIsProcessing(false);
    }
  };

  const handleSkipMigration = () => {
    setStep('complete');
    onClose();
  };

  const renderContent = () => {
    switch (step) {
      case 'check':
        return (
          <div className="text-center py-8">
            <Database className="mx-auto h-12 w-12 text-blue-500 animate-pulse" />
            <p className="mt-4 text-gray-600">Checking for data to migrate...</p>
          </div>
        );

      case 'summary':
        return (
          <div className="space-y-6">
            <div className="text-center">
              <Upload className="mx-auto h-12 w-12 text-green-500" />
              <h3 className="mt-4 text-lg font-semibold">Ready to Migrate Your Data</h3>
              <p className="text-gray-600">We found data in your browser that can be moved to the cloud database.</p>
            </div>

            <div className="bg-gray-50 rounded-lg p-4 space-y-3">
              <h4 className="font-medium text-gray-900">Data Summary:</h4>
              <div className="grid grid-cols-2 gap-4 text-sm">
                <div className="flex justify-between">
                  <span>Templates:</span>
                  <span className="font-medium">{summary.templates}</span>
                </div>
                <div className="flex justify-between">
                  <span>Configurations:</span>
                  <span className="font-medium">{summary.userConfigs}</span>
                </div>
                <div className="flex justify-between">
                  <span>Preferences:</span>
                  <span className="font-medium">{summary.preferences}</span>
                </div>
                <div className="flex justify-between">
                  <span>Other Data:</span>
                  <span className="font-medium">{summary.wizardData + (summary.onboardingComplete ? 1 : 0)}</span>
                </div>
              </div>
              <div className="pt-2 border-t">
                <div className="flex justify-between text-sm font-medium">
                  <span>Total Size:</span>
                  <span>{(summary.totalSize / 1024).toFixed(1)} KB</span>
                </div>
              </div>
            </div>

            <Alert>
              <AlertCircle className="h-4 w-4" />
              <AlertDescription>
                We recommend creating a backup before migration. This ensures your data is safe during the process.
              </AlertDescription>
            </Alert>

            <div className="flex gap-3">
              <Button 
                onClick={handleCreateBackup}
                disabled={isProcessing}
                className="flex-1"
              >
                {isProcessing ? 'Creating Backup...' : 'Create Backup & Continue'}
              </Button>
              <Button 
                variant="outline" 
                onClick={() => setStep('migrate')}
              >
                Skip Backup
              </Button>
            </div>
          </div>
        );

      case 'migrate':
        return (
          <div className="space-y-6">
            <div className="text-center">
              <Database className="mx-auto h-12 w-12 text-blue-500" />
              <h3 className="mt-4 text-lg font-semibold">Ready to Migrate</h3>
              <p className="text-gray-600">Your data will be moved to the secure cloud database.</p>
            </div>

            {backup && (
              <Alert className="bg-green-50 border-green-200">
                <CheckCircle className="h-4 w-4 text-green-600" />
                <AlertDescription className="text-green-800">
                  Backup created successfully! 
                  <Button 
                    variant="link" 
                    size="sm" 
                    onClick={handleDownloadBackup}
                    className="p-0 ml-2 h-auto text-green-700 hover:text-green-800"
                  >
                    Download Backup
                  </Button>
                </AlertDescription>
              </Alert>
            )}

            <div className="bg-blue-50 rounded-lg p-4">
              <h4 className="font-medium text-blue-900 mb-2">What will happen:</h4>
              <ul className="text-sm text-blue-800 space-y-1">
                <li>• Your templates will be saved to the cloud</li>
                <li>• Configurations will be preserved</li>
                <li>• All preferences will be migrated</li>
                <li>• Local data will be cleared after successful migration</li>
              </ul>
            </div>

            {migrationResult && !migrationResult.success && (
              <Alert variant="destructive">
                <AlertCircle className="h-4 w-4" />
                <AlertDescription>
                  Migration failed: {migrationResult.errors.join(', ')}
                </AlertDescription>
              </Alert>
            )}

            <div className="flex gap-3">
              <Button 
                onClick={handleMigrate}
                disabled={isProcessing || !userId}
                className="flex-1"
              >
                {isProcessing ? 'Migrating...' : 'Start Migration'}
              </Button>
              <Button 
                variant="outline" 
                onClick={handleSkipMigration}
              >
                Skip Migration
              </Button>
            </div>
          </div>
        );

      case 'complete':
        const wasSuccessful = migrationResult?.success !== false;
        return (
          <div className="text-center space-y-6">
            <div>
              {wasSuccessful ? (
                <CheckCircle className="mx-auto h-16 w-16 text-green-500" />
              ) : (
                <AlertCircle className="mx-auto h-16 w-16 text-red-500" />
              )}
              
              <h3 className="mt-4 text-lg font-semibold">
                {wasSuccessful ? 'Migration Complete!' : 'Migration Failed'}
              </h3>
              
              {wasSuccessful ? (
                <div className="space-y-2">
                  <p className="text-gray-600">Your data has been successfully moved to the cloud database.</p>
                  {migrationResult && (
                    <div className="bg-green-50 rounded-lg p-4 mt-4">
                      <h4 className="font-medium text-green-900 mb-2">Migration Summary:</h4>
                      <div className="text-sm text-green-800 space-y-1">
                        <div>Templates migrated: {migrationResult.summary.templates}</div>
                        <div>Configurations: {migrationResult.summary.userConfigs}</div>
                        <div>Preferences: {migrationResult.summary.preferences}</div>
                        <div>Other items: {migrationResult.summary.other}</div>
                        <div className="font-medium pt-2 border-t border-green-200">
                          Total items: {migrationResult.migratedItems}
                        </div>
                      </div>
                    </div>
                  )}
                </div>
              ) : (
                <div className="space-y-2">
                  <p className="text-gray-600">The migration could not be completed.</p>
                  {migrationResult && migrationResult.errors.length > 0 && (
                    <div className="bg-red-50 rounded-lg p-4 mt-4">
                      <h4 className="font-medium text-red-900 mb-2">Errors:</h4>
                      <ul className="text-sm text-red-800 space-y-1">
                        {migrationResult.errors.map((error, index) => (
                          <li key={index}>• {error}</li>
                        ))}
                      </ul>
                    </div>
                  )}
                </div>
              )}
            </div>

            <Button onClick={onClose} className="w-full">
              {wasSuccessful ? 'Continue to Application' : 'Close'}
            </Button>
          </div>
        );

      default:
        return null;
    }
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-lg">
        <DialogHeader>
          <DialogTitle>
            {step === 'check' && 'Checking Data'}
            {step === 'summary' && 'Data Migration Available'}
            {step === 'backup' && 'Create Backup'}
            {step === 'migrate' && 'Migrate Data'}
            {step === 'complete' && 'Migration Complete'}
          </DialogTitle>
          <DialogDescription>
            Move your local data to the secure cloud database for better reliability and sync across devices.
          </DialogDescription>
        </DialogHeader>
        
        {renderContent()}
      </DialogContent>
    </Dialog>
  );
}