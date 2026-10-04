# Renders the flat-coloured medicine bottle GLB to a transparent PNG, used when the 3D engine is unavailable.
# Usage: python3 scripts/render-medicine-preview.py entry/src/main/resources/rawfile/models/medicine_3d.glb \
#   entry/src/main/resources/base/media/medicine_bottle_preview.png
import json, struct, zlib, math, sys
src, out, W, H = sys.argv[1], sys.argv[2], 480, 400
SS = 3
d = open(src, 'rb').read()
jl = struct.unpack('<I', d[12:16])[0]
j = json.loads(d[20:20 + jl])
binstart = 20 + jl + 8
blob = d[binstart:]
def acc(i):
    a = j['accessors'][i]; bv = j['bufferViews'][a['bufferView']]
    off = bv.get('byteOffset', 0) + a.get('byteOffset', 0)
    n = {'SCALAR': 1, 'VEC3': 3}[a['type']]
    fmt = {5126: 'f', 5125: 'I', 5123: 'H'}[a['componentType']]
    size = struct.calcsize(fmt)
    stride = bv.get('byteStride', size * n)
    return [struct.unpack_from('<' + fmt * n, blob, off + k * stride) for k in range(a['count'])]
def lin2srgb(c):
    c = max(0.0, min(1.0, c))
    return 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055
tris = []
for node in j['nodes']:
    t = node.get('translation', [0, 0, 0])
    for p in j['meshes'][node['mesh']]['primitives']:
        pos = acc(p['attributes']['POSITION']); nor = acc(p['attributes']['NORMAL'])
        idx = [i[0] for i in acc(p['indices'])]
        col = j['materials'][p['material']]['pbrMetallicRoughness']['baseColorFactor']
        for k in range(0, len(idx), 3):
            v = [tuple(pos[i][c] + t[c] for c in range(3)) for i in idx[k:k + 3]]
            n = [nor[i] for i in idx[k:k + 3]]
            tris.append((v, n, col))
# Camera: the app's default view (orbit angle 0), slightly raised to show the cap.
cx, cy, cz = -0.55, 1.38, 6.2
fov = math.radians(36)
w, h = W * SS, H * SS
f = (h / 2) / math.tan(fov / 2)
light = (-0.45, 0.55, 0.7); ln = math.sqrt(sum(x * x for x in light)); light = tuple(x / ln for x in light)
zbuf = [1e9] * (w * h); cbuf = [None] * (w * h)
def proj(v):
    x, y, z = v[0] - cx, v[1] - cy, v[2] - cz
    zc = -z
    return (w / 2 + f * x / zc, h / 2 - f * y / zc, zc)
for v, n, col in tris:
    p = [proj(a) for a in v]
    minx = max(0, int(min(q[0] for q in p))); maxx = min(w - 1, int(max(q[0] for q in p)) + 1)
    miny = max(0, int(min(q[1] for q in p))); maxy = min(h - 1, int(max(q[1] for q in p)) + 1)
    (x0, y0, z0), (x1, y1, z1), (x2, y2, z2) = p
    area = (x1 - x0) * (y2 - y0) - (x2 - x0) * (y1 - y0)
    if abs(area) < 1e-9:
        continue
    for py in range(miny, maxy + 1):
        for px in range(minx, maxx + 1):
            sx, sy = px + 0.5, py + 0.5
            w0 = ((x1 - sx) * (y2 - sy) - (x2 - sx) * (y1 - sy)) / area
            w1 = ((x2 - sx) * (y0 - sy) - (x0 - sx) * (y2 - sy)) / area
            w2 = 1 - w0 - w1
            if w0 < 0 or w1 < 0 or w2 < 0:
                continue
            z = w0 * z0 + w1 * z1 + w2 * z2
            i = py * w + px
            if z >= zbuf[i]:
                continue
            zbuf[i] = z
            nx = w0 * n[0][0] + w1 * n[1][0] + w2 * n[2][0]
            ny = w0 * n[0][1] + w1 * n[1][1] + w2 * n[2][1]
            nz = w0 * n[0][2] + w1 * n[1][2] + w2 * n[2][2]
            nl = math.sqrt(nx * nx + ny * ny + nz * nz) or 1
            if nz < 0:  # double-sided: face the camera
                nx, ny, nz = -nx, -ny, -nz
            diff = max(0.0, (nx * light[0] + ny * light[1] + nz * light[2]) / nl)
            k = 0.42 + 0.75 * diff
            cbuf[i] = tuple(lin2srgb(col[c] * k) for c in range(3))
rows = []
for y in range(H):
    row = bytearray([0])
    for x in range(W):
        r = g = b = a = 0.0
        for dy in range(SS):
            for dx in range(SS):
                c = cbuf[(y * SS + dy) * w + x * SS + dx]
                if c is not None:
                    r += c[0]; g += c[1]; b += c[2]; a += 1
        if a:
            row += bytes([int(r / a * 255), int(g / a * 255), int(b / a * 255), int(a / (SS * SS) * 255)])
        else:
            row += bytes(4)
    rows.append(bytes(row))
def chunk(t, data):
    return struct.pack('>I', len(data)) + t + data + struct.pack('>I', zlib.crc32(t + data) & 0xffffffff)
png = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', W, H, 8, 6, 0, 0, 0)) + \
    chunk(b'IDAT', zlib.compress(b''.join(rows), 9)) + chunk(b'IEND', b'')
open(out, 'wb').write(png)
print('ok', len(png))
