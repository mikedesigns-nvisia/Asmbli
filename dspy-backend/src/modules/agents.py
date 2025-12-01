"""
Agent Modules - ReAct and Tool-Using Agents

These are WORKING agent implementations that can actually use tools.
"""
from __future__ import annotations

import dspy
from typing import Callable, Any
import json


class ReActSignature(dspy.Signature):
    """ReAct agent signature for reasoning and acting"""

    question: str = dspy.InputField(desc="The task or question to solve")
    trajectory: str = dspy.InputField(desc="Previous thoughts, actions, and observations")
    next_thought: str = dspy.OutputField(desc="Reasoning about what to do next")
    next_action: str = dspy.OutputField(desc="The action to take (tool_name: arguments) or 'finish: answer'")


class Tool:
    """
    A tool that can be used by agents.

    Usage:
        def search(query: str) -> str:
            return f"Results for {query}..."

        search_tool = Tool(
            name="search",
            description="Search for information",
            func=search
        )
    """

    def __init__(self, name: str, description: str, func: Callable[..., str]):
        self.name = name
        self.description = description
        self.func = func

    def execute(self, *args, **kwargs) -> str:
        """Execute the tool and return result as string"""
        try:
            result = self.func(*args, **kwargs)
            return str(result)
        except Exception as e:
            return f"Error executing {self.name}: {str(e)}"

    def __repr__(self) -> str:
        return f"Tool({self.name}: {self.description})"


class ReActAgent(dspy.Module):
    """
    ReAct Agent - Reasoning + Acting in a loop.

    This is a WORKING agent that:
    1. Thinks about the problem
    2. Decides on an action (use a tool or finish)
    3. Observes the result
    4. Repeats until done

    Usage:
        # Define tools
        def calculator(expression: str) -> str:
            return str(eval(expression))

        def search(query: str) -> str:
            return "Search results..."

        tools = [
            Tool("calculator", "Evaluate math expressions", calculator),
            Tool("search", "Search for information", search),
        ]

        agent = ReActAgent(tools=tools, max_iterations=5)
        result = agent(question="What is 25 * 4 + 100?")
        print(result.answer)
        print(result.trajectory)  # See the agent's reasoning
    """

    def __init__(self, tools: list[Tool], max_iterations: int = 5):
        super().__init__()
        self.tools = {tool.name: tool for tool in tools}
        self.max_iterations = max_iterations
        self.react = dspy.ChainOfThought(ReActSignature)

        # Build tool descriptions for the prompt
        self.tool_descriptions = "\n".join([
            f"- {tool.name}: {tool.description}"
            for tool in tools
        ])

    def _parse_action(self, action: str) -> tuple[str, str]:
        """Parse action string into (tool_name, arguments)"""
        action = action.strip()

        # Check for finish action
        if action.lower().startswith("finish:"):
            return "finish", action[7:].strip()

        # Parse tool:arguments format
        if ":" in action:
            parts = action.split(":", 1)
            return parts[0].strip().lower(), parts[1].strip()

        return action.lower(), ""

    def forward(self, question: str) -> dspy.Prediction:
        trajectory = f"Available tools:\n{self.tool_descriptions}\n\n"
        trajectory += f"Question: {question}\n\n"

        for iteration in range(self.max_iterations):
            # Get next thought and action
            pred = self.react(question=question, trajectory=trajectory)

            thought = pred.next_thought
            action = pred.next_action

            trajectory += f"Thought {iteration + 1}: {thought}\n"
            trajectory += f"Action {iteration + 1}: {action}\n"

            # Parse the action
            tool_name, arguments = self._parse_action(action)

            # Check if agent wants to finish
            if tool_name == "finish":
                return dspy.Prediction(
                    answer=arguments,
                    trajectory=trajectory,
                    iterations=iteration + 1,
                    success=True,
                )

            # Execute the tool
            if tool_name in self.tools:
                observation = self.tools[tool_name].execute(arguments)
            else:
                observation = f"Unknown tool: {tool_name}. Available: {list(self.tools.keys())}"

            trajectory += f"Observation {iteration + 1}: {observation}\n\n"

        # Max iterations reached
        return dspy.Prediction(
            answer="Could not complete the task within the iteration limit.",
            trajectory=trajectory,
            iterations=self.max_iterations,
            success=False,
        )


class CodeSignature(dspy.Signature):
    """Generate code to solve a problem"""

    task: str = dspy.InputField(desc="Description of what the code should do")
    language: str = dspy.InputField(desc="Programming language to use")
    code: str = dspy.OutputField(desc="The generated code")
    explanation: str = dspy.OutputField(desc="Explanation of how the code works")


class CodeAgent(dspy.Module):
    """
    Code Generation Agent

    Generates code with explanations. Can optionally execute Python code
    to verify it works.

    Usage:
        agent = CodeAgent(execute_python=True)
        result = agent(
            task="Write a function to calculate fibonacci numbers",
            language="python"
        )
        print(result.code)
        print(result.explanation)
        if result.execution_result:
            print(result.execution_result)
    """

    def __init__(self, execute_python: bool = False):
        super().__init__()
        self.execute_python = execute_python
        self.generate = dspy.ChainOfThought(CodeSignature)

    def _safe_execute(self, code: str) -> str:
        """Safely execute Python code and return output"""
        if not self.execute_python:
            return ""

        try:
            # Create a restricted namespace
            namespace = {"__builtins__": {"print": print, "range": range, "len": len}}

            # Capture output
            import io
            import sys
            old_stdout = sys.stdout
            sys.stdout = captured = io.StringIO()

            exec(code, namespace)

            sys.stdout = old_stdout
            return captured.getvalue() or "Code executed successfully (no output)"
        except Exception as e:
            return f"Execution error: {str(e)}"

    def forward(self, task: str, language: str = "python") -> dspy.Prediction:
        # Generate code
        pred = self.generate(task=task, language=language)

        result = dspy.Prediction(
            code=pred.code,
            explanation=pred.explanation,
            language=language,
        )

        # Optionally execute Python code
        if language.lower() == "python" and self.execute_python:
            result.execution_result = self._safe_execute(pred.code)

        return result


# Pre-built tools for common use cases
def create_calculator_tool() -> Tool:
    """Calculator tool for math expressions"""
    def calculate(expression: str) -> str:
        try:
            # Safe eval for math only
            allowed = set("0123456789+-*/().^ ")
            if not all(c in allowed for c in expression):
                return "Invalid expression"
            result = eval(expression.replace("^", "**"))
            return str(result)
        except Exception as e:
            return f"Error: {str(e)}"

    return Tool("calculator", "Evaluate mathematical expressions", calculate)


def create_json_tool() -> Tool:
    """JSON parsing tool"""
    def parse_json(json_str: str) -> str:
        try:
            data = json.loads(json_str)
            return json.dumps(data, indent=2)
        except Exception as e:
            return f"Invalid JSON: {str(e)}"

    return Tool("json_parser", "Parse and format JSON data", parse_json)
