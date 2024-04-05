CONFIG = debug
WORKSPACE = SwiftAssRenderer
LIB_SCHEME = SwiftAssRenderer
EXAMPLE_SCHEME = Example

DOCC_DIR = docs
DOCC_BASE_PATH = swift-ass-renderer
DOCC_ARCHIVE = SwiftAssRenderer.doccarchive

GENERIC_PLATFORM_IOS = generic/platform=iOS
GENERIC_PLATFORM_TVOS = generic/platform=tvOS
GENERIC_PLATFORM_VISIONOS = generic/platform=visionOS
GENERIC_PLATFORM_MACOS = platform=macOS,arch=arm64
GENERIC_PLATFORM_MAC_CATALYST = platform=macOS,variant=Mac Catalyst,arch=arm64

SIM_PLATFORM_IOS = platform=iOS Simulator,id=$(call udid_for,iOS 17.4,iPhone \d\+ Pro [^M])
SIM_PLATFORM_TVOS = platform=tvOS Simulator,id=$(call udid_for,tvOS 17.4,TV)
SIM_PLATFORM_VISIONOS = platform=visionOS Simulator,id=$(call udid_for,visionOS 1.1,Vision)
SIM_PLATFORM_MACOS = platform=macOS,arch=arm64
SIM_PLATFORM_MAC_CATALYST = platform=macOS,variant=Mac Catalyst,arch=arm64

GREEN='\033[0;32m'
NC='\033[0m'

build-all-platforms:
	for platform in \
	  "$(GENERIC_PLATFORM_IOS)" \
	  "$(GENERIC_PLATFORM_TVOS)" \
	  "$(GENERIC_PLATFORM_VISIONOS)" \
	  "$(GENERIC_PLATFORM_MACOS)" \
	  "$(GENERIC_PLATFORM_MAC_CATALYST)"; \
	do \
		echo -e "\n${GREEN}Building $$platform ${NC}"\n; \
		set -o pipefail && xcrun xcodebuild clean build \
			-workspace $(WORKSPACE).xcworkspace \
			-scheme $(LIB_SCHEME) \
			-configuration $(CONFIG) \
			-scmProvider system \
			-usePackageSupportBuiltinSCM \
			-destination "$$platform" | xcpretty || exit 1; \
	done;

build-docs:
	echo -e "\n${GREEN}Building DocC${NC}\n"
	set -o pipefail && xcrun xcodebuild clean docbuild \
		-workspace $(WORKSPACE).xcworkspace \
		-scheme $(LIB_SCHEME) \
		-derivedDataPath .build \
		-destination "$(GENERIC_PLATFORM_IOS)" \
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

build-example:
ifeq ($(CI),true)
	for platform in \
	  "$(SIM_PLATFORM_IOS)" \
	  "$(SIM_PLATFORM_TVOS)"; \
	do \
		echo -e "\n${GREEN}Building example on $$platform ${NC}"\n; \
		set -o pipefail && xcrun xcodebuild clean build \
			-workspace $(WORKSPACE).xcworkspace \
			-scheme $(EXAMPLE_SCHEME) \
			-configuration Debug \
			-scmProvider system \
			-usePackageSupportBuiltinSCM \
			-destination "$$platform" | xcpretty || exit 1; \
	done;
else
	for platform in \
	  "$(SIM_PLATFORM_IOS)" \
	  "$(SIM_PLATFORM_TVOS)" \
	  "$(SIM_PLATFORM_VISIONOS)" \
	  "$(SIM_PLATFORM_MACOS)" \
	  "$(SIM_PLATFORM_MAC_CATALYST)"; \
	do \
		echo -e "\n${GREEN}Building example on $$platform ${NC}"\n; \
		set -o pipefail && xcrun xcodebuild clean build \
			-workspace $(WORKSPACE).xcworkspace \
			-scheme $(EXAMPLE_SCHEME) \
			-configuration Debug \
			-scmProvider system \
			-usePackageSupportBuiltinSCM \
			-destination "$$platform" | xcpretty || exit 1; \
	done;
endif

test-all-platforms:
ifeq ($(CI),true)
	for platform in \
	  "$(SIM_PLATFORM_IOS)" \
	  "$(SIM_PLATFORM_TVOS)"; \
	do \
		echo -e "\n${GREEN}Testing $$platform ${NC}\n"; \
		set -o pipefail && xcrun xcodebuild clean test \
			-workspace $(WORKSPACE).xcworkspace \
			-scheme $(LIB_SCHEME) \
			-configuration $(CONFIG) \
			-scmProvider system \
			-usePackageSupportBuiltinSCM \
			-destination "$$platform" | xcpretty || exit 1; \
	done;
else
	for platform in \
	  "$(SIM_PLATFORM_IOS)" \
	  "$(SIM_PLATFORM_TVOS)" \
	  "$(SIM_PLATFORM_VISIONOS)" \
	  "$(SIM_PLATFORM_MACOS)" \
	  "$(SIM_PLATFORM_MAC_CATALYST)"; \
	do \
		echo -e "\n${GREEN}Testing $$platform ${NC}\n"; \
		set -o pipefail && xcrun xcodebuild clean test \
			-workspace $(WORKSPACE).xcworkspace \
			-scheme $(LIB_SCHEME) \
			-configuration $(CONFIG) \
			-scmProvider system \
			-usePackageSupportBuiltinSCM \
			-destination "$$platform" | xcpretty || exit 1; \
	done;
endif

lint:
	swiftlint lint --strict

spell:
	cspell-cli lint --no-progress

.PHONY: build-all-platforms build-example build-docs test-all-platforms lint spell

define udid_for
$(shell xcrun simctl list devices available '$(1)' | grep '$(2)' | sort -r | head -1 | awk -F '[()]' '{ print $$(NF-3) }')
endef
