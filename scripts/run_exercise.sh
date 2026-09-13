#!/usr/bin/env bash
# Compiles and runs the testbench for one exercise, then reports PASS/FAIL.
# Usage: scripts/run_exercise.sh ex01
set -uo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <exercise-dir, e.g. ex01>"
  exit 2
fi

EX="$1"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EX_DIR="$ROOT_DIR/exercises/$EX"

if [ ! -d "$EX_DIR" ]; then
  echo "No such exercise: $EX_DIR"
  exit 2
fi

cd "$EX_DIR" || exit 2

SRC_FILES=$(find src -name '*.v' | sort)
TEST_FILES=$(find test -name '*.v' | sort)

if [ -z "$TEST_FILES" ]; then
  echo "No testbench files found in $EX_DIR/test"
  exit 2
fi

echo "== Compiling $EX =="
iverilog -g2012 -o sim.out $SRC_FILES $TEST_FILES
COMPILE_STATUS=$?

if [ $COMPILE_STATUS -ne 0 ]; then
  echo ""
  echo "RESULT: FAIL (compile error) -- see messages above."
  exit 1
fi

echo "== Simulating $EX =="
OUTPUT=$(vvp sim.out)
echo "$OUTPUT"

if echo "$OUTPUT" | grep -q "RESULT: PASS"; then
  exit 0
else
  echo ""
  echo "RESULT: FAIL -- see check messages above for which cases failed."
  exit 1
fi
