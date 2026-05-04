class_name HC65Object
extends RefCounted

## HC65 container v1 — see next_steps.md
const VERSION: int = 1
const FLAG_METADATA: int = 1
const FLAG_HELP: int = 2

const HELP_TAG_SYNTAX: int = 1
const HELP_TAG_DESC: int = 2
const HELP_TAG_EXAMPLE: int = 3
const HELP_TAG_END: int = 0


static func _magic_ok(data: PackedByteArray) -> bool:
	if data.size() < 4:
		return false
	return data[0] == 0x48 and data[1] == 0x43 and data[2] == 0x36 and data[3] == 0x35


static func encode(
	load_addr: int,
	entry_addr: int,
	code: PackedByteArray,
	export_name: String,
	help_syntax: String,
	help_desc: String,
	help_examples: Array
) -> PackedByteArray:
	var flags := 0
	var meta := PackedByteArray()
	var en := export_name.strip_edges()
	if en != "":
		flags |= FLAG_METADATA
		var utf := en.to_utf8_buffer()
		meta.append(utf.size() & 0xFF)
		meta.append((utf.size() >> 8) & 0xFF)
		meta.append_array(utf)
	var help_blob := PackedByteArray()
	var has_help := help_syntax.strip_edges() != "" or help_desc.strip_edges() != "" or help_examples.size() > 0
	if has_help:
		flags |= FLAG_HELP
		help_blob.append_array(_help_tlv(HELP_TAG_SYNTAX, help_syntax))
		help_blob.append_array(_help_tlv(HELP_TAG_DESC, help_desc))
		for ex in help_examples:
			help_blob.append_array(_help_tlv(HELP_TAG_EXAMPLE, str(ex)))
		help_blob.append(HELP_TAG_END)
	var out := PackedByteArray()
	out.append(0x48)
	out.append(0x43)
	out.append(0x36)
	out.append(0x35)
	out.append(VERSION & 0xFF)
	out.append((VERSION >> 8) & 0xFF)
	out.append(flags & 0xFF)
	out.append((flags >> 8) & 0xFF)
	out.append(load_addr & 0xFF)
	out.append((load_addr >> 8) & 0xFF)
	out.append(entry_addr & 0xFF)
	out.append((entry_addr >> 8) & 0xFF)
	var cl := code.size()
	out.append(cl & 0xFF)
	out.append((cl >> 8) & 0xFF)
	out.append((cl >> 16) & 0xFF)
	out.append((cl >> 24) & 0xFF)
	out.append_array(code)
	out.append_array(meta)
	out.append_array(help_blob)
	return out


static func _help_tlv(tag: int, text: String) -> PackedByteArray:
	var b := PackedByteArray()
	var utf := text.to_utf8_buffer()
	b.append(tag & 0xFF)
	b.append(utf.size() & 0xFF)
	b.append((utf.size() >> 8) & 0xFF)
	b.append_array(utf)
	return b


## Returns { "ok": bool, "load_addr": int, "entry_addr": int, "code": PackedByteArray,
##   "export_name": String, "help_syntax": String, "help_desc": String, "help_examples": Array,
##   "errors": Array }
static func decode(data: PackedByteArray) -> Dictionary:
	var errs: Array = []
	if data.size() < 16:
		errs.append("HC65: file too small")
		return {"ok": false, "errors": errs}
	if not _magic_ok(data):
		errs.append("HC65: bad magic")
		return {"ok": false, "errors": errs}
	var ver := data[4] | (data[5] << 8)
	if ver != VERSION:
		errs.append("HC65: unsupported version %d" % ver)
		return {"ok": false, "errors": errs}
	var flags := data[6] | (data[7] << 8)
	var load_addr := data[8] | (data[9] << 8)
	var entry_addr := data[10] | (data[11] << 8)
	var code_len := data[12] | (data[13] << 8) | (data[14] << 16) | (data[15] << 24)
	if code_len < 0 or code_len > 65536:
		errs.append("HC65: bad code length")
		return {"ok": false, "errors": errs}
	if data.size() < 16 + code_len:
		errs.append("HC65: truncated code")
		return {"ok": false, "errors": errs}
	var code := data.slice(16, 16 + code_len)
	var pos := 16 + code_len
	var export_name := ""
	var hs := ""
	var hd := ""
	var hexamples: Array = []
	if flags & FLAG_METADATA:
		if pos + 2 > data.size():
			errs.append("HC65: truncated metadata")
			return {"ok": false, "errors": errs}
		var ml := data[pos] | (data[pos + 1] << 8)
		pos += 2
		if pos + ml > data.size():
			errs.append("HC65: truncated export name")
			return {"ok": false, "errors": errs}
		if ml > 0:
			export_name = data.slice(pos, pos + ml).get_string_from_utf8()
		pos += ml
	if flags & FLAG_HELP:
		while pos < data.size():
			var tag := data[pos]
			pos += 1
			if tag == HELP_TAG_END:
				break
			if pos + 2 > data.size():
				errs.append("HC65: truncated help TLV")
				return {"ok": false, "errors": errs}
			var tl := data[pos] | (data[pos + 1] << 8)
			pos += 2
			if pos + tl > data.size():
				errs.append("HC65: truncated help payload")
				return {"ok": false, "errors": errs}
			var chunk := data.slice(pos, pos + tl).get_string_from_utf8()
			pos += tl
			if tag == HELP_TAG_SYNTAX:
				hs = chunk
			elif tag == HELP_TAG_DESC:
				hd = chunk
			elif tag == HELP_TAG_EXAMPLE:
				hexamples.append(chunk)
	return {
		"ok": true,
		"load_addr": load_addr & 0xFFFF,
		"entry_addr": entry_addr & 0xFFFF,
		"code": code,
		"export_name": export_name,
		"help_syntax": hs,
		"help_desc": hd,
		"help_examples": hexamples,
		"errors": errs,
	}
