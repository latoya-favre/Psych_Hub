"""Tkinter GUI for Optimization Engine Parts A and B."""
from __future__ import annotations

import contextlib
import importlib.util
import os
import queue
import sys
import threading
import time
import traceback
from pathlib import Path
import tkinter as tk
from tkinter import filedialog, messagebox, scrolledtext, ttk


def resource_path(relative):
    return Path(getattr(sys, "_MEIPASS", Path(__file__).resolve().parent)) / relative


def source_project():
    return Path(__file__).resolve().parents[1]


class QueueWriter:
    def __init__(self, messages):
        self.messages = messages
        self.buffer = ""

    def write(self, value):
        self.buffer += str(value)
        while "\n" in self.buffer:
            line, self.buffer = self.buffer.split("\n", 1)
            if line.strip():
                self.messages.put(line)
        return len(value)

    def flush(self):
        if self.buffer.strip():
            self.messages.put(self.buffer.strip())
        self.buffer = ""


class FileRow(ttk.Frame):
    def __init__(self, parent, label, variable, command):
        super().__init__(parent)
        ttk.Label(self, text=label).pack(anchor="w")
        row = ttk.Frame(self)
        row.pack(fill="x", pady=(2, 0))
        ttk.Entry(row, textvariable=variable).pack(side="left", fill="x", expand=True)
        ttk.Button(row, text="Browse...", command=command).pack(side="left", padx=(8, 0))


class OptimizationGUI:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("Stratification Optimization Engine")
        self.root.geometry("900x780")
        self.root.minsize(780, 680)
        self.messages = queue.Queue()
        self.busy = False
        self._variables()
        self._build()
        self.root.after(100, self._drain)
        self.root.mainloop()

    def _variables(self):
        project = source_project() if not getattr(sys, "frozen", False) else Path.home()
        self.master = tk.StringVar(value=str(project / "outputs/deliverables/12aug26/basc4nb_adhd_final_teids_12aug26.xlsx"))
        self.master_sheet = tk.StringVar(value="teid_list")
        self.scored = tk.StringVar(value=str(project / "data_raw/source_sas_data/ADHD"))
        self.swaps = tk.StringVar(value=str(project / "outputs/deliverables/12aug26"))
        self.targets_a = tk.StringVar(value=str(project / "documentation/Demo and OSEP Targets Template.xlsx"))
        self.output_a = tk.StringVar(value=str(project / "outputs/optimization_engine_part_a"))
        self.part_a_file = tk.StringVar(value=str(Path(self.output_a.get()) / "Optimization_Engine_Part_A_prep_output_latest.xlsx"))
        self.targets_b = tk.StringVar(value=self.targets_a.get())
        self.output_b = tk.StringVar(value=str(project / "outputs/optimization_engine_part_b"))
        self.solver_seconds = tk.IntVar(value=300)
        self.forced_swap = tk.StringVar()

    def _build(self):
        ttk.Label(self.root, text="Stratification Optimization Engine", font=("Segoe UI", 16, "bold")).pack(pady=(14, 2))
        ttk.Label(self.root, text="Prepare optimization inputs in Part A, then generate final deliverables in Part B.").pack(pady=(0, 10))
        book = ttk.Notebook(self.root)
        book.pack(fill="both", expand=True, padx=16, pady=(0, 10))
        a = ttk.Frame(book, padding=14)
        b = ttk.Frame(book, padding=14)
        book.add(a, text="Part A — Prepare Inputs")
        book.add(b, text="Part B — Optimize")
        self._part_a(a)
        self._part_b(b)
        ttk.Label(self.root, text="Activity log:", font=("Segoe UI", 9, "bold")).pack(anchor="w", padx=18)
        self.log = scrolledtext.ScrolledText(self.root, height=10, state="disabled", wrap="word")
        self.log.pack(fill="both", padx=16, pady=(3, 14))

    def _part_a(self, tab):
        ttk.Label(tab, text="Part A cleans the master sample, builds the available pool, and prepares exact-sex-balance inputs.", wraplength=820).pack(anchor="w", pady=(0, 8))
        FileRow(tab, "Current master-sample workbook:", self.master, lambda: self._open_file(self.master)).pack(fill="x", pady=3)
        row = ttk.Frame(tab); row.pack(fill="x", pady=3)
        ttk.Label(row, text="Master worksheet:").pack(side="left")
        ttk.Entry(row, textvariable=self.master_sheet, width=22).pack(side="left", padx=(8, 0))
        FileRow(tab, "Folder containing scored SAS data:", self.scored, lambda: self._folder(self.scored)).pack(fill="x", pady=3)
        FileRow(tab, "Folder containing case-swap workbooks:", self.swaps, lambda: self._folder(self.swaps)).pack(fill="x", pady=3)
        FileRow(tab, "Demographic/OSEP target workbook:", self.targets_a, lambda: self._open_file(self.targets_a)).pack(fill="x", pady=3)
        FileRow(tab, "Part A output folder:", self.output_a, lambda: self._folder(self.output_a)).pack(fill="x", pady=3)
        buttons = ttk.Frame(tab); buttons.pack(pady=(12, 0))
        self.a_button = ttk.Button(buttons, text="Run Part A", command=lambda: self._start("Part A", self._run_a))
        self.a_button.pack(side="left", padx=4)
        self.both_button = ttk.Button(buttons, text="Run Part A + Part B", command=lambda: self._start("Parts A and B", self._run_both))
        self.both_button.pack(side="left", padx=4)

    def _part_b(self, tab):
        ttk.Label(tab, text="Part B consumes Part A's prepared workbook, runs the optimizer, and writes the final TEID, demographic/OSEP, swap, and QA workbooks.", wraplength=820).pack(anchor="w", pady=(0, 8))
        FileRow(tab, "Part A prepared workbook:", self.part_a_file, lambda: self._open_file(self.part_a_file)).pack(fill="x", pady=4)
        FileRow(tab, "Demographic/OSEP target workbook:", self.targets_b, lambda: self._open_file(self.targets_b)).pack(fill="x", pady=4)
        FileRow(tab, "Part B output folder:", self.output_b, lambda: self._folder(self.output_b)).pack(fill="x", pady=4)
        options = ttk.Frame(tab); options.pack(fill="x", pady=8)
        ttk.Label(options, text="Maximum solver time (seconds):").grid(row=0, column=0, sticky="w")
        ttk.Spinbox(options, from_=1, to=86400, textvariable=self.solver_seconds, width=10).grid(row=1, column=0, sticky="w", pady=(2, 0))
        ttk.Label(options, text="Forced-only swap (optional):").grid(row=0, column=1, sticky="w", padx=(24, 0))
        ttk.Entry(options, textvariable=self.forced_swap, width=35).grid(row=1, column=1, sticky="w", padx=(24, 0), pady=(2, 0))
        self.b_button = ttk.Button(tab, text="Run Part B", command=lambda: self._start("Part B", self._run_b))
        self.b_button.pack(pady=(12, 0))

    def _open_file(self, variable):
        value = filedialog.askopenfilename(filetypes=[("Excel workbook", "*.xlsx *.xlsm")])
        if value: variable.set(value)

    def _folder(self, variable):
        value = filedialog.askdirectory()
        if value: variable.set(value)

    def _check_file(self, value, label):
        path = Path(value)
        if not path.is_file(): raise ValueError(f"{label} not found:\n{path}")
        return path

    def _check_folder(self, value, label, create=False):
        path = Path(value)
        if create: path.mkdir(parents=True, exist_ok=True)
        if not path.is_dir(): raise ValueError(f"{label} not found:\n{path}")
        return path

    def _script(self, part):
        name = f"Optimization Engine Part {part}.py"
        bundled = resource_path(f"engines/{name}")
        return bundled if bundled.exists() else source_project() / "scripts" / name

    def _load_and_run(self, part, environment):
        old = {key: os.environ.get(key) for key in environment}
        os.environ.update({key: str(value) for key, value in environment.items()})
        try:
            path = self._script(part)
            name = f"optimization_part_{part.lower()}_{time.time_ns()}"
            spec = importlib.util.spec_from_file_location(name, path)
            module = importlib.util.module_from_spec(spec)
            sys.modules[name] = module
            spec.loader.exec_module(module)
            writer = QueueWriter(self.messages)
            with contextlib.redirect_stdout(writer), contextlib.redirect_stderr(writer):
                module.main()
            writer.flush()
        finally:
            for key, value in old.items():
                if value is None: os.environ.pop(key, None)
                else: os.environ[key] = value

    def _run_a(self):
        master = self._check_file(self.master.get(), "Master workbook")
        scored = self._check_folder(self.scored.get(), "Scored SAS-data folder")
        swaps = self._check_folder(self.swaps.get(), "Case-swap folder")
        targets = self._check_file(self.targets_a.get(), "Target workbook")
        output = self._check_folder(self.output_a.get(), "Part A output folder", create=True)
        env = {
            "OPT_ENGINE_MASTER_INPUT": master, "OPT_ENGINE_MASTER_SHEET": self.master_sheet.get().strip() or "teid_list",
            "OPT_ENGINE_SCORED_DATA_DIR": scored, "OPT_ENGINE_CASE_SWAP_DIR": swaps,
            "OPT_ENGINE_TARGET_WORKBOOK": targets, "OPT_ENGINE_PART_A_OUTPUT_ROOT": output,
        }
        self._load_and_run("A", env)
        latest = output / "Optimization_Engine_Part_A_prep_output_latest.xlsx"
        self.root.after(0, lambda: self.part_a_file.set(str(latest)))
        return latest

    def _run_b(self):
        prepared = self._check_file(self.part_a_file.get(), "Part A prepared workbook")
        targets = self._check_file(self.targets_b.get(), "Target workbook")
        output = self._check_folder(self.output_b.get(), "Part B output folder", create=True)
        seconds = int(self.solver_seconds.get())
        if seconds < 1: raise ValueError("Maximum solver time must be at least one second.")
        env = {
            "OPT_ENGINE_PART_A_FILE": prepared, "OPT_ENGINE_TARGET_WORKBOOK": targets,
            "OPT_ENGINE_PART_B_OUTPUT_ROOT": output, "OPT_ENGINE_MAX_SOLVER_SECONDS": seconds,
            "OPT_ENGINE_FORCED_ONLY_SWAP": self.forced_swap.get().strip(),
        }
        self._load_and_run("B", env)
        return output / "latest_deliverables"

    def _run_both(self):
        latest = self._run_a()
        self.part_a_file.set(str(latest))
        return self._run_b()

    def _start(self, label, function):
        if self.busy: return
        self.busy = True
        for button in (self.a_button, self.b_button, self.both_button): button.configure(state="disabled")
        self.messages.put(f"Starting {label}...")
        def worker():
            try:
                result = function()
            except Exception as exc:
                self.messages.put(f"ERROR: {exc}")
                self.messages.put(traceback.format_exc())
                self.root.after(0, lambda: messagebox.showerror("Optimization failed", str(exc)))
            else:
                msg = f"{label} completed successfully.\n\nOutput:\n{result}"
                self.messages.put(msg)
                self.root.after(0, lambda: messagebox.showinfo("Completed", msg))
            finally:
                def ready():
                    self.busy = False
                    for button in (self.a_button, self.b_button, self.both_button): button.configure(state="normal")
                self.root.after(0, ready)
        threading.Thread(target=worker, daemon=True).start()

    def _drain(self):
        while True:
            try: value = self.messages.get_nowait()
            except queue.Empty: break
            self.log.configure(state="normal"); self.log.insert("end", value + "\n"); self.log.see("end"); self.log.configure(state="disabled")
        self.root.after(100, self._drain)


if __name__ == "__main__":
    OptimizationGUI()
