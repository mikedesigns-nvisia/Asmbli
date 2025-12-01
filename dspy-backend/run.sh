#!/bin/bash
# DSPy Backend Runner
#
# Usage:
#   ./run.sh                           # Uses ANTHROPIC_API_KEY from environment
#   ANTHROPIC_API_KEY=sk-... ./run.sh  # Pass key inline
#
# The server will start at http://localhost:8000
# Health check: curl http://localhost:8000/health

set -e

cd "$(dirname "$0")"

# Activate virtual environment
source venv/bin/activate

# Check for API keys
if [ -z "$ANTHROPIC_API_KEY" ] && [ -z "$OPENAI_API_KEY" ]; then
    echo "Error: No API key found."
    echo ""
    echo "Set one of these environment variables:"
    echo "  export ANTHROPIC_API_KEY='your-key'"
    echo "  export OPENAI_API_KEY='your-key'"
    echo ""
    echo "Or run with key inline:"
    echo "  ANTHROPIC_API_KEY='your-key' ./run.sh"
    exit 1
fi

echo "Starting DSPy backend..."
echo "Server: http://localhost:8000"
echo "Health: http://localhost:8000/health"
echo "Docs:   http://localhost:8000/docs"
echo ""

python main.py
