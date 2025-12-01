#!/usr/bin/env python3
"""
Quick test script to verify DSPy is working.

Run with:
    python tests/test_quick.py

This tests the core functionality without needing the full server.
"""

import os
import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from dotenv import load_dotenv
load_dotenv()


def test_dspy_basic():
    """Test basic DSPy functionality"""
    print("=" * 60)
    print("🧪 Testing DSPy Basic Functionality")
    print("=" * 60)

    import dspy

    # Check for API key
    api_key = os.getenv("OPENAI_API_KEY") or os.getenv("ANTHROPIC_API_KEY")
    if not api_key:
        print("❌ No API key found. Set OPENAI_API_KEY or ANTHROPIC_API_KEY")
        return False

    # Determine model
    if os.getenv("OPENAI_API_KEY"):
        model = "openai/gpt-4o-mini"
    else:
        model = "anthropic/claude-3-haiku-20240307"

    print(f"✅ Using model: {model}")

    # Configure DSPy
    lm = dspy.LM(model)
    dspy.configure(lm=lm)
    print("✅ DSPy configured")

    # Test 1: Simple prediction
    print("\n📝 Test 1: Simple Prediction")
    predict = dspy.Predict("question -> answer")
    result = predict(question="What is 2 + 2?")
    print(f"   Question: What is 2 + 2?")
    print(f"   Answer: {result.answer}")
    assert "4" in result.answer, "Basic math failed"
    print("   ✅ PASSED")

    # Test 2: Chain of Thought
    print("\n📝 Test 2: Chain of Thought")
    cot = dspy.ChainOfThought("question -> answer")
    result = cot(question="If I have 3 apples and buy 5 more, then give away 2, how many do I have?")
    print(f"   Question: 3 + 5 - 2 apples")
    print(f"   Reasoning: {getattr(result, 'reasoning', 'N/A')[:100]}...")
    print(f"   Answer: {result.answer}")
    assert "6" in result.answer, "Chain of thought failed"
    print("   ✅ PASSED")

    # Test 3: Structured Output
    print("\n📝 Test 3: Structured Output")

    class AnalysisSignature(dspy.Signature):
        text: str = dspy.InputField()
        sentiment: str = dspy.OutputField(desc="positive, negative, or neutral")
        confidence: float = dspy.OutputField(desc="0.0 to 1.0")

    analyze = dspy.Predict(AnalysisSignature)
    result = analyze(text="I love this product! It's amazing!")
    print(f"   Text: 'I love this product! It's amazing!'")
    print(f"   Sentiment: {result.sentiment}")
    print(f"   Confidence: {result.confidence}")
    assert "positive" in result.sentiment.lower(), "Sentiment analysis failed"
    print("   ✅ PASSED")

    print("\n" + "=" * 60)
    print("🎉 All basic tests passed!")
    print("=" * 60)
    return True


def test_modules():
    """Test custom modules"""
    print("\n" + "=" * 60)
    print("🧪 Testing Custom Modules")
    print("=" * 60)

    import dspy
    from src.modules.reasoning import ChainOfThoughtModule, TreeOfThoughtModule
    from src.modules.agents import ReActAgent, Tool, create_calculator_tool

    # Check for API key
    api_key = os.getenv("OPENAI_API_KEY") or os.getenv("ANTHROPIC_API_KEY")
    if not api_key:
        print("❌ No API key found")
        return False

    model = "openai/gpt-4o-mini" if os.getenv("OPENAI_API_KEY") else "anthropic/claude-3-haiku-20240307"
    lm = dspy.LM(model)
    dspy.configure(lm=lm)

    # Test CoT Module
    print("\n📝 Test 1: Chain of Thought Module")
    cot = ChainOfThoughtModule()
    result = cot(question="What are the prime factors of 12?")
    print(f"   Question: Prime factors of 12")
    print(f"   Reasoning: {result.reasoning[:150]}...")
    print(f"   Answer: {result.answer}")
    print(f"   Confidence: {result.confidence}")
    print("   ✅ PASSED")

    # Test ReAct Agent
    print("\n📝 Test 2: ReAct Agent with Calculator")
    calc_tool = create_calculator_tool()
    agent = ReActAgent(tools=[calc_tool], max_iterations=3)
    result = agent(question="What is 15 * 8 + 45?")
    print(f"   Task: Calculate 15 * 8 + 45")
    print(f"   Answer: {result.answer}")
    print(f"   Iterations: {result.iterations}")
    print(f"   Success: {result.success}")
    assert "165" in result.answer, f"Calculator agent failed, got: {result.answer}"
    print("   ✅ PASSED")

    print("\n" + "=" * 60)
    print("🎉 All module tests passed!")
    print("=" * 60)
    return True


def test_api_endpoints():
    """Test API endpoints (requires server running)"""
    print("\n" + "=" * 60)
    print("🧪 Testing API Endpoints")
    print("=" * 60)

    import httpx

    base_url = "http://localhost:8000"

    try:
        # Health check
        print("\n📝 Test 1: Health Check")
        resp = httpx.get(f"{base_url}/health", timeout=10)
        assert resp.status_code == 200
        data = resp.json()
        print(f"   Status: {data['status']}")
        print(f"   Models: {data['models_available']}")
        print("   ✅ PASSED")

        # Chat endpoint
        print("\n📝 Test 2: Chat Endpoint")
        resp = httpx.post(
            f"{base_url}/chat",
            json={"message": "What is the capital of Japan?"},
            timeout=30,
        )
        assert resp.status_code == 200
        data = resp.json()
        print(f"   Response: {data['response'][:100]}...")
        assert "tokyo" in data['response'].lower()
        print("   ✅ PASSED")

        # Reasoning endpoint
        print("\n📝 Test 3: Reasoning Endpoint")
        resp = httpx.post(
            f"{base_url}/reasoning",
            json={
                "question": "Should I use a database or file storage for user sessions?",
                "pattern": "chain_of_thought"
            },
            timeout=30,
        )
        assert resp.status_code == 200
        data = resp.json()
        print(f"   Pattern: {data['pattern_used']}")
        print(f"   Answer: {data['answer'][:100]}...")
        print(f"   Confidence: {data['confidence']}")
        print("   ✅ PASSED")

        # Agent endpoint
        print("\n📝 Test 4: Agent Endpoint")
        resp = httpx.post(
            f"{base_url}/agent/execute",
            json={
                "task": "Calculate 25 * 4",
                "max_iterations": 3,
            },
            timeout=60,
        )
        assert resp.status_code == 200
        data = resp.json()
        print(f"   Answer: {data['answer']}")
        print(f"   Success: {data['success']}")
        print(f"   Iterations: {data['iterations_used']}")
        print("   ✅ PASSED")

        print("\n" + "=" * 60)
        print("🎉 All API tests passed!")
        print("=" * 60)
        return True

    except httpx.ConnectError:
        print("❌ Could not connect to server. Is it running?")
        print("   Start with: python main.py")
        return False
    except Exception as e:
        print(f"❌ Test failed: {e}")
        return False


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Test DSPy Backend")
    parser.add_argument("--basic", action="store_true", help="Run basic DSPy tests only")
    parser.add_argument("--modules", action="store_true", help="Run module tests")
    parser.add_argument("--api", action="store_true", help="Run API tests (requires server)")
    parser.add_argument("--all", action="store_true", help="Run all tests")

    args = parser.parse_args()

    # Default to basic if no args
    if not any([args.basic, args.modules, args.api, args.all]):
        args.basic = True

    results = []

    if args.basic or args.all:
        results.append(("Basic", test_dspy_basic()))

    if args.modules or args.all:
        results.append(("Modules", test_modules()))

    if args.api or args.all:
        results.append(("API", test_api_endpoints()))

    # Summary
    print("\n" + "=" * 60)
    print("📊 Test Summary")
    print("=" * 60)
    for name, passed in results:
        status = "✅ PASSED" if passed else "❌ FAILED"
        print(f"   {name}: {status}")

    all_passed = all(p for _, p in results)
    sys.exit(0 if all_passed else 1)
