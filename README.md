# decimal

A decimal package for the Odin programming language.

This is a learning experiment for me, so it may not be fully featured or correctly implemented... yet!

## Precision & Overflow

This library uses `i64` internally, which means:

- Values can range from approximately **-9.2 × 10¹⁸** to **9.2 × 10¹⁸**
- The maximum useful scale is **18** decimal places
- The product of two values must also fit in `i64` — for example, multiplying
  two 10-digit numbers may overflow

Arithmetic operations (`add`, `subtract`, `multiply`, `divide`) will **panic**
on overflow rather than silently returning incorrect results. If your use case
involves very large values or high-precision chained operations, validate that
intermediate results stay within `i64` bounds.

For arbitrary-precision arithmetic, consider `core:math/big`.
