.PHONY: test build app sounds clean

test:
	swift test --filter ToiletCoreTests

build:
	swift build

app:
	./scripts/build-app.sh

sounds:
	python3 scripts/generate-sounds.py

clean:
	rm -rf .build dist .swiftpm
