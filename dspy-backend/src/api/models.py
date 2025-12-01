"""
Pydantic models for API requests and responses.

These are the contracts between your Flutter app and the DSPy backend.
"""
from __future__ import annotations

from pydantic import BaseModel, Field
from typing import Optional, Any, List, Dict
from enum import Enum


class ModelType(str, Enum):
    """Available model types"""
    GPT4O_MINI = "openai/gpt-4o-mini"
    GPT4O = "openai/gpt-4o"
    GPT4_TURBO = "openai/gpt-4-turbo"
    CLAUDE_SONNET = "anthropic/claude-3-5-sonnet-20241022"
    CLAUDE_HAIKU = "anthropic/claude-3-haiku-20240307"


class ReasoningPattern(str, Enum):
    """Available reasoning patterns"""
    BASIC = "basic"
    CHAIN_OF_THOUGHT = "chain_of_thought"
    TREE_OF_THOUGHT = "tree_of_thought"
    REACT = "react"


# ============== Chat Endpoints ==============

class ChatRequest(BaseModel):
    """Simple chat request"""
    message: str = Field(..., description="The user's message")
    model: Optional[str] = Field(None, description="Model to use (defaults to configured default)")
    system_prompt: Optional[str] = Field(None, description="Optional system prompt override")
    temperature: float = Field(0.7, ge=0, le=2, description="Temperature for generation")

    class Config:
        json_schema_extra = {
            "example": {
                "message": "What is the capital of France?",
                "model": "openai/gpt-4o-mini",
                "temperature": 0.7
            }
        }


class ChatResponse(BaseModel):
    """Chat response"""
    response: str = Field(..., description="The model's response")
    model: str = Field(..., description="Model that was used")
    reasoning: Optional[str] = Field(None, description="Reasoning if chain-of-thought was used")
    confidence: Optional[float] = Field(None, description="Confidence score if available")

    class Config:
        json_schema_extra = {
            "example": {
                "response": "The capital of France is Paris.",
                "model": "openai/gpt-4o-mini",
                "confidence": 0.95
            }
        }


# ============== RAG Endpoints ==============

class RAGRequest(BaseModel):
    """RAG (Retrieval-Augmented Generation) request"""
    question: str = Field(..., description="The question to answer")
    document_ids: Optional[list[str]] = Field(None, description="Specific documents to search")
    num_passages: int = Field(5, ge=1, le=20, description="Number of passages to retrieve")
    include_citations: bool = Field(True, description="Include source citations in response")
    model: Optional[str] = Field(None, description="Model to use")

    class Config:
        json_schema_extra = {
            "example": {
                "question": "How does the authentication system work?",
                "num_passages": 5,
                "include_citations": True
            }
        }


class RAGSource(BaseModel):
    """A source document used in RAG response"""
    document_id: str
    title: str
    excerpt: str
    relevance_score: float


class RAGResponse(BaseModel):
    """RAG response with sources"""
    answer: str = Field(..., description="The generated answer")
    sources: list[RAGSource] = Field(default_factory=list, description="Sources used")
    confidence: float = Field(..., description="Confidence in the answer")
    model: str = Field(..., description="Model that was used")
    passages_used: int = Field(..., description="Number of passages retrieved")

    class Config:
        json_schema_extra = {
            "example": {
                "answer": "The authentication system uses JWT tokens...",
                "sources": [
                    {
                        "document_id": "doc_123",
                        "title": "Auth Guide",
                        "excerpt": "JWT tokens are used for...",
                        "relevance_score": 0.92
                    }
                ],
                "confidence": 0.88,
                "model": "openai/gpt-4o-mini",
                "passages_used": 3
            }
        }


# ============== Agent Endpoints ==============

class ToolDefinition(BaseModel):
    """Definition of a tool the agent can use"""
    name: str = Field(..., description="Tool name")
    description: str = Field(..., description="What the tool does")


class AgentRequest(BaseModel):
    """Agent request for task execution"""
    task: str = Field(..., description="The task to perform")
    tools: list[ToolDefinition] = Field(default_factory=list, description="Available tools")
    max_iterations: int = Field(5, ge=1, le=20, description="Maximum reasoning iterations")
    model: Optional[str] = Field(None, description="Model to use")

    class Config:
        json_schema_extra = {
            "example": {
                "task": "Calculate 25 * 4 + 100 and explain the steps",
                "tools": [
                    {"name": "calculator", "description": "Evaluate math expressions"}
                ],
                "max_iterations": 5
            }
        }


class AgentStep(BaseModel):
    """A single step in agent execution"""
    iteration: int
    thought: str
    action: str
    observation: Optional[str] = None


class AgentResponse(BaseModel):
    """Agent response with execution trace"""
    answer: str = Field(..., description="Final answer")
    success: bool = Field(..., description="Whether the task was completed successfully")
    steps: list[AgentStep] = Field(default_factory=list, description="Execution trace")
    iterations_used: int = Field(..., description="Number of iterations used")
    model: str = Field(..., description="Model that was used")

    class Config:
        json_schema_extra = {
            "example": {
                "answer": "The result is 200",
                "success": True,
                "steps": [
                    {
                        "iteration": 1,
                        "thought": "I need to calculate 25 * 4 first",
                        "action": "calculator: 25 * 4",
                        "observation": "100"
                    }
                ],
                "iterations_used": 2,
                "model": "openai/gpt-4o-mini"
            }
        }


# ============== Reasoning Endpoints ==============

class ReasoningRequest(BaseModel):
    """Reasoning request with pattern selection"""
    question: str = Field(..., description="The question to reason about")
    pattern: ReasoningPattern = Field(
        ReasoningPattern.CHAIN_OF_THOUGHT,
        description="Reasoning pattern to use"
    )
    model: Optional[str] = Field(None, description="Model to use")
    num_branches: int = Field(3, ge=2, le=5, description="Branches for tree-of-thought")

    class Config:
        json_schema_extra = {
            "example": {
                "question": "Should we use microservices or monolith for a new startup?",
                "pattern": "tree_of_thought",
                "num_branches": 3
            }
        }


class ReasoningResponse(BaseModel):
    """Reasoning response with full trace"""
    answer: str = Field(..., description="Final answer")
    reasoning: str = Field(..., description="Reasoning trace")
    confidence: float = Field(..., description="Confidence in the answer")
    pattern_used: str = Field(..., description="Reasoning pattern that was used")
    model: str = Field(..., description="Model that was used")
    branches: Optional[list[dict]] = Field(None, description="Branches for tree-of-thought")


# ============== Document Management ==============

class DocumentUploadRequest(BaseModel):
    """Upload a document for RAG"""
    title: str = Field(..., description="Document title")
    content: str = Field(..., description="Document content")
    metadata: dict[str, Any] = Field(default_factory=dict, description="Additional metadata")


class DocumentUploadResponse(BaseModel):
    """Response after document upload"""
    document_id: str
    title: str
    chunks_created: int
    message: str


class DocumentListResponse(BaseModel):
    """List of documents in the system"""
    documents: list[dict]
    total_count: int


# ============== Health & Status ==============

class HealthResponse(BaseModel):
    """Health check response"""
    status: str
    version: str
    models_available: list[str]
    vector_db_status: str
    documents_indexed: int


class OptimizationStatus(BaseModel):
    """Status of prompt optimization"""
    module: str
    optimized: bool
    examples_used: int
    accuracy_improvement: Optional[float] = None
