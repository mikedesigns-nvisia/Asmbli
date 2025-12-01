"""
RAG (Retrieval-Augmented Generation) Modules

These are WORKING RAG implementations using DSPy.
Unlike theoretical code, these actually run and produce results.
"""
from __future__ import annotations

import dspy
from typing import Optional, List


class RAGSignature(dspy.Signature):
    """Answer questions based on retrieved context"""

    context: str = dspy.InputField(desc="Retrieved passages relevant to the question")
    question: str = dspy.InputField(desc="The user's question")
    answer: str = dspy.OutputField(desc="A detailed answer based on the context")


class RAGWithCitationsSignature(dspy.Signature):
    """Answer questions with source citations"""

    context: str = dspy.InputField(desc="Retrieved passages with source information")
    question: str = dspy.InputField(desc="The user's question")
    answer: str = dspy.OutputField(desc="A detailed answer based on the context")
    citations: list[str] = dspy.OutputField(desc="List of sources used in the answer")
    confidence: float = dspy.OutputField(desc="Confidence score from 0.0 to 1.0")


class SimpleRAG(dspy.Module):
    """
    Basic RAG module - retrieves context and generates answer.

    This is the simplest working RAG. Use this to verify your setup works.

    Usage:
        rag = SimpleRAG(num_passages=3)
        result = rag(question="What is DSPy?")
        print(result.answer)
    """

    def __init__(self, num_passages: int = 3):
        super().__init__()
        self.num_passages = num_passages
        self.retrieve = dspy.Retrieve(k=num_passages)
        self.generate = dspy.ChainOfThought(RAGSignature)

    def forward(self, question: str) -> dspy.Prediction:
        # Retrieve relevant passages
        retrieved = self.retrieve(question)
        context = "\n\n".join(retrieved.passages)

        # Generate answer with chain-of-thought reasoning
        prediction = self.generate(context=context, question=question)

        return dspy.Prediction(
            answer=prediction.answer,
            context=context,
            passages=retrieved.passages,
        )


class RAGModule(dspy.Module):
    """
    Production RAG module with citations and confidence scoring.

    Features:
    - Chain-of-thought reasoning
    - Source citations
    - Confidence estimation
    - Handles no-context gracefully

    Usage:
        rag = RAGModule(num_passages=5)
        result = rag(question="How does authentication work?")
        print(f"Answer: {result.answer}")
        print(f"Confidence: {result.confidence}")
        print(f"Sources: {result.citations}")
    """

    def __init__(self, num_passages: int = 5, min_confidence: float = 0.3):
        super().__init__()
        self.num_passages = num_passages
        self.min_confidence = min_confidence
        self.retrieve = dspy.Retrieve(k=num_passages)
        self.generate = dspy.ChainOfThought(RAGWithCitationsSignature)

    def forward(self, question: str) -> dspy.Prediction:
        # Retrieve relevant passages
        retrieved = self.retrieve(question)

        if not retrieved.passages:
            return dspy.Prediction(
                answer="I don't have enough information to answer this question.",
                citations=[],
                confidence=0.0,
                context="",
                passages=[],
            )

        # Build context with source markers
        context_parts = []
        for i, passage in enumerate(retrieved.passages):
            context_parts.append(f"[Source {i+1}]: {passage}")
        context = "\n\n".join(context_parts)

        # Generate answer
        prediction = self.generate(context=context, question=question)

        # Ensure confidence is a float
        try:
            confidence = float(prediction.confidence)
        except (ValueError, TypeError):
            confidence = 0.5

        return dspy.Prediction(
            answer=prediction.answer,
            citations=prediction.citations if isinstance(prediction.citations, list) else [],
            confidence=min(max(confidence, 0.0), 1.0),  # Clamp to [0, 1]
            context=context,
            passages=retrieved.passages,
        )


class MultiHopSignature(dspy.Signature):
    """Generate a search query to find more information"""

    context: str = dspy.InputField(desc="Information gathered so far")
    question: str = dspy.InputField(desc="The original question")
    search_query: str = dspy.OutputField(desc="A search query to find more relevant information")


class MultiHopAnswerSignature(dspy.Signature):
    """Synthesize a final answer from multiple retrieval hops"""

    context: str = dspy.InputField(desc="All gathered information from multiple searches")
    question: str = dspy.InputField(desc="The original question")
    answer: str = dspy.OutputField(desc="A comprehensive answer synthesizing all information")
    reasoning: str = dspy.OutputField(desc="Explanation of how the answer was derived")


class MultiHopRAG(dspy.Module):
    """
    Multi-hop RAG for complex questions requiring multiple retrieval steps.

    This handles questions like:
    - "Compare the authentication systems in Project A and Project B"
    - "What are the dependencies of the feature X mentioned in doc Y?"

    Usage:
        rag = MultiHopRAG(max_hops=3)
        result = rag(question="How does the payment flow connect to the user auth?")
        print(result.answer)
        print(result.reasoning)
    """

    def __init__(self, num_passages: int = 3, max_hops: int = 3):
        super().__init__()
        self.num_passages = num_passages
        self.max_hops = max_hops
        self.retrieve = dspy.Retrieve(k=num_passages)
        self.generate_query = dspy.ChainOfThought(MultiHopSignature)
        self.generate_answer = dspy.ChainOfThought(MultiHopAnswerSignature)

    def forward(self, question: str) -> dspy.Prediction:
        # Initial retrieval
        all_passages = []
        retrieved = self.retrieve(question)
        all_passages.extend(retrieved.passages)

        # Multi-hop retrieval
        context = "\n\n".join(all_passages)
        for hop in range(self.max_hops - 1):
            # Generate follow-up query
            query_pred = self.generate_query(context=context, question=question)

            # Retrieve more information
            more_retrieved = self.retrieve(query_pred.search_query)

            # Add new unique passages
            for passage in more_retrieved.passages:
                if passage not in all_passages:
                    all_passages.append(passage)

            # Update context
            context = "\n\n".join(all_passages)

            # Early stop if we have enough context
            if len(all_passages) >= self.num_passages * 2:
                break

        # Generate final answer
        answer_pred = self.generate_answer(context=context, question=question)

        return dspy.Prediction(
            answer=answer_pred.answer,
            reasoning=answer_pred.reasoning,
            context=context,
            passages=all_passages,
            hops_used=hop + 2 if 'hop' in dir() else 1,
        )
