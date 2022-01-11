RM=rm -rf
ASM=nasm
AFLAGS=-felf64 -o
LD = ld -o

main: lib.o dict.o main.o
	$(LD) $@ $^

lib.o: lib.asm
	$(ASM) $(AFLAGS) $@ $<

dict.o: dict.asm
	$(ASM) $(AFLAGS) $@ $<

main.o: main.asm colon.inc words.inc
	$(ASM) $(AFLAGS) $@ $<


.PHONY: clean
clean:
	$(RM) main main.o lib.o dict.o
