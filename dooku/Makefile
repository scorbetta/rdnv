.PHONY: docs clean

default: docs

docs: clean
	# Build documentation
	mkdocs build
	# Open target HTML mini-site
	xdg-open http://127.0.0.1:8000
	# Run MarkDown server *after* opening the mini-site. This goes in foregrund!
	mkdocs serve

clean:
	rm -fR site
