# AgentEngine Deployment Guide

## Overview

AgentEngine provides multiple deployment pathways to suit different use cases, from local development to enterprise-scale production deployments. This guide explains each deployment option, when to use them, and step-by-step instructions.

## Deployment Options Summary

### 1. Claude Desktop Integration
**Best for:** Local development, personal use, and testing
- Direct integration with Claude Desktop application
- Local MCP server configurations
- Instant setup and testing
- No cloud infrastructure required

### 2. Docker Containers
**Best for:** Development teams, staging environments, and single-server deployments
- Containerized application with all dependencies
- Easy local development and testing
- Consistent environment across different machines
- Simple scaling with Docker Compose

### 3. Kubernetes Deployment
**Best for:** Production environments, enterprise deployments, and high-scale applications
- Container orchestration and auto-scaling
- High availability and fault tolerance
- Advanced networking and security features
- Multi-environment management

### 4. Cloud Platform Deployments
**Best for:** Quick production deployments with managed infrastructure

#### Railway
- Zero-config deployments from GitHub
- Automatic HTTPS and domain management
- Built-in monitoring and logging
- Pay-per-usage pricing

#### Render
- Static site and web service hosting
- Automatic builds from Git repositories
- Free tier available for testing
- PostgreSQL database integration

#### Vercel
- Optimized for frontend applications
- Edge functions and global CDN
- Seamless Git integration
- Excellent for serverless deployments

## Detailed Deployment Instructions

### Claude Desktop Integration

Claude Desktop integration is the fastest way to get started with AgentEngine. This deployment method runs your agent locally and integrates directly with the Claude Desktop application.

#### Prerequisites
- Claude Desktop application installed
- Basic familiarity with JSON configuration files
- Local file system access

#### Setup Process

1. **Generate Configuration**
   - Use AgentEngine's wizard to configure your agent
   - Select "Claude Desktop" as your deployment target
   - Download the generated `claude_desktop_config.json`

2. **Locate Claude Desktop Configuration**
   ```
   Windows: %APPDATA%\Claude\claude_desktop_config.json
   macOS: ~/Library/Application Support/Claude/claude_desktop_config.json
   Linux: ~/.config/Claude/claude_desktop_config.json
   ```

3. **Install MCP Server Dependencies**
   ```bash
   # For Figma MCP (if using design templates)
   npm install -g @figma/mcp-server
   
   # For filesystem operations
   npm install -g @mcp/filesystem
   
   # For Git operations
   npm install -g @mcp/git
   ```

4. **Update Configuration**
   - Backup your existing claude_desktop_config.json
   - Replace with the generated configuration
   - Restart Claude Desktop

5. **Verification**
   - Open Claude Desktop
   - Look for new MCP tools in the interface
   - Test basic functionality with your configured agent

#### Example Configuration Structure
```json
{
  "mcpServers": {
    "figma-mcp": {
      "command": "npx",
      "args": ["@figma/mcp-server"],
      "env": {
        "FIGMA_ACCESS_TOKEN": "your-token-here"
      }
    },
    "filesystem-mcp": {
      "command": "npx",
      "args": ["@mcp/filesystem", "/allowed/path"]
    }
  }
}
```

### Docker Deployment

Docker deployment provides a consistent, portable environment for your AgentEngine applications.

#### Prerequisites
- Docker installed and running
- Basic Docker knowledge
- Port 3000 available (or configure alternative)

#### Single Container Deployment

1. **Generate Docker Configuration**
   - Configure your agent in AgentEngine
   - Select "Docker" as deployment target
   - Download the generated `Dockerfile` and `docker-compose.yml`

2. **Build and Run**
   ```bash
   # Build the container
   docker build -t agentengine-app .
   
   # Run the container
   docker run -p 3000:3000 agentengine-app
   ```

3. **Access Your Application**
   - Navigate to `http://localhost:3000`
   - Verify all features are working correctly

#### Multi-Service Deployment with Docker Compose

For applications requiring databases or multiple services:

```yaml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgresql://user:password@db:5432/agentengine
    depends_on:
      - db
      
  db:
    image: postgres:15
    environment:
      POSTGRES_DB: agentengine
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

#### Deployment Commands
```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Scale the application
docker-compose up --scale app=3

# Stop all services
docker-compose down
```

### Kubernetes Deployment

Kubernetes deployment provides enterprise-grade orchestration, scaling, and management capabilities.

#### Prerequisites
- Kubernetes cluster access
- kubectl configured
- Basic Kubernetes knowledge
- Container registry access (DockerHub, ECR, etc.)

#### Deployment Process

1. **Generate Kubernetes Manifests**
   - Configure your agent for production
   - Select "Kubernetes" as deployment target
   - Download generated YAML files

2. **Build and Push Container**
   ```bash
   # Build container
   docker build -t your-registry/agentengine:latest .
   
   # Push to registry
   docker push your-registry/agentengine:latest
   ```

3. **Deploy to Kubernetes**
   ```bash
   # Apply all manifests
   kubectl apply -f k8s/
   
   # Verify deployment
   kubectl get pods -l app=agentengine
   kubectl get services -l app=agentengine
   ```

#### Key Kubernetes Components

**Deployment** - Manages application replicas
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: agentengine
spec:
  replicas: 3
  selector:
    matchLabels:
      app: agentengine
  template:
    spec:
      containers:
      - name: agentengine
        image: your-registry/agentengine:latest
        ports:
        - containerPort: 3000
```

**Service** - Exposes application internally
```yaml
apiVersion: v1
kind: Service
metadata:
  name: agentengine-service
spec:
  selector:
    app: agentengine
  ports:
  - port: 80
    targetPort: 3000
  type: ClusterIP
```

**Ingress** - Manages external access
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: agentengine-ingress
spec:
  rules:
  - host: your-domain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: agentengine-service
            port:
              number: 80
```

#### Monitoring and Scaling

```bash
# Check deployment status
kubectl rollout status deployment/agentengine

# Scale deployment
kubectl scale deployment agentengine --replicas=5

# View logs
kubectl logs -l app=agentengine -f

# Update deployment
kubectl set image deployment/agentengine agentengine=your-registry/agentengine:v2
```

### Cloud Platform Deployments

#### Railway Deployment

Railway provides zero-configuration deployments with automatic scaling and monitoring.

1. **Connect Repository**
   - Create Railway account
   - Connect your GitHub repository
   - Select the repository containing your AgentEngine project

2. **Configure Environment**
   ```bash
   # Install Railway CLI
   npm install -g @railway/cli
   
   # Login and link project
   railway login
   railway link
   ```

3. **Set Environment Variables**
   ```bash
   # Set required environment variables
   railway variables set DATABASE_URL=postgresql://...
   railway variables set SECRET_KEY=your-secret-key
   ```

4. **Deploy**
   ```bash
   # Deploy to Railway
   railway deploy
   
   # View deployment logs
   railway logs
   ```

#### Render Deployment

Render offers simple deployments with built-in CI/CD and database integration.

1. **Create Render Account**
   - Sign up at render.com
   - Connect your GitHub account

2. **Create Web Service**
   - Select "New Web Service"
   - Choose your repository
   - Configure build and start commands:
     ```
     Build Command: npm install && npm run build
     Start Command: npm start
     ```

3. **Configure Environment**
   - Add environment variables in Render dashboard
   - Set up database if required (PostgreSQL available)

4. **Deploy**
   - Render automatically deploys on git push
   - Monitor deployment in Render dashboard

#### Vercel Deployment

Vercel excels at frontend deployments with edge functions and global CDN.

1. **Install Vercel CLI**
   ```bash
   npm install -g vercel
   ```

2. **Configure Project**
   ```bash
   # Initialize Vercel project
   vercel
   
   # Follow prompts to configure
   ```

3. **Deploy**
   ```bash
   # Deploy to preview
   vercel
   
   # Deploy to production
   vercel --prod
   ```

4. **Custom Domain**
   ```bash
   # Add custom domain
   vercel domains add your-domain.com
   ```

## MCP Server Deployment

MCP (Model Context Protocol) servers are essential components that provide specialized capabilities to your agents.

### Common MCP Servers

#### Figma MCP Server
Provides design system integration and file access.

```javascript
// figma-mcp-server.js
import { MCPServer } from '@mcp/sdk';

const server = new MCPServer({
  name: 'figma-mcp',
  version: '1.0.0'
});

server.addTool({
  name: 'get-figma-file',
  description: 'Retrieve Figma file information',
  parameters: {
    type: 'object',
    properties: {
      fileId: { type: 'string' }
    }
  },
  handler: async ({ fileId }) => {
    // Figma API integration logic
    return await fetchFigmaFile(fileId);
  }
});

server.start();
```

#### Filesystem MCP Server
Provides secure file system operations.

```javascript
// filesystem-mcp-server.js
import { MCPServer } from '@mcp/sdk';
import fs from 'fs/promises';
import path from 'path';

const server = new MCPServer({
  name: 'filesystem-mcp',
  version: '1.0.0'
});

const ALLOWED_PATHS = ['/home/user/projects', '/tmp'];

server.addTool({
  name: 'read-file',
  description: 'Read file contents',
  parameters: {
    type: 'object',
    properties: {
      filePath: { type: 'string' }
    }
  },
  handler: async ({ filePath }) => {
    // Security check
    if (!ALLOWED_PATHS.some(allowed => filePath.startsWith(allowed))) {
      throw new Error('Access denied');
    }
    
    return await fs.readFile(filePath, 'utf8');
  }
});

server.start();
```

### MCP Server Deployment Options

#### Local Development
```bash
# Start MCP server locally
node figma-mcp-server.js --port 3001

# Configure in Claude Desktop
{
  "mcpServers": {
    "figma": {
      "command": "node",
      "args": ["figma-mcp-server.js", "--port", "3001"]
    }
  }
}
```

#### Production Deployment
```yaml
# Kubernetes deployment for MCP server
apiVersion: apps/v1
kind: Deployment
metadata:
  name: figma-mcp-server
spec:
  replicas: 2
  selector:
    matchLabels:
      app: figma-mcp-server
  template:
    spec:
      containers:
      - name: figma-mcp
        image: your-registry/figma-mcp:latest
        ports:
        - containerPort: 3001
        env:
        - name: FIGMA_ACCESS_TOKEN
          valueFrom:
            secretKeyRef:
              name: figma-secret
              key: token
```

## Security Considerations

### Authentication and Authorization

#### OAuth Integration
```javascript
// OAuth configuration
const oauthConfig = {
  clientId: process.env.OAUTH_CLIENT_ID,
  clientSecret: process.env.OAUTH_CLIENT_SECRET,
  redirectUri: process.env.OAUTH_REDIRECT_URI,
  scopes: ['read:user', 'write:files']
};
```

#### API Key Management
```bash
# Using environment variables
export FIGMA_API_KEY="your-api-key"
export DATABASE_URL="postgresql://..."

# Using Kubernetes secrets
kubectl create secret generic api-keys \
  --from-literal=figma-key=your-api-key \
  --from-literal=db-url=postgresql://...
```

### Network Security

#### HTTPS/TLS Configuration
```yaml
# Kubernetes ingress with TLS
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: agentengine-ingress
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - your-domain.com
    secretName: agentengine-tls
```

#### Network Policies
```yaml
# Restrict network access
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: agentengine-netpol
spec:
  podSelector:
    matchLabels:
      app: agentengine
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: nginx-ingress
```

## Monitoring and Observability

### Application Monitoring

#### Health Checks
```javascript
// Express.js health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: process.env.APP_VERSION
  });
});
```

#### Kubernetes Probes
```yaml
containers:
- name: agentengine
  livenessProbe:
    httpGet:
      path: /health
      port: 3000
    initialDelaySeconds: 30
    periodSeconds: 10
  readinessProbe:
    httpGet:
      path: /ready
      port: 3000
    initialDelaySeconds: 5
    periodSeconds: 5
```

### Logging and Metrics

#### Structured Logging
```javascript
import winston from 'winston';

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' })
  ]
});

// Log agent interactions
logger.info('Agent request processed', {
  agentId: 'agent-123',
  userId: 'user-456',
  action: 'generate_code',
  duration: 1250
});
```

#### Prometheus Metrics
```javascript
import prometheus from 'prom-client';

// Create metrics
const httpRequestsTotal = new prometheus.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status']
});

const agentResponseTime = new prometheus.Histogram({
  name: 'agent_response_time_seconds',
  help: 'Agent response time in seconds',
  buckets: [0.1, 0.5, 1, 2, 5]
});

// Expose metrics endpoint
app.get('/metrics', (req, res) => {
  res.set('Content-Type', prometheus.register.contentType);
  res.end(prometheus.register.metrics());
});
```

## Troubleshooting Common Issues

### Docker Issues

#### Container Won't Start
```bash
# Check container logs
docker logs container-name

# Common issues:
# 1. Port already in use
# 2. Environment variables not set
# 3. Dependencies not installed
```

#### Permission Issues
```bash
# Fix file permissions
chmod +x entrypoint.sh

# Run as non-root user
USER node
```

### Kubernetes Issues

#### Pod Crashes
```bash
# Check pod status and events
kubectl describe pod pod-name

# Check logs
kubectl logs pod-name --previous

# Common issues:
# 1. Resource limits too low
# 2. ConfigMap/Secret not found
# 3. Image pull failures
```

#### Service Not Accessible
```bash
# Check service endpoints
kubectl get endpoints service-name

# Verify service selector matches pod labels
kubectl get pods --show-labels
```

### MCP Server Issues

#### Connection Failures
```bash
# Check MCP server status
curl http://localhost:3001/health

# Verify configuration
cat ~/.config/Claude/claude_desktop_config.json

# Common issues:
# 1. Incorrect port configuration
# 2. MCP server not running
# 3. Network connectivity problems
```

#### Authentication Errors
```bash
# Verify API keys
echo $FIGMA_ACCESS_TOKEN

# Check token permissions
curl -H "Authorization: Bearer $FIGMA_ACCESS_TOKEN" \
     https://api.figma.com/v1/me
```

## Performance Optimization

### Application Performance

#### Caching Strategies
```javascript
import Redis from 'redis';

const redis = Redis.createClient();

// Cache agent responses
const getCachedResponse = async (key) => {
  return await redis.get(key);
};

const setCachedResponse = async (key, value, ttl = 3600) => {
  await redis.setex(key, ttl, value);
};
```

#### Database Optimization
```sql
-- Index frequently queried columns
CREATE INDEX idx_agent_user_id ON agents(user_id);
CREATE INDEX idx_templates_category ON templates(category);

-- Optimize queries
EXPLAIN ANALYZE SELECT * FROM agents WHERE user_id = $1;
```

### Infrastructure Performance

#### Horizontal Scaling
```yaml
# Kubernetes Horizontal Pod Autoscaler
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: agentengine-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: agentengine
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

#### Load Balancing
```yaml
# NGINX Ingress with load balancing
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: agentengine-ingress
  annotations:
    nginx.ingress.kubernetes.io/load-balance: "round_robin"
    nginx.ingress.kubernetes.io/upstream-keepalive-connections: "10"
```

## Best Practices

### Development Workflow

1. **Local Development**
   - Use Claude Desktop integration for rapid testing
   - Develop MCP servers locally first
   - Test with sample data before production

2. **Staging Environment**
   - Deploy to Docker containers for team testing
   - Use production-like data volumes
   - Test all integrations and MCP servers

3. **Production Deployment**
   - Use Kubernetes for high availability
   - Implement proper monitoring and alerting
   - Plan for disaster recovery and backups

### Security Best Practices

1. **Secret Management**
   - Never commit secrets to version control
   - Use environment variables or secret management systems
   - Rotate secrets regularly

2. **Network Security**
   - Use HTTPS/TLS for all communications
   - Implement network policies and firewalls
   - Restrict MCP server access to authorized clients

3. **Access Control**
   - Implement proper authentication and authorization
   - Use role-based access control (RBAC)
   - Monitor and audit access patterns

### Monitoring Best Practices

1. **Observability**
   - Implement structured logging
   - Use distributed tracing for complex interactions
   - Monitor both application and infrastructure metrics

2. **Alerting**
   - Set up alerts for critical failures
   - Monitor response times and error rates
   - Alert on resource exhaustion

3. **Disaster Recovery**
   - Regular backups of configuration and data
   - Test recovery procedures
   - Document runbooks for common issues

## Conclusion

AgentEngine's flexible deployment architecture supports everything from local development to enterprise-scale production deployments. Choose the deployment method that best fits your use case:

- **Claude Desktop** for local development and personal use
- **Docker** for team development and simple production deployments
- **Kubernetes** for enterprise production deployments with high availability
- **Cloud Platforms** for managed deployments with minimal infrastructure management

Each deployment method can be enhanced with proper monitoring, security, and performance optimization to meet your specific requirements.

For additional support and advanced deployment scenarios, consult the AgentEngine documentation or contact the support team.