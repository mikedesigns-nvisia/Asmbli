import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../providers/context_provider.dart';
import '../../data/models/context_document.dart';

class ContextLibraryScreen extends ConsumerStatefulWidget {
  const ContextLibraryScreen({super.key});

  @override
  ConsumerState<ContextLibraryScreen> createState() => _ContextLibraryScreenState();
}

class _ContextLibraryScreenState extends ConsumerState<ContextLibraryScreen> {
  int selectedTab = 0; // 0 = My Context, 1 = Context Library
  String searchQuery = '';
  String selectedCategory = 'All';
  bool _showCreateFlow = false;

  final List<String> categories = [
    'All', 'Documentation', 'Codebase', 'Guidelines', 'Examples', 
    'Knowledge', 'Custom', 'API Reference', 'Tutorials', 'Best Practices',
    'Code Samples', 'Architecture', 'Security', 'Performance', 'Testing',
    'Deployment', 'Database', 'Frontend', 'Backend', 'Mobile', 'AI & Agents'
  ];

  final List<ContextTemplate> templates = [
    // AI & Agent Specific Content
    const ContextTemplate(
      name: 'Prompt Engineering Best Practices',
      description: 'Effective prompt design and optimization techniques for AI agents',
      category: 'AI & Agents',
      tags: ['ai', 'prompts', 'llm', 'agents', 'optimization'],
      contentPreview: r'''# Prompt Engineering Best Practices

## Core Principles
- Be specific and clear in instructions
- Provide context and examples when needed
- Use structured formats for complex requests
- Iterate and refine based on outputs

## Effective Prompt Patterns

### Chain-of-Thought Prompting
```
Solve this step by step:
1. First, understand what we need to find
2. Then, identify the given information
3. Next, determine the approach
4. Finally, calculate the result

Problem: [Your problem here]
```

### Few-Shot Learning
```
Here are some examples of the task:

Input: "The weather is nice today"
Output: {"sentiment": "positive", "confidence": 0.8}

Input: "I hate waiting in traffic"
Output: {"sentiment": "negative", "confidence": 0.9}

Now classify: "I love spending time with friends"
```

### Role-Based Prompting
```
You are an expert software architect with 15 years of experience in microservices design. 
Your task is to review the following system architecture and provide specific recommendations for improvement.

Focus on:
- Scalability concerns
- Security implications
- Performance bottlenecks
- Maintainability issues
```

## Context Management
- Keep context focused and relevant
- Remove outdated information regularly  
- Use hierarchical context when dealing with complex topics
- Balance detail with clarity

## Error Handling & Refinement
- Test prompts with edge cases
- Create fallback strategies for unclear responses
- Document successful prompt patterns
- Continuously refine based on real usage''',
      useCase: 'Design effective prompts for AI agents and language models',
    ),
    const ContextTemplate(
      name: 'Agent Interaction Patterns',
      description: 'Common patterns for agent communication and task coordination',
      category: 'AI & Agents',
      tags: ['agents', 'patterns', 'communication', 'coordination', 'workflow'],
      contentPreview: r'''# Agent Interaction Patterns

## Task Delegation Pattern
```yaml
Primary Agent:
  - Receives complex task
  - Breaks down into subtasks
  - Delegates to specialized agents
  - Coordinates results
  - Returns unified response

Specialized Agents:
  - Code Analysis Agent
  - Documentation Agent  
  - Testing Agent
  - Security Review Agent
```

## Chain of Responsibility
```
User Request → Router Agent → Appropriate Handler Agent → Response

Router Agent decides:
- Code questions → Code Agent
- Documentation → Docs Agent
- System design → Architecture Agent
- Bug reports → Debug Agent
```

## Agent Communication Protocol
```json
{
  "type": "task_request",
  "from": "primary_agent",
  "to": "code_agent", 
  "task_id": "uuid-1234",
  "payload": {
    "action": "analyze_code",
    "files": ["app.py", "models.py"],
    "focus": "performance"
  },
  "context": {
    "project_type": "web_api",
    "language": "python",
    "framework": "fastapi"
  }
}
```

## Feedback Loop Pattern
```
1. Agent executes task
2. Validates output quality
3. If quality < threshold:
   - Request clarification
   - Try alternative approach
   - Escalate to human if needed
4. If quality sufficient:
   - Return result
   - Log successful pattern
```

## Error Recovery Strategies
- Graceful degradation when agents are unavailable
- Retry mechanisms with exponential backoff
- Fallback to simpler approaches
- Human escalation triggers

## Agent Specialization Examples
- **Code Agent**: Focus on code analysis, generation, debugging
- **Docs Agent**: Technical writing, API documentation, tutorials
- **Security Agent**: Vulnerability assessment, best practices
- **Performance Agent**: Optimization, profiling, benchmarking''',
      useCase: 'Implement effective agent communication and coordination patterns',
    ),

    // Frontend Development Libraries
    const ContextTemplate(
      name: 'React Development Guide',
      description: 'Modern React patterns, hooks, and best practices',
      category: 'Frontend',
      tags: ['react', 'jsx', 'hooks', 'components', 'frontend'],
      contentPreview: r'''# React Development Guide

## Modern React Patterns

### Functional Components with Hooks
```jsx
import React, { useState, useEffect, useCallback } from 'react';

const UserProfile = ({ userId }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const fetchUser = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const response = await fetch('/api/users/' + userId);
      if (!response.ok) throw new Error('Failed to fetch user');
      const userData = await response.json();
      setUser(userData);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }, [userId]);

  useEffect(() => {
    fetchUser();
  }, [fetchUser]);

  if (loading) return <div className="loading">Loading...</div>;
  if (error) return <div className="error">Error: {error}</div>;
  if (!user) return <div>User not found</div>;

  return (
    <div className="user-profile">
      <img src={user.avatar} alt={user.name} />
      <h1>{user.name}</h1>
      <p>{user.email}</p>
      <button onClick={fetchUser}>Refresh</button>
    </div>
  );
};
```

### Custom Hooks
```jsx
// useLocalStorage hook
const useLocalStorage = (key, initialValue) => {
  const [storedValue, setStoredValue] = useState(() => {
    try {
      const item = window.localStorage.getItem(key);
      return item ? JSON.parse(item) : initialValue;
    } catch (error) {
      console.error('Error reading from localStorage:', error);
      return initialValue;
    }
  });

  const setValue = useCallback((value) => {
    try {
      const valueToStore = value instanceof Function ? value(storedValue) : value;
      setStoredValue(valueToStore);
      window.localStorage.setItem(key, JSON.stringify(valueToStore));
    } catch (error) {
      console.error('Error saving to localStorage:', error);
    }
  }, [key, storedValue]);

  return [storedValue, setValue];
};

// Usage
const [user, setUser] = useLocalStorage('user', { name: '', email: '' });
```

### Context API for State Management
```jsx
// Create context
const UserContext = createContext();

// Provider component
export const UserProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(false);

  const login = async (credentials) => {
    setLoading(true);
    try {
      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(credentials)
      });
      const userData = await response.json();
      setUser(userData);
    } finally {
      setLoading(false);
    }
  };

  return (
    <UserContext.Provider value={{ user, loading, login }}>
      {children}
    </UserContext.Provider>
  );
};

// Custom hook to use context
export const useUser = () => {
  const context = useContext(UserContext);
  if (!context) {
    throw new Error('useUser must be used within UserProvider');
  }
  return context;
};
```''',
      useCase: 'Build modern React applications with hooks and functional components',
    ),
    const ContextTemplate(
      name: 'Vue.js Composition API',
      description: 'Vue 3 composition API patterns and reactive programming',
      category: 'Frontend',
      tags: ['vue', 'composition-api', 'reactivity', 'frontend'],
      contentPreview: r'''# Vue.js Composition API Guide

## Basic Composition API Usage
```vue
<template>
  <div class="user-dashboard">
    <div v-if="loading" class="loading">Loading...</div>
    <div v-else-if="error" class="error">{{ error }}</div>
    <div v-else>
      <h1>Welcome, {{ user.name }}!</h1>
      <p>Total posts: {{ posts.length }}</p>
      <button @click="refreshData">Refresh</button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useUser } from '@/composables/useUser'

// Props and emits
const props = defineProps(['userId'])
const emit = defineEmits(['dataLoaded'])

// Reactive state
const user = ref(null)
const posts = ref([])
const loading = ref(false)
const error = ref(null)

// Computed properties
const userStats = computed(() => ({
  totalPosts: posts.value.length,
  avgPostLength: posts.value.reduce((acc, post) => acc + post.content.length, 0) / posts.value.length || 0
}))

// Methods
const fetchUserData = async () => {
  loading.value = true
  error.value = null
  
  try {
    const [userResponse, postsResponse] = await Promise.all([
      fetch('/api/users/' + props.userId),
      fetch('/api/users/' + props.userId + '/posts')
    ])
    
    user.value = await userResponse.json()
    posts.value = await postsResponse.json()
    
    emit('dataLoaded', { user: user.value, posts: posts.value })
  } catch (err) {
    error.value = err.message
  } finally {
    loading.value = false
  }
}

const refreshData = () => {
  fetchUserData()
}

// Lifecycle and watchers
onMounted(() => {
  fetchUserData()
})

watch(() => props.userId, (newUserId) => {
  if (newUserId) {
    fetchUserData()
  }
})
</script>
```

## Composable Functions
```javascript
// composables/useApi.js
import { ref, reactive } from 'vue'

export function useApi() {
  const loading = ref(false)
  const error = ref(null)
  
  const state = reactive({
    data: null
  })

  const execute = async (apiCall) => {
    loading.value = true
    error.value = null
    
    try {
      const result = await apiCall()
      state.data = result
      return result
    } catch (err) {
      error.value = err.message
      throw err
    } finally {
      loading.value = false
    }
  }

  return {
    loading: readonly(loading),
    error: readonly(error),
    data: readonly(state.data),
    execute
  }
}

// Usage in component
import { useApi } from '@/composables/useApi'

const { loading, error, data, execute } = useApi()

const loadUsers = () => {
  execute(() => fetch('/api/users').then(r => r.json()))
}
```

## Reactive State Management
```javascript
// stores/user.js
import { reactive, readonly } from 'vue'

const state = reactive({
  user: null,
  isAuthenticated: false,
  preferences: {},
  loading: false
})

const actions = {
  async login(credentials) {
    state.loading = true
    try {
      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(credentials)
      })
      const user = await response.json()
      
      state.user = user
      state.isAuthenticated = true
      state.preferences = user.preferences || {}
    } finally {
      state.loading = false
    }
  },

  logout() {
    state.user = null
    state.isAuthenticated = false
    state.preferences = {}
  },

  updatePreferences(newPrefs) {
    state.preferences = { ...state.preferences, ...newPrefs }
  }
}

export const useUserStore = () => {
  return {
    state: readonly(state),
    ...actions
  }
}
```''',
      useCase: 'Build reactive Vue.js applications using the Composition API',
    ),

    // Build Tools & Development Setup
    const ContextTemplate(
      name: 'Modern Build Tools & Development Setup',
      description: 'Comprehensive setup for Vite, ESLint, Prettier, TypeScript, and Docker',
      category: 'Frontend',
      tags: ['vite', 'eslint', 'prettier', 'typescript', 'docker', 'development'],
      contentPreview: r'''# Modern Development Environment Setup

## Vite Configuration
```javascript
// vite.config.js
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { resolve } from 'path'

export default defineConfig({
  plugins: [react()],
  
  // Development server
  server: {
    port: 3000,
    host: true,
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, '')
      }
    }
  },
  
  // Build configuration
  build: {
    outDir: 'dist',
    sourcemap: true,
    minify: 'terser',
    target: 'esnext',
    rollupOptions: {
      output: {
        manualChunks: {
          'react-vendor': ['react', 'react-dom'],
          'router': ['react-router-dom'],
          'ui': ['@mui/material', '@mui/icons-material'],
          'utils': ['lodash', 'date-fns', 'axios']
        }
      }
    }
  },
  
  // Path aliases
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src'),
      '@components': resolve(__dirname, 'src/components'),
      '@utils': resolve(__dirname, 'src/utils'),
      '@services': resolve(__dirname, 'src/services'),
      '@types': resolve(__dirname, 'src/types')
    }
  },
  
  // CSS processing
  css: {
    preprocessorOptions: {
      scss: {
        additionalData: '@import "@/styles/variables.scss";'
      }
    }
  }
})
```

## TypeScript Configuration
```json
// tsconfig.json
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,

    /* Bundler mode */
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",

    /* Linting */
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "noImplicitReturns": true,

    /* Path mapping */
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"],
      "@/components/*": ["src/components/*"],
      "@/utils/*": ["src/utils/*"],
      "@/services/*": ["src/services/*"],
      "@/types/*": ["src/types/*"]
    }
  },
  "include": [
    "src/**/*",
    "src/**/*.vue"
  ],
  "exclude": [
    "node_modules",
    "dist"
  ]
}
```

## ESLint Configuration
```javascript
// .eslintrc.cjs
module.exports = {
  root: true,
  env: {
    browser: true,
    es2020: true,
    node: true
  },
  extends: [
    'eslint:recommended',
    '@typescript-eslint/recommended',
    'plugin:react/recommended',
    'plugin:react-hooks/recommended',
    'plugin:jsx-a11y/recommended',
    'plugin:import/recommended',
    'plugin:import/typescript',
    'prettier'
  ],
  ignorePatterns: ['dist', '.eslintrc.cjs'],
  parser: '@typescript-eslint/parser',
  plugins: ['react-refresh'],
  settings: {
    react: {
      version: 'detect'
    },
    'import/resolver': {
      typescript: {
        alwaysTryTypes: true
      }
    }
  },
  rules: {
    'react-refresh/only-export-components': [
      'warn',
      { allowConstantExport: true }
    ],
    'react/react-in-jsx-scope': 'off',
    '@typescript-eslint/no-unused-vars': 'error',
    'import/order': [
      'error',
      {
        groups: [
          'builtin',
          'external',
          'internal',
          'parent',
          'sibling',
          'index'
        ],
        'newlines-between': 'always'
      }
    ]
  }
}
```

## Prettier Configuration
```json
// .prettierrc
{
  "semi": true,
  "singleQuote": true,
  "trailingComma": "es5",
  "tabWidth": 2,
  "printWidth": 100,
  "useTabs": false,
  "bracketSpacing": true,
  "arrowParens": "avoid",
  "endOfLine": "lf",
  "quoteProps": "as-needed"
}
```

## Docker Development Setup
```dockerfile
# Dockerfile.dev
FROM node:18-alpine

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci

# Copy source code
COPY . .

# Expose port
EXPOSE 3000

# Development command
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]
```

```yaml
# docker-compose.dev.yml
version: '3.8'

services:
  frontend:
    build:
      context: .
      dockerfile: Dockerfile.dev
    ports:
      - "3000:3000"
    volumes:
      - .:/app
      - /app/node_modules
    environment:
      - NODE_ENV=development
      - VITE_API_URL=http://localhost:8000
    depends_on:
      - api

  api:
    build:
      context: ./api
      dockerfile: Dockerfile.dev
    ports:
      - "8000:8000"
    volumes:
      - ./api:/app
    environment:
      - NODE_ENV=development
      - DATABASE_URL=postgresql://user:pass@db:5432/myapp

  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=myapp
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

## Package.json Scripts
```json
{
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "lint": "eslint . --ext ts,tsx --report-unused-disable-directives --max-warnings 0",
    "lint:fix": "eslint . --ext ts,tsx --fix",
    "format": "prettier --write \"src/**/*.{ts,tsx,js,jsx,json,css,md}\"",
    "format:check": "prettier --check \"src/**/*.{ts,tsx,js,jsx,json,css,md}\"",
    "type-check": "tsc --noEmit",
    "test": "vitest",
    "test:coverage": "vitest --coverage",
    "docker:dev": "docker-compose -f docker-compose.dev.yml up",
    "docker:build": "docker build -t myapp ."
  }
}
```''',
      useCase: 'Set up a complete modern development environment with all essential tools',
    ),

    // System Design & Security
    const ContextTemplate(
      name: 'Microservices Architecture Patterns',
      description: 'Design patterns and best practices for microservices systems',
      category: 'Architecture',
      tags: ['microservices', 'architecture', 'design-patterns', 'scalability'],
      contentPreview: r'''# Microservices Architecture Patterns

## Core Principles
1. **Single Responsibility**: Each service owns one business capability
2. **Autonomous**: Services can be developed, deployed, and scaled independently
3. **Decentralized**: No central orchestration, prefer choreography
4. **Failure Isolation**: Failure of one service shouldn't cascade
5. **Technology Diversity**: Choose the right tool for each job

## Service Communication Patterns

### Synchronous Communication
```javascript
// API Gateway Pattern
class APIGateway {
  async handleRequest(request) {
    const route = this.router.match(request.path)
    
    // Authentication & Authorization
    const user = await this.authenticate(request.headers.authorization)
    if (!this.authorize(user, route.permissions)) {
      throw new UnauthorizedError()
    }
    
    // Rate limiting
    await this.rateLimiter.checkLimit(user.id, route.limits)
    
    // Load balancing & service discovery
    const serviceInstance = await this.serviceDiscovery.findHealthyInstance(route.service)
    
    // Circuit breaker
    return await this.circuitBreaker.execute(
      route.service,
      () => this.httpClient.request(serviceInstance.url, request)
    )
  }
}
```

### Asynchronous Communication (Event-Driven)
```javascript
// Event Sourcing Pattern
class OrderService {
  async createOrder(orderData) {
    const orderId = generateId()
    
    // Publish events instead of direct calls
    await this.eventBus.publish('order.created', {
      orderId,
      customerId: orderData.customerId,
      items: orderData.items,
      timestamp: new Date().toISOString()
    })
    
    return { orderId }
  }
}

// Event handlers in different services
class InventoryService {
  async handleOrderCreated(event) {
    // Reserve inventory for order items
    for (const item of event.items) {
      await this.reserveItem(item.productId, item.quantity)
    }
    
    // Publish result
    await this.eventBus.publish('inventory.reserved', {
      orderId: event.orderId,
      items: event.items
    })
  }
}

class PaymentService {
  async handleInventoryReserved(event) {
    // Process payment
    const paymentResult = await this.processPayment({
      orderId: event.orderId,
      amount: event.totalAmount
    })
    
    await this.eventBus.publish(
      paymentResult.success ? 'payment.completed' : 'payment.failed',
      { orderId: event.orderId, ...paymentResult }
    )
  }
}
```

## Data Management Patterns

### Database per Service
```yaml
# Each service owns its data
User Service:
  Database: PostgreSQL
  Tables: users, user_profiles
  
Order Service:
  Database: MongoDB
  Collections: orders, order_items
  
Inventory Service:
  Database: Redis + PostgreSQL
  Data: product_stock (Redis), inventory_logs (PostgreSQL)
```

### SAGA Pattern for Distributed Transactions
```javascript
// Choreography-based SAGA
class OrderSaga {
  async execute(orderData) {
    const sagaId = generateId()
    const compensations = []
    
    try {
      // Step 1: Create Order
      const order = await this.orderService.createOrder(orderData)
      compensations.push(() => this.orderService.cancelOrder(order.id))
      
      // Step 2: Reserve Inventory
      await this.inventoryService.reserveItems(order.items)
      compensations.push(() => this.inventoryService.releaseReservation(order.id))
      
      // Step 3: Process Payment
      const payment = await this.paymentService.charge({
        amount: order.total,
        customerId: order.customerId
      })
      compensations.push(() => this.paymentService.refund(payment.id))
      
      // Step 4: Confirm Order
      await this.orderService.confirmOrder(order.id)
      
      return { success: true, orderId: order.id }
      
    } catch (error) {
      // Execute compensations in reverse order
      for (const compensation of compensations.reverse()) {
        try {
          await compensation()
        } catch (compensationError) {
          console.error('Compensation failed:', compensationError)
        }
      }
      
      throw error
    }
  }
}
```

## Observability & Monitoring

### Distributed Tracing
```javascript
// OpenTelemetry integration
const tracer = trace.getTracer('order-service')

class OrderService {
  async processOrder(orderData) {
    const span = tracer.startSpan('process-order', {
      attributes: {
        'order.id': orderData.id,
        'customer.id': orderData.customerId
      }
    })
    
    try {
      // Create child spans for downstream calls
      const inventorySpan = tracer.startSpan('check-inventory', { parent: span })
      const available = await this.inventoryService.checkAvailability(orderData.items)
      inventorySpan.end()
      
      if (!available) {
        throw new Error('Insufficient inventory')
      }
      
      const paymentSpan = tracer.startSpan('process-payment', { parent: span })
      await this.paymentService.charge(orderData.total)
      paymentSpan.end()
      
      span.setStatus({ code: SpanStatusCode.OK })
      return { success: true }
      
    } catch (error) {
      span.recordException(error)
      span.setStatus({ code: SpanStatusCode.ERROR, message: error.message })
      throw error
    } finally {
      span.end()
    }
  }
}
```

### Health Checks & Circuit Breakers
```javascript
class ServiceHealthCheck {
  async checkHealth() {
    const checks = await Promise.allSettled([
      this.checkDatabase(),
      this.checkExternalServices(),
      this.checkMemoryUsage(),
      this.checkDiskSpace()
    ])
    
    return {
      status: checks.every(c => c.status === 'fulfilled') ? 'healthy' : 'unhealthy',
      checks: checks.map(c => ({
        name: c.name,
        status: c.status === 'fulfilled' ? 'pass' : 'fail',
        details: c.status === 'fulfilled' ? c.value : c.reason
      }))
    }
  }
}

class CircuitBreaker {
  constructor(threshold = 5, timeout = 60000) {
    this.threshold = threshold
    this.timeout = timeout
    this.failureCount = 0
    this.state = 'CLOSED' // CLOSED, OPEN, HALF_OPEN
    this.nextAttempt = 0
  }
  
  async execute(operation) {
    if (this.state === 'OPEN') {
      if (Date.now() < this.nextAttempt) {
        throw new Error('Circuit breaker is OPEN')
      }
      this.state = 'HALF_OPEN'
    }
    
    try {
      const result = await operation()
      this.onSuccess()
      return result
    } catch (error) {
      this.onFailure()
      throw error
    }
  }
  
  onSuccess() {
    this.failureCount = 0
    this.state = 'CLOSED'
  }
  
  onFailure() {
    this.failureCount++
    if (this.failureCount >= this.threshold) {
      this.state = 'OPEN'
      this.nextAttempt = Date.now() + this.timeout
    }
  }
}
```''',
      useCase: 'Design and implement scalable microservices architectures',
    ),

    const ContextTemplate(
      name: 'Security Best Practices & Implementation',
      description: 'Comprehensive security guidelines and implementation patterns',
      category: 'Security',
      tags: ['security', 'authentication', 'authorization', 'encryption', 'best-practices'],
      contentPreview: r'''# Security Best Practices & Implementation

## Authentication & Authorization

### JWT Implementation with Refresh Tokens
```javascript
class AuthService {
  constructor() {
    this.accessTokenExpiry = '15m'
    this.refreshTokenExpiry = '7d'
    this.jwtSecret = process.env.JWT_SECRET
    this.refreshTokens = new Map() // In production, use Redis
  }

  async login(credentials) {
    const user = await this.validateCredentials(credentials)
    if (!user) throw new UnauthorizedError('Invalid credentials')
    
    // Generate tokens
    const accessToken = jwt.sign(
      { userId: user.id, email: user.email, roles: user.roles },
      this.jwtSecret,
      { expiresIn: this.accessTokenExpiry }
    )
    
    const refreshToken = this.generateSecureToken()
    const refreshTokenExpiry = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
    
    // Store refresh token securely
    await this.storeRefreshToken(user.id, refreshToken, refreshTokenExpiry)
    
    return {
      accessToken,
      refreshToken,
      user: this.sanitizeUser(user)
    }
  }

  async refreshAccessToken(refreshToken) {
    const storedToken = await this.getRefreshToken(refreshToken)
    if (!storedToken || storedToken.expiresAt < new Date()) {
      throw new UnauthorizedError('Invalid or expired refresh token')
    }
    
    const user = await this.getUserById(storedToken.userId)
    const newAccessToken = jwt.sign(
      { userId: user.id, email: user.email, roles: user.roles },
      this.jwtSecret,
      { expiresIn: this.accessTokenExpiry }
    )
    
    return { accessToken: newAccessToken }
  }

  async validateCredentials(credentials) {
    const { email, password } = credentials
    const user = await this.userRepository.findByEmail(email)
    
    if (!user) return null
    
    // Use bcrypt for password hashing
    const isValid = await bcrypt.compare(password, user.hashedPassword)
    return isValid ? user : null
  }
}
```

### Role-Based Access Control (RBAC)
```javascript
class AuthorizationMiddleware {
  constructor() {
    this.permissions = {
      'admin': ['read', 'write', 'delete', 'admin'],
      'editor': ['read', 'write'],
      'viewer': ['read'],
      'user': ['read:own', 'write:own']
    }
  }

  requirePermission(resource, action) {
    return async (req, res, next) => {
      try {
        const user = req.user // From authentication middleware
        const hasPermission = this.checkPermission(user, resource, action)
        
        if (!hasPermission) {
          return res.status(403).json({
            error: 'Insufficient permissions',
            required: `${action}:${resource}`
          })
        }
        
        next()
      } catch (error) {
        res.status(500).json({ error: 'Authorization error' })
      }
    }
  }

  checkPermission(user, resource, action) {
    const userRoles = user.roles || []
    
    return userRoles.some(role => {
      const rolePermissions = this.permissions[role] || []
      return rolePermissions.some(permission => {
        if (permission === `${action}:${resource}`) return true
        if (permission === action && !resource.includes(':')) return true
        if (permission.includes(':own') && user.id === resource.ownerId) return true
        return false
      })
    })
  }
}

// Usage in routes
app.get('/api/users', 
  authenticateToken,
  authz.requirePermission('users', 'read'),
  getUsersController
)

app.delete('/api/users/:id',
  authenticateToken, 
  authz.requirePermission('users', 'delete'),
  deleteUserController
)
```

## Input Validation & Sanitization

### Comprehensive Validation Layer
```javascript
const Joi = require('joi')

class ValidationService {
  constructor() {
    this.schemas = {
      user: Joi.object({
        email: Joi.string().email().max(254).required(),
        password: Joi.string()
          .min(8)
          .max(128)
          .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
          .required()
          .messages({
            'string.pattern.base': 'Password must contain at least 1 uppercase, 1 lowercase, 1 number, and 1 special character'
          }),
        name: Joi.string().min(2).max(50).pattern(/^[a-zA-Z\s]+$/).required(),
        age: Joi.number().integer().min(13).max(120)
      }),
      
      apiKey: Joi.object({
        name: Joi.string().min(3).max(50).required(),
        permissions: Joi.array().items(Joi.string().valid('read', 'write', 'admin')),
        expiresIn: Joi.number().integer().min(1).max(365) // days
      })
    }
  }

  validate(data, schemaName) {
    const schema = this.schemas[schemaName]
    if (!schema) throw new Error('Unknown validation schema: ' + schemaName)
    
    const { error, value } = schema.validate(data, {
      abortEarly: false,
      stripUnknown: true,
      convert: true
    })
    
    if (error) {
      const details = error.details.map(d => ({
        field: d.path.join('.'),
        message: d.message,
        value: d.context?.value
      }))
      throw new ValidationError('Validation failed', details)
    }
    
    return value
  }
}

// SQL Injection Prevention
class DatabaseService {
  async findUser(email) {
    // Use parameterized queries ALWAYS
    const query = 'SELECT * FROM users WHERE email = $1 AND deleted_at IS NULL'
    const result = await this.pool.query(query, [email])
    return result.rows[0]
  }
  
  // For dynamic queries, use query builders with validation
  async searchUsers(filters) {
    const allowedFields = ['name', 'email', 'created_at']
    const allowedOperators = ['=', 'LIKE', '>', '<', '>=', '<=']
    
    let query = 'SELECT id, name, email, created_at FROM users WHERE 1=1'
    const params = []
    
    Object.entries(filters).forEach(([field, condition]) => {
      if (!allowedFields.includes(field)) {
        throw new Error('Invalid filter field: ' + field)
      }
      
      if (!allowedOperators.includes(condition.operator)) {
        throw new Error('Invalid operator: ' + condition.operator)
      }
      
      params.push(condition.value)
      query += ` AND ${field} ${condition.operator} $${params.length}`
    })
    
    return await this.pool.query(query, params)
  }
}
```

## API Security Headers & Rate Limiting

### Security Headers Middleware
```javascript
const helmet = require('helmet')
const rateLimit = require('express-rate-limit')

class SecurityMiddleware {
  static configure(app) {
    // Helmet for security headers
    app.use(helmet({
      contentSecurityPolicy: {
        directives: {
          defaultSrc: ["'self'"],
          scriptSrc: ["'self'", "'unsafe-inline'", "https://cdn.jsdelivr.net"],
          styleSrc: ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com"],
          imgSrc: ["'self'", "data:", "https:"],
          fontSrc: ["'self'", "https://fonts.gstatic.com"]
        }
      },
      hsts: {
        maxAge: 31536000,
        includeSubDomains: true,
        preload: true
      }
    }))

    // Rate limiting
    const limiter = rateLimit({
      windowMs: 15 * 60 * 1000, // 15 minutes
      max: 100, // limit each IP to 100 requests per windowMs
      message: {
        error: 'Too many requests',
        retryAfter: 900 // seconds
      },
      standardHeaders: true,
      legacyHeaders: false,
      store: new RedisStore({
        client: redisClient,
        prefix: 'rl:'
      })
    })

    // Different limits for different endpoints
    app.use('/api/auth/', rateLimit({
      windowMs: 15 * 60 * 1000,
      max: 5 // Stricter limit for auth endpoints
    }))

    app.use('/api/', limiter)
  }
}

// API Key Authentication
class ApiKeyAuth {
  constructor() {
    this.apiKeys = new Map() // In production, use database
  }

  async validateApiKey(req, res, next) {
    const apiKey = req.headers['x-api-key']
    
    if (!apiKey) {
      return res.status(401).json({ error: 'API key required' })
    }
    
    const keyData = await this.getApiKeyData(apiKey)
    if (!keyData || keyData.expiresAt < new Date()) {
      return res.status(401).json({ error: 'Invalid or expired API key' })
    }
    
    // Check rate limits for this API key
    const usage = await this.checkApiKeyUsage(apiKey)
    if (usage.requestsThisHour > keyData.hourlyLimit) {
      return res.status(429).json({ error: 'API key rate limit exceeded' })
    }
    
    req.apiKey = keyData
    next()
  }
}
```

## Data Encryption & Secure Storage

### Encryption at Rest and in Transit
```javascript
const crypto = require('crypto')

class EncryptionService {
  constructor() {
    this.algorithm = 'aes-256-gcm'
    this.keyDerivationRounds = 100000
  }

  // Encrypt sensitive data before storing
  encrypt(text, password) {
    const salt = crypto.randomBytes(16)
    const iv = crypto.randomBytes(12)
    const key = crypto.pbkdf2Sync(password, salt, this.keyDerivationRounds, 32, 'sha256')
    
    const cipher = crypto.createCipherGCM(this.algorithm, key, iv)
    let encrypted = cipher.update(text, 'utf8', 'hex')
    encrypted += cipher.final('hex')
    
    const authTag = cipher.getAuthTag()
    
    return {
      encrypted,
      salt: salt.toString('hex'),
      iv: iv.toString('hex'),
      authTag: authTag.toString('hex')
    }
  }

  decrypt(encryptedData, password) {
    const key = crypto.pbkdf2Sync(
      password, 
      Buffer.from(encryptedData.salt, 'hex'), 
      this.keyDerivationRounds, 
      32, 
      'sha256'
    )
    
    const decipher = crypto.createDecipherGCM(
      this.algorithm, 
      key, 
      Buffer.from(encryptedData.iv, 'hex')
    )
    
    decipher.setAuthTag(Buffer.from(encryptedData.authTag, 'hex'))
    
    let decrypted = decipher.update(encryptedData.encrypted, 'hex', 'utf8')
    decrypted += decipher.final('utf8')
    
    return decrypted
  }

  // Hash passwords securely
  async hashPassword(password) {
    const saltRounds = 12
    return await bcrypt.hash(password, saltRounds)
  }
}
```

## Security Monitoring & Logging

### Security Event Logging
```javascript
class SecurityLogger {
  constructor() {
    this.logger = winston.createLogger({
      level: 'info',
      format: winston.format.json(),
      transports: [
        new winston.transports.File({ filename: 'security.log' }),
        new winston.transports.Console()
      ]
    })
  }

  logSecurityEvent(eventType, details, req = null) {
    const logData = {
      timestamp: new Date().toISOString(),
      eventType,
      details,
      ip: req?.ip,
      userAgent: req?.get('User-Agent'),
      userId: req?.user?.id,
      sessionId: req?.sessionId
    }

    switch (eventType) {
      case 'LOGIN_SUCCESS':
      case 'LOGIN_FAILURE':
      case 'PASSWORD_RESET_REQUEST':
      case 'ACCOUNT_LOCKED':
      case 'SUSPICIOUS_ACTIVITY':
        this.logger.warn('Security Event', logData)
        break
      case 'UNAUTHORIZED_ACCESS_ATTEMPT':
      case 'SQL_INJECTION_ATTEMPT':
      case 'XSS_ATTEMPT':
        this.logger.error('Security Threat', logData)
        this.alertSecurityTeam(logData)
        break
      default:
        this.logger.info('Security Event', logData)
    }
  }

  async alertSecurityTeam(eventData) {
    // Send alert to security team
    // This could be email, Slack, PagerDuty, etc.
  }
}
```''',
      useCase: 'Implement comprehensive security measures for web applications and APIs',
    ),

    // Include existing templates for completeness
    const ContextTemplate(
      name: 'API Documentation Template',
      description: 'Complete REST API documentation with examples',
      category: 'Documentation',
      tags: ['api', 'rest', 'documentation', 'examples'],
      contentPreview: '# API Documentation\n\n## Overview\nThis API provides...\n\n## Endpoints\n\n### GET /api/users\n...',
      useCase: 'Document REST APIs with clear examples and response formats',
    ),
    const ContextTemplate(
      name: 'Database Schema Documentation',
      description: 'Complete database structure and relationships',
      category: 'Documentation',
      tags: ['database', 'schema', 'sql', 'relationships'],
      contentPreview: '# Database Schema\n\n## Tables\n\n### users\n- id (Primary Key)\n- email (Unique)\n- created_at...',
      useCase: 'Document database structure and table relationships',
    ),
    const ContextTemplate(
      name: 'Testing Strategies',
      description: 'Unit, integration, and E2E testing approaches',
      category: 'Best Practices',
      tags: ['testing', 'unit-tests', 'integration', 'e2e'],
      contentPreview: '''# Testing Strategy

## Unit Testing

### Jest Configuration
```javascript
module.exports = {
  testEnvironment: 'node'...''',
      useCase: 'Establish comprehensive testing practices for your codebase',
    ),
    const ContextTemplate(
      name: 'DevOps Pipeline',
      description: 'CI/CD pipeline configuration and deployment',
      category: 'Deployment',
      tags: ['devops', 'ci-cd', 'docker', 'kubernetes'],
      contentPreview: '# CI/CD Pipeline\n\n## GitHub Actions\n\n```yaml\nname: Deploy\non:\n  push:\n    branches: [main]',
      useCase: 'Set up automated deployment pipelines with best practices',
    ),
    const ContextTemplate(
      name: 'Mobile App Architecture',
      description: 'Flutter/React Native app structure patterns',
      category: 'Architecture',
      tags: ['mobile', 'flutter', 'react-native', 'architecture'],
      contentPreview: '# Mobile App Architecture\n\n## Folder Structure\n\n```\nlib/\n├── core/\n│   ├── constants/\n│   └── utils/',
      useCase: 'Structure mobile applications with scalable architecture',
    ),
  ];

  List<ContextTemplate> get filteredTemplates {
    return templates.where((template) {
      final matchesSearch = template.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          template.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
          template.tags.any((tag) => tag.toLowerCase().contains(searchQuery.toLowerCase()));
      
      final matchesCategory = selectedCategory == 'All' || template.category == selectedCategory;
      
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SemanticColors.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(SpacingTokens.headerPadding),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  SemanticColors.background,
                  SemanticColors.background.withValues(alpha: 0.95),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    HeaderButton(
                      text: 'Back',
                      icon: Icons.arrow_back,
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          context.pop();
                        }
                      },
                    ),
                    const Spacer(),
                    Text(
                      'Context Library',
                      style: TextStyles.pageTitle.copyWith(
                        color: SemanticColors.onSurface,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 100), // Balance the back button
                  ],
                ),
                const SizedBox(height: SpacingTokens.lg),
                // Tab selector
                Container(
                  decoration: BoxDecoration(
                    color: SemanticColors.surface.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                    border: Border.all(color: SemanticColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => selectedTab = 0),
                          child: Container(
                            padding: const EdgeInsets.all(SpacingTokens.md),
                            decoration: BoxDecoration(
                              color: selectedTab == 0 ? SemanticColors.primary.withValues(alpha: 0.1) : null,
                              borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                            ),
                            child: Text(
                              'My Context',
                              textAlign: TextAlign.center,
                              style: TextStyles.bodyMedium.copyWith(
                                color: selectedTab == 0 ? SemanticColors.primary : SemanticColors.onSurfaceVariant,
                                fontWeight: selectedTab == 0 ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => selectedTab = 1),
                          child: Container(
                            padding: const EdgeInsets.all(SpacingTokens.md),
                            decoration: BoxDecoration(
                              color: selectedTab == 1 ? SemanticColors.primary.withValues(alpha: 0.1) : null,
                              borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                            ),
                            child: Text(
                              'Template Library',
                              textAlign: TextAlign.center,
                              style: TextStyles.bodyMedium.copyWith(
                                color: selectedTab == 1 ? SemanticColors.primary : SemanticColors.onSurfaceVariant,
                                fontWeight: selectedTab == 1 ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: selectedTab == 0 ? _buildMyContextTab() : _buildTemplateLibraryTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildMyContextTab() {
    final contextAsync = ref.watch(contextDocumentsWithVectorProvider);
    
    return contextAsync.when(
      data: (documents) {
        if (documents.isEmpty) {
          return _buildEmptyMyContext();
        }
        
        return Padding(
          padding: const EdgeInsets.all(SpacingTokens.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search and filter
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) => setState(() => searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search my context...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                          borderSide: const BorderSide(color: SemanticColors.border),
                        ),
                        filled: true,
                        fillColor: SemanticColors.surface,
                      ),
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.lg),
                  AsmblButton.primary(
                    text: 'Add Context',
                    icon: Icons.add,
                    onPressed: () => setState(() => _showCreateFlow = true),
                  ),
                ],
              ),
              
              const SizedBox(height: SpacingTokens.xl),
              
              // Context documents grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: SpacingTokens.lg,
                    mainAxisSpacing: SpacingTokens.lg,
                  ),
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final doc = documents[index];
                    return AsmblCard(
                      child: Padding(
                        padding: const EdgeInsets.all(SpacingTokens.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.description,
                                  size: 20,
                                  color: SemanticColors.primary,
                                ),
                                const SizedBox(width: SpacingTokens.sm),
                                Expanded(
                                  child: Text(
                                    doc.title,
                                    style: TextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: SemanticColors.onSurface,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: SpacingTokens.md),
                            Text(
                              doc.type.displayName,
                              style: TextStyles.caption.copyWith(
                                color: SemanticColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: SpacingTokens.sm),
                            Expanded(
                              child: Text(
                                doc.content,
                                style: TextStyles.bodySmall.copyWith(
                                  color: SemanticColors.onSurfaceVariant,
                                ),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: SpacingTokens.md),
                            // Tags
                            if (doc.tags.isNotEmpty) ...[ 
                              Wrap(
                                spacing: 4,
                                children: doc.tags.take(3).map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: SemanticColors.surfaceVariant.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                                    ),
                                    child: Text(
                                      tag,
                                      style: TextStyles.caption.copyWith(
                                        color: SemanticColors.onSurfaceVariant,
                                        fontSize: 10,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: SemanticColors.error,
            ),
            const SizedBox(height: SpacingTokens.componentSpacing),
            Text(
              'Error loading context documents',
              style: TextStyles.pageTitle.copyWith(
                color: SemanticColors.onSurface,
              ),
            ),
            const SizedBox(height: SpacingTokens.componentSpacing),
            Text(
              error.toString(),
              style: TextStyles.bodyMedium.copyWith(
                color: SemanticColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMyContext() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 64,
              color: SemanticColors.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: SpacingTokens.xl),
            Text(
              'Your Context Library is Empty',
              style: TextStyles.pageTitle.copyWith(
                color: SemanticColors.onSurface,
              ),
            ),
            const SizedBox(height: SpacingTokens.md),
            Text(
              'Add context documents to help your agents understand your codebase, requirements, and preferences.',
              style: TextStyles.bodyMedium.copyWith(
                color: SemanticColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SpacingTokens.xl),
            AsmblButton.primary(
              text: 'Add Your First Context',
              icon: Icons.add,
              onPressed: () => setState(() => _showCreateFlow = true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateLibraryTab() {
    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and filters
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) => setState(() => searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search templates...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                      borderSide: const BorderSide(color: SemanticColors.border),
                    ),
                    filled: true,
                    fillColor: SemanticColors.surface,
                  ),
                ),
              ),
              const SizedBox(width: SpacingTokens.lg),
              DropdownButton<String>(
                value: selectedCategory,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() => selectedCategory = newValue);
                  }
                },
                items: categories.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ],
          ),
          
          const SizedBox(height: SpacingTokens.xl),
          
          // Templates grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.75,
                crossAxisSpacing: SpacingTokens.lg,
                mainAxisSpacing: SpacingTokens.lg,
              ),
              itemCount: filteredTemplates.length,
              itemBuilder: (context, index) {
                final template = filteredTemplates[index];
                return TemplateCard(template: template);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TemplateCard extends StatefulWidget {
  final ContextTemplate template;

  const TemplateCard({
    super.key,
    required this.template,
  });

  @override
  State<TemplateCard> createState() => _TemplateCardState();
}

class _TemplateCardState extends State<TemplateCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AsmblCard(
        isInteractive: true,
        child: Padding(
          padding: const EdgeInsets.all(SpacingTokens.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: SemanticColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                ),
                child: Text(
                  widget.template.category,
                  style: TextStyles.caption.copyWith(
                    color: SemanticColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              const SizedBox(height: SpacingTokens.md),
              
              // Title
              Text(
                widget.template.name,
                style: TextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: SemanticColors.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: SpacingTokens.sm),
              
              // Description
              Expanded(
                child: Text(
                  widget.template.description,
                  style: TextStyles.bodySmall.copyWith(
                    color: SemanticColors.onSurfaceVariant,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const SizedBox(height: SpacingTokens.md),
              
              // Tags
              if (widget.template.tags.isNotEmpty) ...[
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: widget.template.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: SemanticColors.surfaceVariant.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(BorderRadiusTokens.sm),
                      ),
                      child: Text(
                        tag,
                        style: TextStyles.caption.copyWith(
                          color: SemanticColors.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: SpacingTokens.md),
              ],
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: AsmblButton.secondary(
                      text: 'Preview',
                      onPressed: () => _showPreview(context),
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                  Expanded(
                    child: AsmblButton.primary(
                      text: 'Use',
                      onPressed: () => _useTemplate(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPreview(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: SemanticColors.surface,
        child: Container(
          width: 800,
          height: 600,
          padding: const EdgeInsets.all(SpacingTokens.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.template.name,
                      style: TextStyles.pageTitle.copyWith(
                        color: SemanticColors.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: SpacingTokens.md),
              
              Text(
                widget.template.description,
                style: TextStyles.bodyMedium.copyWith(
                  color: SemanticColors.onSurfaceVariant,
                ),
              ),
              
              const SizedBox(height: SpacingTokens.lg),
              
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(SpacingTokens.lg),
                  decoration: BoxDecoration(
                    color: SemanticColors.surfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
                    border: Border.all(color: SemanticColors.border),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      widget.template.contentPreview,
                      style: TextStyles.bodySmall.copyWith(
                        color: SemanticColors.onSurface,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: SpacingTokens.lg),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AsmblButton.secondary(
                    text: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: SpacingTokens.md),
                  AsmblButton.primary(
                    text: 'Use This Template',
                    onPressed: () {
                      Navigator.of(context).pop();
                      _useTemplate(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _useTemplate(BuildContext context) {
    // Navigate to create context form with template pre-filled
    // This would integrate with the existing context creation flow
  }
}

class ContextTemplate {
  final String name;
  final String description;
  final String category;
  final List<String> tags;
  final String contentPreview;
  final String useCase;

  const ContextTemplate({
    required this.name,
    required this.description,
    required this.category,
    required this.tags,
    required this.contentPreview,
    required this.useCase,
  });
}