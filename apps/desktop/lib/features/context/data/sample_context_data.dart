import '../presentation/widgets/context_hub_widget.dart';
import 'models/context_document.dart';
import 'package:flutter/material.dart';

class SampleContextData {
 static List<SampleContext> getAllSamples() {
 return [
 // AI & Agent Category
 ...getAIAgentSamples(),
 
 // Development Category
 ...getDevelopmentSamples(),
 
 // Business Category 
 ...getBusinessSamples(),
 
 // Research Category
 ...getResearchSamples(),
 
 // Documentation Category
 ...getDocumentationSamples(),
 
 // Templates Category
 ...getTemplateSamples(),
 
 // System Design Category
 ...getSystemDesignSamples(),
 
 // Security Category
 ...getSecuritySamples(),
 
 // Frontend Libraries Category
 ...getFrontendLibrariesSamples(),
 ];
 }

 static List<SampleContext> getDevelopmentSamples() {
 return [
 SampleContext(
 title: 'API Best Practices',
 description: 'REST API design principles and standards',
 content: '''# REST API Best Practices

## Design Principles
- Use HTTP methods appropriately (GET, POST, PUT, DELETE)
- Implement proper status codes (200, 201, 400, 404, 500)
- Use consistent naming conventions for endpoints
- Version your APIs (/api/v1/, /api/v2/)
- Implement proper error handling and responses

## Security Guidelines
- Always use HTTPS in production
- Implement authentication and authorization
- Validate all input data
- Use rate limiting to prevent abuse
- Never expose sensitive data in URLs

## Response Format
```json
{
 "success": true,
 "data": {...},
 "message": "Operation completed successfully",
 "timestamp": "2024-01-01T00:00:00Z"
}
```

## Error Handling
```json
{
 "success": false,
 "error": {
 "code": "VALIDATION_ERROR",
 "message": "Invalid input provided",
 "details": {...}
 },
 "timestamp": "2024-01-01T00:00:00Z"
}
```''',
 contextType: ContextType.guidelines,
 category: ContextHubCategory.development,
 tags: ['api', 'rest', 'guidelines', 'backend'],
 icon: Icons.api,
 ),
 
 SampleContext(
 title: 'React Component Patterns',
 description: 'Modern React patterns and best practices',
 content: '''# React Component Patterns

## Functional Components with Hooks
```jsx
import React, { useState, useEffect, useCallback } from 'react';

const UserProfile = ({ userId }) => {
 const [user, setUser] = useState(null);
 const [loading, setLoading] = useState(true);
 
 const fetchUser = useCallback(async () => {
 try {
 setLoading(true);
 const response = await fetch(`/api/users/{userId}`);
 const userData = await response.json();
 setUser(userData);
 } catch (error) {
 console.error('Failed to fetch user:', error);
 } finally {
 setLoading(false);
 }
 }, [userId]);
 
 useEffect(() => {
 fetchUser();
 }, [fetchUser]);
 
 if (loading) return <LoadingSpinner />;
 if (!user) return <ErrorMessage />;
 
 return (
 <div className="user-profile">
 <h1>{user.name}</h1>
 <p>{user.email}</p>
 </div>
 );
};
```

## Custom Hooks Pattern
```jsx
const useApi = (url) => {
 const [data, setData] = useState(null);
 const [loading, setLoading] = useState(true);
 const [error, setError] = useState(null);
 
 useEffect(() => {
 fetch(url)
 .then(res => res.json())
 .then(setData)
 .catch(setError)
 .finally(() => setLoading(false));
 }, [url]);
 
 return { data, loading, error };
};
```

## Component Composition
```jsx
const Card = ({ children, className }) => (
 <div className={'card ' + className}>
 {children}
 </div>
);

const CardHeader = ({ children }) => (
 <div className="card-header">{children}</div>
);

const CardBody = ({ children }) => (
 <div className="card-body">{children}</div>
);
```''',
 contextType: ContextType.examples,
 category: ContextHubCategory.development,
 tags: ['react', 'javascript', 'frontend', 'patterns'],
 icon: Icons.widgets,
 ),
 
 SampleContext(
 title: 'Database Schema Design',
 description: 'SQL database design principles and normalization',
 content: '''# Database Schema Design

## Normalization Rules
- **1NF**: Eliminate duplicate columns from the same table
- **2NF**: Remove subsets of data that apply to multiple rows
- **3NF**: Remove columns that are not dependent on the primary key

## Table Design Example
```sql
-- Users table
CREATE TABLE users (
 id SERIAL PRIMARY KEY,
 email VARCHAR(255) UNIQUE NOT NULL,
 username VARCHAR(50) UNIQUE NOT NULL,
 password_hash VARCHAR(255) NOT NULL,
 created_at TIMESTAMP DEFAULT NOW(),
 updated_at TIMESTAMP DEFAULT NOW()
);

-- Profiles table (1:1 relationship)
CREATE TABLE profiles (
 id SERIAL PRIMARY KEY,
 user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
 first_name VARCHAR(100),
 last_name VARCHAR(100),
 bio TEXT,
 avatar_url VARCHAR(500)
);

-- Posts table (1:many relationship)
CREATE TABLE posts (
 id SERIAL PRIMARY KEY,
 user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
 title VARCHAR(255) NOT NULL,
 content TEXT,
 status VARCHAR(20) DEFAULT 'draft',
 published_at TIMESTAMP,
 created_at TIMESTAMP DEFAULT NOW()
);
```

## Indexing Strategy
```sql
-- Performance indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_status_published ON posts(status, published_at);

-- Composite index for common queries
CREATE INDEX idx_posts_user_status ON posts(user_id, status);
```

## Best Practices
- Use consistent naming conventions
- Always define primary keys
- Use foreign key constraints
- Index frequently queried columns
- Normalize data but consider denormalization for performance
- Use appropriate data types and lengths''',
 contextType: ContextType.guidelines,
 category: ContextHubCategory.development,
 tags: ['database', 'sql', 'schema', 'design'],
 icon: Icons.storage,
 ),
 ];
 }

 static List<SampleContext> getBusinessSamples() {
 return [
 SampleContext(
 title: 'Product Requirements Template',
 description: 'Structured template for product requirements documentation',
 content: '''# Product Requirements Document (PRD)

## Executive Summary
Brief overview of the product, its purpose, and key benefits.

## Problem Statement
### Current Pain Points
- [Specific problem 1]
- [Specific problem 2]
- [Specific problem 3]

### Target Users
- **Primary**: [Description of main user segment]
- **Secondary**: [Description of secondary users]

## Solution Overview
### Key Features
1. **Feature A**: [Description and user benefit]
2. **Feature B**: [Description and user benefit]
3. **Feature C**: [Description and user benefit]

### Success Metrics
- **Engagement**: [Specific metric and target]
- **Retention**: [Specific metric and target]
- **Business**: [Revenue/cost impact]

## User Stories
### Epic 1: [Epic Name]
- **As a** [user type], **I want** [functionality] **so that** [benefit]
- **Acceptance Criteria**:
 - [ ] Criterion 1
 - [ ] Criterion 2

## Technical Requirements
### Performance
- Page load time < 2 seconds
- 99.9% uptime
- Support for 10,000 concurrent users

### Security
- Data encryption at rest and in transit
- Multi-factor authentication
- GDPR compliance

## Timeline & Milestones
- **Phase 1** (4 weeks): Core functionality
- **Phase 2** (6 weeks): Advanced features
- **Phase 3** (2 weeks): Polish and optimization

## Resources Needed
- **Development**: 3 engineers
- **Design**: 1 designer
- **QA**: 1 tester
- **PM**: 1 product manager''',
 contextType: ContextType.documentation,
 category: ContextHubCategory.business,
 tags: ['prd', 'product', 'requirements', 'planning'],
 icon: Icons.assignment,
 ),
 
 SampleContext(
 title: 'Meeting Notes Template',
 description: 'Structured format for capturing meeting discussions and action items',
 content: '''# Meeting Notes Template

## Meeting Details
**Date**: [Date]
**Time**: [Start Time] - [End Time]
**Attendees**: [List of participants]
**Meeting Lead**: [Name]
**Note Taker**: [Name]

## Agenda
1. [Agenda item 1]
2. [Agenda item 2]
3. [Agenda item 3]

## Discussion Summary
### Topic 1: [Topic Name]
**Key Points Discussed**:
- [Point 1]
- [Point 2]

**Decisions Made**:
- [Decision 1]
- [Decision 2]

### Topic 2: [Topic Name]
**Key Points Discussed**:
- [Point 1]
- [Point 2]

**Open Questions**:
- [Question 1] - Owner: [Name]
- [Question 2] - Owner: [Name]

## Action Items
| Task | Owner | Due Date | Status |
|------|-------|----------|--------|
| [Task description] | [Name] | [Date] | [Status] |
| [Task description] | [Name] | [Date] | [Status] |

## Next Steps
- [Next step 1]
- [Next step 2]

## Next Meeting
**Date**: [Date]
**Agenda Items**:
- Follow up on action items
- [Additional agenda items]''',
 contextType: ContextType.custom,
 category: ContextHubCategory.business,
 tags: ['meetings', 'notes', 'collaboration', 'template'],
 icon: Icons.event_note,
 ),
 ];
 }

 static List<SampleContext> getResearchSamples() {
 return [
 SampleContext(
 title: 'User Research Methods',
 description: 'Guide to various user research methodologies and when to use them',
 content: '''# User Research Methods Guide

## Quantitative Methods

### Surveys
**Best for**: Large sample sizes, statistical significance
**Timeline**: 1-2 weeks
**Sample Questions**:
- "How often do you use [product]?"
- "On a scale of 1-10, how likely are you to recommend?"
- "What is your primary use case?"

### A/B Testing
**Best for**: Comparing design alternatives, feature effectiveness
**Key Metrics**: Conversion rate, engagement, retention
**Tools**: Google Optimize, Optimizely, Split.io

### Analytics Analysis
**Key Metrics**:
- **Engagement**: DAU, MAU, session duration
- **Conversion**: Funnel analysis, drop-off rates
- **Retention**: Cohort analysis, churn rate

## Qualitative Methods

### User Interviews
**Best for**: Understanding motivations, pain points, workflows
**Structure**:
1. **Warm-up** (5 min): Build rapport
2. **Context** (10 min): Current process/tools
3. **Deep dive** (30 min): Specific scenarios
4. **Wrap-up** (5 min): Final thoughts

**Sample Questions**:
- "Walk me through your typical workflow"
- "What's the most frustrating part of this process?"
- "How do you currently solve [problem]?"

### Usability Testing
**Best for**: Identifying interface issues, task completion
**Process**:
1. Define tasks and success criteria
2. Recruit representative users
3. Observe and take notes (don't help!)
4. Analyze patterns across sessions

### Card Sorting
**Best for**: Information architecture, menu organization
**Types**:
- **Open**: Users create their own categories
- **Closed**: Pre-defined categories provided
- **Hybrid**: Combination of both approaches

## Research Planning Template

### Research Question
"How do [user segment] currently [perform task/solve problem]?"

### Methodology Selection
- **Primary method**: [Chosen method]
- **Supporting methods**: [Additional methods]
- **Rationale**: [Why these methods]

### Participant Criteria
- **Demographics**: [Age, role, experience level]
- **Behavioral**: [Usage patterns, tool preferences]
- **Screening questions**: [Key qualifying questions]

### Success Metrics
- **Qualitative**: [Insights, themes, pain points identified]
- **Quantitative**: [Statistical significance, sample size reached]''',
 contextType: ContextType.knowledge,
 category: ContextHubCategory.research,
 tags: ['research', 'user-research', 'methodology', 'ux'],
 icon: Icons.psychology,
 ),
 ];
 }

 static List<SampleContext> getDocumentationSamples() {
 return [
 SampleContext(
 title: 'API Documentation Template',
 description: 'Complete template for documenting REST APIs',
 content: '''# API Documentation Template

## Overview
Brief description of what the API does and its main purpose.

**Base URL**: `https://api.example.com/v1`
**Authentication**: Bearer Token

## Authentication
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \\
 https://api.example.com/v1/endpoint
```

## Endpoints

### GET /users
Retrieve a list of users with optional filtering.

**Parameters**:
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 20, max: 100)
- `status` (optional): Filter by user status (`active`, `inactive`)

**Example Request**:
```bash
curl -X GET "https://api.example.com/v1/users?page=1&limit=10" \\
 -H "Authorization: Bearer YOUR_TOKEN"
```

**Example Response**:
```json
{
 "success": true,
 "data": {
 "users": [
 {
 "id": 123,
 "email": "user@example.com",
 "name": "John Doe",
 "status": "active",
 "created_at": "2024-01-01T00:00:00Z"
 }
 ],
 "pagination": {
 "current_page": 1,
 "total_pages": 5,
 "total_items": 47,
 "items_per_page": 10
 }
 }
}
```

### POST /users
Create a new user account.

**Request Body**:
```json
{
 "email": "user@example.com",
 "name": "John Doe",
 "password": "secure_password"
}
```

**Example Response**:
```json
{
 "success": true,
 "data": {
 "user": {
 "id": 124,
 "email": "user@example.com",
 "name": "John Doe",
 "status": "active",
 "created_at": "2024-01-01T00:00:00Z"
 }
 },
 "message": "User created successfully"
}
```

## Error Codes
| Code | Message | Description |
|------|---------|-------------|
| 400 | Bad Request | Invalid request format or parameters |
| 401 | Unauthorized | Invalid or missing authentication token |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource not found |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server-side error |

## Rate Limits
- **Standard**: 1000 requests per hour
- **Premium**: 10000 requests per hour
- **Headers**: `X-RateLimit-Remaining`, `X-RateLimit-Reset`

## SDKs and Examples
- [JavaScript SDK](https://github.com/example/js-sdk)
- [Python SDK](https://github.com/example/python-sdk)
- [PHP SDK](https://github.com/example/php-sdk)''',
 contextType: ContextType.documentation,
 category: ContextHubCategory.documentation,
 tags: ['api', 'documentation', 'rest', 'reference'],
 icon: Icons.api,
 ),
 ];
 }

 static List<SampleContext> getTemplateSamples() {
 return [
 SampleContext(
 title: 'Bug Report Template',
 description: 'Standardized template for reporting software bugs',
 content: '''# Bug Report Template

## Summary
Brief, clear description of the issue in one sentence.

## Environment
- **Platform**: [Windows/Mac/Linux/iOS/Android]
- **Browser**: [Chrome 120, Safari 17, etc.]
- **App Version**: [Version number]
- **Device**: [Desktop/Mobile device model]

## Steps to Reproduce
1. [First step]
2. [Second step]
3. [Third step]
4. [Point where the issue occurs]

## Expected Behavior
What should happen when following the steps above.

## Actual Behavior
What actually happens. Be specific about error messages, unexpected behaviors, etc.

## Screenshots/Videos
[Attach visual evidence if applicable]

## Additional Context
- **Frequency**: How often does this occur? (Always/Sometimes/Rarely)
- **Impact**: How does this affect the user experience?
- **Workaround**: Is there a way to work around this issue?

## Console Logs
```
[Paste any relevant console errors or logs here]
```

## Priority
- [ ] Critical (System unusable)
- [ ] High (Major feature broken)
- [ ] Medium (Minor feature issue)
- [ ] Low (Cosmetic issue)

## Labels
Add relevant labels: `bug`, `ui`, `performance`, `mobile`, etc.''',
 contextType: ContextType.custom,
 category: ContextHubCategory.templates,
 tags: ['bug-report', 'template', 'qa', 'testing'],
 icon: Icons.bug_report,
 ),
 
 SampleContext(
 title: 'Code Review Checklist',
 description: 'Comprehensive checklist for code review process',
 content: '''# Code Review Checklist

## Functionality
- [ ] Code does what it's supposed to do
- [ ] Edge cases are handled appropriately
- [ ] Error handling is implemented
- [ ] No obvious bugs or logical errors

## Code Quality
- [ ] Code is readable and well-structured
- [ ] Variable and function names are descriptive
- [ ] Functions are focused and not too long
- [ ] No unnecessary code duplication
- [ ] Comments explain "why", not "what"

## Testing
- [ ] Unit tests are included and comprehensive
- [ ] Tests cover edge cases and error scenarios
- [ ] All tests pass
- [ ] Test names are descriptive
- [ ] No test code in production builds

## Performance
- [ ] No obvious performance bottlenecks
- [ ] Database queries are efficient
- [ ] Large datasets are handled appropriately
- [ ] Memory leaks are avoided
- [ ] Caching is used where appropriate

## Security
- [ ] Input validation is implemented
- [ ] No hardcoded secrets or sensitive data
- [ ] Authentication/authorization is proper
- [ ] SQL injection vulnerabilities avoided
- [ ] XSS vulnerabilities prevented

## Best Practices
- [ ] Follows team coding standards
- [ ] Uses established patterns and conventions
- [ ] Dependencies are justified and minimal
- [ ] Code is backwards compatible (if required)
- [ ] Documentation is updated if needed

## Git & Process
- [ ] Commit messages are clear and descriptive
- [ ] Branch is up to date with main
- [ ] No merge conflicts
- [ ] CI/CD pipeline passes
- [ ] Related tickets/issues are linked

## Review Comments
### Suggestions for Improvement
- [Specific suggestion with line reference]
- [Another improvement opportunity]

### Questions
- [Any clarifications needed]
- [Questions about design decisions]

### Approval Status
- [ ] Approve (no changes needed)
- [ ] Approve with minor changes
- [ ] Request changes (must fix before merge)

## Reviewer Notes
[Additional context, architectural concerns, or broader feedback]''',
 contextType: ContextType.guidelines,
 category: ContextHubCategory.templates,
 tags: ['code-review', 'checklist', 'quality', 'process'],
 icon: Icons.checklist,
 ),
 ];
 }

 static List<SampleContext> getAIAgentSamples() {
 return [
 SampleContext(
 title: 'Prompt Engineering Best Practices',
 description: 'Comprehensive guide to crafting effective AI prompts',
 content: '''# Prompt Engineering Best Practices

## Core Principles

### 1. Be Specific and Clear
- Use precise language and avoid ambiguity
- Specify the desired output format
- Include relevant context and constraints

### 2. Provide Context and Examples
```
Instead of: "Write a function"
Better: "Write a Python function that validates email addresses using regex, returns True/False, and includes error handling"
```

### 3. Use Structured Prompts
**Task**: [What you want the AI to do]
**Context**: [Background information]
**Format**: [How you want the output structured]
**Examples**: [Sample inputs/outputs]

## Advanced Techniques

### Chain of Thought Prompting
```
Prompt: "Let me think through this step by step:
1. First, I need to understand the problem
2. Then identify the key requirements
3. Finally, implement the solution

Problem: [Your problem here]"
```

### Role-Based Prompting
```
"Act as a senior software engineer with 10 years experience.
Review this code and provide feedback on:
- Performance optimizations
- Security considerations  
- Maintainability improvements"
```

### Few-Shot Learning
Provide 2-3 examples of input/output pairs:
```
Example 1: Input: X → Output: Y
Example 2: Input: A → Output: B
Now apply this pattern to: [Your input]
```

### Prompt Templates

#### Code Review Template
```
Review this [LANGUAGE] code for:
- Functionality: Does it work correctly?
- Performance: Any bottlenecks or inefficiencies?
- Security: Potential vulnerabilities?
- Best practices: Following language/framework conventions?

Code:
[CODE_BLOCK]

Format your response as:
- ✅ Strengths: [List positives]
- ⚠️ Issues: [List problems with severity]
- 🔧 Suggestions: [Specific improvements]
```

#### API Design Template  
```
Design a REST API for [DOMAIN] with these requirements:
- [Requirement 1]
- [Requirement 2]

Include:
- Endpoint structure
- HTTP methods and status codes
- Request/response schemas
- Authentication approach
- Error handling strategy
```

## Model-Specific Tips

### Claude (Anthropic)
- Excellent at analysis and reasoning
- Prefers structured, detailed prompts
- Good with ethical considerations
- Strong at code explanation and documentation

### GPT Models (OpenAI)
- Creative and conversational
- Good at brainstorming and ideation
- Effective with shorter, more direct prompts
- Strong at text generation and transformation

## Common Pitfalls
- Being too vague or generic
- Not providing sufficient context
- Expecting the AI to read your mind
- Not iterating and refining prompts
- Ignoring output format specifications''',
 contextType: ContextType.knowledge,
 category: ContextHubCategory.research,
 tags: ['ai', 'prompts', 'best-practices', 'optimization'],
 icon: Icons.psychology,
 ),
 
 SampleContext(
 title: 'Agent Interaction Patterns',
 description: 'Effective patterns for working with AI agents',
 content: '''# Agent Interaction Patterns

## Collaborative Development

### Iterative Refinement Pattern
1. **Initial Request**: Broad requirements
2. **Agent Response**: First attempt
3. **Refinement**: Specific feedback and adjustments
4. **Iteration**: Improved version
5. **Finalization**: Polish and completion

### Code Pair Programming
```
Human: "Let's build a user authentication system"
Agent: [Provides initial structure]
Human: "Add password hashing and JWT tokens"
Agent: [Enhances with security features]
Human: "Now add rate limiting for login attempts"
Agent: [Implements rate limiting]
```

### Design-First Approach
1. Start with architecture and design
2. Break into smaller, manageable components
3. Implement each component iteratively
4. Test and validate at each step

## Communication Strategies

### The "Rubber Duck" Pattern
Explain your problem in detail as if teaching someone:
- Current situation
- Desired outcome
- Obstacles faced
- Attempts made

### Constraint-Driven Development
Always specify:
- **Performance requirements**: "Must handle 1000 requests/second"
- **Technology constraints**: "Use React hooks, no class components"
- **Business rules**: "Users can only access their own data"
- **Timeline limits**: "Need MVP in 2 weeks"

### Error Recovery Pattern
When things go wrong:
1. **Describe the error**: Exact error message and context
2. **Share your attempt**: What you tried to fix it
3. **Specify environment**: OS, versions, dependencies
4. **Ask targeted questions**: Focus on specific issues

## Agent Capabilities & Limitations

### What AI Agents Excel At
- Code generation and refactoring
- Pattern recognition and analysis
- Documentation and explanation
- Brainstorming and ideation
- Code review and debugging
- Testing strategy development

### Current Limitations
- Cannot execute code directly
- No real-time data access
- Cannot make external API calls
- Limited by training data cutoff
- Cannot access your local environment
- Cannot remember across conversations

## Effective Workflow Patterns

### The Research-Implement-Validate Cycle
```
1. Research Phase
   - "Explain the best practices for X"
   - "What are the trade-offs of approach Y vs Z?"
   
2. Implementation Phase
   - "Now implement this using the approach we discussed"
   - "Add error handling and logging"
   
3. Validation Phase
   - "Review this implementation for issues"
   - "What test cases should I write?"
```

### Progressive Disclosure
Start simple, then add complexity:
```
Level 1: "Create a basic REST API"
Level 2: "Add authentication and validation"  
Level 3: "Add caching and rate limiting"
Level 4: "Add monitoring and logging"
```

### Context Management
- **Save important context**: Maintain key decisions and requirements
- **Reference previous work**: "Using the pattern we established earlier..."
- **Update context**: "The requirements have changed to include X"

## Quality Assurance with AI

### Code Review Checklist
Ask your agent to review for:
- [ ] Functionality and logic
- [ ] Performance considerations
- [ ] Security vulnerabilities
- [ ] Code style and conventions
- [ ] Error handling
- [ ] Test coverage
- [ ] Documentation completeness

### Testing Strategy Development
```
"Help me create a testing strategy for [COMPONENT] that includes:
- Unit tests for core functionality
- Integration tests for external dependencies
- Edge case scenarios
- Performance benchmarks
- Error condition testing"
```

## Advanced Techniques

### Multi-Turn Problem Solving
Break complex problems across multiple interactions:
1. Problem analysis and breaking down
2. Architecture and design decisions
3. Implementation of core components
4. Testing and validation strategy
5. Documentation and deployment

### Template Creation
Develop reusable prompt templates for common tasks:
- Code review templates
- Architecture decision records
- API design patterns
- Testing checklists
- Documentation standards''',
 contextType: ContextType.guidelines,
 category: ContextHubCategory.research,
 tags: ['agent', 'collaboration', 'workflow', 'patterns'],
 icon: Icons.smart_toy,
 ),
 ];
 }

 static List<SampleContext> getSystemDesignSamples() {
 return [
 SampleContext(
 title: 'Microservices Architecture Patterns',
 description: 'Design patterns for building scalable microservices',
 content: '''# Microservices Architecture Patterns

## Core Design Principles

### Single Responsibility
Each service should have one business capability:
```
❌ UserOrderPaymentService  
✅ UserService + OrderService + PaymentService
```

### Decentralized Governance
- Each team owns their service lifecycle
- Technology diversity based on service needs
- Independent deployment and scaling

### Failure Isolation
- Circuit breaker pattern for fault tolerance
- Bulkhead pattern to isolate critical resources
- Timeout and retry strategies

## Service Communication Patterns

### Synchronous Communication
```javascript
// API Gateway pattern
const express = require('express');
const httpProxy = require('http-proxy-middleware');

const app = express();

// Route to user service
app.use('/api/users', httpProxy({
 target: 'http://user-service:3001',
 changeOrigin: true
}));

// Route to order service  
app.use('/api/orders', httpProxy({
 target: 'http://order-service:3002',
 changeOrigin: true
}));
```

### Asynchronous Communication
```javascript
// Event-driven with message queue
const EventEmitter = require('events');

class OrderService extends EventEmitter {
 async createOrder(orderData) {
 const order = await this.saveOrder(orderData);
 
 // Emit event for other services
 this.emit('order.created', {
 orderId: order.id,
 userId: order.userId,
 amount: order.total
 });
 
 return order;
 }
}

// Payment service listens for order events
orderService.on('order.created', async (data) => {
 await paymentService.processPayment(data);
});
```

## Data Management Patterns

### Database per Service
```sql
-- User Service Database
CREATE TABLE users (
 id SERIAL PRIMARY KEY,
 email VARCHAR(255) UNIQUE,
 created_at TIMESTAMP
);

-- Order Service Database  
CREATE TABLE orders (
 id SERIAL PRIMARY KEY,
 user_id INTEGER, -- Reference to user service
 status VARCHAR(50),
 created_at TIMESTAMP
);
```

### Saga Pattern for Distributed Transactions
```javascript
// Choreography-based saga
class OrderSaga {
 async handle(orderCreatedEvent) {
 try {
 await inventoryService.reserveItems(orderCreatedEvent.items);
 await paymentService.chargeCard(orderCreatedEvent.payment);
 await shippingService.createShipment(orderCreatedEvent.address);
 
 this.emit('order.completed', orderCreatedEvent);
 } catch (error) {
 // Compensating transactions
 await this.rollbackOrder(orderCreatedEvent);
 }
 }
}
```

### CQRS (Command Query Responsibility Segregation)
```javascript
// Command side - writes
class CreateUserCommand {
 constructor(userData) {
 this.userData = userData;
 }
}

class UserCommandHandler {
 async handle(command) {
 const user = new User(command.userData);
 await userRepository.save(user);
 
 // Emit event for read model updates
 eventBus.publish('user.created', user);
 }
}

// Query side - reads
class UserQueryService {
 async getUserById(id) {
 return await userReadModel.findById(id);
 }
 
 async searchUsers(criteria) {
 return await userReadModel.search(criteria);
 }
}
```

## Service Discovery & Load Balancing

### Service Registry Pattern
```javascript
// Service registration
class ServiceRegistry {
 constructor() {
 this.services = new Map();
 }
 
 register(serviceName, serviceUrl, metadata) {
 this.services.set(serviceName, {
 url: serviceUrl,
 metadata,
 lastHeartbeat: Date.now()
 });
 }
 
 discover(serviceName) {
 return this.services.get(serviceName);
 }
}

// Health check endpoint
app.get('/health', (req, res) => {
 res.json({
 status: 'healthy',
 timestamp: new Date().toISOString(),
 uptime: process.uptime()
 });
});
```

## Observability & Monitoring

### Distributed Tracing
```javascript
const opentelemetry = require('@opentelemetry/api');

class OrderController {
 async createOrder(req, res) {
 const tracer = opentelemetry.trace.getTracer('order-service');
 
 return tracer.startActiveSpan('create-order', async (span) => {
 try {
 span.setAttributes({
 'user.id': req.user.id,
 'order.items': req.body.items.length
 });
 
 const order = await orderService.create(req.body);
 
 span.setStatus({ code: opentelemetry.SpanStatusCode.OK });
 res.json(order);
 } catch (error) {
 span.setStatus({
 code: opentelemetry.SpanStatusCode.ERROR,
 message: error.message
 });
 throw error;
 } finally {
 span.end();
 }
 });
 }
}
```

### Structured Logging
```javascript
const winston = require('winston');

const logger = winston.createLogger({
 format: winston.format.combine(
 winston.format.timestamp(),
 winston.format.errors({ stack: true }),
 winston.format.json()
 ),
 defaultMeta: {
 service: 'order-service',
 version: process.env.SERVICE_VERSION
 }
});

// Usage
logger.info('Order created', {
 orderId: order.id,
 userId: user.id,
 correlationId: req.headers['x-correlation-id']
});
```

## Security Patterns

### API Gateway Authentication
```javascript
// JWT validation middleware
const jwt = require('jsonwebtoken');

const authenticateToken = (req, res, next) => {
 const authHeader = req.headers['authorization'];
 const token = authHeader && authHeader.split(' ')[1];
 
 if (!token) {
 return res.sendStatus(401);
 }
 
 jwt.verify(token, process.env.ACCESS_TOKEN_SECRET, (err, user) => {
 if (err) return res.sendStatus(403);
 req.user = user;
 next();
 });
};
```

### Service-to-Service Authentication
```javascript
// mTLS configuration
const https = require('https');
const fs = require('fs');

const options = {
 cert: fs.readFileSync('client-cert.pem'),
 key: fs.readFileSync('client-key.pem'),
 ca: fs.readFileSync('ca-cert.pem'),
 rejectUnauthorized: true
};

const makeSecureRequest = (url, data) => {
 return new Promise((resolve, reject) => {
 const req = https.request(url, options, (res) => {
 // Handle response
 });
 req.write(JSON.stringify(data));
 req.end();
 });
};
```

## Deployment Patterns

### Blue-Green Deployment
```yaml
# Blue environment (current production)
apiVersion: apps/v1
kind: Deployment
metadata:
 name: user-service-blue
 labels:
 version: blue
spec:
 replicas: 3
 selector:
 matchLabels:
 app: user-service
 version: blue

---
# Green environment (new version)
apiVersion: apps/v1  
kind: Deployment
metadata:
 name: user-service-green
 labels:
 version: green
spec:
 replicas: 3
 selector:
 matchLabels:
 app: user-service
 version: green
```

### Canary Deployment
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
spec:
 replicas: 10
 strategy:
 canary:
 steps:
 - setWeight: 10  # Route 10% traffic to new version
 - pause: {duration: 10m}
 - setWeight: 50  # Route 50% traffic to new version  
 - pause: {duration: 10m}
 - setWeight: 100 # Route 100% traffic to new version
```''',
 contextType: ContextType.knowledge,
 category: ContextHubCategory.development,
 tags: ['microservices', 'architecture', 'scalability', 'design-patterns'],
 icon: Icons.architecture,
 ),
 ];
 }

 static List<SampleContext> getSecuritySamples() {
 return [
 SampleContext(
 title: 'Application Security Best Practices',
 description: 'Comprehensive security guidelines for modern applications',
 content: r'''# Application Security Best Practices

## Authentication & Authorization

### Multi-Factor Authentication (MFA)
```javascript
// TOTP implementation
const speakeasy = require('speakeasy');

class MFAService {
 generateSecret(user) {
 const secret = speakeasy.generateSecret({
 name: 'MyApp (' + user.email + ')',
 issuer: 'MyApp'
 });
 
 return {
 secret: secret.base32,
 qrCode: secret.otpauth_url
 };
 }
 
 verifyToken(secret, token) {
 return speakeasy.totp.verify({
 secret: secret,
 encoding: 'base32',
 token: token,
 window: 2 // Allow 2-step window for time sync issues
 });
 }
}
```

### JWT Security Best Practices
```javascript
const jwt = require('jsonwebtoken');

class JWTService {
 generateTokens(payload) {
 const accessToken = jwt.sign(
 payload,
 process.env.ACCESS_TOKEN_SECRET,
 { 
 expiresIn: '15m',
 issuer: 'myapp.com',
 audience: 'api.myapp.com'
 }
 );
 
 const refreshToken = jwt.sign(
 { userId: payload.userId },
 process.env.REFRESH_TOKEN_SECRET,
 { expiresIn: '7d' }
 );
 
 return { accessToken, refreshToken };
 }
 
 // Rotate refresh tokens
 async rotateRefreshToken(oldToken) {
 try {
 const decoded = jwt.verify(oldToken, process.env.REFRESH_TOKEN_SECRET);
 
 // Invalidate old token
 await this.blacklistToken(oldToken);
 
 // Generate new tokens
 return this.generateTokens({ userId: decoded.userId });
 } catch (error) {
 throw new Error('Invalid refresh token');
 }
 }
}
```

## Input Validation & Sanitization

### SQL Injection Prevention
```javascript
// ❌ Vulnerable to SQL injection
const getUserById = (id) => {
 return db.query('SELECT * FROM users WHERE id = ' + id);
};

// ✅ Safe with parameterized queries
const getUserById = (id) => {
 return db.query('SELECT * FROM users WHERE id = ?', [id]);
};

// ✅ Using ORM with built-in protections
const getUserById = async (id) => {
 return await User.findById(id); // Sequelize/TypeORM automatically sanitizes
};
```

### XSS Prevention
```javascript
const DOMPurify = require('dompurify');
const { JSDOM } = require('jsdom');

const window = new JSDOM('').window;
const purify = DOMPurify(window);

// Sanitize HTML input
const sanitizeHtml = (html) => {
 return purify.sanitize(html, {
 ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'p', 'br'],
 ALLOWED_ATTR: []
 });
};

// Content Security Policy headers
app.use((req, res, next) => {
 res.setHeader(
 'Content-Security-Policy',
 "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'"
 );
 next();
});
```

### Request Validation
```javascript
const Joi = require('joi');

const userValidationSchema = Joi.object({
 email: Joi.string().email().required(),
 password: Joi.string().min(8).pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/).required(),
 age: Joi.number().integer().min(13).max(120),
 preferences: Joi.object({
 newsletter: Joi.boolean().default(false),
 notifications: Joi.boolean().default(true)
 })
});

const validateUser = (req, res, next) => {
 const { error } = userValidationSchema.validate(req.body);
 if (error) {
 return res.status(400).json({
 error: 'Validation failed',
 details: error.details
 });
 }
 next();
};
```

## Data Protection

### Encryption at Rest
```javascript
const crypto = require('crypto');

class EncryptionService {
 constructor() {
 this.algorithm = 'aes-256-gcm';
 this.secretKey = process.env.ENCRYPTION_KEY; // 32 bytes key
 }
 
 encrypt(text) {
 const iv = crypto.randomBytes(16);
 const cipher = crypto.createCipher(this.algorithm, this.secretKey, iv);
 
 let encrypted = cipher.update(text, 'utf8', 'hex');
 encrypted += cipher.final('hex');
 
 const authTag = cipher.getAuthTag();
 
 return {
 encrypted,
 iv: iv.toString('hex'),
 authTag: authTag.toString('hex')
 };
 }
 
 decrypt(encryptedData) {
 const decipher = crypto.createDecipher(
 this.algorithm,
 this.secretKey,
 Buffer.from(encryptedData.iv, 'hex')
 );
 
 decipher.setAuthTag(Buffer.from(encryptedData.authTag, 'hex'));
 
 let decrypted = decipher.update(encryptedData.encrypted, 'hex', 'utf8');
 decrypted += decipher.final('utf8');
 
 return decrypted;
 }
}
```

### Password Hashing
```javascript
const bcrypt = require('bcrypt');
const argon2 = require('argon2');

class PasswordService {
 // Using bcrypt (good)
 async hashPasswordBcrypt(password) {
 const saltRounds = 12;
 return await bcrypt.hash(password, saltRounds);
 }
 
 async verifyPasswordBcrypt(password, hash) {
 return await bcrypt.compare(password, hash);
 }
 
 // Using Argon2 (better - modern standard)
 async hashPasswordArgon2(password) {
 return await argon2.hash(password, {
 type: argon2.argon2id,
 memoryCost: 2 ** 16, // 64 MB
 timeCost: 3,
 parallelism: 1,
 });
 }
 
 async verifyPasswordArgon2(password, hash) {
 return await argon2.verify(hash, password);
 }
}
```

## Rate Limiting & DDoS Protection

### Express Rate Limiting
```javascript
const rateLimit = require('express-rate-limit');
const RedisStore = require('rate-limit-redis');
const Redis = require('ioredis');

const redisClient = new Redis(process.env.REDIS_URL);

// General API rate limiting
const generalLimiter = rateLimit({
 store: new RedisStore({
 sendCommand: (...args) => redisClient.call(...args),
 }),
 windowMs: 15 * 60 * 1000, // 15 minutes
 max: 100, // limit each IP to 100 requests per windowMs
 message: 'Too many requests from this IP',
 standardHeaders: true,
 legacyHeaders: false,
});

// Strict rate limiting for auth endpoints
const authLimiter = rateLimit({
 windowMs: 15 * 60 * 1000,
 max: 5, // only 5 login attempts per 15 minutes
 skipSuccessfulRequests: true, // don't count successful requests
});

app.use('/api/', generalLimiter);
app.use('/api/auth/login', authLimiter);
```

### IP Whitelisting & Blacklisting
```javascript
class SecurityMiddleware {
 static ipWhitelist = new Set([
 '192.168.1.0/24',
 '10.0.0.0/8'
 ]);
 
 static ipBlacklist = new Set();
 
 static checkIPAccess(req, res, next) {
 const clientIP = req.ip || req.connection.remoteAddress;
 
 if (this.ipBlacklist.has(clientIP)) {
 return res.status(403).json({ error: 'Access denied' });
 }
 
 // For admin endpoints, require whitelisted IPs
 if (req.path.startsWith('/admin')) {
 const isWhitelisted = this.ipWhitelist.has(clientIP);
 if (!isWhitelisted) {
 return res.status(403).json({ error: 'Access denied' });
 }
 }
 
 next();
 }
}
```

## Security Headers

### Essential Security Headers
```javascript
const helmet = require('helmet');

app.use(helmet({
 // Content Security Policy
 contentSecurityPolicy: {
 directives: {
 defaultSrc: ["'self'"],
 styleSrc: ["'self'", "'unsafe-inline'", "fonts.googleapis.com"],
 fontSrc: ["'self'", "fonts.gstatic.com"],
 imgSrc: ["'self'", "data:", "https:"],
 scriptSrc: ["'self'"],
 },
 },
 
 // HTTP Strict Transport Security
 hsts: {
 maxAge: 31536000, // 1 year
 includeSubDomains: true,
 preload: true
 },
 
 // X-Frame-Options
 frameguard: { action: 'deny' },
 
 // X-Content-Type-Options
 noSniff: true,
 
 // Referrer Policy
 referrerPolicy: { policy: "same-origin" }
}));

// Custom security headers
app.use((req, res, next) => {
 res.setHeader('X-API-Version', '1.0');
 res.setHeader('X-Powered-By', ''); // Remove default Express header
 next();
});
```

## Vulnerability Scanning & Monitoring

### Dependency Scanning
```bash
# Package.json security auditing
npm audit
npm audit fix

# Using specialized tools
npx audit-ci --moderate
snyk test
```

### Runtime Security Monitoring
```javascript
const winston = require('winston');

class SecurityMonitor {
 static logger = winston.createLogger({
 level: 'info',
 format: winston.format.json(),
 transports: [
 new winston.transports.File({ filename: 'security.log' })
 ]
 });
 
 static logSecurityEvent(event, details) {
 this.logger.warn('Security Event', {
 type: event,
 timestamp: new Date().toISOString(),
 ip: details.ip,
 userAgent: details.userAgent,
 userId: details.userId,
 details: details.additional
 });
 
 // Alert if critical
 if (details.severity === 'critical') {
 this.sendAlert(event, details);
 }
 }
 
 static async sendAlert(event, details) {
 // Send to monitoring system (PagerDuty, Slack, etc.)
 await alertingService.send({
 title: 'Security Alert: ' + event,
 message: JSON.stringify(details),
 severity: 'high'
 });
 }
}

// Usage in middleware
const securityAuditMiddleware = (req, res, next) => {
 // Log suspicious patterns
 if (req.body && typeof req.body === 'string' && 
 (req.body.includes('script>') || req.body.includes('SELECT * FROM'))) {
 
 SecurityMonitor.logSecurityEvent('potential_injection_attempt', {
 ip: req.ip,
 userAgent: req.get('User-Agent'),
 payload: req.body,
 severity: 'high'
 });
 }
 
 next();
};
```

## OWASP Top 10 Checklist

### 1. Injection Prevention ✓
- Use parameterized queries
- Validate and sanitize all input
- Use ORM/query builders

### 2. Broken Authentication ✓  
- Implement MFA
- Use strong password policies
- Secure session management

### 3. Sensitive Data Exposure ✓
- Encrypt data at rest and in transit
- Use HTTPS everywhere
- Proper key management

### 4. XML External Entities (XXE) ✓
- Disable XML external entity processing
- Use secure XML parsers

### 5. Broken Access Control ✓
- Implement proper authorization checks
- Use principle of least privilege
- Validate permissions server-side

### 6. Security Misconfiguration ✓
- Keep software updated
- Remove default accounts
- Secure headers and configurations

### 7. Cross-Site Scripting (XSS) ✓
- Validate input, encode output  
- Use CSP headers
- Sanitize HTML content

### 8. Insecure Deserialization ✓
- Validate serialized data
- Use integrity checks
- Isolate deserialization code

### 9. Known Vulnerabilities ✓
- Regular dependency updates
- Vulnerability scanning
- Security monitoring

### 10. Insufficient Logging ✓
- Log security events
- Monitor for suspicious activity
- Implement alerting systems''',
 contextType: ContextType.guidelines,
 category: ContextHubCategory.development,
 tags: ['security', 'authentication', 'validation', 'best-practices'],
 icon: Icons.security,
 ),
 ];
 }

 static List<SampleContext> getFrontendLibrariesSamples() {
 return [
 SampleContext(
 title: 'React Ecosystem Libraries',
 description: 'Essential React libraries and their implementation patterns',
 content: r'''# React Ecosystem Libraries

## State Management - Redux Toolkit
```javascript
import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';

export const fetchUser = createAsyncThunk(
 'user/fetchUser',
 async (userId) => {
 const response = await fetch('/api/users/' + userId);
 return await response.json();
 }
);

const userSlice = createSlice({
 name: 'user',
 initialState: { data: null, loading: false, error: null },
 reducers: {
 clearUser: (state) => { state.data = null; },
 },
 extraReducers: (builder) => {
 builder
 .addCase(fetchUser.pending, (state) => { state.loading = true; })
 .addCase(fetchUser.fulfilled, (state, action) => {
 state.loading = false;
 state.data = action.payload;
 });
 },
});
```

## Form Handling - React Hook Form
```javascript
import { useForm } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';

const LoginForm = () => {
 const { register, handleSubmit, formState: { errors } } = useForm({
 resolver: yupResolver(schema)
 });

 return (
 <form onSubmit={handleSubmit(onSubmit)}>
 <input {...register('email')} placeholder="Email" />
 {errors.email && <span>{errors.email.message}</span>}
 <button type="submit">Login</button>
 </form>
 );
};
```

## Data Fetching - TanStack Query
```javascript
import { useQuery, useMutation } from '@tanstack/react-query';

const usePosts = () => {
 return useQuery({
 queryKey: ['posts'],
 queryFn: () => fetch('/api/posts').then(res => res.json()),
 staleTime: 5 * 60 * 1000,
 });
};

const useCreatePost = () => {
 return useMutation({
 mutationFn: (newPost) => 
 fetch('/api/posts', {
 method: 'POST',
 body: JSON.stringify(newPost)
 })
 });
};
```

## UI Components - Material-UI
```javascript
import { ThemeProvider, createTheme, Button, Card } from '@mui/material';

const theme = createTheme({
 palette: { primary: { main: '#1976d2' } }
});

const UserCard = ({ user }) => (
 <ThemeProvider theme={theme}>
 <Card>
 <Button variant="contained" color="primary">
 Edit Profile
 </Button>
 </Card>
 </ThemeProvider>
);
```

## Animation - Framer Motion
```javascript
import { motion, AnimatePresence } from 'framer-motion';

const AnimatedCard = ({ isVisible }) => (
 <AnimatePresence>
 {isVisible && (
 <motion.div
 initial={{ opacity: 0, scale: 0.8 }}
 animate={{ opacity: 1, scale: 1 }}
 exit={{ opacity: 0 }}
 whileHover={{ scale: 1.05 }}
 >
 <h3>Animated Card</h3>
 </motion.div>
 )}
 </AnimatePresence>
);
```

## Testing - React Testing Library
```javascript
import { render, screen, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

describe('LoginForm', () => {
 test('submits form with user credentials', async () => {
 const user = userEvent.setup();
 render(<LoginForm />);
 
 await user.type(screen.getByLabelText(/email/i), 'test@example.com');
 await user.click(screen.getByRole('button', { name: /login/i }));
 
 expect(screen.getByText('Logging in...')).toBeInTheDocument();
 });
});
```''',
 contextType: ContextType.knowledge,
 category: ContextHubCategory.development,
 tags: ['react', 'frontend', 'libraries', 'components'],
 icon: Icons.widgets,
 ),
 
 SampleContext(
 title: 'CSS Frameworks & Styling',
 description: 'Modern CSS frameworks and styling approaches',
 content: r'''# CSS Frameworks & Styling

## Tailwind CSS
```html
<!-- Responsive Grid Layout -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
 <div class="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition-shadow">
 <h2 class="text-xl font-semibold text-gray-900 mb-4">Card Title</h2>
 <p class="text-gray-600">Content goes here</p>
 <button class="mt-4 bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded">
 Action
 </button>
 </div>
</div>

<!-- Form Styling -->
<form class="max-w-lg mx-auto space-y-6">
 <div>
 <label class="block text-sm font-medium text-gray-700 mb-2">Email</label>
 <input 
 type="email"
 class="w-full px-3 py-2 border rounded-md focus:ring-2 focus:ring-blue-500"
 />
 </div>
 <button class="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700">
 Submit
 </button>
</form>
```

## Bootstrap 5
```html
<!-- Navigation -->
<nav class="navbar navbar-expand-lg navbar-dark bg-primary">
 <div class="container">
 <a class="navbar-brand" href="#">MyApp</a>
 <ul class="navbar-nav ms-auto">
 <li class="nav-item">
 <a class="nav-link" href="#">Home</a>
 </li>
 </ul>
 </div>
</nav>

<!-- Card Components -->
<div class="container my-5">
 <div class="row g-4">
 <div class="col-md-4">
 <div class="card h-100">
 <div class="card-body">
 <h5 class="card-title">Feature</h5>
 <p class="card-text">Description</p>
 <a href="#" class="btn btn-primary">Learn More</a>
 </div>
 </div>
 </div>
 </div>
</div>
```

## CSS-in-JS - Styled Components
```javascript
import styled from 'styled-components';

const Button = styled.button`
 background-color: \${props => props.primary ? '#007bff' : 'transparent'};
 color: \${props => props.primary ? '#fff' : '#007bff'};
 border: 2px solid #007bff;
 padding: 0.75rem 1.5rem;
 border-radius: 0.375rem;
 cursor: pointer;
 transition: all 0.2s ease;
 
 &:hover {
 opacity: 0.9;
 transform: translateY(-2px);
 }
`;

const Card = styled.div`
 background: white;
 border-radius: 0.5rem;
 box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
 padding: 1.5rem;
`;
```

## Sass/SCSS
```scss
// Variables
$primary-color: #007bff;
$breakpoints: (mobile: 576px, tablet: 768px);

// Mixins
@mixin flex-center {
 display: flex;
 align-items: center;
 justify-content: center;
}

@mixin responsive($breakpoint) {
 @media (min-width: map-get($breakpoints, $breakpoint)) {
 @content;
 }
}

// Usage
.hero {
 @include flex-center;
 height: 100vh;
 background: $primary-color;
 
 @include responsive(tablet) {
 height: 80vh;
 }
 
 &__title {
 font-size: 3rem;
 color: white;
 
 @include responsive(mobile) {
 font-size: 2rem;
 }
 }
}
```''',
 contextType: ContextType.knowledge,
 category: ContextHubCategory.development,
 tags: ['css', 'tailwind', 'bootstrap', 'styling'],
 icon: Icons.brush,
 ),
 
 SampleContext(
 title: 'Build Tools & Development Setup',
 description: 'Modern build tools and development environment configuration',
 content: r'''# Build Tools & Development Setup

## Vite Configuration
```javascript
// vite.config.js
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
 plugins: [react()],
 
 server: {
 port: 3000,
 proxy: {
 '/api': 'http://localhost:8000'
 }
 },
 
 build: {
 outDir: 'dist',
 sourcemap: true
 },
 
 resolve: {
 alias: {
 '@': '/src',
 '@components': '/src/components'
 }
 }
});
```

## ESLint & Prettier Setup
```javascript
// .eslintrc.js
module.exports = {
 extends: [
 'eslint:recommended',
 '@typescript-eslint/recommended',
 'plugin:react/recommended',
 'prettier'
 ],
 rules: {
 'react/react-in-jsx-scope': 'off',
 '@typescript-eslint/no-unused-vars': 'error'
 }
};

// .prettierrc
{
 "semi": true,
 "singleQuote": true,
 "tabWidth": 2,
 "trailingComma": "es5"
}
```

## TypeScript Configuration
```json
// tsconfig.json
{
 "compilerOptions": {
 "target": "ES2020",
 "lib": ["DOM", "DOM.Iterable"],
 "strict": true,
 "jsx": "react-jsx",
 "baseUrl": ".",
 "paths": {
 "@/*": ["src/*"],
 "@/components/*": ["src/components/*"]
 }
 },
 "include": ["src"],
 "exclude": ["node_modules"]
}
```

## Package.json Scripts
```json
{
 "scripts": {
 "dev": "vite",
 "build": "tsc && vite build",
 "test": "jest",
 "lint": "eslint src --ext .ts,.tsx",
 "lint:fix": "eslint src --fix",
 "format": "prettier --write src/**/*.{ts,tsx}",
 "type-check": "tsc --noEmit"
 }
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

EXPOSE 3000

CMD ["npm", "run", "dev"]
```

## Environment Variables
```javascript
// .env.local
VITE_API_URL=http://localhost:8000
VITE_APP_VERSION=1.0.0

// Usage in code
const apiUrl = import.meta.env.VITE_API_URL;
```''',
 contextType: ContextType.knowledge,
 category: ContextHubCategory.development,
 tags: ['vite', 'build-tools', 'typescript', 'eslint', 'development'],
 icon: Icons.build,
 ),
 ];
 }
}