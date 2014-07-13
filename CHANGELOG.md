CHANGELOG
=========

v0.2:
Fairly large update, with labels being implemented (no longer just the instruction number). The implementation could be sped up in a future version. Opening files passed on the command line appears to be buggy so I did not implement it here.

Bugs fixed:
- The stack copy instruction is now zero indexed from the top of the stack rather than the bottom (which would be bad)
- The heap instructions now remove the arguments passed to them.
- The stack copy instruction also did not save registers.
- Label processing is shifted to the first pass.
- The Hello World program is more interesting.

v0.11:
Fixed the execution function of the interpreter to be faster and less silly.
It now looks up the function in an array of addresses using the function number
as an index and calls it (instead of checking through each function one at a time).

v0.1:
Just released! Still has a lot of issues, but is functional.
