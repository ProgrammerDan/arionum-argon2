#
# Argon2 source code package
# 
# This work is licensed under a Creative Commons CC0 1.0 License/Waiver.
# 
# You should have received a copy of the CC0 Public Domain Dedication along with
# this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
#

CC = gcc
REF_CFLAGS = -std=c99 -pthread -O3 -Wall -Wno-unused-function
OPT_CFLAGS = $(REF_FLAGS) -m64 -mavx

ARGON2_DIR = ./src
BLAKE2_DIR = ./src/blake2
BUILD_DIR = ./build
TEST_DIR = ./test

ARGON2_SRC = argon2.c argon2-core.c kat.c
BLAKE2_SRC = blake2b-ref.c
OPT_SRC = argon2-opt-core.c
REF_SRC = argon2-ref-core.c
TEST_SRC = argon2-test.c

LIB_NAME=argon2

ARGON2_BUILD_SRC = $(addprefix $(ARGON2_DIR)/,$(ARGON2_SRC))
BLAKE2_BUILD_SRC = $(addprefix $(BLAKE2_DIR)/,$(BLAKE2_SRC))
TEST_BUILD_SRC = $(addprefix $(ARGON2_DIR)/,$(TEST_SRC))


#OPT=TRUE
ifeq ($(OPT), TRUE)
	CFLAGS=$(OPT_CFLAGS)
	ARGON2_BUILD_SRC += $(addprefix $(ARGON2_DIR)/,$(OPT_SRC))
else
	CFLAGS=$(REF_CFLAGS)
	ARGON2_BUILD_SRC += $(addprefix $(ARGON2_DIR)/,$(REF_SRC))
endif


SRC_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

BUILD_DIR_PATH := $(shell pwd)/$(BUILD_DIR)

SYSTEM_KERNEL_NAME := $(shell uname -s)

ifeq ($(SYSTEM_KERNEL_NAME), Linux)
	LIB_EXT := so
	LIB_CFLAGS := -shared -fPIC
	LIB_PATH := -Wl,-rpath=$(BUILD_DIR_PATH)
endif
ifeq ($(SYSTEM_KERNEL_NAME), Darwin)
	LIB_EXT := dylib
	LIB_CFLAGS := -dynamiclib -install_name @rpath/lib$(LIB_NAME).$(LIB_EXT)
	LIB_PATH := -Xlinker -rpath -Xlinker $(BUILD_DIR_PATH)
endif

.PHONY: clean genkat lib test

all:  argon2 genkat lib 

argon2:
	mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) \
		$(ARGON2_BUILD_SRC) $(BLAKE2_BUILD_SRC) $(TEST_BUILD_SRC) \
		-I$(ARGON2_DIR) -I$(BLAKE2_DIR) \
		-o $(BUILD_DIR)/$@

genkat:
	mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) \
		-DARGON2_KAT -DARGON2_KAT_INTERNAL \
		$(ARGON2_BUILD_SRC) $(BLAKE2_BUILD_SRC) $(TEST_BUILD_SRC) \
		-I$(ARGON2_DIR) -I$(BLAKE2_DIR) \
		-o $(BUILD_DIR)/$@

lib:
	mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) $(LIB_CFLAGS) \
		$(ARGON2_BUILD_SRC) $(BLAKE2_BUILD_SRC) \
		-I$(ARGON2_DIR) -I$(BLAKE2_DIR) \
		-o $(BUILD_DIR)/lib$(LIB_NAME).$(LIB_EXT)

test:   genkat
	./check_test_vectors.sh -src=$(SRC_DIR)

clean:
	rm -rf $(BUILD_DIR)/
	rm -f $(TEST_DIR)/run_*
