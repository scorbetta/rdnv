.PHONY: docs clean

default: docs

# Base folder of repo
MKDOCS_LOCAL_SRC_DIR=$(shell git rev-parse --show-toplevel)

docs: clean
	
	# Build documentation
	MKDOCS_LOCAL_SRC_DIR=$(MKDOCS_LOCAL_SRC_DIR) mkdocs build
	# Open target HTML mini-site
	xdg-open http://127.0.0.1:8000
	# Run MarkDown server *after* opening the mini-site. This goes in foregrund!
	MKDOCS_LOCAL_SRC_DIR=$(MKDOCS_LOCAL_SRC_DIR) mkdocs serve

clean:
	rm -fR $(SITE_DIR)
	find . -name __pycache__ -exec rm -fR {} +
