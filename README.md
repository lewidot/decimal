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

## Installation

Clone or copy this package into your project:

```sh
git clone https://github.com/lewidot/decimal.git

# or as a git submodule
git submodule add https://github.com/lewidot/decimal.git
```

Then import it using a relative path:

```odin
package main

import "decimal"

main :: proc() {
    price := decimal.make_decimal(1999, 2)  // 19.99
    qty := decimal.make_decimal(3, 0)       // 3
    total := decimal.multiply(price, qty)   // 59.97
}
```
