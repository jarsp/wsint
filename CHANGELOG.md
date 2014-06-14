CHANGELOG
=========

v0.11:
Fixed the execution function of the interpreter to be faster and less silly.
It now looks up the function in an array of addresses using the function number
as an index and calls it (instead of checking through each function one at a time).

v0.1:
Just released! Still has a lot of issues, but is functional.