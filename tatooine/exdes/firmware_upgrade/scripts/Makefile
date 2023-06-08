.PHONY: clean

# Target ELF name
TARGET=fpga_upgrade_golden

# Compiler flags
CFLAGS=-O2 -Wall

# Default
all: $(TARGET)

$(TARGET): $(TARGET).c
	gcc $(CFLAGS) -o $@ $<

clean:
	rm -f $(TARGET)
