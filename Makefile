ARCHS = armv7
TARGET = iphone:clang:latest:6.0

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = iPodClassicU2
iPodClassicU2_FILES = main.m AppDelegate.m ClickWheelView.m ClassicLCDView.m MainViewController.m
iPodClassicU2_FRAMEWORKS = UIKit Foundation QuartzCore MediaPlayer AudioToolbox AVFoundation
iPodClassicU2_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/application.mk
