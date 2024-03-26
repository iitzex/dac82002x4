TARGET=i2s
TOP=${TARGET}

OBJS+=${TARGET}.v 

all: ${TARGET}.bit 

$(TARGET).json: $(OBJS)
	yosys -p "synth_ecp5 -top ${TOP} -json $@" $(OBJS)

$(TARGET)_out.config: $(TARGET).json pinmap.lpf
	nextpnr-ecp5 --25k --package CABGA256 --speed 6 --json $< --textcfg $@ --lpf pinmap.lpf --freq 65 --lpf-allow-unconstrained 

$(TARGET).bit: $(TARGET)_out.config
	ecppack --compress --svf ${TARGET}.svf $< $@

${TARGET}.svf: ${TARGET}.bit

sim: ${OBJS} ${TARGET}.bit
	iverilog -o ${TARGET}.out ${TARGET}_tb.v ${OBJS}
	vvp ${TARGET}.out
	# gtkwave tb.vcd tb.gtkw &

probe:
	ecpdap probes 

run: ${TARGET}.bit
	ecpdap program --freq 10000 ${TARGET}.bit

write: ${TARGET}.bit
	ecpdap flash write ${TARGET}.bit

unprotect:
	ecpdap flash unprotect

clean:
	rm -f *.svf *.bit *.config *.json *.ys *bom *out

.PHONY: all prog clean
