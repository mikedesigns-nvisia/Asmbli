/// Sample documents for demo scenarios with built-in uncertainty triggers
class DemoDocuments {
  /// Legal contract with compliance complexity (triggers uncertainty)
  static const String complexContract = '''
SOFTWARE LICENSE AGREEMENT

This Software License Agreement ("Agreement") is entered into on December 1, 2024, 
between TechStartup Inc., a Delaware corporation ("Licensor"), and Enterprise Corp., 
a multinational corporation with subsidiaries in EU, UK, and California ("Licensee").

1. LICENSE GRANT
Licensor grants Licensee a non-exclusive, non-transferable license to use the 
Software in accordance with the terms herein.

2. DATA HANDLING
Licensee may process personal data of EU residents using the Software. 
[UNCERTAINTY TRIGGER: This involves GDPR compliance requirements]

3. LIABILITY LIMITATIONS  
IN NO EVENT SHALL LICENSOR BE LIABLE FOR ANY INDIRECT, INCIDENTAL, OR 
CONSEQUENTIAL DAMAGES. Maximum liability shall not exceed \$50,000.
[UNCERTAINTY TRIGGER: Conflicts with UK consumer protection laws]

4. TERMINATION
This Agreement may be terminated by either party with 30 days notice.
However, California law requires 60 days notice for enterprise agreements.
[UNCERTAINTY TRIGGER: Conflicting jurisdiction requirements]

5. GOVERNING LAW
This Agreement shall be governed by Delaware law, except where superseded 
by mandatory EU data protection regulations.
[UNCERTAINTY TRIGGER: Multi-jurisdictional complexity]

6. ARTIFICIAL INTELLIGENCE USAGE
Software includes AI components trained on proprietary datasets. 
Licensee acknowledges potential biases and agrees to human oversight 
for decisions affecting individuals.
[UNCERTAINTY TRIGGER: New AI governance requirements - unclear compliance]
''';

  /// Startup pitch deck with market analysis challenges
  static const String startupPitchDeck = '''
TECHNOVATE AI - SERIES A PITCH DECK

SLIDE 1: PROBLEM
Enterprise customers struggle with AI implementation complexity.
Current solutions require 6+ months and \$500K+ investments.

SLIDE 2: SOLUTION  
TechnoVate AI provides no-code AI automation platform.
Customers can deploy AI workflows in under 2 weeks.

SLIDE 3: MARKET SIZE
Total Addressable Market: \$47 billion (Source: Gartner 2024)
[UNCERTAINTY TRIGGER: But McKinsey report says \$28 billion - which is correct?]

Serviceable Addressable Market: \$12 billion
[UNCERTAINTY TRIGGER: Based on 2022 data, may be outdated]

Current market growth: 23% CAGR
[UNCERTAINTY TRIGGER: Pre-AI winter projections, current reality unclear]

SLIDE 4: TRACTION
- 15 enterprise customers (ARR: \$300K)
- Customer interviews show 89% satisfaction
[UNCERTAINTY TRIGGER: Sample size only 9 customers responded]

- Pilot with Fortune 500 company shows 40% efficiency gains
[UNCERTAINTY TRIGGER: Pilot was only 3 weeks, limited data]

SLIDE 5: BUSINESS MODEL
SaaS pricing: \$50-500 per user per month
Average customer: 200 users = \$120K ARR
[UNCERTAINTY TRIGGER: Only 2 customers at this scale, others much smaller]

SLIDE 6: COMPETITION
Direct competitors: UiPath, Automation Anywhere
[UNCERTAINTY TRIGGER: Both have pivoted to AI, competitive landscape shifted]

Our advantage: 10x faster implementation
[UNCERTAINTY TRIGGER: Based on single case study, not validated across segments]

SLIDE 7: TEAM
CEO: John Smith (Ex-Google, 10 years AI experience)
CTO: Jane Doe (Ex-Tesla, 8 years automation)
[UNCERTAINTY TRIGGER: Recent departures from previous companies under unclear circumstances]

SLIDE 8: FUNDING
Seeking: \$5M Series A
Use of funds: 60% engineering, 30% sales, 10% marketing
[UNCERTAINTY TRIGGER: Burn rate suggests 12-month runway, aggressive hiring plan]
''';

  /// Technical specification with domain expertise requirements  
  static const String technicalSpec = '''
MICROSERVICES ARCHITECTURE SPECIFICATION
Project: E-commerce Platform Redesign

OVERVIEW
Migrate monolithic e-commerce platform to microservices architecture.
Current system: 500K daily active users, 2M products, \$50M GMV.

PROPOSED ARCHITECTURE

1. USER SERVICE
- Technology: Node.js + Redis
- Database: PostgreSQL with read replicas
- Expected Load: 10K RPS peak
[UNCERTAINTY TRIGGER: Redis clustering configuration for this scale unclear]

2. PRODUCT CATALOG SERVICE  
- Technology: Python + Elasticsearch
- Database: MongoDB with sharding
- Search Requirements: Sub-100ms response time
[UNCERTAINTY TRIGGER: MongoDB + Elasticsearch consistency challenges at scale]

3. ORDER PROCESSING SERVICE
- Technology: Java Spring Boot + Kafka
- Database: PostgreSQL with ACID compliance
- SLA: 99.99% uptime for payment processing
[UNCERTAINTY TRIGGER: Kafka exactly-once semantics for financial transactions complex]

4. INVENTORY MANAGEMENT
- Technology: Go + Redis Streams  
- Real-time updates across 15 warehouses
- Eventual consistency acceptable (5-second lag)
[UNCERTAINTY TRIGGER: Go + Redis Streams combination unproven at this scale]

5. PAYMENT PROCESSING
- Technology: .NET Core + SQL Server
- PCI DSS Level 1 compliance required
- Integration: Stripe, PayPal, Apple Pay
[UNCERTAINTY TRIGGER: Multi-payment provider failover logic not specified]

PERFORMANCE REQUIREMENTS
- 99.9% uptime (current: 99.5%)
- <200ms API response time (current: 800ms)  
- Support 5x traffic spikes during Black Friday
[UNCERTAINTY TRIGGER: Performance targets based on theoretical calculations, not load testing]

SECURITY CONSIDERATIONS
- OAuth 2.0 + JWT for authentication
- AES-256 encryption for PII
- WAF + DDoS protection via CloudFlare
[UNCERTAINTY TRIGGER: JWT token rotation strategy not defined]

DEPLOYMENT STRATEGY
- Kubernetes on AWS EKS
- Blue-green deployment with 0 downtime
- Automated rollback on health check failures
[UNCERTAINTY TRIGGER: Database migration during blue-green deployment not addressed]

TIMELINE
Phase 1 (Months 1-3): User + Product services
Phase 2 (Months 4-6): Order + Inventory services  
Phase 3 (Months 7-9): Payment integration + testing
[UNCERTAINTY TRIGGER: Timeline assumes no integration issues, likely optimistic]

RISKS
- Data migration complexity (2TB+ historical data)
- Third-party API rate limits during migration
- Team learning curve for new technologies
[UNCERTAINTY TRIGGER: Risk mitigation strategies not detailed]
''';

  /// Financial report with data quality variance
  static const String financialReport = '''
QUARTERLY FINANCIAL ANALYSIS - Q3 2024
TechCorp Industries

REVENUE SUMMARY
Q3 2024 Revenue: \$12.4M (reported)
[UNCERTAINTY TRIGGER: Preliminary figure, pending final reconciliation]

Q3 2023 Revenue: \$8.7M
Year-over-Year Growth: 42.5%
[UNCERTAINTY TRIGGER: Different accounting method used in Q3 2023]

REVENUE BREAKDOWN
Software Licenses: \$8.1M (65%)
Professional Services: \$3.2M (26%)  
Support & Maintenance: \$1.1M (9%)
[UNCERTAINTY TRIGGER: Revenue recognition changed mid-quarter for services]

EXPENSES
Total Operating Expenses: \$9.8M
- Salaries & Benefits: \$6.2M (63%)
- Marketing & Sales: \$2.1M (21%)
- R&D: \$1.2M (12%)
- Other: \$0.3M (4%)

Net Income: \$2.6M
[UNCERTAINTY TRIGGER: Includes \$0.8M one-time gain from asset sale]

CUSTOMER METRICS
New Customers: 47 (Q3) vs 31 (Q2)
Customer Churn: 3.2% monthly
[UNCERTAINTY TRIGGER: Churn calculation methodology changed, not comparable to previous quarters]

Average Contract Value: \$78K
[UNCERTAINTY TRIGGER: Excludes pilot customers, skews actual average]

CASH FLOW
Operating Cash Flow: \$3.1M
Free Cash Flow: \$2.4M (after \$0.7M CapEx)
Cash on Hand: \$15.7M (end of quarter)
[UNCERTAINTY TRIGGER: Pending \$2.3M payment from major customer]

KEY PERFORMANCE INDICATORS
Monthly Recurring Revenue: \$3.2M
[UNCERTAINTY TRIGGER: Includes one-time setup fees as recurring, may inflate actual MRR]

Customer Acquisition Cost: \$12K
Customer Lifetime Value: \$180K
LTV:CAC Ratio: 15:1
[UNCERTAINTY TRIGGER: LTV calculation based on 18-month average, newer cohorts may differ]

MARKET CONDITIONS
Industry Growth Rate: 18% (Source: TechAnalyst Report)
[UNCERTAINTY TRIGGER: Report based on pre-recession data, current conditions different]

Competitive Landscape: 3 new entrants in Q3
Market Share: Estimated 12% in our segment
[UNCERTAINTY TRIGGER: Market share estimate based on limited survey data]

FORWARD GUIDANCE
Q4 2024 Revenue Projection: \$14-16M
[UNCERTAINTY TRIGGER: Based on current pipeline, but major deals uncertain]

Full Year 2024: \$48-52M revenue target
[UNCERTAINTY TRIGGER: Assumes no macro economic deterioration]

RISKS & UNCERTAINTIES
- Customer concentration: Top 3 customers = 45% of revenue
- Dependency on external data providers
- Potential regulatory changes in our industry
[UNCERTAINTY TRIGGER: Regulatory impact assessment incomplete]
''';

  /// Get document by type for demo scenarios
  static String getDocument(DocumentType type) {
    switch (type) {
      case DocumentType.legalContract:
        return complexContract;
      case DocumentType.pitchDeck:
        return startupPitchDeck;
      case DocumentType.technicalSpec:
        return technicalSpec;
      case DocumentType.financialReport:
        return financialReport;
    }
  }

  /// Get uncertainty triggers for each document type
  static List<UncertaintyTrigger> getUncertaintyTriggers(DocumentType type) {
    switch (type) {
      case DocumentType.legalContract:
        return [
          UncertaintyTrigger(
            line: 12,
            reason: "GDPR compliance requirements unclear",
            confidence: 0.23,
            requiredExpertise: "Legal/Data Protection",
          ),
          UncertaintyTrigger(
            line: 18,
            reason: "Conflicting UK consumer protection laws",
            confidence: 0.31,
            requiredExpertise: "International Law",
          ),
          UncertaintyTrigger(
            line: 23,
            reason: "Multi-jurisdictional complexity",
            confidence: 0.45,
            requiredExpertise: "Corporate Law",
          ),
        ];
      
      case DocumentType.pitchDeck:
        return [
          UncertaintyTrigger(
            line: 15,
            reason: "Conflicting market size data sources",
            confidence: 0.42,
            requiredExpertise: "Market Research",
          ),
          UncertaintyTrigger(
            line: 25,
            reason: "Limited sample size for satisfaction metric",
            confidence: 0.34,
            requiredExpertise: "Statistical Analysis",
          ),
          UncertaintyTrigger(
            line: 39,
            reason: "Competitive landscape has shifted",
            confidence: 0.28,
            requiredExpertise: "Competitive Intelligence",
          ),
        ];
      
      case DocumentType.technicalSpec:
        return [
          UncertaintyTrigger(
            line: 18,
            reason: "Redis clustering at this scale unproven",
            confidence: 0.38,
            requiredExpertise: "Redis Architecture",
          ),
          UncertaintyTrigger(
            line: 29,
            reason: "Kafka exactly-once semantics complexity",
            confidence: 0.29,
            requiredExpertise: "Distributed Systems",
          ),
          UncertaintyTrigger(
            line: 51,
            reason: "Blue-green deployment with database migrations",
            confidence: 0.33,
            requiredExpertise: "DevOps Architecture",
          ),
        ];
      
      case DocumentType.financialReport:
        return [
          UncertaintyTrigger(
            line: 8,
            reason: "Accounting method change affects comparability",
            confidence: 0.41,
            requiredExpertise: "Financial Analysis",
          ),
          UncertaintyTrigger(
            line: 32,
            reason: "Churn calculation methodology changed",
            confidence: 0.36,
            requiredExpertise: "Business Analytics",
          ),
          UncertaintyTrigger(
            line: 47,
            reason: "LTV calculation based on limited cohort data",
            confidence: 0.39,
            requiredExpertise: "Customer Analytics",
          ),
        ];
    }
  }
}

enum DocumentType {
  legalContract,
  pitchDeck,
  technicalSpec,
  financialReport,
}

class UncertaintyTrigger {
  final int line;
  final String reason;
  final double confidence;
  final String requiredExpertise;

  const UncertaintyTrigger({
    required this.line,
    required this.reason,
    required this.confidence,
    required this.requiredExpertise,
  });
}