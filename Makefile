# Mashkal Tweak - Makefile for iPhone 15
# Optimized for arm64e architecture

# Device settings (for on-device build)
ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:14.0

# For iPhone 15 specific optimizations
ADDITIONAL_CFLAGS = -mcpu=apple-a16 -O3

# Install target
INSTALL_TARGET_PROCESSES = SpringBoard

TWEAK_NAME = Mashkal

# Source files
Mashkal_FILES = Tweak.xm     OneStateOverlay.mm     OneStateOverlayUI.mm     MetalRenderer.mm     MetalContext.mm     MetalBuffer.mm     MetalTexture.mm     FramebufferDescriptor.mm     SecurityManager.mm     ImGuiMenu.mm

# Frameworks (iOS system frameworks)
Mashkal_FRAMEWORKS = UIKit Foundation Metal MetalKit Security CoreGraphics QuartzCore CoreImage
Mashkal_LIBRARIES = substrate c++
Mashkal_CFLAGS = -fobjc-arc -std=c++17 -O3 -DIMGUI_IMPL_METAL $(ADDITIONAL_CFLAGS)
Mashkal_LDFLAGS = -Wl,-segalign,4000

# ImGui configuration (adjust path if needed)
# If ImGui is installed via apt or in ~/include
Mashkal_CCFLAGS = -I$(THEOS)/include/imgui -I$(THEOS)/include/imgui/backends

# Debug mode (uncomment for debugging)
# Mashkal_CFLAGS += -DDEBUG -g

# Release optimizations
Mashkal_CFLAGS += -DNDEBUG

include $(THEOS)/makefiles/common.mk
include $(THEOS)/makefiles/tweak.mk

# Post-install: respring
after-install::
	install.exec "killall -9 SpringBoard"

# Clean target
clean::
	rm -rf .theos packages
