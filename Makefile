HEAP_SIZE      = 8388208
STACK_SIZE     = 61800

PRODUCT = Playnote.pdx

# Locate the SDK
SDK = ${PLAYDATE_SDK_PATH}
ifeq ($(SDK),)
        SDK = $(shell egrep '^\s*SDKRoot' ~/.Playdate/config | head -n 1 | cut -c9-)
endif

ifeq ($(SDK),)
$(error SDK path not found; set ENV value PLAYDATE_SDK_PATH)
endif

######
# IMPORTANT: You must add your source folders to VPATH for make to find them
# ex: VPATH += src1:src2
######

VPATH += ppmlib
VPATH += extension

# List C source files here
SRC = \
	extension/main.c \
	ppmlib/utils.c \
	ppmlib/player.c \
	ppmlib/ppmlib.c \
	ppmlib/tmblib.c \
	ppmlib/audio.c \
	ppmlib/video.c \
	ppmlib/ppm.c \
	ppmlib/tmb.c

# List all user directories here
UINCDIR = extension ppmlib

# List user asm files
UASRC = 

# List all user C define here, like -D_DEBUG=1
UDEFS = 

# Define ASM defines here
UADEFS = 

# List the user directory to look for the libraries here
ULIBDIR =

# List all user libraries here
ULIBS =

include $(SDK)/C_API/buildsupport/common.mk

