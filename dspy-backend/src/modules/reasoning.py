"""
Reasoning Modules - Chain of Thought and Tree of Thought

Structured reasoning patterns that actually work.
"""
from __future__ import annotations

import dspy
from typing import Optional


class BasicReasoningSignature(dspy.Signature):
    """Basic reasoning with step-by-step thinking"""

    question: str = dspy.InputField(desc="The question or problem to reason about")
    reasoning: str = dspy.OutputField(desc="Step-by-step reasoning process")
    answer: str = dspy.OutputField(desc="The final answer")
    confidence: float = dspy.OutputField(desc="Confidence in the answer from 0.0 to 1.0")


class AnalysisSignature(dspy.Signature):
    """Deep analysis of a topic or problem"""

    topic: str = dspy.InputField(desc="The topic or problem to analyze")
    context: str = dspy.InputField(desc="Additional context or constraints", default="")
    analysis: str = dspy.OutputField(desc="Detailed analysis with multiple perspectives")
    key_points: list[str] = dspy.OutputField(desc="List of key takeaways")
    recommendations: list[str] = dspy.OutputField(desc="Actionable recommendations")


class ChainOfThoughtModule(dspy.Module):
    """
    Chain of Thought reasoning module.

    Forces the model to think step-by-step before answering.
    This significantly improves accuracy on complex reasoning tasks.

    Usage:
        cot = ChainOfThoughtModule()
        result = cot(question="If it takes 5 machines 5 minutes to make 5 widgets, how long would it take 100 machines to make 100 widgets?")
        print(result.reasoning)  # See the step-by-step thinking
        print(result.answer)     # "5 minutes"
        print(result.confidence) # e.g., 0.95
    """

    def __init__(self):
        super().__init__()
        self.reason = dspy.ChainOfThought(BasicReasoningSignature)

    def forward(self, question: str) -> dspy.Prediction:
        pred = self.reason(question=question)

        # Ensure confidence is valid
        try:
            confidence = float(pred.confidence)
            confidence = min(max(confidence, 0.0), 1.0)
        except (ValueError, TypeError):
            confidence = 0.5

        return dspy.Prediction(
            reasoning=pred.reasoning,
            answer=pred.answer,
            confidence=confidence,
        )


class ThoughtBranch(dspy.Signature):
    """Generate a branch of thought for tree-of-thought reasoning"""

    problem: str = dspy.InputField(desc="The problem to solve")
    approach: str = dspy.InputField(desc="The specific approach to explore")
    reasoning: str = dspy.OutputField(desc="Reasoning following this approach")
    conclusion: str = dspy.OutputField(desc="Conclusion from this approach")
    viability: float = dspy.OutputField(desc="How viable is this approach (0.0 to 1.0)")


class ThoughtSynthesis(dspy.Signature):
    """Synthesize multiple thought branches into a final answer"""

    problem: str = dspy.InputField(desc="The original problem")
    branches: str = dspy.InputField(desc="Summary of all explored approaches and conclusions")
    best_approach: str = dspy.OutputField(desc="The best approach identified")
    final_answer: str = dspy.OutputField(desc="The synthesized final answer")
    reasoning: str = dspy.OutputField(desc="Why this answer is best")


class TreeOfThoughtModule(dspy.Module):
    """
    Tree of Thought reasoning module.

    Explores multiple reasoning paths in parallel, then synthesizes
    the best answer. Good for:
    - Problems with multiple valid approaches
    - Creative tasks
    - Decision making with tradeoffs

    Usage:
        tot = TreeOfThoughtModule(num_branches=3)
        result = tot(
            problem="Design a caching strategy for a high-traffic API"
        )
        print(result.branches)      # All explored approaches
        print(result.best_approach) # The winner
        print(result.final_answer)  # Synthesized answer
    """

    def __init__(self, num_branches: int = 3):
        super().__init__()
        self.num_branches = num_branches
        self.branch = dspy.ChainOfThought(ThoughtBranch)
        self.synthesize = dspy.ChainOfThought(ThoughtSynthesis)

        # Different approaches to explore
        self.approaches = [
            "the most straightforward solution",
            "an unconventional or creative approach",
            "the most robust and scalable solution",
            "the fastest to implement",
            "the most maintainable long-term",
        ]

    def forward(self, problem: str) -> dspy.Prediction:
        branches = []

        # Explore multiple approaches
        for i in range(min(self.num_branches, len(self.approaches))):
            approach = self.approaches[i]
            branch_pred = self.branch(problem=problem, approach=approach)

            try:
                viability = float(branch_pred.viability)
            except (ValueError, TypeError):
                viability = 0.5

            branches.append({
                "approach": approach,
                "reasoning": branch_pred.reasoning,
                "conclusion": branch_pred.conclusion,
                "viability": viability,
            })

        # Format branches for synthesis
        branches_summary = "\n\n".join([
            f"Approach: {b['approach']}\n"
            f"Reasoning: {b['reasoning']}\n"
            f"Conclusion: {b['conclusion']}\n"
            f"Viability: {b['viability']:.2f}"
            for b in branches
        ])

        # Synthesize final answer
        synthesis = self.synthesize(problem=problem, branches=branches_summary)

        return dspy.Prediction(
            branches=branches,
            branches_summary=branches_summary,
            best_approach=synthesis.best_approach,
            final_answer=synthesis.final_answer,
            reasoning=synthesis.reasoning,
        )


class AnalysisModule(dspy.Module):
    """
    Deep analysis module for comprehensive topic exploration.

    Usage:
        analyzer = AnalysisModule()
        result = analyzer(
            topic="Migrating from monolith to microservices",
            context="E-commerce platform with 1M daily users"
        )
        print(result.analysis)
        print(result.key_points)
        print(result.recommendations)
    """

    def __init__(self):
        super().__init__()
        self.analyze = dspy.ChainOfThought(AnalysisSignature)

    def forward(self, topic: str, context: str = "") -> dspy.Prediction:
        pred = self.analyze(topic=topic, context=context)

        return dspy.Prediction(
            analysis=pred.analysis,
            key_points=pred.key_points if isinstance(pred.key_points, list) else [],
            recommendations=pred.recommendations if isinstance(pred.recommendations, list) else [],
        )


class DecisionSignature(dspy.Signature):
    """Make a decision with confidence scoring"""

    situation: str = dspy.InputField(desc="The situation requiring a decision")
    options: str = dspy.InputField(desc="Available options to choose from")
    constraints: str = dspy.InputField(desc="Constraints or requirements", default="")
    decision: str = dspy.OutputField(desc="The recommended decision")
    rationale: str = dspy.OutputField(desc="Detailed rationale for the decision")
    confidence: float = dspy.OutputField(desc="Confidence in this decision (0.0 to 1.0)")
    risks: list[str] = dspy.OutputField(desc="Potential risks of this decision")


class DecisionModule(dspy.Module):
    """
    Decision making module with confidence scoring.

    Perfect for:
    - Routing decisions in agent systems
    - Feature flags and A/B decisions
    - Risk assessment

    Usage:
        decider = DecisionModule()
        result = decider(
            situation="User wants to delete their account",
            options="1. Soft delete, 2. Hard delete, 3. Deactivate",
            constraints="GDPR compliance required"
        )
        print(result.decision)
        print(result.confidence)
        print(result.risks)
    """

    def __init__(self, min_confidence: float = 0.7):
        super().__init__()
        self.min_confidence = min_confidence
        self.decide = dspy.ChainOfThought(DecisionSignature)

    def forward(
        self,
        situation: str,
        options: str,
        constraints: str = ""
    ) -> dspy.Prediction:
        pred = self.decide(
            situation=situation,
            options=options,
            constraints=constraints
        )

        try:
            confidence = float(pred.confidence)
            confidence = min(max(confidence, 0.0), 1.0)
        except (ValueError, TypeError):
            confidence = 0.5

        return dspy.Prediction(
            decision=pred.decision,
            rationale=pred.rationale,
            confidence=confidence,
            risks=pred.risks if isinstance(pred.risks, list) else [],
            meets_threshold=confidence >= self.min_confidence,
        )
