GO_EASY_ON_ME = 1
include theos/makefiles/common.mk

TWEAK_NAME = SSLIntercept
SSLIntercept_FILES = URLConnection.xm ASIHTTPRequest.xm

include $(THEOS_MAKE_PATH)/tweak.mk
