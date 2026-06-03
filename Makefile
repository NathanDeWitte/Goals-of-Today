APP_NAME := GoalsOfToday
APP := dist/$(APP_NAME).app
INSTALL_DIR := /Applications
RELEASE_BIN := .build/release/$(APP_NAME)
RESOURCE_BUNDLE := .build/release/$(APP_NAME)_$(APP_NAME).bundle

.PHONY: build bundle install icon run clean

build:
	swift build -c release

bundle: build
	rm -rf $(APP)
	mkdir -p $(APP)/Contents/MacOS $(APP)/Contents/Resources
	cp $(RELEASE_BIN) $(APP)/Contents/MacOS/
	cp -R $(RESOURCE_BUNDLE) $(APP)/Contents/Resources/
	cp packaging/Info.plist $(APP)/Contents/
	cp packaging/AppIcon.icns $(APP)/Contents/Resources/
	codesign --force --sign - $(APP)
	@echo "Built $(APP)"

install: bundle
	@pkill -x $(APP_NAME) 2>/dev/null || true
	rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"
	ditto $(APP) "$(INSTALL_DIR)/$(APP_NAME).app"
	open "$(INSTALL_DIR)/$(APP_NAME).app"
	@echo "Installed and launched $(INSTALL_DIR)/$(APP_NAME).app"

# Regenerate packaging/AppIcon.icns from scripts/make-icon.swift
icon:
	swift scripts/make-icon.swift /tmp/goals-icon-1024.png
	rm -rf /tmp/AppIcon.iconset
	mkdir -p /tmp/AppIcon.iconset
	sips -z 16 16     /tmp/goals-icon-1024.png --out /tmp/AppIcon.iconset/icon_16x16.png > /dev/null
	sips -z 32 32     /tmp/goals-icon-1024.png --out /tmp/AppIcon.iconset/icon_16x16@2x.png > /dev/null
	sips -z 32 32     /tmp/goals-icon-1024.png --out /tmp/AppIcon.iconset/icon_32x32.png > /dev/null
	sips -z 64 64     /tmp/goals-icon-1024.png --out /tmp/AppIcon.iconset/icon_32x32@2x.png > /dev/null
	sips -z 128 128   /tmp/goals-icon-1024.png --out /tmp/AppIcon.iconset/icon_128x128.png > /dev/null
	sips -z 256 256   /tmp/goals-icon-1024.png --out /tmp/AppIcon.iconset/icon_128x128@2x.png > /dev/null
	sips -z 256 256   /tmp/goals-icon-1024.png --out /tmp/AppIcon.iconset/icon_256x256.png > /dev/null
	sips -z 512 512   /tmp/goals-icon-1024.png --out /tmp/AppIcon.iconset/icon_256x256@2x.png > /dev/null
	sips -z 512 512   /tmp/goals-icon-1024.png --out /tmp/AppIcon.iconset/icon_512x512.png > /dev/null
	cp /tmp/goals-icon-1024.png /tmp/AppIcon.iconset/icon_512x512@2x.png
	iconutil -c icns /tmp/AppIcon.iconset -o packaging/AppIcon.icns
	@echo "Wrote packaging/AppIcon.icns"

run:
	swift run

clean:
	rm -rf .build dist
