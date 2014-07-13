wsint v 0.1
===========

Introduction:

wsint is a Whitespace interpreter written for MASM, mainly for amusement and educational purposes.

Whitespace is an esoteric programming language created by Edwin Brady and Chris Morris (http://comsoc.dur.ac.uk/whitespace/index.php) which has space, tab, and linefeed as the only tokens in the language, with all other keyboard characters being interpreted as comments. It utilises a virtual stack and a virtual heap to manipulate and store data, and the source code is always quite amusing to look at.

Usage:

Basic usage of the interpreter involves just downloading the executable and creating a file called 'script.ws' in the same directory. Run wsint from the command line to see the results of the interpreter acting on script.ws. The script.ws file in this repo prints "Hello World" to the screen in a slightly non-trivial way.

Compiling:

This interpreter was written for MASM, and compiled on Visual Studio 2010 Express. Currently, it depends on an external library (Irvine32.lib) available at kipirvine.com/asm/examples/index.htm. Although this was compiled in VS2010, I believe other versions should work (just download the correct library version), although I have not tested this. I will eventually work on eliminating the dependency on this library.

In order to test the interpreter, you can follow the instructions at http://kipirvine.com/asm/gettingStartedVS2010/index.htm to set up the appropriate linker/compiler configurations. The script should be called 'script.ws' and placed in the same directory.

Disclaimer:

This is very much still a work in progress. Some features are not fully/properly implemented, and it may be buggy. I'll try my best to fix these problems. For more information, see the changelogs and the TODO.

Quick Syntax Reference:

A more detailed reference is at the Whitespace website.

Comments (ignored by interpreter): Non-space ([SP]), tab ([TB]) or linefeed ([LF]) characters

Numbers are signed integers written in binary, where the first [SP]/[TB] is positive/negative respectively, and the following [SP]/[TB] are 0/1 respectively, from the highest bit to the lowest. [LF] terminates the number. 

Numbers are supposed to be arbitrary precision, but v0.1 of wsint enforces a 32-bit signed integer size. Future versions should rectify this.

Labels are entered in the same way as numbers. There is only one global namespace, however.

In v0.1, creating labels do not affect anything. In order to jump to a specific instruction, simply specify the instruction's number (zero-indexed) as the argument. This has been fixed from v0.2 onwards. 

Stack Operations:

PUSH: [SP][SP]num

COPY: [SP][TB][SP]num

SLIDE: [SP][TB][LF]num

DUPLICATE: [SP][LF][SP]

SWAP: [SP][LF][TB]

DISCARD: [SP][LF][LF]

Arithmetic Operations:

ADD: [TB][SP][SP][SP]

SUB: [TB][SP][SP][TB]

MUL: [TB][SP][SP][LF]

DIV: [TB][SP][TB][SP]

MOD: [TB][SP][TB][TB]

Heap Operations:

STORE: [TB][TB][SP]

LOAD: [TB][TB][TB]

I/O Operations:

OUTCHAR: [TB][LF][SP][SP]

OUTNUM: [TB][LF][SP][TB]

INCHAR: [TB][LF][TB][SP]

INNUM: [TB][LF][TB][TB]

Flow Control:

MAKE LABEL: [LF][SP][SP]lbl

CALL SUBROUTINE: [LF][SP][TB]lbl

UNCOND. JUMP: [LF][SP][LF]lbl

JUMP IF ZERO: [LF][TB][SP]lbl

JUMP IF NEG: [LF][TB][TB]lbl

RETURN FROM SUB.: [LF][TB][LF]

END PROGRAM: [LF][LF][LF]

Enjoy!
