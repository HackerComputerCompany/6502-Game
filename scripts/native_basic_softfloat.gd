extends RefCounted

## IEEE754 binary32 soft-float ops for BASIC NATIVE runtime mode.
## Bit patterns match GDScript float encode/decode (typically IEEE754 LE).

const MASK_SIGN := 0x80000000
const MASK_EXP := 0x7F800000
const MASK_FRAC := 0x007FFFFF
const EXP_BIAS := 127
const QUIET_NAN := 0x7FC00000


func float_bits(x: float) -> int:
	var b := PackedByteArray()
	b.resize(4)
	b.encode_float(0, x)
	return int(b.decode_u32(0))


func bits_float(u: int) -> float:
	var b := PackedByteArray()
	b.resize(4)
	b.encode_u32(0, u & 0xFFFFFFFF)
	return b.decode_float(0)


func is_nan(bits: int) -> bool:
	var u := bits & 0xFFFFFFFF
	return ((u & MASK_EXP) == MASK_EXP) and ((u & MASK_FRAC) != 0)


func is_inf(bits: int) -> bool:
	var u := bits & 0xFFFFFFFF
	return ((u & MASK_EXP) == MASK_EXP) and ((u & MASK_FRAC) == 0)


func is_zero(bits: int) -> bool:
	return (bits & 0x7FFFFFFF) == 0


func _sign(bits: int) -> int:
	return (bits >> 31) & 1


func _combine(s: int, exp: int, frac23: int) -> int:
	var u := ((s & 1) << 31) | ((exp & 0xFF) << 23) | (frac23 & MASK_FRAC)
	return int(u & 0xFFFFFFFF)


func neg_bits(bits: int) -> int:
	if is_nan(bits):
		return QUIET_NAN
	return bits ^ MASK_SIGN


func sub_bits(a: int, b: int) -> int:
	return add_bits(a, b ^ MASK_SIGN)


func _mag_ge(ea: int, ma: int, eb: int, mb: int) -> bool:
	return ea > eb or (ea == eb and ma >= mb)


func add_bits(ai: int, bi: int) -> int:
	var a := ai & 0xFFFFFFFF
	var b := bi & 0xFFFFFFFF
	if is_nan(a) or is_nan(b):
		return QUIET_NAN
	var a_inf := is_inf(a)
	var b_inf := is_inf(b)
	if a_inf and b_inf:
		if _sign(a) == _sign(b):
			return int(a)
		return QUIET_NAN
	if a_inf:
		return int(a)
	if b_inf:
		return int(b)
	if is_zero(a):
		return int(b)
	if is_zero(b):
		return int(a)

	var sa := _sign(a)
	var sb := _sign(b)
	var ea_a := _norm_exp(a)
	var eb_b := _norm_exp(b)
	var ma_a := _norm_sig(a)
	var mb_b := _norm_sig(b)

	## Big = larger magnitude; shift small mantissa to big's exponent.
	var ea_big: int
	var eb_sma: int
	var ma_big: int
	var mb_sma: int
	var s_big: int
	var s_sma: int
	if _mag_ge(ea_a, ma_a, eb_b, mb_b):
		ea_big = ea_a
		ma_big = ma_a
		s_big = sa
		eb_sma = eb_b
		mb_sma = mb_b
		s_sma = sb
	else:
		ea_big = eb_b
		ma_big = mb_b
		s_big = sb
		eb_sma = ea_a
		mb_sma = ma_a
		s_sma = sa

	var shift := ea_big - eb_sma
	var mb_al := mb_sma
	if shift >= 32:
		mb_al = 0
	else:
		mb_al = mb_sma >> shift

	var sr: int
	var mr: int
	var er := ea_big
	if s_big == s_sma:
		sr = s_big
		mr = ma_big + mb_al
	else:
		sr = s_big
		mr = ma_big - mb_al
		if mr == 0:
			return 0
		if mr < 0:
			mr = -mr
			sr = sr ^ 1

	while mr != 0 and mr < 0x00800000:
		mr <<= 1
		er -= 1
	while mr >= 0x01000000:
		mr = mr >> 1
		er += 1

	if er <= 0:
		return 0
	if er >= 255:
		return _combine(sr, 255, 0)

	var frac := mr & MASK_FRAC
	return _combine(sr, er, frac)


func mul_bits(ai: int, bi: int) -> int:
	var a := ai & 0xFFFFFFFF
	var b := bi & 0xFFFFFFFF
	if is_nan(a) or is_nan(b):
		return QUIET_NAN
	var a_inf := is_inf(a)
	var b_inf := is_inf(b)
	if (a_inf and is_zero(b)) or (b_inf and is_zero(a)):
		return QUIET_NAN
	if a_inf or b_inf:
		return _combine(_sign(a) ^ _sign(b), 255, 0)
	if is_zero(a) or is_zero(b):
		return _combine(_sign(a) ^ _sign(b), 0, 0)

	var sa := _sign(a)
	var sb := _sign(b)
	var ea := _norm_exp(a)
	var eb := _norm_exp(b)
	var ma := _norm_sig(a)
	var mb := _norm_sig(b)
	var sr := sa ^ sb
	var er := ea + eb - EXP_BIAS
	## Product of implicit mantissas scaled down into fixed-point mantissa lane (~IEEE multiply step).
	var sig: int = (ma * mb) >> 23

	while sig >= (1 << 24):
		sig >>= 1
		er += 1
	while sig != 0 and sig < (1 << 23):
		sig <<= 1
		er -= 1

	if er <= 0:
		return _combine(sr, 0, 0)
	if er >= 255:
		return _combine(sr, 255, 0)

	var frac := sig & MASK_FRAC
	return _combine(sr, er, frac)


func div_bits(ai: int, bi: int) -> int:
	var a := ai & 0xFFFFFFFF
	var b := bi & 0xFFFFFFFF
	if is_nan(a) or is_nan(b):
		return QUIET_NAN
	var b_inf := is_inf(b)
	var a_inf := is_inf(a)
	if b_inf:
		return _combine(_sign(a) ^ _sign(b), 0, 0)
	if is_zero(b):
		if is_zero(a):
			return QUIET_NAN
		var sr := _sign(a) ^ _sign(b)
		return _combine(sr, 255, 0)
	if a_inf:
		var sr2 := _sign(a) ^ _sign(b)
		return _combine(sr2, 255, 0)
	if is_zero(a):
		var sx := _sign(a) ^ _sign(b)
		return _combine(sx, 0, 0)

	var sa := _sign(a)
	var sb := _sign(b)
	var ea := _norm_exp(a)
	var eb := _norm_exp(b)
	var ma := _norm_sig(a)
	var mb := _norm_sig(b)
	var sr := sa ^ sb
	var er := ea - eb + EXP_BIAS

	var num: int = ma << 23
	var q: int = int(float(num) / mb)
	var rem: int = num % mb

	while q >= 0x01000000:
		q >>= 1
		er += 1
	while q != 0 and q < 0x00800000:
		q <<= 1
		er -= 1
		if er <= 0:
			break

	## Round to nearest (tie down): append remainder bit.
	if rem * 2 >= mb:
		q += 1
		if q >= 0x01000000:
			q >>= 1
			er += 1

	if er <= 0:
		return _combine(sr, 0, 0)
	if er >= 255:
		return _combine(sr, 255, 0)

	var frac := q & MASK_FRAC
	return _combine(sr, er, frac)


## Normalized exponent [1..254] for finite non-zero values after extracting hidden bit into mantissa.
func _norm_exp(bits: int) -> int:
	var e := (bits >> 23) & 0xFF
	var f := bits & MASK_FRAC
	if e == 0:
		## Denormal: shift frac until implicit bit appears.
		var sig := f
		if sig == 0:
			return 1
		var adj := 1 - EXP_BIAS
		while sig < 0x00800000:
			sig <<= 1
			adj -= 1
		return adj
	return e


## Mantissa with bit 23 set (0x00800000..0x00FFFFFF range for normalized internals).
func _norm_sig(bits: int) -> int:
	var e := (bits >> 23) & 0xFF
	var f := bits & MASK_FRAC
	if e == 0:
		var sig := f
		if sig == 0:
			return 0
		while sig < 0x00800000:
			sig <<= 1
		return sig
	return f | 0x00800000


func lt_bits(a: int, b: int) -> bool:
	if is_nan(a) or is_nan(b):
		return false
	return bits_float(a) < bits_float(b)


func lte_bits(a: int, b: int) -> bool:
	if is_nan(a) or is_nan(b):
		return false
	return bits_float(a) <= bits_float(b)


func gt_bits(a: int, b: int) -> bool:
	if is_nan(a) or is_nan(b):
		return false
	return bits_float(a) > bits_float(b)


func gte_bits(a: int, b: int) -> bool:
	if is_nan(a) or is_nan(b):
		return false
	return bits_float(a) >= bits_float(b)


func eq_bits(a: int, b: int) -> bool:
	var ua := a & 0xFFFFFFFF
	var ub := b & 0xFFFFFFFF
	if is_nan(ua) or is_nan(ub):
		return false
	## +0 / -0 compare equal.
	if ((ua | ub) & 0x7FFFFFFF) == 0:
		return true
	return ua == ub


func ne_bits(a: int, b: int) -> bool:
	return not eq_bits(a, b)
