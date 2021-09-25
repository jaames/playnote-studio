HEAP_SIZE      = 8388208
STACK_SIZE     = 61800

PRODUCT = Playnote.pdx

SDK = $(shell egrep '^\s*SDKRoot' ~/.Playdate/config | head -n 1 | cut -c9-)

######
# IMPORTANT: You must add your source folders to VPATH for make to find them
# ex: VPATH += src1:src2
######

VPATH += src

# List C source files here
SRC = \
	src/main.c \
	src/luaglue.c

ASRC = setup.s

# List all user directories here
UINCDIR =

# List all user C define here, like -D_DEBUG=1
UDEFS = 

# Define ASM defines here
UADEFS = 

# List the user directory to look for the libraries here
ULIBDIR =

# List all user libraries here
ULIBS = 

include $(SDK)/C_API/buildsupport/common.mk