extends RefCounted

const ASSET_NAME := "Tech-Repair-Simulator-Windows-x64.zip"
const MAX_PACKAGE_BYTES := 256 * 1024 * 1024


static func valid_repository(value: String) -> bool:
	var format := RegEx.create_from_string("^[A-Za-z0-9][A-Za-z0-9-]{0,38}/[A-Za-z0-9][A-Za-z0-9_.-]{0,99}$")
	return format.search(value) != null


static func version_parts(tag: String) -> PackedInt32Array:
	var pattern := RegEx.create_from_string("^v(0|[1-9][0-9]{0,8})\\.(0|[1-9][0-9]{0,8})\\.(0|[1-9][0-9]{0,8})$")
	var match_result := pattern.search(tag)
	if match_result == null:
		return PackedInt32Array()
	return PackedInt32Array([int(match_result.get_string(1)), int(match_result.get_string(2)), int(match_result.get_string(3))])


static func is_newer(candidate: String, installed: String) -> bool:
	var left := version_parts(candidate)
	var right := version_parts(installed)
	if left.is_empty():
		return false
	if right.is_empty():
		return true
	for index in 3:
		if left[index] != right[index]:
			return left[index] > right[index]
	return false


static func parse(data: Variant, repository: String, fixture_base: String = "") -> Dictionary:
	if not data is Dictionary or data.get("draft", false) or data.get("prerelease", false):
		return {}
	var tag: Variant = data.get("tag_name")
	var assets: Variant = data.get("assets")
	if not tag is String or version_parts(tag).is_empty() or not assets is Array:
		return {}
	var expected_url := "https://github.com/%s/releases/download/%s/%s" % [repository, tag, ASSET_NAME]
	if not fixture_base.is_empty():
		expected_url = fixture_base + "/" + ASSET_NAME
	var digest_pattern := RegEx.create_from_string("^sha256:[a-fA-F0-9]{64}$")
	for asset in assets:
		if not asset is Dictionary or asset.get("name") != ASSET_NAME:
			continue
		var bytes: Variant = asset.get("size")
		var digest: Variant = asset.get("digest")
		var url: Variant = asset.get("browser_download_url")
		if not (bytes is int or bytes is float) or bytes <= 0 or bytes > MAX_PACKAGE_BYTES or floorf(bytes) != bytes:
			return {}
		if not digest is String or digest_pattern.search(digest) == null:
			return {}
		if not url is String or url.nocasecmp_to(expected_url) != 0:
			return {}
		return {"version": tag, "bytes": int(bytes), "hash": digest.substr(7).to_lower(), "url": url}
	return {}
