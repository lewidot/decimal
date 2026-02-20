package decimal

import "core:testing"

@(test)
make_positive :: proc(t: ^testing.T) {
	d := make_decimal(12345, 2)

	testing.expect(t, d.value == 12345)
	testing.expect(t, d.scale == 2)
}

@(test)
make_negative :: proc(t: ^testing.T) {
	d := make_decimal(-12345, 2)

	testing.expect(t, d.value == -12345)
	testing.expect(t, d.scale == 2)
}

@(test)
make_whole :: proc(t: ^testing.T) {
	d := make_decimal(12345, 0)

	testing.expect(t, d.value == 12345)
	testing.expect(t, d.scale == 0)
}

@(test)
to_f64_tests :: proc(t: ^testing.T) {
	Test_Case :: struct {
		name:     string,
		value:    i64,
		scale:    i8,
		expected: f64,
	}

	test_cases := []Test_Case {
		{"basic", 12345, 2, 123.45},
		{"whole_number", 1000, 0, 1000.0},
		{"small", 7, 3, 0.007},
		{"negative", -999, 1, -99.9},
	}

	for tc in test_cases {
		d := make_decimal(tc.value, tc.scale)
		result := to_f64(d)
		testing.expectf(
			t,
			result == tc.expected,
			"[%s] expected %v, got %v",
			tc.name,
			tc.expected,
			result,
		)
	}
}

@(test)
to_string_tests :: proc(t: ^testing.T) {
	Test_Case :: struct {
		name:     string,
		value:    i64,
		scale:    i8,
		expected: string,
	}

	test_cases := []Test_Case {
		{"basic", 12345, 2, "123.45"},
		{"whole_number", 12345, 0, "12345"},
		{"negative", -999, 1, "-99.9"},
		{"small", 7, 3, "0.007"},
		{"zero", 0, 0, "0"},
		{"zero_with_scale", 0, 2, "0.00"},
		{"negative_small", -7, 3, "-0.007"},
		{"large", 12345678999, 2, "123456789.99"},
	}

	for tc in test_cases {
		d := make_decimal(tc.value, tc.scale)
		str := to_string(d)
		defer delete(str)
		testing.expectf(
			t,
			str == tc.expected,
			"[%s] expected '%s', got '%s'",
			tc.name,
			tc.expected,
			str,
		)
	}
}

@(test)
add_tests :: proc(t: ^testing.T) {
	Test_Case :: struct {
		name:           string,
		d1_value:       i64,
		d1_scale:       i8,
		d2_value:       i64,
		d2_scale:       i8,
		expected_value: i64,
		expected_scale: i8,
	}

	test_cases := []Test_Case {
		{"same_scale", 12345, 2, 6789, 2, 19134, 2},
		{"different_scale", 51, 1, 7, 3, 5107, 3},
		{"positive_negative_pos", 12345, 2, -50, 0, 7345, 2},
		{"positive_negative_neg", 50, 0, -12345, 2, -7345, 2},
		{"negatives", -505, 1, -3025, 2, -8075, 2},
		{"cancel_to_zero", 10000, 2, -10000, 2, 0, 2},
	}

	for tc in test_cases {
		d1 := make_decimal(tc.d1_value, tc.d1_scale)
		d2 := make_decimal(tc.d2_value, tc.d2_scale)
		result := add(d1, d2)

		testing.expectf(
			t,
			result.value == tc.expected_value,
			"[%s] expected value %v, got %v",
			tc.name,
			tc.expected_value,
			result.value,
		)
		testing.expectf(
			t,
			result.scale == tc.expected_scale,
			"[%s] expected scale %v, got %v",
			tc.name,
			tc.expected_scale,
			result.scale,
		)
	}
}

@(test)
subtract_tests :: proc(t: ^testing.T) {
	Test_Case :: struct {
		name:           string,
		d1_value:       i64,
		d1_scale:       i8,
		d2_value:       i64,
		d2_scale:       i8,
		expected_value: i64,
		expected_scale: i8,
	}
	test_cases := []Test_Case {
		{"same_scale", 12345, 2, 5000, 2, 7345, 2},
		{"different_scale", 51, 1, 7, 3, 5093, 3},
		{"result_negative", 5000, 2, 12345, 2, -7345, 2},
		{"subtract_negative", 5000, 2, -3000, 2, 8000, 2},
		{"negative_minus_positive", -5000, 2, 3000, 2, -8000, 2},
		{"two_negatives", -5000, 2, -3000, 2, -2000, 2},
		{"equals_zero", 10000, 2, 10000, 2, 0, 2},
	}
	for tc in test_cases {
		d1 := make_decimal(tc.d1_value, tc.d1_scale)
		d2 := make_decimal(tc.d2_value, tc.d2_scale)
		result := subtract(d1, d2)
		testing.expectf(
			t,
			result.value == tc.expected_value,
			"[%s] expected value %v, got %v",
			tc.name,
			tc.expected_value,
			result.value,
		)
		testing.expectf(
			t,
			result.scale == tc.expected_scale,
			"[%s] expected scale %v, got %v",
			tc.name,
			tc.expected_scale,
			result.scale,
		)
	}
}

@(test)
multiply_tests :: proc(t: ^testing.T) {
	Test_Case :: struct {
		name:           string,
		d1_value:       i64,
		d1_scale:       i8,
		d2_value:       i64,
		d2_scale:       i8,
		expected_value: i64,
		expected_scale: i8,
	}
	test_cases := []Test_Case {
		{"basic", 12345, 2, 2, 0, 24690, 2},
		{"both_decimals", 125, 1, 25, 1, 3125, 2},
		{"small_numbers", 5, 1, 2, 1, 10, 2},
		{"negative", 105, 1, -2, 0, -210, 1},
		{"two_negatives", -55, 1, -20, 1, 1100, 2},
		{"multiply_by_zero", 12345, 2, 0, 0, 0, 2},
		{"multiply_by_one", 12345, 2, 1, 0, 12345, 2},
		{"high_precision", 1, 3, 1, 3, 1, 6},
	}
	for tc in test_cases {
		d1 := make_decimal(tc.d1_value, tc.d1_scale)
		d2 := make_decimal(tc.d2_value, tc.d2_scale)
		result := multiply(d1, d2)
		testing.expectf(
			t,
			result.value == tc.expected_value,
			"[%s] expected value %v, got %v",
			tc.name,
			tc.expected_value,
			result.value,
		)
		testing.expectf(
			t,
			result.scale == tc.expected_scale,
			"[%s] expected scale %v, got %v",
			tc.name,
			tc.expected_scale,
			result.scale,
		)
	}
}

@(test)
divide_tests :: proc(t: ^testing.T) {
	Test_Case :: struct {
		name:           string,
		d1_value:       i64,
		d1_scale:       i8,
		d2_value:       i64,
		d2_scale:       i8,
		precision:      i8,
		expected_value: i64,
		expected_scale: i8,
	}
	test_cases := []Test_Case {
		// Basic cases
		{"basic_default_precision", 105, 1, 2, 0, 2, 525, 2}, // 10.5/2 = 5.25 ✓
		{"whole_number_result", 100, 0, 2, 0, 2, 5000, 2}, // 100/2 = 50.00 ✓
		{"divide_by_one", 12345, 2, 1, 0, 2, 12345, 2}, // 123.45/1 = 123.45 ✓

		// Rounding cases (these need correction)
		{"both_decimals", 1234, 2, 5678, 2, 2, 22, 2}, // 12.34/56.78 = 0.217... → 0.22
		{"high_precision", 1234, 2, 5678, 2, 9, 217330046, 9}, // (was 217330046)

		// Negative cases
		{"negative_dividend", -105, 1, 2, 0, 2, -525, 2}, // -10.5/2 = -5.25 ✓
		{"negative_divisor", 105, 1, -2, 0, 2, -525, 2}, // 10.5/-2 = -5.25 ✓
		{"both_negative", -105, 1, -2, 0, 2, 525, 2}, // -10.5/-2 = 5.25 ✓

		// Edge cases
		{"small_divisor", 1005, 1, 3, 2, 2, 335000, 2}, // 100.5/0.03 = 3350 ✓
		{"precision_zero", 105, 1, 2, 0, 0, 5, 0}, // 10.5/2 = 5 (truncated to 0 decimals) ✓

		// Additional rounding test cases
		{"round_down_example", 100, 0, 3, 0, 2, 3333, 2}, // 100/3 = 33.333... → 33.33
		{"round_up_example", 100, 0, 6, 0, 2, 1667, 2}, // 100/6 = 16.666... → 16.67
		{"exactly_half", 15, 0, 2, 0, 1, 75, 1}, // 15/2 = 7.5 → 7.5 (no rounding, exact)
		{"just_over_half", 151, 1, 2, 0, 1, 76, 1}, // 15.1/2 = 7.55 → 7.6 (round up)
		{"just_under_half", 149, 1, 2, 0, 1, 75, 1}, // 14.9/2 = 7.45 → 7.4 (stay)
	}
	for tc in test_cases {
		d1 := make_decimal(tc.d1_value, tc.d1_scale)
		d2 := make_decimal(tc.d2_value, tc.d2_scale)
		result := divide(d1, d2, tc.precision)
		testing.expectf(
			t,
			result.value == tc.expected_value,
			"[%s] expected value %v, got %v",
			tc.name,
			tc.expected_value,
			result.value,
		)
		testing.expectf(
			t,
			result.scale == tc.expected_scale,
			"[%s] expected scale %v, got %v",
			tc.name,
			tc.expected_scale,
			result.scale,
		)
	}
}


@(test)
from_i64_tests :: proc(t: ^testing.T) {
	Test_Case :: struct {
		name:           string,
		input:          i64,
		expected_value: i64,
		expected_scale: i8,
	}

	test_cases := []Test_Case {
		{"positive", 12345, 12345, 0},
		{"negative", -12345, -12345, 0},
		{"zero", 0, 0, 0},
	}

	for tc in test_cases {
		result := from_i64(tc.input)
		testing.expectf(
			t,
			result.value == tc.expected_value,
			"[%s] expected value %v, got %v",
			tc.name,
			tc.expected_value,
			result.value,
		)
		testing.expectf(
			t,
			result.scale == tc.expected_scale,
			"[%s] expected scale %v, got %v",
			tc.name,
			tc.expected_scale,
			result.scale,
		)
	}
}

@(test)
normalize_tests :: proc(t: ^testing.T) {
	Test_Case :: struct {
		name:           string,
		value:          i64,
		scale:          i8,
		expected_value: i64,
		expected_scale: i8,
	}

	test_cases := []Test_Case {
		{"no_trailing_zeros", 12345, 2, 12345, 2},
		{"trailing_zeros", 12500, 4, 125, 2},
		{"all_trailing_zeros", 100, 2, 1, 0},
		{"zero_value", 0, 5, 0, 0},
		{"zero_no_scale", 0, 0, 0, 0},
		{"negative_trailing", -4500, 3, -45, 1},
		{"whole_number", 42, 0, 42, 0},
		{"single_trailing", 120, 1, 12, 0},
	}

	for tc in test_cases {
		d := make_decimal(tc.value, tc.scale)
		result := normalize(d)
		testing.expectf(
			t,
			result.value == tc.expected_value,
			"[%s] expected value %v, got %v",
			tc.name,
			tc.expected_value,
			result.value,
		)
		testing.expectf(
			t,
			result.scale == tc.expected_scale,
			"[%s] expected scale %v, got %v",
			tc.name,
			tc.expected_scale,
			result.scale,
		)
	}
}

@(test)
equal_tests :: proc(t: ^testing.T) {
	Test_Case :: struct {
		name:     string,
		d1_value: i64,
		d1_scale: i8,
		d2_value: i64,
		d2_scale: i8,
		expected: bool,
	}

	test_cases := []Test_Case {
		{"same_representation", 12345, 2, 12345, 2, true},
		{"different_scale_equal", 100, 2, 1, 0, true},
		{"different_scale_equal_2", 1250, 3, 125, 2, true},
		{"not_equal", 12345, 2, 12346, 2, true == false},
		{"different_scale_not_equal", 100, 2, 2, 0, false},
		{"zero_variants", 0, 0, 0, 3, true},
		{"positive_vs_negative", 100, 2, -100, 2, false},
		{"negative_equal", -125, 1, -1250, 2, true},
	}

	for tc in test_cases {
		d1 := make_decimal(tc.d1_value, tc.d1_scale)
		d2 := make_decimal(tc.d2_value, tc.d2_scale)
		result := equal(d1, d2)
		testing.expectf(
			t,
			result == tc.expected,
			"[%s] expected %v, got %v",
			tc.name,
			tc.expected,
			result,
		)
	}
}
