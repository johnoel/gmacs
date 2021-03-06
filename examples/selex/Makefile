# Name of executable.
OUTPUT:=seltest
LIBINCLUDE = ../../src/lib/bin
# Global source files from current dir.
LIBS:=$(wildcard ../../src/lib/*.cpp)
SRCS:=$(wildcard *.cpp *.c *.cc *.cxx ) 

vpath %.h ../../src/include

# Portable makefiles (http://skramm.blogspot.com/2013/04/writing-portable-makefiles.html)
# Windows users: download http://gnuwin32.sourceforge.net/packages/make.htm
ifdef ComSpec
    RM=del /F /Q
    CXX:=g++
else
    RM=rm -rf
		CXX:=clang++
endif 


# Path to ADMB distribution directory if ADMB_HOME is not declared in your evironment variables
# export ADMB_HOME=/Users/stevenmartell1/admb-trunk/build/dist
# export ADMB_HOME=/Users/jim/admb/build/dist

# Compiler
# CXX:=clang++

# Compiler and linker flags.
CXXFLAGS:=-g -Wall -D__GNUDOS__ -Dlinux -DUSE_LAPLACE  \
	      -I.                                          \
	      -I$(ADMB_HOME)/include                       \
	      -I$(ADMB_HOME)/contrib/include               \
	      -I$(LIBINCLUDE)                              \
	      -I/usr/include/libxml2                       \
	      -std=c++11                                   \
	      -stdlib=libc++
LDFLAGS:= 

# Release specific flags.
RELEASE_CXXFLAGS:=-O3 -DOPT_LIB
RELEASE_LDFLAGS:= $(ADMB_HOME)/lib/libadmb-contribo.a            \
	              $(LIBINCLUDE)/release/libgmacs.a               \
	              lib/bin/release/libgmacs.a 						 \
	              -lxml2

# Debug specific flags.
DEBUG_CXXFLAGS:=-O0 -DSAFE_ALL
DEBUG_LDFLAGS:= $(ADMB_HOME)/lib/libadmb-contrib.a               \
	            $(LIBINCLUDE)/debug/libgmacs.a                   \
	            lib/bin/debug/libgmacs.a                           \
	            -lxml2

# Name of text file containing build number.
BUILD_NUMBER_FILE=build-number.txt

# ======================= END OF CONFIGURABLE THINGS ===========================
# Create debug & release list of object files as well as dep files.
BASEFILES:=$(basename $(SRCS))
DEBUG_OBJS:=$(addprefix build/debug/,$(addsuffix .o,$(BASEFILES)))
RELEASE_OBJS:=$(addprefix build/release/,$(addsuffix .o,$(BASEFILES)))
DEPFILES:=$(addprefix build/deps/,$(addsuffix .d,$(BASEFILES)))

# Default to release build.
all: $(OUTPUT).cpp library  debug release

library: $(LIBS)
	@$(MAKE) --directory=../../src/lib

$(OUTPUT).cpp: $(OUTPUT).tpl
	$(ADMB_HOME)/bin/tpl2cpp $(OUTPUT)

# Directory targets
build/debug:
	@echo creating debug directory
	@mkdir -p build/debug build/deps

build/release:
	@echo creating release directory
	@mkdir -p build/release build/deps

# Debug route.
.PHONY: debug
debug: CXXFLAGS+= $(DEBUG_CXXFLAGS)
debug: LDFLAGS+= $(DEBUG_LDFLAGS)
debug: build/debug/$(OUTPUT)

build/debug/$(OUTPUT): build/debug $(DEBUG_OBJS)
	@echo 'linking ' build/debug/$(OUTPUT)
	@$(CXX) -o build/debug/$(OUTPUT) $(DEBUG_OBJS) $(LDFLAGS)

-include $(DEPFILES)

build/debug/%.o : %.cpp
	@echo 'compiling ' $<
	@$(CXX) -c $(CXXFLAGS) $< -o $@
	@$(CXX) -MM $(CXXFLAGS) $< -o build/deps/$*.d
	@mv -f build/deps/$*.d build/deps/$*.d.tmp
	@sed -e 's|.*:|build/debug/$*.o:|' < build/deps/$*.d.tmp \
	  > build/deps/$*.d
	@sed -e 's/.*://' -e 's/\\$$//' < build/deps/$*.d.tmp | fmt -1 \
	  | sed -e 's/^ *//' -e 's/$$/:/' >> build/deps/$*.d
	@rm -f build/deps/$*.d.tmp	

# Release route.
.PHONY: release
release: CXXFLAGS+= $(RELEASE_CXXFLAGS)
release: LDFLAGS+= $(RELEASE_LDFLAGS)
release: build/release/$(OUTPUT)

build/release/$(OUTPUT): build/release $(RELEASE_OBJS)
	@echo 'linking ' build/release/$(OUTPUT)
	@$(CXX) -o build/release/$(OUTPUT) $(RELEASE_OBJS) $(LDFLAGS)

build/release/%.o : %.cpp
	@echo 'compiling ' $<
	@$(CXX) -c $(CXXFLAGS) $< -o $@
	@$(CXX) -MM $(CXXFLAGS) $< -o build/deps/$*.d
	@mv -f build/deps/$*.d build/deps/$*.d.tmp
	@sed -e 's|.*:|build/release/$*.o:|' < build/deps/$*.d.tmp \
	  > build/deps/$*.d
	@sed -e 's/.*://' -e 's/\\$$//' < build/deps/$*.d.tmp | fmt -1 | \
	  sed -e 's/^ *//' -e 's/$$/:/' >> build/deps/$*.d
	@rm -f build/deps/$*.d.tmp

.PHONY: clean
clean:
	@echo 'removing build directory'
	@$(RM) -rf build
