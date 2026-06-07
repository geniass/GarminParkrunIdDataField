# Makefile for Garmin Connect IQ QR Code Data Field

SDK_HOME ?= "/Users/ari/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-8.4.0-2025-12-03-5122605dc"
MONKEYC ?= $(SDK_HOME)/bin/monkeyc
MONKEYDO ?= $(SDK_HOME)/bin/monkeydo

PRODUCT ?= fr255
APP_NAME = qr-data-field
PRIVATE_KEY ?= ./developer_key
JUNGLE = monkey.jungle
SETTINGS ?= $(APP_NAME)-settings.json

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

release: clean publish

clean:
	rm -rf gen/*
	rm -rf bin/
	rm -f $(APP_NAME).prg
	rm -f $(APP_NAME).prg.debug.xml

.PHONY: build run test publish release clean
