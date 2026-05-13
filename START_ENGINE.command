#!/bin/bash
# Move to the directory where this script is located
cd "$(dirname "$0")"

echo "======================================================"
echo "    BLACKSWAN NOVA - Monte Carlo Risk Engine          "
echo "======================================================"
echo "Starting Backend Server..."

# Free up port 8000 if it's already in use
PIDS=$(lsof -t -i :8000)
if [ ! -z "$PIDS" ]; then
    echo "Found existing process on port 8000. Terminating to prevent port conflicts..."
    kill -9 $PIDS
fi

# Activate virtual environment if it exists
if [ -d "venv" ]; then
    source venv/bin/activate
fi

# Start the FastAPI backend
cd backend
uvicorn main:app --port 8000 &
BACKEND_PID=$!

echo "Backend started on http://localhost:8000 (PID: $BACKEND_PID)"

# Wait a few seconds to ensure the server is up
sleep 2

# Open the intro page in the default web browser
cd ..
echo "Opening BLACKSWAN NOVA Frontend..."
open "intro.html"

echo "======================================================"
echo "Engine is running. Keep this terminal window open."
echo "Press Ctrl+C to stop the engine and close."
echo "======================================================"

# Handle termination to kill the backend process when the terminal is closed
trap "kill $BACKEND_PID; exit" INT TERM EXIT

# Wait for user to terminate the script
wait $BACKEND_PID
