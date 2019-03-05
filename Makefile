# Project details
-include project.mk

BINARY ?= stm32
PREFIX ?= arm-none-eabi-
LDSCRIPT ?= stm32.ld
BUILDDIR ?= build
STFLASH_ADDR ?= 0x08000000
JLINKTARGET ?= STM32F407VG

# Tools
CC := $(PREFIX)gcc
CXX := $(PREFIX)g++
AS := $(PREFIX)g++
LD := $(PREFIX)g++
OBJCOPY := $(PREFIX)objcopy
OBJDUMP := $(PREFIX)objdump
GDB := $(PREFIX)gdb
MKDIR := mkdir -p
STFLASH := st-flash
JLINKEXE := JLinkExe
JLINKGDBSERVER := JLinkGDBServer

# Targets
.PHONY: all clean cleanall deploy debug

all: $(BINARY).bin $(BUILDDIR)/$(BINARY).dump
	@echo "Building finished"

clean:
	@echo "Cleaning build"
	@rm -rf $(OBJS) $(DEPS) $(BINARY).bin

cleanall: clean
	@rm -rf $(BUILDDIR)

deploy: all
	@echo "Flashing   $(BINARY).bin"
ifeq ($(USE_STFLASH), y)
	$(STFLASH) --reset write $(BINARY).bin $(STFLASH_ADDR)
else
	echo -e "loadfile $(BINARY).bin\nr\ng\nq\n" | $(JLINKEXE) -device $(JLINKTARGET) -if SWD -speed 4000 -autoconnect 1
endif

debug: deploy
	@echo "Debuging   $(BINARY).bin"
ifeq ($(USE_STFLASH), y)
	# TODO: openocd
else
	@$(JLINKGDBSERVER) -device $(JLINKTARGET) -if SWD
endif

gdb: $(BUILDDIR)/$(BINARY).elf
	@echo "Starting gdb"
	$(GDB) --symbols $(BUILDDIR)/$(BINARY).elf -x gdb.commands

# Files
-include $(shell find . -name subdir.mk)

OBJS := $(SOURCES:.c=.o)
OBJS := $(OBJS:.cpp=.o)
OBJS := $(OBJS:.S=.o)
OBJS := $(addprefix $(BUILDDIR)/,$(OBJS))
DEPS := $(OBJS:%.o=%.d)

# Compiler flags
CFLAGS += $(TARGET)
CFLAGS += -fdata-sections -ffunction-sections
CFLAGS += $(addprefix -D,$(DEFINES))
CFLAGS += $(addprefix -I,$(INCLUDE_DIRS))

CXXFLAGS += $(TARGET)
CXXFLAGS += -fdata-sections -ffunction-sections
CXXFLAGS += $(addprefix -D,$(DEFINES))
CXXFLAGS += $(addprefix -I,$(INCLUDE_DIRS))

ASFLAGS += $(TARGET)

LDFLAGS += $(TARGET)
LDFLAGS += -Wl,--gc-sections,--start
LDFLAGS += $(addprefix -L,$(LIB_DIRS))
LDFLAGS += $(addprefix -l,$(LIBS))

# Common rules
%.bin: $(BUILDDIR)/%.elf
	@echo "Exporting  $(@)"
	@$(OBJCOPY) -O binary $(<) $(@)
	
%.dump: %.elf
	@echo "Exporting  $(@)"
	@$(OBJDUMP) -d $(<) > $(@)
	
$(BUILDDIR)/$(BINARY).elf: $(OBJS) $(STATIC_LIBS)
	@echo "Linking    $(@)"
	@$(LD) $(LDFLAGS) -T $(LDSCRIPT) $(OBJS) $(STATIC_LIBS) -o $@

$(BUILDDIR)/%.o: %.cpp
	@echo "Compiling  $(<)"
	@$(MKDIR) $(dir $(@))
	@$(CXX) $(CXXFLAGS) -MMD -MP -MF$(@:%.o=%.d) -MT$(@) -c $(<) -o $(@)
	
$(BUILDDIR)/%.o: %.c
	@echo "Compiling  $(<)"
	@$(MKDIR) $(dir $(@))
	@$(CC) $(CFLAGS) -MMD -MP -MF$(@:%.o=%.d) -MT$(@) -c $(<) -o $(@)
	
$(BUILDDIR)/%.o: %.S
	@echo "Assembling $(<)"
	@$(MKDIR) $(dir $(@))
	@$(AS) $(ASFLAGS) -c $(<) -o $(@)
	
-include $(DEPS)
