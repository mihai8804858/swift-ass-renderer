NAME = SwiftAssRenderer
CONFIG = debug

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

lint:
	swiftlint lint --strict

.PHONY: build-all-platforms test-all-platforms lint

define udid_for
$(shell xcrun simctl list devices available '$(1)' | grep '$(2)' | sort -r | head -1 | awk -F '[()]' '{ print $$(NF-3) }')
endef
