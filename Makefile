# Four toolchains, one entry point. Each target is independent, so a missing
# toolchain only breaks its own line.

.PHONY: help spec test test-flutter test-react-native test-kotlin test-swift \
        check check-flutter check-react-native check-swift clean

help:
	@echo "spec                 regenerate the shared conformance fixtures"
	@echo "test                 run all four test suites"
	@echo "test-flutter         flutter test"
	@echo "test-react-native    node --test"
	@echo "test-kotlin          gradle test"
	@echo "test-swift           swift test"
	@echo "check                analyze / typecheck / build every port"
	@echo "clean                remove build output from every port"

spec:
	node spec/generate.mjs

test: test-flutter test-react-native test-kotlin test-swift

test-flutter:
	cd flutter && flutter test

test-react-native:
	cd react-native && npm test

test-kotlin:
	cd kotlin && gradle test

test-swift:
	cd swift && swift test

check: check-flutter check-react-native check-swift
	cd kotlin && gradle assembleRelease

check-flutter:
	cd flutter && flutter analyze
	cd flutter/example && flutter analyze

check-react-native:
	cd react-native && npm run typecheck && npm run build

check-swift:
	cd swift && swift build

clean:
	cd flutter && flutter clean
	rm -rf react-native/dist react-native/node_modules
	rm -rf kotlin/build kotlin/.gradle
	rm -rf swift/.build
