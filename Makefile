.PHONY: format lint build test check run clean

format:
	./scripts/format.sh

lint:
	./scripts/lint.sh

build:
	swift build

test:
	mkdir -p /private/tmp/pbshow-swift-cache
	HOME=/private/tmp/pbshow-swift-cache swift test

check: lint test

run:
	swift run pbshow show

clean:
	swift package clean
