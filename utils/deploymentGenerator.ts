import { WizardData } from '../types/wizard';

export function generateDeploymentConfigs(wizardData: WizardData, promptOutput: string): Record<string, string> {
  const configs: Record<string, string> = {};

  // Check if this is a design-focused agent
  const hasDesignExtensions = wizardData.extensions?.some(ext => 
    ext.enabled && ['figma-mcp', 'storybook-api', 'design-tokens', 'sketch-api', 'zeplin-api', 'supabase-api'].includes(ext.id)
  );

  // Desktop Extension (.dxt) - Primary Recommendation
  const desktopExtension = {
    name: wizardData.agentName || "Custom AI Agent",
    version: "1.0.0",
    description: wizardData.agentDescription || "Custom AI agent with MCP integration",
    agent_type: hasDesignExtensions ? "design_agent" : "general_agent",
    extension_config: {
      integrations: wizardData.extensions?.filter(s => s.enabled).reduce((acc, extension) => {
        acc[extension.id] = {
          platforms: extension.selectedPlatforms,
          config: extension.config,
          security_level: extension.securityLevel,
          ...(hasDesignExtensions && extension.category === 'Design & Prototyping' && {
            design_specific: {
              sync_interval: "5m",
              auto_update_tokens: true,
              component_validation: true,
              accessibility_checks: true
            }
          })
        };
        return acc;
      }, {} as Record<string, any>) || {}
    },
    security: {
      auth_method: wizardData.security.authMethod,
      permissions: wizardData.security.permissions,
      vault_integration: wizardData.security.vaultIntegration,
      audit_logging: wizardData.security.auditLogging,
      rate_limiting: wizardData.security.rateLimiting,
      session_timeout: wizardData.security.sessionTimeout
    },
    behavior: {
      tone: wizardData.tone,
      response_length: wizardData.responseLength,
      constraints: wizardData.constraints,
      constraint_documentation: wizardData.constraintDocs
    },
    ...(hasDesignExtensions && {
      design_configuration: {
        design_system_enforcement: true,
        accessibility_validation: "wcag_2_1_aa",
        responsive_design_check: true,
        brand_consistency_validation: true,
        component_library_sync: true,
        design_token_validation: true,
        figma_file_organization: {
          enforce_naming_conventions: true,
          layer_organization: true,
          component_structure_validation: true
        }
      }
    }),
    system_prompt: promptOutput
  };
  configs.desktop = JSON.stringify(desktopExtension, null, 2);

  // Modern Platform Configurations
  configs.railway = generateRailwayConfig(wizardData, hasDesignExtensions);
  configs.render = generateRenderConfig(wizardData, hasDesignExtensions);
  configs.fly = generateFlyConfig(wizardData, hasDesignExtensions);
  configs.vercel = generateVercelConfig(wizardData, hasDesignExtensions);
  configs.cloudrun = generateCloudRunConfig(wizardData, hasDesignExtensions);

  // Traditional Container Configurations
  configs.docker = generateDockerConfig(wizardData, hasDesignExtensions);
  configs.kubernetes = generateKubernetesConfig(wizardData, hasDesignExtensions);

  // Raw JSON Configuration
  configs.json = JSON.stringify({
    agent: {
      name: wizardData.agentName,
      description: wizardData.agentDescription,
      purpose: wizardData.primaryPurpose,
      environment: wizardData.targetEnvironment,
      type: hasDesignExtensions ? "design_agent" : "general_agent"
    },
    extensions: wizardData.extensions?.filter(s => s.enabled) || [],
    security: wizardData.security,
    behavior: {
      tone: wizardData.tone,
      response_length: wizardData.responseLength,
      constraints: wizardData.constraints,
      constraint_documentation: wizardData.constraintDocs
    },
    ...(hasDesignExtensions && {
      design_capabilities: {
        figma_integration: wizardData.extensions?.some(ext => ext.enabled && ext.id === 'figma-mcp'),
        storybook_integration: wizardData.extensions?.some(ext => ext.enabled && ext.id === 'storybook-api'),
        design_tokens: wizardData.extensions?.some(ext => ext.enabled && ext.id === 'design-tokens'),
        supabase_backend: wizardData.extensions?.some(ext => ext.enabled && ext.id === 'supabase-api'),
        accessibility_enforcement: wizardData.constraints?.includes('accessibility'),
        design_system_compliance: wizardData.constraints?.includes('design-system'),
        responsive_design: wizardData.constraints?.includes('responsive-design'),
        brand_consistency: wizardData.constraints?.includes('brand-consistency')
      }
    }),
    system_prompt: promptOutput,
    test_results: wizardData.testResults,
    observability: {
      metrics: "prometheus",
      tracing: "opentelemetry",
      logging: "structured-json",
      health_endpoints: ["/health", "/ready", "/metrics"]
    }
  }, null, 2);

  return configs;
}

function generateDockerConfig(wizardData: WizardData, hasDesignExtensions: boolean): string {
  const dockerServices: string[] = [];
  
  if (wizardData.extensions?.some(s => s.enabled && s.category === 'database')) {
    dockerServices.push(`
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: agentdb
      POSTGRES_USER: agent_user
      POSTGRES_PASSWORD: \${POSTGRES_PASSWORD}
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U agent_user -d agentdb"]
      interval: 30s
      timeout: 10s
      retries: 3

  qdrant:
    image: qdrant/qdrant:latest
    ports:
      - "6333:6333"
    volumes:
      - qdrant_storage:/qdrant/storage
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:6333/health"]
      interval: 30s
      timeout: 10s
      retries: 3`);
  }

  // Add Supabase local development setup for design agents
  if (hasDesignExtensions && wizardData.extensions?.some(s => s.enabled && s.id === 'supabase-api')) {
    dockerServices.push(`
  supabase-db:
    image: supabase/postgres:15.1.0.117
    healthcheck:
      test: pg_isready -U postgres -h localhost
      interval: 5s
      timeout: 5s
      retries: 10
    command:
      - postgres
      - -c
      - config_file=/etc/postgresql/postgresql.conf
      - -c
      - log_min_messages=fatal
    environment:
      POSTGRES_HOST: /var/run/postgresql
      PGPORT: 5432
      POSTGRES_PORT: 5432
      PGPASSWORD: \${POSTGRES_PASSWORD:-your-super-secret-and-long-postgres-password}
      POSTGRES_PASSWORD: \${POSTGRES_PASSWORD:-your-super-secret-and-long-postgres-password}
      PGDATABASE: postgres
      POSTGRES_DB: postgres
    volumes:
      - supabase_db_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  supabase-storage:
    image: supabase/storage-api:v0.40.4
    depends_on:
      supabase-db:
        condition: service_healthy
    restart: unless-stopped
    environment:
      ANON_KEY: \${ANON_KEY}
      SERVICE_KEY: \${SERVICE_ROLE_KEY}
      POSTGREST_URL: http://supabase-rest:3000
      PGRST_JWT_SECRET: \${JWT_SECRET}
      DATABASE_URL: postgresql://postgres:\${POSTGRES_PASSWORD:-your-super-secret-and-long-postgres-password}@supabase-db:5432/postgres
      STORAGE_BACKEND: file
      FILE_SIZE_LIMIT: 52428800
      TENANT_ID: stub
      REGION: stub
      GLOBAL_S3_BUCKET: stub
      ENABLE_IMAGE_TRANSFORMATION: true
      IMGPROXY_URL: http://supabase-imgproxy:5001
    ports:
      - "5000:5000"
    volumes:
      - supabase_storage_data:/var/lib/storage`);
  }

  if (wizardData.security.vaultIntegration === 'hashicorp') {
    dockerServices.push(`
  vault:
    image: hashicorp/vault:latest
    cap_add:
      - IPC_LOCK
    environment:
      VAULT_DEV_ROOT_TOKEN_ID: \${VAULT_ROOT_TOKEN}
      VAULT_DEV_LISTEN_ADDRESS: 0.0.0.0:8200
    ports:
      - "8200:8200"`);
  }

  // Add design-specific services
  if (hasDesignExtensions) {
    dockerServices.push(`
  design-token-server:
    image: tokens-studio/figma-plugin:latest
    environment:
      NODE_ENV: ${wizardData.targetEnvironment}
      TOKEN_STORAGE_TYPE: database
      DATABASE_URL: postgresql://agent_user:\${POSTGRES_PASSWORD}@postgres:5432/agentdb
    ports:
      - "3001:3001"
    depends_on:
      - postgres
    volumes:
      - ./design-tokens:/app/tokens
      - ./design-system:/app/system`);
  }

  return `# ${wizardData.agentName} - Docker Compose Configuration
version: '3.8'

networks:
  agent_network:
    driver: bridge

services:${dockerServices.join('')}

  extension-orchestrator:
    build: 
      context: .
      dockerfile: Dockerfile
    environment:
      NODE_ENV: ${wizardData.targetEnvironment}
      AGENT_NAME: "${wizardData.agentName}"
      AGENT_TYPE: "${hasDesignExtensions ? 'design_agent' : 'general_agent'}"
      AUTH_METHOD: ${wizardData.security.authMethod}
      VAULT_INTEGRATION: ${wizardData.security.vaultIntegration}
      AUDIT_LOGGING: ${wizardData.security.auditLogging}
      RATE_LIMITING: ${wizardData.security.rateLimiting}
      SESSION_TIMEOUT: ${wizardData.security.sessionTimeout}${hasDesignExtensions ? `
      # Design-specific environment variables
      DESIGN_SYSTEM_VALIDATION: true
      ACCESSIBILITY_CHECKS: true
      FIGMA_SYNC_INTERVAL: "5m"
      COMPONENT_VALIDATION: true` : ''}
    volumes:
      - ./config:/app/config
      - ./logs:/app/logs${hasDesignExtensions ? `
      - ./design-system:/app/design-system
      - ./design-tokens:/app/design-tokens
      - ./component-library:/app/component-library` : ''}
    ports:
      - "8080:8080"
    depends_on:${dockerServices.length > 0 ? dockerServices.map(s => 
      s.includes('postgres:') ? '\n      - postgres' :
      s.includes('supabase-db:') ? '\n      - supabase-db' :
      s.includes('qdrant:') ? '\n      - qdrant' :
      s.includes('vault:') ? '\n      - vault' : 
      s.includes('design-token-server:') ? '\n      - design-token-server' : ''
    ).filter(Boolean).join('') : ''}
    networks:
      - agent_network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    restart: unless-stopped

volumes:${dockerServices.includes('postgres') ? '\n  postgres_data:' : ''}${dockerServices.includes('supabase_db_data') ? '\n  supabase_db_data:\n  supabase_storage_data:' : ''}${dockerServices.includes('qdrant') ? '\n  qdrant_storage:' : ''}
  agent_logs:
  agent_config:${hasDesignExtensions ? '\n  design_system_data:\n  design_tokens_data:\n  component_library_data:' : ''}`;
}

function generateKubernetesConfig(wizardData: WizardData, hasDesignExtensions: boolean): string {
  const agentSlug = wizardData.agentName.toLowerCase().replace(/[^a-z0-9]/g, '-');
  
  return `# ${wizardData.agentName} - Kubernetes Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${agentSlug}-agent
  labels:
    app: ${agentSlug}-agent
    version: "1.0.0"
    environment: ${wizardData.targetEnvironment}
    agent-type: ${hasDesignExtensions ? 'design-agent' : 'general-agent'}
spec:
  replicas: ${wizardData.targetEnvironment === 'production' ? 3 : 1}
  selector:
    matchLabels:
      app: ${agentSlug}-agent
  template:
    metadata:
      labels:
        app: ${agentSlug}-agent
        agent-type: ${hasDesignExtensions ? 'design-agent' : 'general-agent'}
    spec:
      containers:
      - name: agent-container
        image: ${agentSlug}-agent:latest
        ports:
        - containerPort: 8080
        env:
        - name: NODE_ENV
          value: "${wizardData.targetEnvironment}"
        - name: AGENT_NAME
          value: "${wizardData.agentName}"
        - name: AGENT_TYPE
          value: "${hasDesignExtensions ? 'design_agent' : 'general_agent'}"
        - name: AUTH_METHOD
          value: "${wizardData.security.authMethod}"
        - name: VAULT_INTEGRATION
          value: "${wizardData.security.vaultIntegration}"
        - name: OTEL_SERVICE_NAME
          value: "${agentSlug}"
        - name: OTEL_EXPORTER_OTLP_ENDPOINT
          value: "http://opentelemetry-collector:4317"
        - name: OTEL_RESOURCE_ATTRIBUTES
          value: "service.name=${agentSlug},service.version=1.0.0,environment=${wizardData.targetEnvironment}"
        - name: PROMETHEUS_METRICS_PORT
          value: "9090"
        - name: LOG_LEVEL
          value: "${wizardData.targetEnvironment === 'production' ? 'info' : 'debug'}"${hasDesignExtensions ? `
        - name: DESIGN_SYSTEM_VALIDATION
          value: "true"
        - name: ACCESSIBILITY_CHECKS
          value: "true"
        - name: FIGMA_SYNC_INTERVAL
          value: "5m"
        - name: COMPONENT_VALIDATION
          value: "true"` : ''}
        resources:
          requests:
            memory: "${hasDesignExtensions ? '1Gi' : '512Mi'}"
            cpu: "${hasDesignExtensions ? '500m' : '250m'}"
          limits:
            memory: "${hasDesignExtensions ? '2Gi' : '1Gi'}" 
            cpu: "${hasDesignExtensions ? '1' : '500m'}"
        volumeMounts:
        - name: config-volume
          mountPath: /app/config${hasDesignExtensions ? `
        - name: design-system-volume
          mountPath: /app/design-system
        - name: design-tokens-volume
          mountPath: /app/design-tokens` : ''}
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: config-volume
        configMap:
          name: ${agentSlug}-config${hasDesignExtensions ? `
      - name: design-system-volume
        persistentVolumeClaim:
          claimName: ${agentSlug}-design-system-pvc
      - name: design-tokens-volume
        persistentVolumeClaim:
          claimName: ${agentSlug}-design-tokens-pvc` : ''}
---
apiVersion: v1
kind: Service
metadata:
  name: ${agentSlug}-service
  labels:
    app: ${agentSlug}-agent
    agent-type: ${hasDesignExtensions ? 'design-agent' : 'general-agent'}
spec:
  selector:
    app: ${agentSlug}-agent
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${agentSlug}-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"${hasDesignExtensions ? `
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"  # For design asset uploads` : ''}
spec:
  tls:
  - hosts:
    - ${agentSlug}.example.com
    secretName: ${agentSlug}-tls
  rules:
  - host: ${agentSlug}.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ${agentSlug}-service
            port:
              number: 80${hasDesignExtensions ? `
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${agentSlug}-design-system-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${agentSlug}-design-tokens-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${agentSlug}-design-config
data:
  design-system.yml: |
    design_system:
      validation:
        accessibility: wcag_2_1_aa
        responsive_breakpoints:
          - mobile: 320px
          - tablet: 768px
          - desktop: 1024px
          - large: 1440px
      figma:
        sync_interval: 5m
        component_validation: true
        naming_conventions: true
      storybook:
        auto_documentation: true
        visual_testing: true
      tokens:
        auto_sync: true
        validation: strict` : ''}`;
}

function generateRailwayConfig(wizardData: WizardData, hasDesignExtensions: boolean): string {
  const agentSlug = wizardData.agentName.toLowerCase().replace(/[^a-z0-9]/g, '-');
  
  return `# ${wizardData.agentName} - Railway Configuration
[build]
  builder = "NIXPACKS"
  buildCommand = "npm ci && npm run build"

[deploy]
  startCommand = "npm start"
  healthcheckPath = "/health"
  healthcheckTimeout = 300
  restartPolicyType = "ON_FAILURE"
  restartPolicyMaxRetries = 10

[environments.production]
  NODE_ENV = "production"
  AGENT_NAME = "${wizardData.agentName}"
  AGENT_TYPE = "${hasDesignExtensions ? 'design_agent' : 'general_agent'}"
  PORT = { { PORT } }
  
  # Security Configuration
  AUTH_METHOD = "${wizardData.security.authMethod}"
  VAULT_INTEGRATION = "${wizardData.security.vaultIntegration}"
  AUDIT_LOGGING = "${wizardData.security.auditLogging}"
  RATE_LIMITING = "${wizardData.security.rateLimiting}"
  SESSION_TIMEOUT = "${wizardData.security.sessionTimeout}"

  # Observability
  OTEL_SERVICE_NAME = "${agentSlug}"
  OTEL_EXPORTER_OTLP_ENDPOINT = "https://api.railway.app/v1/otel"
  LOG_LEVEL = "${wizardData.targetEnvironment === 'production' ? 'info' : 'debug'}"${hasDesignExtensions ? `
  
  # Design Agent Configuration
  DESIGN_SYSTEM_VALIDATION = "true"
  ACCESSIBILITY_CHECKS = "true"
  FIGMA_SYNC_INTERVAL = "5m"
  COMPONENT_VALIDATION = "true"` : ''}

[environments.staging]
  NODE_ENV = "staging"
  AGENT_NAME = "${wizardData.agentName}-staging"
  AGENT_TYPE = "${hasDesignExtensions ? 'design_agent' : 'general_agent'}"
  
[networking]
  serviceName = "${agentSlug}"
  servicePort = 8080`;
}

function generateRenderConfig(wizardData: WizardData, hasDesignExtensions: boolean): string {
  const agentSlug = wizardData.agentName.toLowerCase().replace(/[^a-z0-9]/g, '-');
  
  return `# ${wizardData.agentName} - Render Blueprint
services:
  - type: web
    name: ${agentSlug}
    runtime: node
    plan: ${wizardData.targetEnvironment === 'production' ? 'standard' : 'starter'}
    buildCommand: npm ci && npm run build
    startCommand: npm start
    healthCheckPath: /health
    
    envVars:
      - key: NODE_ENV
        value: ${wizardData.targetEnvironment}
      - key: AGENT_NAME
        value: ${wizardData.agentName}
      - key: AGENT_TYPE
        value: ${hasDesignExtensions ? 'design_agent' : 'general_agent'}
      - key: AUTH_METHOD
        value: ${wizardData.security.authMethod}
      - key: VAULT_INTEGRATION
        value: ${wizardData.security.vaultIntegration}
      - key: AUDIT_LOGGING
        value: ${wizardData.security.auditLogging}
      - key: RATE_LIMITING
        value: ${wizardData.security.rateLimiting}
      - key: SESSION_TIMEOUT
        value: ${wizardData.security.sessionTimeout}
      - key: OTEL_SERVICE_NAME
        value: ${agentSlug}
      - key: LOG_LEVEL
        value: ${wizardData.targetEnvironment === 'production' ? 'info' : 'debug'}${hasDesignExtensions ? `
      - key: DESIGN_SYSTEM_VALIDATION
        value: "true"
      - key: ACCESSIBILITY_CHECKS
        value: "true"
      - key: FIGMA_SYNC_INTERVAL
        value: "5m"
      - key: COMPONENT_VALIDATION
        value: "true"` : ''}

${wizardData.extensions?.some(ext => ext.enabled && ext.category === 'database') ? `databases:
  - name: ${agentSlug}-postgres
    databaseName: ${agentSlug}
    user: ${agentSlug}_user
    plan: starter` : ''}`;
}

function generateFlyConfig(wizardData: WizardData, hasDesignExtensions: boolean): string {
  const agentSlug = wizardData.agentName.toLowerCase().replace(/[^a-z0-9]/g, '-');
  
  return `# ${wizardData.agentName} - Fly.io Configuration
app = "${agentSlug}"
primary_region = "sea"
kill_signal = "SIGINT"
kill_timeout = "5s"

[experimental]
  auto_rollback = true

[build]

[deploy]
  release_command = "npm run db:migrate"

[env]
  NODE_ENV = "${wizardData.targetEnvironment}"
  AGENT_NAME = "${wizardData.agentName}"
  AGENT_TYPE = "${hasDesignExtensions ? 'design_agent' : 'general_agent'}"
  AUTH_METHOD = "${wizardData.security.authMethod}"
  VAULT_INTEGRATION = "${wizardData.security.vaultIntegration}"
  AUDIT_LOGGING = "${wizardData.security.auditLogging}"
  RATE_LIMITING = "${wizardData.security.rateLimiting}"
  SESSION_TIMEOUT = "${wizardData.security.sessionTimeout}"
  OTEL_SERVICE_NAME = "${agentSlug}"
  LOG_LEVEL = "${wizardData.targetEnvironment === 'production' ? 'info' : 'debug'}"${hasDesignExtensions ? `
  DESIGN_SYSTEM_VALIDATION = "true"
  ACCESSIBILITY_CHECKS = "true"
  FIGMA_SYNC_INTERVAL = "5m"
  COMPONENT_VALIDATION = "true"` : ''}

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = true
  auto_start_machines = true
  min_machines_running = ${wizardData.targetEnvironment === 'production' ? 1 : 0}
  processes = ["app"]

  [http_service.checks]
    [http_service.checks.health]
      grace_period = "10s"
      interval = "30s"
      method = "GET"
      timeout = "5s"
      path = "/health"

[[vm]]
  memory = "${hasDesignExtensions ? '1gb' : '512mb'}"
  cpu_kind = "shared"
  cpus = ${hasDesignExtensions ? 2 : 1}

[metrics]
  port = 9091
  path = "/metrics"`;
}

function generateVercelConfig(wizardData: WizardData, hasDesignExtensions: boolean): string {
  const agentSlug = wizardData.agentName.toLowerCase().replace(/[^a-z0-9]/g, '-');
  
  return JSON.stringify({
    name: agentSlug,
    version: 2,
    builds: [
      {
        src: "package.json",
        use: "@vercel/node",
        config: {
          maxLambdaSize: hasDesignExtensions ? "50mb" : "25mb"
        }
      }
    ],
    routes: [
      {
        src: "/health",
        dest: "/api/health"
      },
      {
        src: "/metrics",
        dest: "/api/metrics"
      },
      {
        src: "/(.*)",
        dest: "/api/agent"
      }
    ],
    env: {
      NODE_ENV: wizardData.targetEnvironment,
      AGENT_NAME: wizardData.agentName,
      AGENT_TYPE: hasDesignExtensions ? 'design_agent' : 'general_agent',
      AUTH_METHOD: wizardData.security.authMethod,
      VAULT_INTEGRATION: wizardData.security.vaultIntegration,
      AUDIT_LOGGING: wizardData.security.auditLogging,
      RATE_LIMITING: wizardData.security.rateLimiting,
      SESSION_TIMEOUT: wizardData.security.sessionTimeout,
      OTEL_SERVICE_NAME: agentSlug,
      LOG_LEVEL: wizardData.targetEnvironment === 'production' ? 'info' : 'debug',
      ...(hasDesignExtensions && {
        DESIGN_SYSTEM_VALIDATION: "true",
        ACCESSIBILITY_CHECKS: "true",
        FIGMA_SYNC_INTERVAL: "5m",
        COMPONENT_VALIDATION: "true"
      })
    },
    functions: {
      "api/agent.js": {
        runtime: "nodejs18.x",
        maxDuration: hasDesignExtensions ? 30 : 10
      }
    },
    regions: ["sea1", "iad1", "fra1"]
  }, null, 2);
}

function generateCloudRunConfig(wizardData: WizardData, hasDesignExtensions: boolean): string {
  const agentSlug = wizardData.agentName.toLowerCase().replace(/[^a-z0-9]/g, '-');
  
  return `# ${wizardData.agentName} - Google Cloud Run Configuration
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: ${agentSlug}
  labels:
    agent-type: ${hasDesignExtensions ? 'design-agent' : 'general-agent'}
  annotations:
    run.googleapis.com/ingress: all
    run.googleapis.com/execution-environment: gen2
spec:
  template:
    metadata:
      annotations:
        autoscaling.knative.dev/minScale: "${wizardData.targetEnvironment === 'production' ? '1' : '0'}"
        autoscaling.knative.dev/maxScale: "${wizardData.targetEnvironment === 'production' ? '10' : '3'}"
        run.googleapis.com/cpu-throttling: "false"
        run.googleapis.com/memory: "${hasDesignExtensions ? '2Gi' : '1Gi'}"
        run.googleapis.com/cpu: "${hasDesignExtensions ? '2' : '1'}"
    spec:
      containerConcurrency: 80
      timeoutSeconds: 300
      serviceAccountName: ${agentSlug}-sa
      containers:
      - name: agent
        image: gcr.io/PROJECT_ID/${agentSlug}:latest
        ports:
        - name: http1
          containerPort: 8080
        env:
        - name: NODE_ENV
          value: "${wizardData.targetEnvironment}"
        - name: AGENT_NAME
          value: "${wizardData.agentName}"
        - name: AGENT_TYPE
          value: "${hasDesignExtensions ? 'design_agent' : 'general_agent'}"
        - name: AUTH_METHOD
          value: "${wizardData.security.authMethod}"
        - name: VAULT_INTEGRATION
          value: "${wizardData.security.vaultIntegration}"
        - name: AUDIT_LOGGING
          value: "${wizardData.security.auditLogging}"
        - name: RATE_LIMITING
          value: "${wizardData.security.rateLimiting}"
        - name: SESSION_TIMEOUT
          value: "${wizardData.security.sessionTimeout}"
        - name: GOOGLE_CLOUD_PROJECT
          value: "PROJECT_ID"
        - name: OTEL_SERVICE_NAME
          value: "${agentSlug}"
        - name: OTEL_EXPORTER_OTLP_ENDPOINT
          value: "https://cloudtrace.googleapis.com/v1/projects/PROJECT_ID/traces"
        - name: LOG_LEVEL
          value: "${wizardData.targetEnvironment === 'production' ? 'info' : 'debug'}"${hasDesignExtensions ? `
        - name: DESIGN_SYSTEM_VALIDATION
          value: "true"
        - name: ACCESSIBILITY_CHECKS
          value: "true"
        - name: FIGMA_SYNC_INTERVAL
          value: "5m"
        - name: COMPONENT_VALIDATION
          value: "true"` : ''}
        resources:
          limits:
            cpu: "${hasDesignExtensions ? '2000m' : '1000m'}"
            memory: "${hasDesignExtensions ? '2Gi' : '1Gi'}"
          requests:
            cpu: "${hasDesignExtensions ? '1000m' : '500m'}"
            memory: "${hasDesignExtensions ? '1Gi' : '512Mi'}"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
  traffic:
  - percent: 100
    latestRevision: true`;
}