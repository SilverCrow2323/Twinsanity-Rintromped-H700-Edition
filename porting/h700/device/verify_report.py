#!/usr/bin/env python3
"""Verify the integrity of a previously generated H700 evidence report."""
import argparse
import json
import sys
from pathlib import Path
from validation_report import ReportError, verify_report

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("report", type=Path)
    parser.add_argument("--evidence-dir", type=Path, required=True)
    parser.add_argument("--package", type=Path)
    args = parser.parse_args()
    try:
        report = json.loads(args.report.read_text(encoding="utf-8"))
        verify_report(report, args.evidence_dir, args.package)
    except (OSError, json.JSONDecodeError, ReportError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    print("H700 evidence report: fingerprints verified")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
