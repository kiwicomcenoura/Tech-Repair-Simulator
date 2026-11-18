extends RefCounted

const Release := preload("res://release_info.gd")

var version := "v0.1.0"
var fault := ""
var payload := PackedByteArray()
var _hash := ""
var _port := 0
var _listener := TCPServer.new()
var _peers: Array[Dictionary] = []


func start(port: int, package: PackedByteArray) -> Error:
	_port = port
	payload = package
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update(payload)
	_hash = hashing.finish().hex_encode()
	return _listener.listen(port, "127.0.0.1")


func stop() -> void:
	_listener.stop()
	for connection in _peers:
		connection.peer.disconnect_from_host()
	_peers.clear()


func tick() -> void:
	while _listener.is_connection_available():
		_peers.append({"peer": _listener.take_connection(), "input": "", "reply": PackedByteArray(), "sent": 0})
	for index in range(_peers.size() - 1, -1, -1):
		var connection := _peers[index]
		var peer: StreamPeerTCP = connection.peer
		peer.poll()
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			_peers.remove_at(index)
			continue
		if connection.reply.is_empty() and peer.get_available_bytes() > 0:
			connection.input += peer.get_utf8_string(peer.get_available_bytes())
			if "\r\n\r\n" in connection.input:
				connection.reply = _response(connection.input.get_slice(" ", 1))
		if connection.reply.is_empty():
			continue
		var packet: PackedByteArray = connection.reply.slice(connection.sent, connection.sent + 128 * 1024)
		var written := peer.put_partial_data(packet)
		connection.sent += int(written[1])
		if written[0] != OK or connection.sent >= connection.reply.size():
			peer.disconnect_from_host()
			_peers.remove_at(index)


func _response(path: String) -> PackedByteArray:
	var body := PackedByteArray()
	var content_type := "application/octet-stream"
	var status := "200 OK"
	if path == "/latest":
		content_type = "application/json"
		body = JSON.stringify({
			"tag_name": version,
			"assets": [{
				"name": Release.ASSET_NAME,
				"size": payload.size(),
				"digest": "sha256:" + ("0".repeat(64) if fault == "digest" else _hash),
				"browser_download_url": "http://127.0.0.1:%d/%s" % [_port, Release.ASSET_NAME],
			}],
		}).to_utf8_buffer()
	elif path == "/" + Release.ASSET_NAME:
		body = payload
	else:
		status = "404 Not Found"
	var length := body.size()
	if path != "/latest" and fault == "truncate":
		body = body.slice(0, length / 2)
	var response := ("HTTP/1.1 %s\r\nContent-Type: %s\r\nContent-Length: %d\r\nConnection: close\r\n\r\n" % [
		status, content_type, length
	]).to_utf8_buffer()
	response.append_array(body)
	return response
