VERSION ?= $(shell git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "0.0.0")
BUILD_NUMBER ?= $(shell git rev-list --count HEAD 2>/dev/null || echo "1")
ARCH ?= $(shell uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')
FLUTTER_PLATFORM_amd64 := x64
FLUTTER_PLATFORM_arm64 := arm64
FLUTTER_PLATFORM = $(FLUTTER_PLATFORM_$(ARCH))
LINUX_PLATFORM_amd64 := x64
LINUX_PLATFORM_arm64 := arm64
LINUX_PLATFORM = $(LINUX_PLATFORM_$(ARCH))
DIST_DIR ?= dist
PLUGIN_DIR ?= remote_turner.koplugin

.PHONY: all android ios windows macos linux koplugin clean release

all: android linux koplugin

android:
	mkdir -p $(DIST_DIR)
	flutter build apk --release --build-name=$(VERSION) --build-number=$(BUILD_NUMBER)
	cp build/app/outputs/flutter-apk/app-release.apk \
		$(DIST_DIR)/koreader-remote-$(VERSION)-android.apk

ios:
	mkdir -p $(DIST_DIR)
	flutter build ipa --no-codesign --build-name=$(VERSION) --build-number=$(BUILD_NUMBER)
	cp build/ios/ipa/Runner.ipa \
		$(DIST_DIR)/koreader-remote-$(VERSION)-ios.ipa

windows:
	mkdir -p $(DIST_DIR)
	flutter build windows --release --build-name=$(VERSION) --build-number=$(BUILD_NUMBER)
	iscc installers/windows/setup.iss \
		/dMyAppVer=$(VERSION) \
		/dMyAppArch=$(ARCH) \
		/dMyAppPlatform=x64 \
		/dOutputDir=$(abspath $(DIST_DIR))

macos:
	mkdir -p $(DIST_DIR)
	# Build arm64 slice (explicit arch for cross-compile on Intel runners)
	ARCHS=arm64 flutter build macos --release --build-name=$(VERSION) --build-number=$(BUILD_NUMBER)
	mv build/macos/Build/Products/Release/koreader_remote_turner.app \
		/tmp/koreader_remote_turner_arm64.app
	# Build x86_64 slice
	rm -rf build/macos
	ARCHS=x86_64 flutter build macos --release --build-name=$(VERSION) --build-number=$(BUILD_NUMBER)
	# Lipo arm64 + x86_64 into universal binary
	lipo -create \
		/tmp/koreader_remote_turner_arm64.app/Contents/MacOS/koreader_remote_turner \
		build/macos/Build/Products/Release/koreader_remote_turner.app/Contents/MacOS/koreader_remote_turner \
		-output build/macos/Build/Products/Release/koreader_remote_turner.app/Contents/MacOS/koreader_remote_turner
	# Merge frameworks (ditto merges directory trees)
	ditto /tmp/koreader_remote_turner_arm64.app/Contents/Frameworks \
		build/macos/Build/Products/Release/koreader_remote_turner.app/Contents/Frameworks
	# Create DMG
	hdiutil create -srcFolder build/macos/Build/Products/Release/koreader_remote_turner.app \
		-format UDZO -volname "KOReader Remote Turner" \
		$(DIST_DIR)/koreader-remote-$(VERSION)-macos-universal.dmg

linux:
	mkdir -p $(DIST_DIR)
	flutter build linux --release --build-name=$(VERSION) --build-number=$(BUILD_NUMBER)
	bash scripts/build-deb.sh $(VERSION) $(ARCH) $(LINUX_PLATFORM)

koplugin:
	mkdir -p $(DIST_DIR)
	cd $(PLUGIN_DIR) && \
		zip -r ../$(DIST_DIR)/remote_turner-$(VERSION).koplugin.zip .

release:
	npx semantic-release

clean:
	rm -rf $(DIST_DIR) build/
