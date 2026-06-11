.PHONY: clean
.PHONY: build
.PHONY: run
.PHONY: copy

# Locate the SDK
SDK = ${PLAYDATE_SDK_PATH}
ifeq ($(SDK),)
	SDK = $(shell egrep '^\s*SDKRoot' ~/.Playdate/config | head -n 1 | cut -c9-)
endif

ifeq ($(SDK),)
$(error SDK path not found; set ENV value PLAYDATE_SDK_PATH)
endif

SDKBIN=$(SDK)/bin
GAME=$(shell basename '$(CURDIR)')
OS=$(shell uname -s)

build: clean compile run

run: open

clean:
	rm -rf '$(GAME).pdx'

compile: Source/main.lua
	"$(SDKBIN)/pdc" 'Source' '$(GAME).pdx'
	
open:
ifeq ($(OS), Darwin)
	open -a '$(SDKBIN)/Playdate Simulator.app' '$(GAME).pdx'
else
	$(SDKBIN)/PlaydateSimulator '$(GAME).pdx'
endif