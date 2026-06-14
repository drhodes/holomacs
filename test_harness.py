#!/usr/bin/env python3
import subprocess
import sys
import os
import tempfile
import difflib

DUMP_SCRIPT = """
(print "--- BUFFERS ---")
(let ((tail (buffer-list)))
  (while tail
    (let* ((buf (car tail))
           (name (buffer-name buf)))
      (if (string-equal (substring name 0 1) " ")
          nil
        (progn
          (set-buffer buf)
          (print (concat "Buffer: " name " (point: " (int-to-string (point)) ")"))
          (print "<<<")
          (print (buffer-substring (point-min) (point-max)))
          (print ">>>"))))
    (setq tail (cdr tail))))
"""

def clean_oracle_output(text):
    lines = text.splitlines()
    cleaned = []
    for line in lines:
        if "Warning: lisp library" in line:
            continue
        if "Bare impure Emacs" in line:
            continue
        if line.startswith("Loading ") and line.endswith("..."):
            continue
        cleaned.append(line)
    return "\n".join(cleaned).strip()

def clean_cl_output(text):
    lines = text.splitlines()
    cleaned = []
    for line in lines:
        # Filter out SBCL banner, compiler notes, and warnings
        if line.startswith(";") or line.startswith("*") or "WARNING" in line:
            continue
        cleaned.append(line)
    return "\n".join(cleaned).strip()

def run_test(el_path):
    print(f"Running test: {os.path.basename(el_path)}")
    
    # Read original test content
    with open(el_path, 'r') as f:
        original_content = f.read()
    
    # Create temp file with dump script appended
    with tempfile.NamedTemporaryFile(mode='w', suffix='.el', delete=False) as temp:
        temp.write(original_content)
        temp.write("\n")
        temp.write(DUMP_SCRIPT)
        temp_path = temp.name

    try:
        # 1. Run C Oracle
        oracle_bin = "./emacs-archaeology/src/emacs_oracle"
        env = os.environ.copy()
        env["EMACSLOADPATH"] = os.path.dirname(temp_path)
        
        oracle_proc = subprocess.run(
            [oracle_bin, "-batch", "-l", temp_path],
            env=env,
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        
        oracle_out = clean_oracle_output(oracle_proc.stdout + oracle_proc.stderr)

        # 2. Run CL Engine
        cl_cmd = [
            "sbcl", "--noinform", "--non-interactive",
            "--load", "holomacs/holomacs.asd",
            "--eval", "(asdf:load-system :holomacs)",
            "--eval", f'(holomacs:run-file "{temp_path}")'
        ]
        
        cl_proc = subprocess.run(
            cl_cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        
        cl_out = clean_cl_output(cl_proc.stdout + cl_proc.stderr)

        # 3. Compare
        if oracle_out == cl_out:
            print("  [PASS] Output matches perfectly!")
            return True
        else:
            print("  [FAIL] Output mismatch!")
            print("--- C Oracle Output ---")
            print(oracle_out)
            print("--- Holomacs CL Output ---")
            print(cl_out)
            print("--- Diff ---")
            diff = difflib.unified_diff(
                oracle_out.splitlines(keepends=True),
                cl_out.splitlines(keepends=True),
                fromfile='C Oracle',
                tofile='CL Holomacs'
            )
            sys.stdout.writelines(diff)
            print()
            return False

    finally:
        if os.path.exists(temp_path):
            os.remove(temp_path)

def main():
    if len(sys.argv) < 2:
        print("Usage: test_harness.py <el_file1> [el_file2 ...]")
        sys.exit(1)
        
    success = True
    for el_file in sys.argv[1:]:
        if not run_test(el_file):
            success = False
            
    if success:
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()
