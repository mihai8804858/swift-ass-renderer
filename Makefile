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
GENERIC_PLATFORM_MACOS = platform=macOS
GENERIC_PLATFORM_MAC_CATALYST = platform=macOS,variant=Mac Catalyst

SIM_PLATFORM_IOS = platform=iOS Simulator,id=$(call udid_for,iOS,iPhone [0-9]+ Pro,iPhone [0-9]+.*)
# Snapshot references depend on the screen scale, so tvOS needs the newest 2x Apple TV 4K,
# of any generation, and never an "(at 1080p)" model, which renders at 1x
SIM_PLATFORM_TVOS = platform=tvOS Simulator,id=$(call udid_for,tvOS,Apple TV 4K( \([0-9]+(st|nd|rd|th) generation\))?)
SIM_PLATFORM_VISIONOS = platform=visionOS Simulator,id=$(call udid_for,visionOS,Apple Vision.*)
SIM_PLATFORM_MACOS = platform=macOS
SIM_PLATFORM_MAC_CATALYST = platform=macOS,variant=Mac Catalyst

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

test-all-platforms:
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

lint:
	swiftlint lint --strict

spell:
	cspell-cli lint --no-progress

all: lint spell build-all-platforms build-example build-docs test-all-platforms

.PHONY: all
.DEFAULT_GOAL := all

# Newest available simulator runtime version for a platform, e.g. "26.5" for iOS
define latest_runtime
$(shell xcrun simctl list runtimes available | grep '^$(1) ' | awk '{ print $$2 }' | sort -V | tail -1)
endef

OPEN_PAREN := (
CLOSE_PAREN := )

# UDID of the newest device on runtime $(1) whose name is exactly matched by the extended regex $(2)
define find_udid
$(shell xcrun simctl list devices available '$(1)' | grep -E '^ +$(2) [$(OPEN_PAREN)][0-9A-F-]{36}[$(CLOSE_PAREN)]' \
  | sed -E 's/^ +(.*) \(([0-9A-F-]{36})\) [$(OPEN_PAREN)].*$$/\1|\2/' | sort -t '|' -k1,1 -V -r | head -1 | cut -d '|' -f2)
endef

# UDID of a simulator on the newest $(1) runtime named like $(2), or else like $(3)
define udid_for
$(strip $(eval _rt := $(call latest_runtime,$(1)))$(or \
  $(if $(_rt),,$(error No available $(1) simulator runtime)), \
  $(call find_udid,$(1) $(_rt),$(2)), \
  $(if $(3),$(call find_udid,$(1) $(_rt),$(3))), \
  $(error No available $(1) $(_rt) simulator named like "$(2)")))
endef
