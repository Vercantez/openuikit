# Builds the Objective-C facade + proof app against a Swift-built
# libOpenUIKitC.so. Run inside the openuikit-objc-facade image (see Dockerfile);
# scripts/objc_facade_verify.sh drives the whole thing.
#
# REPO defaults to the parent directory; BUILD is the SPM build dir.

REPO  ?= ..
BUILD ?= $(REPO)/.build/release
OUT   ?= $(REPO)/.build/objc

# -fobjc-runtime=gnustep-2.2 selects libobjc2's modern ABI (non-fragile ivars,
# real ARC). -fobjc-arc because a facade that hand-writes retain/release is a
# facade with leaks. Both are exactly what a normal GNUstep app uses.
OBJCFLAGS = -fobjc-arc -fobjc-runtime=gnustep-2.2 -fblocks -fexceptions \
            -Wall -Wno-unused-parameter -O2 -g

INCLUDES  = -Iinclude -I$(REPO)/Sources/COpenUIKitABI/include -I/usr/local/include

# libOpenUIKitC.so already records the Swift runtime as DT_NEEDED, so the ObjC
# link line does not mention Swift at all. That is the point: the two worlds
# meet at a C symbol table and nothing else.
LDFLAGS   = -L$(BUILD) -lOpenUIKitC \
            -L/usr/local/lib -lobjc -lgnustep-base \
            -Wl,-rpath,$(abspath $(BUILD)) -Wl,-rpath,/usr/local/lib

SOURCES   = UIKitFacade.m OpenUIKitBridge.m
APP       = ProofApp.m

all: $(OUT)/proofapp

$(OUT):
	mkdir -p $(OUT)

$(OUT)/proofapp: $(SOURCES) $(APP) include/UIKit.h include/UIGeometry.h include/OpenUIKitABI.h | $(OUT)
	clang $(OBJCFLAGS) $(INCLUDES) $(SOURCES) $(APP) -o $@ $(LDFLAGS)

clean:
	rm -rf $(OUT)

.PHONY: all clean
