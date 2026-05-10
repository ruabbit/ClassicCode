DEVELOPER_DIR ?= /Applications/Xcode.app/Contents/Developer
MAC_SDK ?= macosx10.7
IOS_SDK ?= iphoneos6.1
MAC_MIN ?= 10.6
IOS_MIN ?= 6.0
MAC_ARCH ?= x86_64
IOS_ARCH ?= armv7
IOS_DEVICE_HOST ?= classiccode-ipad6-via-local

BUILD_DIR ?= build
HOST_NAME := ClassicCodeHost
IOS_APP_NAME := ClassicCodeClient
IOS_BUNDLE_ID := io.ruabbit.ClassicCodeClient

MAC_SDK_PATH := $(shell DEVELOPER_DIR="$(DEVELOPER_DIR)" xcodebuild -version -sdk $(MAC_SDK) Path 2>/dev/null)
IOS_SDK_PATH := $(shell DEVELOPER_DIR="$(DEVELOPER_DIR)" xcodebuild -version -sdk $(IOS_SDK) Path 2>/dev/null)

SHARED_SRCS := Sources/Shared/CCWire.m Sources/Shared/CCRemoteControl.m
HOST_SRCS := Sources/Host/ClassicCodeHost.m $(SHARED_SRCS)
IOS_SRCS := Sources/iOS/main.m \
	Sources/iOS/CCAppDelegate.m \
	Sources/iOS/CCConnectionProfile.m \
	Sources/iOS/CCDiagnosticRemoteControlAdapter.m \
	Sources/iOS/CCHomeViewController.m \
	Sources/iOS/CCLineRemoteControlAdapter.m \
	Sources/iOS/CCRemoteClient.m \
	Sources/iOS/CCSettingsViewController.m \
	Sources/iOS/CCWorkbenchDetailViewController.m \
	Sources/iOS/CCWorkbenchListViewController.m \
	Sources/iOS/CCWorkbenchViewController.m \
	$(SHARED_SRCS)

HOST_OBJS := $(patsubst %.m,$(BUILD_DIR)/macosx/obj/%.o,$(HOST_SRCS))
IOS_OBJS := $(patsubst %.m,$(BUILD_DIR)/iphoneos/obj/%.o,$(IOS_SRCS))
IOS_ICON_SRCS := $(wildcard Resources/iOS/Icons/*)
IOS_FILE_ICON_SRCS := $(wildcard Resources/iOS/FileIcons/*)

COMMON_WARNINGS := -Wall -Wextra -Werror=implicit-function-declaration
COMMON_INCLUDES := -ISources/Shared

MAC_CC := DEVELOPER_DIR="$(DEVELOPER_DIR)" xcrun --sdk $(MAC_SDK) clang
IOS_CC := DEVELOPER_DIR="$(DEVELOPER_DIR)" xcrun --sdk $(IOS_SDK) clang

MAC_CFLAGS := $(COMMON_WARNINGS) $(COMMON_INCLUDES) -arch $(MAC_ARCH) -isysroot "$(MAC_SDK_PATH)" -mmacosx-version-min=$(MAC_MIN) -fobjc-exceptions
IOS_CFLAGS := $(COMMON_WARNINGS) $(COMMON_INCLUDES) -arch $(IOS_ARCH) -isysroot "$(IOS_SDK_PATH)" -miphoneos-version-min=$(IOS_MIN) -fobjc-abi-version=2 -fobjc-legacy-dispatch -fobjc-exceptions

.PHONY: all clean host ios run-host deploy-ios print-config

all: host ios

print-config:
	@echo "DEVELOPER_DIR=$(DEVELOPER_DIR)"
	@echo "MAC_SDK=$(MAC_SDK)"
	@echo "MAC_SDK_PATH=$(MAC_SDK_PATH)"
	@echo "MAC_ARCH=$(MAC_ARCH)"
	@echo "IOS_SDK=$(IOS_SDK)"
	@echo "IOS_SDK_PATH=$(IOS_SDK_PATH)"
	@echo "IOS_ARCH=$(IOS_ARCH)"

host: $(BUILD_DIR)/macosx/$(HOST_NAME)

ios: $(BUILD_DIR)/iphoneos/$(IOS_APP_NAME).app

$(BUILD_DIR)/macosx/obj/%.o: %.m
	@mkdir -p "$(dir $@)"
	$(MAC_CC) $(MAC_CFLAGS) -c "$<" -o "$@"

$(BUILD_DIR)/iphoneos/obj/%.o: %.m
	@mkdir -p "$(dir $@)"
	$(IOS_CC) $(IOS_CFLAGS) -c "$<" -o "$@"

$(BUILD_DIR)/macosx/$(HOST_NAME): $(HOST_OBJS)
	@mkdir -p "$(dir $@)"
	$(MAC_CC) $(MAC_CFLAGS) $^ -framework Foundation -o "$@"

$(BUILD_DIR)/iphoneos/$(IOS_APP_NAME).app: $(IOS_OBJS) Resources/iOS/Info.plist $(IOS_ICON_SRCS) $(IOS_FILE_ICON_SRCS)
	@rm -rf "$@"
	@mkdir -p "$@"
	$(IOS_CC) $(IOS_CFLAGS) $(IOS_OBJS) -framework UIKit -framework Foundation -framework CoreGraphics -framework QuartzCore -o "$@/$(IOS_APP_NAME)"
	@cp Resources/iOS/Info.plist "$@/Info.plist"
	@cp Resources/iOS/Icons/* "$@/"
	@cp Resources/iOS/FileIcons/* "$@/"
	@chmod 755 "$@/$(IOS_APP_NAME)"
	@if command -v ldid >/dev/null 2>&1; then ldid -S "$@/$(IOS_APP_NAME)"; else echo "ldid not found; leaving iOS binary unsigned"; fi

run-host: host
	CLASSICCODE_PORT=$${CLASSICCODE_PORT:-17390} "$(BUILD_DIR)/macosx/$(HOST_NAME)"

deploy-ios: ios
	scp -r "$(BUILD_DIR)/iphoneos/$(IOS_APP_NAME).app" "$(IOS_DEVICE_HOST):/tmp/$(IOS_APP_NAME).app"
	ssh "$(IOS_DEVICE_HOST)" '\
		killall $(IOS_APP_NAME) 2>/dev/null || true; \
		rm -rf /Applications/$(IOS_APP_NAME).app && \
		mv /tmp/$(IOS_APP_NAME).app /Applications/$(IOS_APP_NAME).app && \
		chown -R root:wheel /Applications/$(IOS_APP_NAME).app && \
		chmod -R go+rX /Applications/$(IOS_APP_NAME).app && \
		(command -v ldid >/dev/null 2>&1 && ldid -S /Applications/$(IOS_APP_NAME).app/$(IOS_APP_NAME) || true) && \
		(if command -v uicache >/dev/null 2>&1; then su mobile -c uicache 2>/dev/null || uicache || true; fi)'

clean:
	rm -rf "$(BUILD_DIR)"
