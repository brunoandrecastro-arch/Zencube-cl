#!/usr/bin/env python3
"""Run every existing CI regression, including UI/final checks, on Godot 4.5.1.

Each Godot process has disposable user data, so tests never touch a player's saves.
No UI branch condition can silently skip a check in the Play release audit.
"""
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "build/release-checks"
GODOT = os.environ.get("GODOT", "godot")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    version = subprocess.check_output([GODOT, "--version"], text=True).strip()
    assert version.startswith("4.5.1.stable."), "Exact Godot 4.5.1 required"
    subprocess.run([sys.executable, "scripts/check_play_release.py"], cwd=ROOT, check=True)
    subprocess.run([GODOT, "--headless", "--editor", "--import", "--quit"], cwd=ROOT, check=True)
    workflow = (ROOT / ".github/workflows/android.yml").read_text()
    tests = list(dict.fromkeys(re.findall(r"(?:python3 |--script )(tests/[\w]+\.(?:py|gd))", workflow)))
    tests.append("tests/test_play_save_compatibility.gd")
    results = []
    for index, path in enumerate(tests, 1):
        start = time.monotonic()
        command = [sys.executable, path] if path.endswith(".py") else [GODOT, "--headless", "--path", ".", "--script", path]
        with tempfile.TemporaryDirectory(prefix="zencube-release-save-") as user_dir:
            environment = {**os.environ, "XDG_DATA_HOME": user_dir}
            try:
                run = subprocess.run(command, cwd=ROOT, env=environment, text=True, stdout=subprocess.PIPE,
                                     stderr=subprocess.STDOUT, timeout=140)
                log, code = run.stdout, run.returncode
            except subprocess.TimeoutExpired as error:
                log, code = str(error.stdout), 124
        (OUT / (Path(path).stem + ".log")).write_text(log)
        script_error = bool(re.search(r"SCRIPT ERROR:|Parse Error:|Failed to load script", log))
        status = "passed" if code == 0 and not script_error else "failed"
        results.append({"test": path, "status": status, "exit_code": code,
                        "seconds": round(time.monotonic() - start, 2),
                        "exit_resource_warning": "still in use at exit" in log or "ObjectDB instances leaked" in log})
        print(f"[{index}/{len(tests)}] {status.upper()} {path}", flush=True)
        if status == "failed":
            print(log[-7000:], flush=True)
    # Keep the existing tactical simulator as part of the Play gate as well.
    start = time.monotonic()
    simulator = OUT / "zencube-sim"
    compiled = subprocess.run(["g++", "-O3", "-std=c++17", "tests/simulate.cpp", "-o", str(simulator)],
                              cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=90)
    simulation = None
    if compiled.returncode == 0:
        simulation = subprocess.run([str(simulator), "reports/lines.json"], cwd=ROOT, text=True,
                                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=90)
    code = compiled.returncode if simulation is None else simulation.returncode
    log = compiled.stdout + (simulation.stdout if simulation is not None else "")
    (OUT / "tactical-simulation.json").write_text(log)
    games = sum(batch["games"] for batch in json.loads(simulation.stdout)["batches"]) if code == 0 else 0
    results.append({"test": "tests/simulate.cpp", "status": "passed" if code == 0 and games == 10000 else "failed",
                    "exit_code": code, "games": games, "seconds": round(time.monotonic() - start, 2)})
    simulator.unlink(missing_ok=True)
    print(f"Tactical simulation: {games} games, {results[-1]['status']}", flush=True)
    summary = {"godot": version, "source_commit": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
               "passed": sum(row["status"] == "passed" for row in results),
               "failed": sum(row["status"] == "failed" for row in results), "checks": results}
    (OUT / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    print(f"Release checks: {summary['passed']} passed, {summary['failed']} failed")
    return 1 if summary["failed"] else 0


if __name__ == "__main__":
    sys.exit(main())
