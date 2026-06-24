VERSION ?= $(shell git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "0.0.0")
BUILD_NUMBER ?= $(shell git rev-list --count HEAD 2>/dev/null || echo "1")
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
		/dOutputDir=$(abspath $(DIST_DIR))

macos:
	mkdir -p $(DIST_DIR)
	flutter build macos --release --build-name=$(VERSION) --build-number=$(BUILD_NUMBER)
	hdiutil create -srcFolder build/macos/Build/Products/Release/koreader_remote_turner.app \
		-format UDZO -volname "KOReader Remote Turner" \
		$(DIST_DIR)/koreader-remote-$(VERSION)-macos.dmg

linux:
	mkdir -p $(DIST_DIR)
	flutter build linux --release --build-name=$(VERSION) --build-number=$(BUILD_NUMBER)
	bash scripts/build-deb.sh $(VERSION)

koplugin:
	mkdir -p $(DIST_DIR)
	cd $(PLUGIN_DIR) && \
		zip -r ../$(DIST_DIR)/remote_turner-$(VERSION).koplugin.zip .

release:
	npx semantic-release

clean:
	rm -rf $(DIST_DIR) build/
