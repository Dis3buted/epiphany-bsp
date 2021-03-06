ESDK=${EPIPHANY_HOME}

# ARCH will be either x86_64, x86, or armv7l (parallella)
ARCH=$(shell uname -m)

ifeq ($(ARCH),x86_64)
PLATFORM_PREFIX=arm-linux-gnueabihf-
else
PLATFORM_PREFIX=
endif

HOST_LIBNAME = libhost-bsp
E_LIBNAME	= libe-bsp
LIBEXT = .a

E_SRCS = \
		e_bsp.c \
		e_bsp_drma.c \
		e_bsp_mp.c \
		e_bsp_memory.c

E_ASM_SRCS = \
		e_bsp_raw_time.s

E_HEADERS = \
			include/common.h \
			include/e_bsp.h \
			include/e_bsp_private.h

HOST_HEADERS = \
			   include/common.h \
			   include/host_bsp.h

HOST_SRCS = \
		host_bsp.c

INCLUDES = -I/usr/arm-linux-gnueabihf/include \
		   -I./include \
		   -I${ESDK}/tools/host/include

HOST_LIBS= -L${ESDK}/tools/host/lib \
		   -le-hal

E_FLAGS = -Os -fno-strict-aliasing -ffast-math -std=c99 -Wall

E_OBJS = $(E_SRCS:%.c=bin/e/%.o) $(E_ASM_SRCS:%.s=bin/e/%.o)
HOST_OBJS = $(HOST_SRCS:%.c=bin/host/%.o) 
E_ASMS = $(E_SRCS:%.c=bin/e/%.s)

########################################################

vpath %.c src
vpath %.s src

bin/host/%.o: %.c $(HOST_HEADERS)
	@echo "CC $<"
	@$(PLATFORM_PREFIX)gcc -O3 -Wall -std=c99 $(INCLUDES) -c $< -o $@ ${HOST_LIBS}
	
# C code to object file
bin/e/%.o: %.c $(E_HEADERS)
	@echo "CC $<"
	@e-gcc $(E_FLAGS) $(INCLUDES) -c $< -o $@ -le-lib

# Assembly to object file
bin/e/%.o: %.s $(E_HEADERS)
	@echo "CC $<"
	@e-gcc $(E_FLAGS) -c $< -o $@ -le-lib

# C code to assembly
bin/e/%.s: %.c $(E_HEADERS)
	@echo "CC $<"
	@e-gcc $(E_FLAGS) $(INCLUDES) -fverbose-asm -S $< -o $@

all: host e

host: host_dirs lib/$(HOST_LIBNAME)$(LIBEXT)

e: e_dirs lib/$(E_LIBNAME)$(LIBEXT)

assembly: $(E_ASMS)

lint:
	@scripts/cpplint.py --filter=-whitespace/braces,-readability/casting,-build/include,-build/header_guard --extensions=h,c $(E_SRCS:%.c=src/%.c) $(HOST_SRCS:%c=src/%c) $(E_HEADERS) $(HOST_HEADERS)

unit_test:
	@make -B; cd test; make -B; ./test.py

doxygen: $(E_HEADERS) $(HOST_HEADERS)
	@cd doc; doxygen Doxyfile

host_dirs:
	@mkdir -p bin/host lib

e_dirs:
	@mkdir -p bin/e lib

lib/$(HOST_LIBNAME)$(LIBEXT): $(HOST_OBJS)
	@$(PLATFORM_PREFIX)ar rs $@ $^ 

lib/$(E_LIBNAME)$(LIBEXT): $(E_OBJS)
	@e-ar rs $@ $^ 

sizecheck: src/sizeof_check.cpp
	@echo "-----------------------"
	@echo "Sizecheck using e-g++"
	@echo "-----------------------"
	e-g++ -Wall $(INCLUDES) -c $< -o /dev/null
	@echo "-----------------------"
	@echo "Sizecheck using g++"
	@echo "-----------------------"
	$(PLATFORM_PREFIX)g++ -Wall $(INCLUDES) -c $< -o /dev/null

########################################################

clean:
	rm -r lib
	rm -r bin
