FPC ?= fpc
UNIT_PATHS = -Fusrc/cli -Fusrc/diagnostics -Fusrc/incremental -Fusrc/model -Fusrc/parser -Fusrc/render -Fusrc/validation
FPC_FLAGS = -Mobjfpc -Sh $(UNIT_PATHS) -FUbuild/units

ifeq ($(OS),Windows_NT)
MKDIR_COMMAND = cmd /c "if not exist build\bin mkdir build\bin && if not exist build\tests mkdir build\tests && if not exist build\units mkdir build\units"
TEST_COMMAND = build\tests\test_pasweave.exe
CLEAN_COMMAND = cmd /c "if exist build rmdir /s /q build"
else
MKDIR_COMMAND = mkdir -p build/bin build/tests build/units
TEST_COMMAND = ./build/tests/test_pasweave
CLEAN_COMMAND = rm -rf build
endif

.PHONY: all test clean dirs

all: dirs
	$(FPC) $(FPC_FLAGS) -FEbuild/bin src/pasweave.lpr

test: dirs
	$(FPC) $(FPC_FLAGS) -FEbuild/tests tests/test_pasweave.pas
	$(TEST_COMMAND)

dirs:
	$(MKDIR_COMMAND)

clean:
	$(CLEAN_COMMAND)
