#!/usr/bin/env python3
"""Rebuild trimmed SingleStepTests 65x02 JSON fixtures (official NMOS opcodes only).

Reads opcode hex literals from scripts/cpu_6502.gd _build_opcode_table block,
downloads https://github.com/SingleStepTests/65x02 (MIT), skips ADC/SBC cases with
decimal mode set (D=1) because BASIC6502's CPU core is binary-only for ADC/SBC.

Run from repo root: python3 tests/fixtures/processor_tests/build_subset.py
"""
from __future__ import annotations

import json
import os
import re
import urllib.request

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
CPU_GD = os.path.join(REPO_ROOT, "scripts", "cpu_6502.gd")
OUT_DIR = os.path.join(os.path.dirname(__file__), "v1")
LICENSE_OUT = os.path.join(os.path.dirname(__file__), "LICENSE.processor_tests")
BASE_URL = "https://raw.githubusercontent.com/SingleStepTests/65x02/main/6502/v1"

TESTS_PER_OPCODE = 10

DECIMAL_ADC_SBC = {
    0x69,
    0x65,
    0x75,
    0x6D,
    0x7D,
    0x79,
    0x61,
    0x71,
    0xE9,
    0xE5,
    0xF5,
    0xED,
    0xFD,
    0xF9,
    0xE1,
    0xF1,
}


def opcode_bytes_from_cpu_gd(path: str) -> list[int]:
    with open(path, encoding="utf-8") as f:
        lines = f.readlines()
    ins = outs = None
    for i, ln in enumerate(lines):
        if "var opcodes = {" in ln:
            ins = i
            continue
        if ins is not None and outs is None:
            if ln.strip().startswith("}") and "for opcode in opcodes" in lines[i + 1]:
                outs = i
                break
    if ins is None or outs is None:
        raise RuntimeError("Could not locate opcode table in cpu_6502.gd")
    block = "".join(lines[ins : outs + 1])
    hexes = {int(x, 16) for x in re.findall(r"0x[0-9A-Fa-f]{2}", block)}
    return sorted(hexes)


def trim_tests(raw_list: list) -> list:
    kept = []
    for t in raw_list:
        ini = t["initial"]
        p = ini["p"]
        pc = ini["pc"]
        opc_at_pc = None
        for addr, val in ini["ram"]:
            if addr == pc:
                opc_at_pc = val
                break
        if opc_at_pc is None:
            continue
        if opc_at_pc in DECIMAL_ADC_SBC and (p & 0x08):
            continue
        kept.append(t)
        if len(kept) >= TESTS_PER_OPCODE:
            break
    return kept


def main() -> None:
    opcoded = opcode_bytes_from_cpu_gd(CPU_GD)
    os.makedirs(OUT_DIR, exist_ok=True)
    total = 0
    for opc in opcoded:
        fn = f"{opc:02x}.json"
        url = f"{BASE_URL}/{fn}"
        with urllib.request.urlopen(url) as resp:
            data = json.load(resp)
        trimmed = trim_tests(data)
        outp = os.path.join(OUT_DIR, fn)
        with open(outp, "w", encoding="utf-8") as wf:
            json.dump(trimmed, wf, separators=(",", ":"))
        total += len(trimmed)
    urllib.request.urlretrieve(
        "https://raw.githubusercontent.com/SingleStepTests/65x02/main/LICENSE",
        LICENSE_OUT,
    )
    print(f"Opcodes: {len(opcoded)}, trimmed tests written: {total}, dir: {OUT_DIR}")


if __name__ == "__main__":
    main()
