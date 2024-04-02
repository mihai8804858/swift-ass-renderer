NAME = SwiftAssRenderer
CONFIG = debug

DOCC_DIR = docs
DOCC_BASE_PATH = swift-ass-renderer
DOCC_ARCHIVE = SwiftAssRenderer.doccarchive

BUILD_PLATFORM_IOS = generic/platform=iOS
BUILD_PLATFORM_TVOS = generic/platform=tvOS
BUILD_PLATFORM_VISIONOS = generic/platform=visionOS
BUILD_PLATFORM_MACOS = platform=macOS,arch=arm64
BUILD_PLATFORM_MAC_CATALYST = platform=macOS,variant=Mac Catalyst,arch=arm64

TEST_PLATFORM_IOS = platform=iOS Simulator,id=$(call udid_for,iOS,iPhone \d\+ Pro [^M])
TEST_PLATFORM_TVOS = platform=tvOS Simulator,id=$(call udid_for,tvOS,TV)
TEST_PLATFORM_VISIONOS = platform=visionOS Simulator,id=$(call udid_for,visionOS,Vision)
TEST_PLATFORM_MACOS = platform=macOS,arch=arm64
TEST_PLATFORM_MAC_CATALYST = platform=macOS,variant=Mac Catalyst,arch=arm64

GREEN='\033[0;32m'
NC='\033[0m'

build-all-platforms:
	for platform in \
	  "$(BUILD_PLATFORM_IOS)" \
	  "$(BUILD_PLATFORM_TVOS)" \
	  "$(BUILD_PLATFORM_VISIONOS)" \
	  "$(BUILD_PLATFORM_MACOS)" \
	  "$(BUILD_PLATFORM_MAC_CATALYST)"; \
	do \
		echo -e "\n${GREEN}Building $$platform ${NC}"\n; \
		set -o pipefail && xcrun xcodebuild build \
			-workspace $(NAME).xcworkspace \
			-scheme $(NAME) \
			-configuration $(CONFIG) \
			-scmProvider system \
			-usePackageSupportBuiltinSCM \
			-destination "$$platform" | xcpretty || exit 1; \
	done;

test-all-platforms:
	for platform in \
	  "$(TEST_PLATFORM_IOS)" \
	  "$(TEST_PLATFORM_TVOS)"; \
	do \
		echo -e "\n${GREEN}Testing $$platform ${NC}\n"; \
		set -o pipefail && xcrun xcodebuild test \
			-workspace $(NAME).xcworkspace \
			-scheme $(NAME) \
			-configuration $(CONFIG) \
			-scmProvider system \
			-usePackageSupportBuiltinSCM \
			-destination "$$platform" | xcpretty || exit 1; \
	done;

build-docs:
	echo -e "\n${GREEN}Building DocC${NC}\n"
	set -o pipefail && xcrun xcodebuild docbuild \
		-workspace $(NAME).xcworkspace \
		-scheme $(NAME) \
		-derivedDataPath .build \
		-destination "$(BUILD_PLATFORM_IOS)" \
		-parallelizeTargets | xcpretty || exit 1

	echo -e "\n${GREEN}Copying DocC archives to .docarchives${NC}\n"
	rm -rf .docarchives
	mkdir .docarchives
	cp -R `find .build -type d -name "*.doccarchive"` .docarchives

	echo -e "\n${GREEN}Generate static site${NC}\n"
	rm -rf $(DOCC_DIR)
	mkdir $(DOCC_DIR)
	xcrun docc process-archive transform-for-static-hosting .docarchives/$(DOCC_ARCHIVE)/ \
		--hosting-base-path $(DOCC_BASE_PATH) \
		--output-path $(DOCC_DIR)

lint:
	swiftlint lint --strict

.PHONY: build-all-platforms test-all-platforms build-docs lint

define udid_for
$(shell xcrun simctl list devices available '$(1)' | grep '$(2)' | sort -r | head -1 | awk -F '[()]' '{ print $$(NF-3) }')
endef
