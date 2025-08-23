import '../presentation/widgets/context_hub_widget.dart';
import 'models/context_document.dart';
import 'package:flutter/material.dart';

class SampleContextData {
  static List<SampleContext> getAllSamples() {
    return [
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
  <div className={`card \${className}`}>
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
}