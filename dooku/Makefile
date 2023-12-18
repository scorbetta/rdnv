.PHONY: gen-md gen-json docs clean

default: docs

# Generate JSON files once
gen-json: .gen-json.done
.gen-json.done:
	make -C ../tatooine/library json
	date > .gen-json.done

# Generate MarkDown files
gen-md:
	python3 scripts/generate_docs.py

# Generate mini-site and launch server
docs: gen-json gen-md
	# Build documentation
	mkdocs build
	# Open target HTML mini-site
	xdg-open http://127.0.0.1:8000
	# Run MarkDown server *after* opening the mini-site. This goes in foregrund!
	mkdocs serve

clean:
	rm -fR site/
	find . -name __pycache__ -exec rm -fR {} +
	rm -f .gen-json.done
