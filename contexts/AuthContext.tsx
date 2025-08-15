import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { User, AuthState, LoginCredentials, SignupCredentials, UserRole, ROLE_CONFIGURATIONS } from '../types/auth';

interface AuthContextType extends AuthState {
  login: (credentials: LoginCredentials) => Promise<void>;
  signup: (credentials: SignupCredentials) => Promise<void>;
  logout: () => void;
  updateUserRole: (role: UserRole) => void;
  hasFeature: (feature: string) => boolean;
  isStepAllowed: (step: string) => boolean;
  getPreConfiguredSettings: () => Record<string, any>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}

interface AuthProviderProps {
  children: ReactNode;
}

export function AuthProvider({ children }: AuthProviderProps) {
  const [authState, setAuthState] = useState<AuthState>({
    user: null,
    isAuthenticated: false,
    isLoading: true,
    error: null,
  });

  // Check for existing session on mount
  useEffect(() => {
    const checkAuthStatus = () => {
      try {
        const storedUser = localStorage.getItem('agent_builder_user');
        if (storedUser) {
          const user = JSON.parse(storedUser);
          setAuthState({
            user,
            isAuthenticated: true,
            isLoading: false,
            error: null,
          });
        } else {
          setAuthState(prev => ({ ...prev, isLoading: false }));
        }
      } catch (error) {
        console.error('Error checking auth status:', error);
        setAuthState(prev => ({ ...prev, isLoading: false, error: 'Failed to load user session' }));
      }
    };

    checkAuthStatus();
  }, []);

  const login = async (credentials: LoginCredentials): Promise<void> => {
    setAuthState(prev => ({ ...prev, isLoading: true, error: null }));

    try {
      // Mock authentication - in real app, this would call your API
      await new Promise(resolve => setTimeout(resolve, 1000)); // Simulate network delay

      // Mock user data - in real app, this would come from your backend
      const mockUsers: Record<string, { password: string; user: Omit<User, 'id'> }> = {
        'beginner@example.com': {
          password: 'password',
          user: {
            email: 'beginner@example.com',
            name: 'John Beginner',
            role: 'beginner',
            createdAt: new Date(),
            lastLoginAt: new Date(),
            subscription: {
              plan: 'beginner',
              status: 'active',
              startDate: new Date(),
              features: []
            }
          }
        },
        'power@example.com': {
          password: 'password',
          user: {
            email: 'power@example.com',
            name: 'Jane Power',
            role: 'power_user',
            createdAt: new Date(),
            lastLoginAt: new Date(),
            subscription: {
              plan: 'power_user',
              status: 'active',
              startDate: new Date(),
              features: []
            }
          }
        },
        'enterprise@example.com': {
          password: 'password',
          user: {
            email: 'enterprise@example.com',
            name: 'Admin Enterprise',
            role: 'enterprise',
            createdAt: new Date(),
            lastLoginAt: new Date(),
            subscription: {
              plan: 'enterprise',
              status: 'active',
              startDate: new Date(),
              features: []
            }
          }
        }
      };

      const mockUser = mockUsers[credentials.email];
      if (!mockUser || mockUser.password !== credentials.password) {
        throw new Error('Invalid email or password');
      }

      const user: User = {
        id: `user_${Date.now()}`,
        ...mockUser.user,
        lastLoginAt: new Date(),
      };

      localStorage.setItem('agent_builder_user', JSON.stringify(user));

      setAuthState({
        user,
        isAuthenticated: true,
        isLoading: false,
        error: null,
      });
    } catch (error) {
      setAuthState(prev => ({
        ...prev,
        isLoading: false,
        error: error instanceof Error ? error.message : 'Login failed',
      }));
      throw error;
    }
  };

  const signup = async (credentials: SignupCredentials): Promise<void> => {
    setAuthState(prev => ({ ...prev, isLoading: true, error: null }));

    try {
      // Mock signup - in real app, this would call your API
      await new Promise(resolve => setTimeout(resolve, 1000)); // Simulate network delay

      const user: User = {
        id: `user_${Date.now()}`,
        email: credentials.email,
        name: credentials.name,
        role: credentials.role || 'beginner',
        createdAt: new Date(),
        lastLoginAt: new Date(),
        subscription: {
          plan: credentials.role || 'beginner',
          status: 'active',
          startDate: new Date(),
          features: []
        }
      };

      localStorage.setItem('agent_builder_user', JSON.stringify(user));

      setAuthState({
        user,
        isAuthenticated: true,
        isLoading: false,
        error: null,
      });
    } catch (error) {
      setAuthState(prev => ({
        ...prev,
        isLoading: false,
        error: error instanceof Error ? error.message : 'Signup failed',
      }));
      throw error;
    }
  };

  const logout = () => {
    localStorage.removeItem('agent_builder_user');
    setAuthState({
      user: null,
      isAuthenticated: false,
      isLoading: false,
      error: null,
    });
  };

  const updateUserRole = (role: UserRole) => {
    if (!authState.user) return;

    const updatedUser = {
      ...authState.user,
      role,
      subscription: {
        ...authState.user.subscription!,
        plan: role,
      }
    };

    localStorage.setItem('agent_builder_user', JSON.stringify(updatedUser));
    setAuthState(prev => ({
      ...prev,
      user: updatedUser,
    }));
  };

  const hasFeature = (feature: string): boolean => {
    if (!authState.user) return false;
    
    const roleConfig = ROLE_CONFIGURATIONS[authState.user.role];
    return !roleConfig.restrictions.disabledFeatures.includes(feature);
  };

  const isStepAllowed = (step: string): boolean => {
    if (!authState.user) return false;
    
    const roleConfig = ROLE_CONFIGURATIONS[authState.user.role];
    return !roleConfig.restrictions.hiddenSteps.includes(step);
  };

  const getPreConfiguredSettings = (): Record<string, any> => {
    if (!authState.user) return {};
    
    const roleConfig = ROLE_CONFIGURATIONS[authState.user.role];
    return roleConfig.restrictions.preConfiguredSettings;
  };

  const contextValue: AuthContextType = {
    ...authState,
    login,
    signup,
    logout,
    updateUserRole,
    hasFeature,
    isStepAllowed,
    getPreConfiguredSettings,
  };

  return (
    <AuthContext.Provider value={contextValue}>
      {children}
    </AuthContext.Provider>
  );
}