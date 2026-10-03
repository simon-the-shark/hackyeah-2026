## 5. Media and Drawing Components

### Video

Video playback component.

**Constructor:** `Video(value: VideoOptions)`

| Parameter | Type | Required | Default | Description |
|------|------|------|--------|------|
| src | string \| Resource | Yes | — | Video source |
| currentProgressRate | number \| PlaybackSpeed | No | 1 | Playback speed |
| previewUri | string \| Resource \| PixelMap | No | — | Preview image |
| controller | VideoController | No | — | Controller |

**Properties and methods:**

| Method | Signature | Default | Description |
|------|------|--------|------|
| .muted | `.muted(value: boolean)` | false | Mute |
| .autoPlay | `.autoPlay(value: boolean)` | false | Auto-play |
| .controls | `.controls(value: boolean)` | true | Show controls |
| .loop | `.loop(value: boolean)` | false | Loop playback |
| .objectFit | `.objectFit(value: ImageFit)` | Cover | Fit mode |

**Events:**

| Events | Signature | Description |
|------|------|------|
| .onStart | `.onStart(event: () => void)` | Playback started |
| .onPause | `.onPause(event: () => void)` | Paused |
| .onFinish | `.onFinish(event: () => void)` | Playback finished |
| .onError | `.onError(event: () => void)` | Error |
| .onPrepared | `.onPrepared(callback: Callback<PreparedInfo>)` | Prepared; PreparedInfo has a `.duration` property (seconds) |
| .onSeeking | `.onSeeking(callback: Callback<PlaybackInfo>)` | Seek progress; PlaybackInfo has a `.time` property (seconds) |
| .onUpdate | `.onUpdate(callback: Callback<PlaybackInfo>)` | Playback progress update; PlaybackInfo has a `.time` property (seconds) |

> Note: onUpdate/onPrepared callback arguments are **objects**, not numbers. There is no onTimeUpdate.
> Official example: `.onUpdate((e?: TimeObject) => { if (e) { let t = e.time } })`

---

### Canvas / Shape Drawing Quick Reference

| Component | Constructor Signature | Core Methods |
|-----------|---------|-------------|
| **Canvas** | `Canvas(context?: CanvasRenderingContext2D)` | Canvas component; `context` provides a 2D drawing context |
| **CanvasRenderingContext2D** | `new CanvasRenderingContext2D(settings?)` | `fillRect/strokeRect/clearRect/drawImage/fillText/strokeText/arc/beginPath/closePath/moveTo/lineTo/bezierCurveTo/quadraticCurveTo/rotate/scale/translate/save/restore/clip/createLinearGradient/createRadialGradient` |
| **OffscreenCanvas** | `new OffscreenCanvas(width, height)` | Offscreen rendering |
| **Path2D** | `new Path2D()` | `addPath/arc/arcTo/bezierCurveTo/ellipse/lineTo/moveTo/quadraticCurveTo/rect` |
| **Shape** | `Shape(options?: {viewPort})` | `.fill()` `.stroke()` `.strokeWidth()` `.strokeDashArray()` `.strokeLineCap()` `.antiAlias()` |
| **Rect** | `Rect(options?)` | `.width()` `.height()` `.radiusWidth()` `.radiusHeight()` `.fill()` `.stroke()` |
| **Circle** | `Circle(options?)` | `.width()` `.height()` `.fill()` `.stroke()` |
| **Ellipse** | `Ellipse(options?)` | `.width()` `.height()` `.fill()` `.stroke()` |
| **Line** | `Line(options?)` | `.startPoint()` `.endPoint()` `.fill()` `.stroke()` `.strokeWidth()` |
| **Polyline** | `Polyline(options?)` | `.points(Array\<Point\>)` `.fill()` `.stroke()` |
| **Polygon** | `Polygon(options?)` | `.points(Array\<Point\>)` `.fill()` `.stroke()` |
| **Path** | `Path(options?)` | `.commands(string)` `.fill()` `.stroke()` |

---
