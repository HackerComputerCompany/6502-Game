#!/usr/bin/env bash
## Run every automated suite: regression, 65x02 JSON step tests, CLI smoke, fuzz smoke.
## Usage:
##   ./scripts/run_all_tests.sh
##   FUZZ_ITERS=2000 FUZZ_SEED=99 ./scripts/run_all_tests.sh
##   GODOT=/Applications/Godot.app/Contents/MacOS/Godot ./scripts/run_all_tests.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

GODOT="${GODOT:-godot}"
FUZZ_ITERS="${FUZZ_ITERS:-400}"
FUZZ_SEED="${FUZZ_SEED:-42}"

run() {
	echo ""
	echo "==> $*"
	echo ""
}

run "$GODOT --path \"$ROOT\" --headless -s tests/test_regression.gd"
"$GODOT" --path "$ROOT" --headless -s tests/test_regression.gd

run "$GODOT --path \"$ROOT\" --headless -s tests/test_processor_step_tests.gd"
"$GODOT" --path "$ROOT" --headless -s tests/test_processor_step_tests.gd

run "$GODOT --path \"$ROOT\" --headless -s tests/test_cli.gd"
"$GODOT" --path "$ROOT" --headless -s tests/test_cli.gd

run "$GODOT ... test_fuzz_smoke.gd -- --fuzz-iters=$FUZZ_ITERS --fuzz-seed=$FUZZ_SEED"
"$GODOT" --path "$ROOT" --headless -s tests/test_fuzz_smoke.gd -- --fuzz-iters="$FUZZ_ITERS" --fuzz-seed="$FUZZ_SEED"

echo ""
echo "=== All test suites finished successfully ==="
echo "    (regression + 65x02 step + CLI + fuzz  iters=$FUZZ_ITERS seed=$FUZZ_SEED)"
