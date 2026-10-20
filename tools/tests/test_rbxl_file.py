import struct
import sys
from pathlib import Path

def fail(message):
    raise SystemExit("FAIL RBXL load check: " + message)

def u32(data, offset):
    if offset + 4 > len(data):
        fail("truncated 32-bit field")
    return struct.unpack_from("<I", data, offset)[0]

def lz4_decompress(block, expected_length):
    out = bytearray()
    i = 0
    while i < len(block):
        token = block[i]
        i += 1
        literal = token >> 4
        if literal == 15:
            while True:
                if i >= len(block): fail("truncated literal extension")
                v = block[i]
                i += 1
                literal += v
                if v != 255: break
        if i + literal > len(block): fail("literal exceeds chunk boundary")
        out.extend(block[i:i + literal])
        i += literal
        if i == len(block): break
        if i + 2 > len(block): fail("truncated match offset")
        offset = block[i] | (block[i + 1] << 8)
        i += 2
        if offset == 0 or offset > len(out): fail("invalid LZ4 match offset")
        length = (token & 15) + 4
        if (token & 15) == 15:
            while True:
                if i >= len(block): fail("truncated match extension")
                v = block[i]
                i += 1
                length += v
                if v != 255: break
        for _ in range(length):
            out.append(out[-offset])
    if len(out) != expected_length:
        fail(f"LZ4 decoded {len(out)} bytes, expected {expected_length}")
    return bytes(out)

def parse_inst(raw):
    if len(raw) < 13: fail("short INST payload")
    idx = u32(raw, 0)
    n = u32(raw, 4)
    end_name = 8 + n
    if end_name + 5 > len(raw): fail("truncated INST class name")
    name = raw[8:end_name].decode("utf-8")
    return idx, name, raw[end_name], u32(raw, end_name + 1)

path = Path(sys.argv[1] if len(sys.argv) > 1 else "build/StealAnAnimal.rbxl")
if not path.is_file(): fail(f"file not found: {path}")
data = path.read_bytes()
if len(data) < 32: fail("short RBXL header")
if data[:8] != b"<roblox!" or data[8:14] != bytes.fromhex("89ff0d0a1a0a"): fail("not an RBXL binary place")
version = struct.unpack_from("<H", data, 14)[0]
if version != 0: fail(f"unsupported RBXL version {version}")
declared_classes, declared_instances = u32(data, 16), u32(data, 20)
if data[24:32] != bytes(8): fail("reserved header bytes are not zero")
offset, classes, instance_total, parents, ends = 32, {}, 0, 0, 0
while offset < len(data):
    if offset + 16 > len(data): fail("truncated chunk header")
    sig = data[offset:offset + 4]
    compressed, uncompressed = u32(data, offset + 4), u32(data, offset + 8)
    if data[offset + 12:offset + 16] != bytes(4): fail(f"reserved chunk bytes set in {sig!r}")
    start = offset + 16
    stop = start + (compressed if compressed else uncompressed)
    if stop > len(data): fail(f"chunk {sig!r} extends outside the file")
    payload = data[start:stop]
    raw = lz4_decompress(payload, uncompressed) if compressed else payload
    if not compressed and len(raw) != uncompressed: fail(f"length mismatch for {sig!r}")
    if sig == b"INST":
        idx, name, service, count = parse_inst(raw)
        if idx in classes: fail(f"duplicate class index {idx}")
        classes[idx] = {"name": name, "service": service, "count": count}
        instance_total += count
    elif sig == b"PRNT":
        parents += 1
    elif sig == b"END\x00":
        ends += 1
        if compressed or raw != b"</roblox>": fail("invalid END marker")
        if stop != len(data): fail("trailing bytes after END")
    offset = stop
    if sig == b"END\x00": break
if offset != len(data): fail("file parser did not consume all bytes")
if len(classes) != declared_classes: fail(f"header declares {declared_classes} classes; found {len(classes)}")
if instance_total != declared_instances: fail(f"header declares {declared_instances} instances; found {instance_total}")
if parents != 1 or ends != 1: fail(f"expected one PRNT and one END; got {parents} and {ends}")
counts = {item["name"]: item["count"] for item in classes.values()}
if counts.get("Workspace") != 1: fail("serialized place has no Workspace service")
if counts.get("Part", 0) < 300: fail(f"only {counts.get('Part', 0)} Parts were serialized; map missing")
if counts.get("Script", 0) < 1 or counts.get("LocalScript", 0) < 1 or counts.get("ModuleScript", 0) < 3:
    fail("server, client, or shared modules missing from place")
print(f"PASS RBXL load integrity: {path} ({len(data)} bytes), {declared_classes} classes, {instance_total} instances, {counts.get('Part', 0)} Parts, all LZ4 chunks decoded, PRNT/END valid.")
