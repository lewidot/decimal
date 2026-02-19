package decimal

import "core:fmt"
import "core:math"
import "core:strings"

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
	divisor := math.pow(10, f64(d.scale))
	return f64(d.value) / divisor
}

// Convert Decimal to string.
to_string :: proc(d: Decimal) -> string {
	value_str := fmt.aprintf("%d", d.value)

	if d.scale == 0 {
		return value_str
	}

	defer delete(value_str)

	// Handle negative sign
	is_negative := d.value < 0
	abs_value_str := is_negative ? value_str[1:] : value_str


	str_len := len(abs_value_str)

	// Case A: Need leading zeros (0.007)
	if int(d.scale) >= str_len {
		num_leading_zeros := int(d.scale) - str_len

		builder := strings.builder_make()
		defer strings.builder_destroy(&builder)

		if is_negative {
			strings.write_string(&builder, "-")
		}
		strings.write_string(&builder, "0.")
		for i := 0; i < num_leading_zeros; i += 1 {
			strings.write_byte(&builder, '0')
		}
		strings.write_string(&builder, abs_value_str)

		return strings.clone(strings.to_string(builder))
	}

	// Case B: Normal case (123.45)
	decimal_pos := str_len - int(d.scale)
	left_part := abs_value_str[:decimal_pos]
	right_part := abs_value_str[decimal_pos:]

	if is_negative {
		return fmt.aprintf("-%s.%s", left_part, right_part)
	}
	return fmt.aprintf("%s.%s", left_part, right_part)
}


add :: proc(d1, d2: Decimal) -> Decimal {
	// Align scale
	value1, value2, scale := align_scales(d1, d2)

	return make_decimal(value1 + value2, scale)
}

subtract :: proc(d1, d2: Decimal) -> Decimal {
	// Align scale
	value1, value2, scale := align_scales(d1, d2)

	return make_decimal(value1 - value2, scale)
}

multiply :: proc(d1, d2: Decimal) -> Decimal {
	// Multiply values
	value := d1.value * d2.value

	// Add scales
	scale := d1.scale + d2.scale

	return make_decimal(value, scale)
}

divide :: proc(
	d1, d2: Decimal,
	precision: i8 = 2,
	rounding: Rounding_Mode = Rounding_Mode.Half_Up,
) -> Decimal {
	// Calculate scale adjustment
	scale_adjustment := precision + d2.scale - d1.scale

	// Scale up d1 value
	d1_scaled: i64
	if scale_adjustment >= 0 {
		d1_scaled = d1.value * pow10(scale_adjustment)
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
			if quotient >= 0 {
				quotient += 1
			} else {
				quotient -= 1
			}
		}

	}

	return make_decimal(quotient, precision)
}

// Calculate 10^n using integer multiplication.
// Returns 10 to the power of n (e.g., pow10(3) = 1000).
@(private)
pow10 :: proc(n: i8) -> i64 {
	result: i64 = 1
	for i: i8 = 0; i < n; i += 1 {
		result *= 10
	}
	return result
}

// Align the scales of two Decimals.
@(private)
align_scales :: proc(d1, d2: Decimal) -> (value1: i64, value2: i64, scale: i8) {
	// Get the larger scale
	scale = max(d1.scale, d2.scale)

	// Scale up d1 if needed
	value1 = d1.value * pow10(scale - d1.scale)

	// Scale up d2 if needed
	value2 = d2.value * pow10(scale - d2.scale)

	return
}
