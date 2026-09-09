#!/usr/bin/env python3
import subprocess
import atexit
import os

_process = None

def stress_start():
    global _process
    if _process is None:
        # 🧬 DYNAMIC HARDWARE DETECTION: Automatically grabs the host system's exact thread count (12 or 16)
        # 🧬 BAZZITE COMPATIBILITY FILTER: Targets stress-ng cleanly to match your layered package architecture
        thread_count = str(os.cpu_count() or 12)
        _process = subprocess.Popen(
            ["stress-ng", "--cpu", thread_count],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )

def stress_stop():
    global _process
    if _process:
        _process.terminate()
        try:
            _process.wait(timeout=2)
        except subprocess.TimeoutExpired:
            _process.kill()
        _process = None

atexit.register(stress_stop)
