# Makefile for Garmin Connect IQ QR Code App
# Supports building as both data field and standalone watch app

# Environment variables
SDK_HOME ?= "/Users/ari/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-8.4.0-2025-12-03-5122605dc"
MONKEYC ?= $(SDK_HOME)/bin/monkeyc
MONKEYDO ?= $(SDK_HOME)/bin/monkeydo

# Project configuration
PRODUCT ?= fr255
APP_NAME = qr-data-field
WATCHAPP_NAME = qr-watch-app
PRIVATE_KEY ?= ./developer_key
JUNGLE = monkey.jungle
SETTINGS ?= $(APP_NAME)-settings.json

# ============================================
# DATA FIELD BUILD TARGETS (default)
# ============================================

build:
	$(MONKEYC) -d $(PRODUCT) -f $(JUNGLE) -o $(APP_NAME).prg -y $(PRIVATE_KEY) -w --debug-log-level=3

run: build
	$(MONKEYDO) $(APP_NAME).prg $(PRODUCT) -a "$(SETTINGS):GARMIN/Settings/$(SETTINGS)"

test:
	$(MONKEYC) -d $(PRODUCT) -f $(JUNGLE) -o $(APP_NAME).prg -y $(PRIVATE_KEY) -w -t --debug-log-level=3
	$(MONKEYDO) $(APP_NAME).prg $(PRODUCT) -t

publish:
	rm -rf bin/
	mkdir bin/
	$(MONKEYC) -f $(JUNGLE) -o ./bin/$(APP_NAME).iq -y $(PRIVATE_KEY) -e -r -w -O=3z

# ============================================
# WATCH APP BUILD TARGETS
# ============================================

JUNGLE_WATCHAPP = monkey-watchapp.jungle

build-watchapp:
	$(MONKEYC) -d $(PRODUCT) -f $(JUNGLE_WATCHAPP) \
		-o $(WATCHAPP_NAME).prg -y $(PRIVATE_KEY) -w --debug-log-level=3

run-watchapp: build-watchapp
	$(MONKEYDO) $(WATCHAPP_NAME).prg $(PRODUCT)

test-watchapp:
	$(MONKEYC) -d $(PRODUCT) -f $(JUNGLE_WATCHAPP) \
		-o $(WATCHAPP_NAME).prg -y $(PRIVATE_KEY) -w -t --debug-log-level=3
	$(MONKEYDO) $(WATCHAPP_NAME).prg $(PRODUCT) -t

publish-watchapp:
	rm -rf bin/
	mkdir bin/
	$(MONKEYC) -f $(JUNGLE_WATCHAPP) \
		-o ./bin/$(WATCHAPP_NAME).iq -y $(PRIVATE_KEY) -e -r -w -O=3z

# ============================================
# COMMON TARGETS
# ============================================

release: clean publish

release-watchapp: clean publish-watchapp

release-all: clean publish publish-watchapp

clean:
	rm -rf gen/*
	rm -rf bin/
	rm -f $(APP_NAME).prg
	rm -f $(APP_NAME).prg.debug.xml
	rm -f $(WATCHAPP_NAME).prg
	rm -f $(WATCHAPP_NAME).prg.debug.xml

.PHONY: build run test publish release clean \
        build-watchapp run-watchapp test-watchapp publish-watchapp release-watchapp release-all
