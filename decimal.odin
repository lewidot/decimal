// Package decimal provides fixed-point decimal arithmetic using an i64 backing value
// with an i8 scale (digits after the decimal point).
//
// Precision limits:
//   - i64 supports values up to ±9,223,372,036,854,775,807 (~9.2 × 10¹⁸)
//   - Maximum useful scale is 18 (pow10(18) fits in i64, pow10(19) does not)
//   - Arithmetic operations will panic on overflow rather than silently producing
//     incorrect results
//
// For applications requiring arbitrary precision, consider using core:math/big.

package decimal

import "base:intrinsics"
import "core:fmt"
import "core:strings"

Ordering :: enum {
	Less,
	Equal,
	Greater,
}

Rounding_Mode :: enum {
	Truncate, // Always round toward zero
	Half_Up, // Round 0.5 away from zero
	// Half_Down, // Round 0.5 toward zero
	// Half_Even, // Banker's rounding: 0.5 rounds to nearest even
}

Decimal :: struct {
	value: i64,
	scale: i8,
}

// Create a new Decimal.
make_decimal :: proc(value: i64, scale: i8) -> Decimal {
	assert(scale >= 0, "decimal: negative scale not supported")
	return Decimal{value, scale}
}

// Create a new Decimal from an integer.
from_i64 :: proc(value: i64) -> Decimal {
	return Decimal{value, 0}
}

// Convert Decimal to f64.
//
// value / 10^scale
to_f64 :: proc(d: Decimal) -> f64 {
	return f64(d.value) / f64(pow10(d.scale))
}

// Convert Decimal to string.
to_string :: proc(d: Decimal, allocator := context.allocator) -> string {
	// Allocate a string builder.
	builder := strings.builder_make(allocator)

	// Handle negative sign.
	if d.value < 0 {
		strings.write_byte(&builder, '-')
	}

	// Temporarily allocate a string for the absolute value.
	abs_value := abs(d.value)
	abs_str := fmt.tprintf("%d", abs_value)

	// If the scale is 0, then we can return the string as is.
	if d.scale == 0 {
		strings.write_string(&builder, abs_str)
		return strings.to_string(builder)
	}

	// Get the len of the absolute value string.
	str_len := len(abs_str)

	if int(d.scale) >= str_len {
		// Need leading zeros (0.007)
		num_leading_zeros := int(d.scale) - str_len
		strings.write_string(&builder, "0.")

		for _ in 0 ..< num_leading_zeros {
			strings.write_byte(&builder, '0')
		}
		strings.write_string(&builder, abs_str)
	} else {
		// Normal case (123.45)
		decimal_pos := str_len - int(d.scale)
		strings.write_string(&builder, abs_str[:decimal_pos])
		strings.write_byte(&builder, '.')
		strings.write_string(&builder, abs_str[decimal_pos:])
	}

	return strings.to_string(builder)
}


add :: proc(d1, d2: Decimal) -> Decimal {
	// Align scale
	value1, value2, scale := align_scales(d1, d2)

	return make_decimal(checked_add(value1, value2), scale)
}

subtract :: proc(d1, d2: Decimal) -> Decimal {
	// Align scale
	value1, value2, scale := align_scales(d1, d2)

	return make_decimal(checked_sub(value1, value2), scale)
}

multiply :: proc(d1, d2: Decimal) -> Decimal {
	// Multiply values
	value := checked_mul(d1.value, d2.value)

	// Add scales
	scale := d1.scale + d2.scale

	return make_decimal(value, scale)
}

divide :: proc(
	d1, d2: Decimal,
	precision: i8 = 2,
	rounding: Rounding_Mode = Rounding_Mode.Half_Up,
) -> Decimal {
	// Panic on division by zero
	assert(d2.value != 0, "decimal: division by zero")

	// Calculate scale adjustment
	scale_adjustment := precision + d2.scale - d1.scale

	// Scale up d1 value
	d1_scaled: i64
	if scale_adjustment >= 0 {
		d1_scaled = checked_mul(d1.value, pow10(scale_adjustment))
	} else {
		// Negative adjustment means divide
		d1_scaled = d1.value / pow10(-scale_adjustment)
	}

	// Calculate quotient and remainder
	quotient := d1_scaled / d2.value
	remainder := d1_scaled % d2.value

	switch rounding {
	case .Truncate:
	// Do nothing, quotient is already truncated
	case .Half_Up:
		// Round up if remainder is at least half the divisor
		// Use absolute values to handle negative numbers correctly
		if abs(remainder) * 2 >= abs(d2.value) {
			quotient += 1 if quotient >= 0 else -1
		}

	}

	return make_decimal(quotient, precision)
}

// Normalize a Decimal by removing trailing zeros.
//
// This reduces the scale to the minimum needed to represent the value,
// e.g. 1.2500 (value=12500, scale=4) becomes 1.25 (value=125, scale=2).
normalize :: proc(d: Decimal) -> Decimal {
	if d.value == 0 {
		return Decimal{0, 0}
	}
	v := d.value
	s := d.scale
	for s > 0 && v % 10 == 0 {
		v /= 10
		s -= 1
	}
	return Decimal{v, s}
}

// Check equality of two Decimals.
equal :: proc(d1, d2: Decimal) -> bool {
	v1, v2, _ := align_scales(d1, d2)
	return v1 == v2
}


compare :: proc(d1, d2: Decimal) -> Ordering {
	v1, v2, _ := align_scales(d1, d2)
	if v1 < v2 do return .Less
	if v1 > v2 do return .Greater
	return .Equal
}

// Calculate 10^n using integer multiplication.
// Returns 10 to the power of n (e.g., pow10(3) = 1000).
@(private)
pow10 :: proc(n: i8, loc := #caller_location) -> i64 {
	result: i64 = 1
	for i: i8 = 0; i < n; i += 1 {
		result = checked_mul(result, 10, loc)
	}
	return result
}

// Align the scales of two Decimals.
@(private)
align_scales :: proc(d1, d2: Decimal) -> (value1: i64, value2: i64, scale: i8) {
	// Get the larger scale
	scale = max(d1.scale, d2.scale)

	// Scale up d1 if needed
	value1 = checked_mul(d1.value, pow10(scale - d1.scale))

	// Scale up d2 if needed
	value2 = checked_mul(d2.value, pow10(scale - d2.scale))

	return
}

// Multiplication helper that checks for overflow and panics.
@(private)
checked_mul :: proc(a, b: i64, loc := #caller_location) -> i64 {
	result, overflow := intrinsics.overflow_mul(a, b)
	assert(!overflow, "decimal overflow: multiplication", loc)
	return result
}

// Add helper that checks for overflow and panics.
@(private)
checked_add :: proc(a, b: i64, loc := #caller_location) -> i64 {
	result, overflow := intrinsics.overflow_add(a, b)
	assert(!overflow, "decimal overflow: addition", loc)
	return result
}

// Subtract helper that checks for overflow and panics.
@(private)
checked_sub :: proc(a, b: i64, loc := #caller_location) -> i64 {
	result, overflow := intrinsics.overflow_sub(a, b)
	assert(!overflow, "decimal overflow: subtraction", loc)
	return result
}
