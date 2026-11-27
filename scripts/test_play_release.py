#!/usr/bin/env python3
"""Run every repository regression with the release profile and isolated saves."""
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import json
import os
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
TESTS = ROOT / "tests"
LOGS = ROOT / "build" / "release-tests"


def run(test):
    with tempfile.TemporaryDirectory(prefix="zencube-test-") as profile:
        env = os.environ.copy()
        for key in ("XDG_DATA_HOME", "XDG_CONFIG_HOME", "XDG_CACHE_HOME"):
            env[key] = str(Path(profile) / key)
        command = [sys.executable, str(test)] if test.suffix == ".py" else [
            env["GODOT"], "--headless", "--audio-driver", "Dummy", "--path", str(ROOT), "--script", str(test)
        ]
        try:
            proc = subprocess.run(command, cwd=ROOT, env=env, stdout=subprocess.PIPE,
                                  stderr=subprocess.STDOUT, timeout=180)
            output, code = proc.stdout, proc.returncode
        except subprocess.TimeoutExpired as error:
            output, code = error.stdout or b"", 124
    (LOGS / (test.name + ".log")).write_bytes(output)
    # A GDScript runtime error can occur even when a test exits with zero.
    fatal = b"SCRIPT ERROR:" in output or b"Parse Error:" in output
    print(f"{test.name} {code}" + (" [script error]" if fatal else ""), flush=True)
    return {"test": test.name, "exit": code, "script_error": fatal}


def main():
    LOGS.mkdir(parents=True, exist_ok=True)
    paths = (sorted(TESTS.glob("test_*.py"))
             + sorted(set(TESTS.glob("test_*.gd")) | set(TESTS.glob("*_test.gd"))))
    if not paths or not os.environ.get("GODOT"):
        raise SystemExit("Set GODOT to the Godot 4.5.1 binary and run from the complete source tree.")
    with ThreadPoolExecutor(max_workers=3) as pool:
        results = list(pool.map(run, paths))
    (LOGS / "results.json").write_text(json.dumps(results, indent=2))
    with tempfile.TemporaryDirectory(prefix="zencube-sim-") as directory:
        executable = str(Path(directory) / "simulate")
        subprocess.run(["g++", "-O3", "-std=c++17", str(TESTS / "simulate.cpp"), "-o", executable], check=True)
        with (LOGS / "simulation.json").open("w") as log:
            subprocess.run([executable, str(ROOT / "reports/lines.json")], check=True, stdout=log)
    return int(any(item["exit"] or item["script_error"] for item in results))


if __name__ == "__main__":
    raise SystemExit(main())
