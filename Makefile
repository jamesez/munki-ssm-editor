TOOL_NAME = munki-ssm-editor
VERSION = $(shell git describe --abbrev=0 --tags)

CODESIGN_IDENTITY = "Developer ID Application: Pork Chop Software, LLC (PNC9632PM4)"

PREFIX = /usr/local
INSTALL_PATH = $(PREFIX)/bin/$(TOOL_NAME)
SHARE_PATH = $(PREFIX)/share/$(TOOL_NAME)
BUILD_PATH = .build/apple/Products/Release/$(TOOL_NAME)
CURRENT_PATH = $(PWD)

build:
	swift build -c release --arch arm64 --arch x86_64
	rm -rf out || true
	mkdir -p Binaries
	cp ${BUILD_PATH} Binaries/${TOOL_NAME}

install: build
	mkdir -p $(PREFIX)/bin
	cp -f $(BUILD_PATH) $(INSTALL_PATH)

uninstall:
	rm -f $(INSTALL_PATH)

sign: Binaries/${TOOL_NAME}
	xcrun codesign -s ${CODESIGN_IDENTITY} \
		--options=runtime \
		--timestamp \
		Binaries/${TOOL_NAME}

