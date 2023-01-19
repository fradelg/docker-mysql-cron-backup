# Makefile

all: test

test:
	# Checking for syntax errors
	set -e; for SCRIPT in *.sh; \
	do \
		bash -n $$SCRIPT; \
	done

	# Checking for bashisms (currently not failing, but only listing)
	SCRIPT="$$(which checkbashisms)"; if [ -n "$$SCRIPT" ] && [ -x "$$SCRIPT" ]; \
	then \
		$$SCRIPT *.sh || true; \
	else \
		echo "WARNING: skipping bashism test - you need to install checkbashism."; \
	fi

	SCRIPT="$$(which shellcheck)"; if [ -n "$$SCRIPT" ] && [ -x "$$SCRIPT" ]; \
	then \
		$$SCRIPT *.sh || true; \
	else \
		echo "WARNING: skipping shellcheck test - you need to install shellcheck."; \
	fi
