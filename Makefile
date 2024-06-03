CROSS   ?=avr-
CC      :=$(CROSS)gcc
CXX     :=$(CROSS)g++
LD      :=$(CROSS)g++
SIZE    :=$(CROSS)size
OBJCOPY :=$(CROSS)objcopy
OBJDUMP :=$(CROSS)objdump

TARGET=flashlight
MMCU?=
AVRDUDE_FLAGS?=

SOURCES=$(wildcard *.cpp) $(wildcard *.c)
INCLUDES=

SETTINGS=settings.h

OBJECTS=$(SOURCES:.cpp=.o)
OBJECTS:=$(OBJECTS:.c=.o)

CSTD?=c99
COPT=-O2 -fdata-sections -ffunction-sections
CFLAGS=-mmcu=$(MMCU) -std=$(CSTD) $(COPT) -Wall
CFLAGS+=$(addprefix -I,$(INCLUDES))
CFLAGS+=-include "$(SETTINGS)"

CXXSTD?=c++98
CXXOPT=$(COPT) -fno-exceptions -fno-rtti
CXXFLAGS=-mmcu=$(MMCU) -std=$(CXXSTD) $(CXXOPT) -Wall
CXXFLAGS+=$(addprefix -I,$(INCLUDES))
CXXFLAGS+=-include "$(SETTINGS)"

LDFLAGS=-mmcu=$(MMCU) -Wl,--gc-sections -Wl,-Map=$(TARGET).map,--cref

.PHONY: all avrdude clean
all: $(TARGET).hex $(TARGET).lst
	avr-size -C --mcu=$(MMCU) $(TARGET).elf

$(TARGET).elf: $(OBJECTS)
	$(LD) $(LDFLAGS) $^ -lm -o $@

$(TARGET).hex: $(TARGET).elf
	$(OBJCOPY) -O ihex -R .eeprom -R .fuse -R .lock -R .signature $< $@

$(TARGET).bin: $(TARGET).elf
	$(OBJCOPY) -O binary -R .eeprom -R .fuse -R .lock -R .signature $< $@

%.o: %.cpp
	$(CXX) -o $@ $(CXXFLAGS) -MMD -MP -MF $(@:%.o=%.d) $< -c

%.o: %.c
	$(CC) -o $@ $(CFLAGS) -MMD -MP -MF $(@:%.o=%.d) $< -c

$(TARGET).lst: $(TARGET).elf
	$(OBJDUMP) -h -S $< > $@

avrdude:
	avrdude $(AVRDUDE_FLAGS) -e -m flash -i $(TARGET).hex

clean:
	-rm -f $(addprefix $(TARGET), .elf .hex .bin .lst .map)
	-rm -f $(OBJECTS) $(OBJECTS:.o=.d)
size:
	avr-size -C --mcu=$(MMCU) $(TARGET).elf
