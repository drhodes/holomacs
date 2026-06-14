.PHONY: build-oracle run-demos clean

build-oracle:
	cd emacs-archaeology && nix-shell --run "cd src && rm -f *.o && make -f Makefile_oracle"

run-demos:
	chmod +x test_harness.py
	python3 test_harness.py demos/demo_math.el demos/demo_buffer.el demos/demo_variables.el demos/demo_engine.el demos/demo_markers.el demos/demo_transpiler.el demos/demo_command_loop.el

clean:
	cd emacs-archaeology/src && rm -f *.o emacs_oracle
	rm -rf debug_logs
	rm -f temp_test_file.txt
