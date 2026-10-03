import {
  MAX_ZOOM,
  MIN_ZOOM,
  MapViewport,
  fitZoom,
  latFromWorldY,
  lngFromWorldX,
  metersPerVp,
  worldSize,
  worldX,
  worldY
} from '../services/MapTiles';
import { MapScaleBar, MapTileLayer, mapAttribution, mapTilesUnavailable, mapZoomButton } from './MapLayers';

const MAP_HEIGHT: number = 320;
const PIN_SIZE: number = 40;
/** Smallest radius used to pick the initial zoom, so a tiny circle still shows its street. */
const MIN_FIT_RADIUS_M: number = 50;
/** Coordinates closer than this (about 1 cm) are the same point. */
const SAME_POINT_DEG: number = 0.0000001;

/**
 * Map for choosing the safe-area centre. The point under the pin in the middle
 * is the picked one: drag the map, or tap a spot to bring it under the pin, and
 * pinch or use the buttons to zoom. The circle shows the radius to scale.
 * `onPick` reports the new centre when a drag or tap ends. Changing `lat` or
 * `lng` from outside moves the map; changing `radiusM` zooms to fit the circle.
 */
@Component
export struct AreaPickerMap {
  @Prop @Watch('onTargetChanged') lat: number = 0;
  @Prop @Watch('onTargetChanged') lng: number = 0;
  @Prop @Watch('onRadiusChanged') radiusM: number = 0;
  onPick: (lat: number, lng: number) => void = () => {};
  @State private viewport: MapViewport = new MapViewport(MIN_ZOOM, 0, 0, 0, MAP_HEIGHT);
  @State private pinchScale: number = 1;
  @State private failedTiles: number = 0;
  private centerLat: number = 0;
  private centerLng: number = 0;
  private lastPanX: number = 0;
  private lastPanY: number = 0;

  aboutToAppear(): void {
    this.centerLat = this.lat;
    this.centerLng = this.lng;
  }

  private onTargetChanged(): void {
    if (Math.abs(this.lat - this.centerLat) < SAME_POINT_DEG && Math.abs(this.lng - this.centerLng) < SAME_POINT_DEG) {
      return;
    }
    this.moveTo(this.lat, this.lng, this.viewport.zoom);
  }

  private onRadiusChanged(): void {
    this.moveTo(this.centerLat, this.centerLng, this.fittedZoom());
  }

  /** Largest zoom at which the whole circle fits, with a margin. */
  private fittedZoom(): number {
    const halfView = Math.min(this.viewport.width, MAP_HEIGHT) / 2 - 24;
    if (halfView <= 0) {
      return this.viewport.zoom;
    }
    return fitZoom(this.centerLat, Math.max(MIN_FIT_RADIUS_M, this.radiusM) * 1.2, halfView);
  }

  private moveTo(lat: number, lng: number, zoom: number): void {
    const nextZoom = Math.max(MIN_ZOOM, Math.min(MAX_ZOOM, zoom));
    const width = this.viewport.width;
    this.centerLat = lat;
    this.centerLng = lng;
    this.viewport = new MapViewport(nextZoom, worldX(lng, nextZoom) - width / 2,
      worldY(lat, nextZoom) - MAP_HEIGHT / 2, width, MAP_HEIGHT);
  }

  /** Pan offsets are cumulative; only the change since the last update moves the map. */
  private panBy(offsetX: number, offsetY: number): void {
    const view = this.viewport;
    const dx = (offsetX - this.lastPanX) / this.pinchScale;
    const dy = (offsetY - this.lastPanY) / this.pinchScale;
    this.lastPanX = offsetX;
    this.lastPanY = offsetY;
    const halfHeight = view.height / 2;
    const originX = view.originX - dx;
    const originY = Math.max(-halfHeight, Math.min(worldSize(view.zoom) - halfHeight, view.originY - dy));
    this.viewport = new MapViewport(view.zoom, originX, originY, view.width, view.height);
    this.centerLng = lngFromWorldX(originX + view.width / 2, view.zoom);
    this.centerLat = latFromWorldY(originY + halfHeight, view.zoom);
  }

  private centerOn(localX: number, localY: number): void {
    const view = this.viewport;
    this.moveTo(latFromWorldY(view.originY + localY, view.zoom), lngFromWorldX(view.originX + localX, view.zoom),
      view.zoom);
    this.onPick(this.centerLat, this.centerLng);
  }

  /** Scales the drawn map while pinching; the zoom level snaps when the pinch ends. */
  private pinchTo(scale: number): void {
    const zoom = this.viewport.zoom;
    this.pinchScale = Math.max(Math.pow(2, MIN_ZOOM - zoom), Math.min(Math.pow(2, MAX_ZOOM - zoom), scale));
  }

  private pinchEnd(): void {
    const steps = Math.round(Math.log(this.pinchScale) / Math.LN2);
    this.pinchScale = 1;
    if (steps !== 0) {
      this.moveTo(this.centerLat, this.centerLng, this.viewport.zoom + steps);
    }
  }

  private changeZoom(step: number): void {
    this.moveTo(this.centerLat, this.centerLng, this.viewport.zoom + step);
  }

  private radiusVp(): number {
    return this.radiusM / metersPerVp(this.centerLat, this.viewport.zoom);
  }

  /** Circles far larger than the view are skipped; the view would be entirely inside them. */
  private circleDrawable(): boolean {
    const radius = this.radiusVp();
    return radius >= 1 && radius < 4 * Math.max(this.viewport.width, MAP_HEIGHT);
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Stack({ alignContent: Alignment.TopStart }) {
        MapTileLayer({
          viewport: this.viewport,
          onFailedTiles: (count: number) => {
            this.failedTiles = count;
          }
        })

        if (this.circleDrawable()) {
          Circle({ width: this.radiusVp() * 2, height: this.radiusVp() * 2 })
            .fill($r('app.color.map_area_fill'))
            .stroke($r('app.color.action_primary'))
            .strokeWidth(3)
            .strokeDashArray([10, 6])
            .position({ x: this.viewport.width / 2 - this.radiusVp(), y: MAP_HEIGHT / 2 - this.radiusVp() })
            .accessibilityLevel('no')
        }
      }
      .width('100%')
      .height(MAP_HEIGHT)
      .scale({ x: this.pinchScale, y: this.pinchScale })

      Row() {
        SymbolGlyph($r('sys.symbol.house_fill'))
          .fontSize(20)
          .fontColor([Color.White])
      }
      .width(PIN_SIZE)
      .height(PIN_SIZE)
      .borderRadius(PIN_SIZE / 2)
      .justifyContent(FlexAlign.Center)
      .backgroundColor($r('app.color.action_primary'))
      .border({ width: 3, color: Color.White })
      .shadow({ radius: 8, color: $r('app.color.card_shadow'), offsetY: 2 })
      .position({ x: this.viewport.width / 2 - PIN_SIZE / 2, y: MAP_HEIGHT / 2 - PIN_SIZE / 2 })
      .accessibilityLevel('no')

      if (this.failedTiles > 0) {
        mapTilesUnavailable(Math.max(120, this.viewport.width - 156))
      }

      Column({ space: 8 }) {
        mapZoomButton($r('sys.symbol.plus'), 'Zoom in', () => this.changeZoom(1))
        mapZoomButton($r('sys.symbol.minus'), 'Zoom out', () => this.changeZoom(-1))
      }
      .position({ x: this.viewport.width - 132, y: 12 })

      MapScaleBar({ lat: this.centerLat, zoom: this.viewport.zoom })
        .position({ x: 12, y: MAP_HEIGHT - 50 })

      mapAttribution(MAP_HEIGHT)
    }
    .width('100%')
    .height(MAP_HEIGHT)
    .clip(true)
    .borderRadius(20)
    .backgroundColor($r('app.color.divider'))
    .gesture(
      GestureGroup(GestureMode.Exclusive,
        TapGesture({ count: 1 })
          .onAction((event: GestureEvent) => {
            const finger = event.fingerList[0];
            if (finger !== undefined) {
              this.centerOn(finger.localX, finger.localY);
            }
          }),
        GestureGroup(GestureMode.Parallel,
          PanGesture({ fingers: 1 })
            .onActionStart(() => {
              this.lastPanX = 0;
              this.lastPanY = 0;
            })
            .onActionUpdate((event: GestureEvent) => this.panBy(event.offsetX, event.offsetY))
            .onActionEnd(() => this.onPick(this.centerLat, this.centerLng))
            .onActionCancel(() => this.onPick(this.centerLat, this.centerLng)),
          PinchGesture({ fingers: 2 })
            .onActionUpdate((event: GestureEvent) => this.pinchTo(event.scale))
            .onActionEnd(() => this.pinchEnd())
            .onActionCancel(() => this.pinchEnd())
        )
      )
    )
    .onAreaChange((oldValue: Area, newValue: Area) => {
      const width = Number(newValue.width);
      if (width === this.viewport.width) {
        return;
      }
      const firstLayout = this.viewport.width <= 0;
      const view = this.viewport;
      this.viewport = new MapViewport(view.zoom, view.originX, view.originY, width, MAP_HEIGHT);
      this.moveTo(this.centerLat, this.centerLng, firstLayout ? this.fittedZoom() : view.zoom);
    })
  }
}
