.PHONY: docs clean

default: docs

# Target folder as defined in  mkdocs.yml  
SITE_DIR=$(shell grep "site_dir" mkdocs.yml | cut -d ':' -f 2 )

docs: clean
	# Build documentation
	mkdocs build
	# Open target HTML mini-site
	xdg-open http://127.0.0.1:8000
	# Run MarkDown server *after* opening the mini-site. This goes in foregrund!
	mkdocs serve

clean:
	rm -fR $(SITE_DIR)
	find . -name __pycache__ -exec rm -fR {} +
