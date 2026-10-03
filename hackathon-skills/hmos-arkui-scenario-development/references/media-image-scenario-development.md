# Graphical component image display case Set

# Functional points typically use scene comparison

| Graphical component | Typical use scenario | Core competencies | Non-applicability scenario |
|---------|------------|---------|-----------|
|Image | Commodity master, user header, background, list thumbnail | Multiple data sources + multiple fillers + bitmap | Frame animation, video stream rendering |
ImageAnimator Live gift effects, animated expression, guided animation, | Sequence-by-frame play + status control, | static photo presentation, GIF animation |

---

# Scenario one: the Electrician Commodity List displays a commodity master map to support multiple data sources and load failures

** Example description of scene **: Electrician list page, each commodity card displays a commodity master map, possibly from local resources, network URLs or PixelMap, with the default position map when the image is loaded down.

** Solution**: Use Image component to support multiple data sources, set image filling by objectFit, alt property settings to load failed bitmap, onError processing failed loadbacks.

• Alternative components
|---------|------------|
|XComponent | for custom rendering Surface, plain picture displays need not be so complex
| ImageAnimator | for frame animation, static pictures need not be shown on frame by frame

```typescript
Local resources
Image($r('app.media.startIcon'))
  .objectFit(ImageFit.Cover)
.alt ( 'app.media.placeholder') / /load failure Figure

// Network URL
Image(product.imageUrl)
  .objectFit(ImageFit.Cover)
  .width(80).height(80).borderRadius(8)
.alt ( 'app.media.startIcon') // Load failed Bottom
.onError(()=>{/* Load failed*/})
  .onComplete((event) => {
/ /event.width /event.head is the actual width (px) for layout calculations
    console.info(`loaded: ${event.width}x${event.height}`)
  })
```

# Image Key API

| Properties | Role | Example |
|------|-----|------|
`src`| Photo Data Source |`$r('app.media.icon')`/`'https://...'`/`pixelMap`|
`objectFit` | Filling Method |XKEEP1ZX / `Contain` / `Fill`|
`alt` ZEX ZEX ZEKEP1ZX ZEX
`onError` | Load failed to return |XKEEP1ZX |
`onComplete` | Loaded back

# # List scene performance limit

When using Image to load a web URL image, the Image component is decoded internally without blocking the scrolling list:

- Network URL image loaded and decoded by Image Interstep, main route unblocked, LazyForEach/List list is properly scrolled
- Prohibits synchronizing the image decoding (e. g. synchronizing PixelMap to src) in the build logic of the bild or list entry, otherwise the carton will scroll
- If PixelMap reprocessing (clip/filter) based on web images is required, it should be accessed on Complete in a different direction, without blocking the build

# oncomplete echoes and pictures are actually wide

`onComplete` triggers when the picture is loaded, and the object parameter contains the actual size of the picture, which can be used for layout calculations:

```typescript
// Network URL - bind onError and oncomplete, get the actual width for layout
Image(product.imageUrl)
  .objectFit(ImageFit.Cover)
  .width(80).height(80).borderRadius(8)
.alt ( 'app.media.startIcon') // Load failed Bottom
.onError(() = > {/* Load failure log/ burypoint report*/})
  .onComplete((event) => {
/ /event.width /event.head is the actual width (px) for layout calculations
    console.info(`loaded: ${event.width}x${event.height}`)
  })
```

> Note: ent.width/event.head of onComplete is the actual size of the image decoded, different from the width(80)/height(80) display size of the component, which can be used to adjust the layout to the light-high-speed dynamic.

ImageFit count

Equation, behaviour, application of scenes,
|--------|------|---------|
`Contain` | Keep the width ratio and show it fully in the container | need to show the whole picture
Z `Cover` | Keep wide ratio and fully cover containers (possibly cropping) | commercial cards, headers (most commonly used) |
Z `Fill` | does not keep the width ratio and stretch to fill the | background, decoration |
`Auto` | Keep original size | small icon, precise size control  Z
Z `ScaleDown` | shrinks when larger than the container and does not zoom in at times | unsure of the general scene of the image size
Z`None` | do not zoom, show | by original size

---

# Scene II: Lives on App's luxurious special effects on the frame

** Example description of scenes **: live App shows a set of gift special effects animations (e.g., fireworks, rocket lifts) consisting of dozens of serial frame images (e.g., fireworks, rocket lifts) when the user sends a luxury gift, and an animated frame shows on a continuous basis to support play/suspension/cut control.

** Solution**: Use the ImageAnimator component to set the path, size and duration of each frame of picture by using the images properties, state control play/ pause/ stop. The rawfile resource must return to the source type using `$rawfile('xxx.png')`.

• Alternative components
|---------|------------|
|Image | Shows only a single static map or GIF, which does not accurately control the length and play state of each frame
| Lottie/ Animation API frame animation consists of a serial frame image, ImageAniemator playing the most precise effect by frame

```typescript
/ / Construct frame arrays, src must return the resource type using $rawfile()
private getFrameImages(dirIndex: number): ImageFrameInfo[] {
  const images: ImageFrameInfo[] = [];
  for (let i = 0; i < this.totalFrames; i++) {
    const idx = i < 10 ? `0${i}` : `${i}`;
    images.push({
      src: $rawfile(`${dir}/frame_${idx}.png`),
      width: 240, height: 240,
      duration: this.perFrameDuration
    });
  }
  return images;
}

/ ImageAnimator-images do not support dynamic updates, toggle gifts to render
ImageAnimator()
  .images(this.getFrameImages(0))
.state(this.animstate) / / Play status control
. internationals (this. internationals) / -1 = infinite cycle
  .reverse(false)
  .fillMode(FillMode.None)
  .width(240).height(240)

// Play Control
Button ('Running' ).onClick() = {this.animstate=AnimationStatus.Running;})
Button ( 'Pause'). onClick() = {this.animstate = Animation Status. Paused;})
Button (`stop'). onClick() = {this.animstate=AnimationStatus.Stopped;})
```

# Animationstatus

Equation values Behaviour
|--------|------|
`Running`| playing |
Z`Paused`| Pause (Recoverable) |
Z `Stopped` | Stop (back to front frame, replay)  Z
`Initial`| Initial state

# FillMode #

Equation values Behaviour
|--------|------|
`None` | Do not keep the last frame after the animation
`Forwards` | Keep last frame after the animation
Show the first frame before the animation begins
`Both` Zulu

# Watch out #

1. **images properties do not support dynamic updates**: use condition rendering (if/else) to switch different gifts
2. **Resource **: Reference to rawfile resource must use `$rawfile('xxx.png')` to return source type
3. **Sequence frame naming code**: proposed to use zero numbering (frame 00.png, frame 01.png, ...)

---

# Graphical component selection speed check table

| Component | Data type | Core competencies | Typical scene | Critical limitations |
|------|---------|---------|---------|---------|
**Image** Static/Webchart/PixelMap | Multiple Data Sources+Multiple Filling Method  ** Commodity Master, Header, Background Chart  ** does not support frame animation
**ImageAnimator**  **Sequencer frame image array  **Face by frame + status control + circulation control  **Photo effects, animation, guide animation  **images cannot be dynamically updated and conditioned |
