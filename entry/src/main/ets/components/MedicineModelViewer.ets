import { Camera, EnvironmentBackgroundType, Light, LightType, Scene } from '@kit.ArkGraphics3D';
import { CareButtonStyle } from './DesignSystem';

// Framing is specific to the supplied bottle: x=-0.55, y=-0.038..2.794.
// Keep the model intact and orbit the camera around its centre.
const CENTRE_X: number = -0.55;
const CENTRE_Y: number = 1.38;
const CAMERA_DISTANCE: number = 6.2;

@Component
export struct MedicineModelViewer {
  @State private options: SceneOptions | undefined = undefined;
  @State private failed: boolean = false;
  private scene: Scene | undefined = undefined;
  private camera: Camera | undefined = undefined;
  private keyLight: Light | undefined = undefined;
  private fillLight: Light | undefined = undefined;
  private angle: number = 0;
  private dragStartAngle: number = 0;
  private loadGeneration: number = 0;

  aboutToAppear(): void {
    this.loadModel();
  }

  aboutToDisappear(): void {
    // Invalidate a pending load so it cannot attach a scene to a closed page.
    this.loadGeneration++;
    this.options = undefined;
    this.camera = undefined;
    this.keyLight = undefined;
    this.fillLight = undefined;
    this.scene?.destroy();
    this.scene = undefined;
  }

  private async loadModel(): Promise<void> {
    const generation = ++this.loadGeneration;
    this.failed = false;
    let scene: Scene | undefined = undefined;
    try {
      scene = await Scene.load($rawfile('models/medicine_3d.glb'));
      const factory = scene.getResourceFactory();
      const camera = await factory.createCamera({ name: 'MedicineCamera' });
      camera.enabled = true;
      camera.nearPlane = 0.1;
      camera.farPlane = 100;
      camera.clearColor = { r: 250 / 255, g: 248 / 255, b: 243 / 255, a: 1 };
      const environment = await factory.createEnvironment({ name: 'MedicineBackground' });
      environment.backgroundType = EnvironmentBackgroundType.BACKGROUND_NONE;
      scene.environment = environment;

      const keyLight = await factory.createLight({ name: 'MedicineKeyLight' }, LightType.DIRECTIONAL);
      keyLight.color = { r: 1, g: 1, b: 1, a: 1 };
      keyLight.intensity = 2;
      keyLight.enabled = true;
      const fillLight = await factory.createLight({ name: 'MedicineFillLight' }, LightType.DIRECTIONAL);
      fillLight.color = { r: 0.85, g: 0.92, b: 1, a: 1 };
      fillLight.intensity = 0.8;
      fillLight.enabled = true;

      if (generation !== this.loadGeneration) {
        scene.destroy();
        return;
      }
      this.scene = scene;
      this.camera = camera;
      this.keyLight = keyLight;
      this.fillLight = fillLight;
      this.setAngle(0);
      // Texture composition keeps the embedded viewer clipped inside the scrolling card.
      this.options = { scene: scene, modelType: ModelType.TEXTURE };
    } catch (err) {
      scene?.destroy();
      if (generation === this.loadGeneration) {
        this.scene = undefined;
        this.camera = undefined;
        this.keyLight = undefined;
        this.fillLight = undefined;
        this.options = undefined;
        this.failed = true;
      }
    }
  }

  private setAngle(angle: number): void {
    if (this.camera === undefined) {
      return;
    }
    this.angle = angle;
    this.camera.position = {
      x: CENTRE_X + CAMERA_DISTANCE * Math.sin(angle),
      y: CENTRE_Y,
      z: CAMERA_DISTANCE * Math.cos(angle)
    };
    this.camera.rotation = { x: 0, y: Math.sin(angle / 2), z: 0, w: Math.cos(angle / 2) };
    // Lights follow the viewing angle so the back of the bottle is also readable.
    if (this.keyLight !== undefined) {
      const yaw = angle - Math.PI / 6;
      this.keyLight.rotation = { x: 0, y: Math.sin(yaw / 2), z: 0, w: Math.cos(yaw / 2) };
    }
    if (this.fillLight !== undefined) {
      const yaw = angle + Math.PI / 3;
      this.fillLight.rotation = { x: 0, y: Math.sin(yaw / 2), z: 0, w: Math.cos(yaw / 2) };
    }
  }

  build() {
    Column({ space: 12 }) {
      Text('Compare with your medicine')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      Stack() {
        if (this.options !== undefined) {
          Component3D(this.options)
            .width('100%')
            .height('100%')
            .accessibilityText('Interactive 3D demo medicine bottle. Drag left or right to rotate. Double-tap to reset the view.')
            .gesture(
              GestureGroup(GestureMode.Exclusive,
                PanGesture({ fingers: 1, direction: PanDirection.Horizontal })
                  .onActionStart((event: GestureEvent) => {
                    this.dragStartAngle = this.angle;
                    this.setAngle(this.dragStartAngle - event.offsetX * 0.01);
                  })
                  .onActionUpdate((event: GestureEvent) => {
                    this.setAngle(this.dragStartAngle - event.offsetX * 0.01);
                  }),
                TapGesture({ count: 2 })
                  .onAction(() => this.setAngle(0))
              )
            )
        } else if (this.failed) {
          Column({ space: 12 }) {
            Text('The 3D view could not be loaded.')
              .fontSize(18)
              .fontColor($r('app.color.text_primary'))
              .textAlign(TextAlign.Center)
            Button('Try again')
              .fontSize(18)
              .constraintSize({ minHeight: 56 })
              .attributeModifier(new CareButtonStyle())
              .onClick(() => this.loadModel())
          }
          .padding(20)
        } else {
          Column({ space: 12 }) {
            LoadingProgress()
              .width(40)
              .height(40)
              .color($r('app.color.senior_accent'))
            Text('Loading 3D view…')
              .fontSize(18)
              .fontColor($r('app.color.text_primary'))
          }
        }
      }
      .width('100%')
      .height(300)
      .backgroundColor($r('app.color.model_background'))
      .borderRadius(20)
      .clip(true)

      Text('Drag left or right to turn the bottle. Double-tap to reset.')
        .fontSize(17)
        .fontColor($r('app.color.text_secondary'))

      Text('Demo reference model · The same bottle is shown for every medicine for now.')
        .fontSize(16)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .padding(16)
    .borderRadius(24)
    .backgroundColor($r('app.color.surface'))
  }
}
