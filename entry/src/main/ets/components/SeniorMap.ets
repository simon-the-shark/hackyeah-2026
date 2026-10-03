import { distanceMeters } from '../models/SeniorLocation';
import { MAX_ZOOM, MIN_ZOOM, MapViewport, fitZoom, metersPerVp, worldX, worldY } from '../services/MapTiles';
import { MapScaleBar, MapTileLayer, mapAttribution, mapTilesUnavailable, mapZoomButton } from './MapLayers';

const MAP_HEIGHT: number = 300;
const MIN_EXTENT_M: number = 150;
const MAX_ZOOM_DELTA: number = 2;
const MIN_ZOOM_DELTA: number = -3;

/** What the map shows. Replace the whole object to trigger a redraw. */
export class MapScene {
  hasMarker: boolean = false;
  markerLat: number = 0;
  markerLng: number = 0;
  accuracyM: number = -1;
  hasArea: boolean = false;
  areaLat: number = 0;
  areaLng: number = 0;
  areaRadiusM: number = 0;
  /** Greys out the marker when the position is old. */
  stale: boolean = false;
}

/**
 * Self-drawn map: OpenStreetMap raster tiles underneath, with the senior's last
 * position, its accuracy and the safe-area circle drawn to scale on top. If the
 * tiles cannot load, the overlay and scale bar still show the relative
 * positions, and the map says so. The drawn layers are hidden from screen
 * readers; the details card next to the map carries the same information.
 */
@Component
export struct SeniorMap {
  @Prop @Watch('relayout') scene: MapScene = new MapScene();
  @State private viewWidth: number = 0;
  @State private zoomDelta: number = 0;
  @State private viewport: MapViewport = new MapViewport(MIN_ZOOM, 0, 0, 0, MAP_HEIGHT);
  @State private failedTiles: number = 0;

  private centerLat(): number {
    return this.scene.hasMarker ? this.scene.markerLat : this.scene.areaLat;
  }

  private centerLng(): number {
    return this.scene.hasMarker ? this.scene.markerLng : this.scene.areaLng;
  }

  private relayout(): void {
    if (this.viewWidth <= 0 || (!this.scene.hasMarker && !this.scene.hasArea)) {
      return;
    }
    const lat = this.centerLat();
    const lng = this.centerLng();
    let extent = Math.max(MIN_EXTENT_M, this.scene.accuracyM);
    if (this.scene.hasArea) {
      extent = Math.max(extent,
        distanceMeters(lat, lng, this.scene.areaLat, this.scene.areaLng) + this.scene.areaRadiusM);
    }
    const halfView = Math.min(this.viewWidth, MAP_HEIGHT) / 2 - 16;
    const zoom = Math.max(MIN_ZOOM, Math.min(MAX_ZOOM, fitZoom(lat, extent * 1.15, halfView) + this.zoomDelta));
    this.viewport = new MapViewport(zoom, worldX(lng, zoom) - this.viewWidth / 2, worldY(lat, zoom) - MAP_HEIGHT / 2,
      this.viewWidth, MAP_HEIGHT);
  }

  private changeZoom(step: number): void {
    const next = Math.max(MIN_ZOOM_DELTA, Math.min(MAX_ZOOM_DELTA, this.zoomDelta + step));
    if (next !== this.zoomDelta) {
      this.zoomDelta = next;
      this.relayout();
    }
  }

  private screenX(lng: number): number {
    return worldX(lng, this.viewport.zoom) - this.viewport.originX;
  }

  private screenY(lat: number): number {
    return worldY(lat, this.viewport.zoom) - this.viewport.originY;
  }

  private radiusVp(meters: number): number {
    return meters / metersPerVp(this.centerLat(), this.viewport.zoom);
  }

  /** Circles far larger than the view are skipped; the view would be entirely inside them. */
  private drawable(radius: number): boolean {
    return radius >= 1 && radius < 4 * Math.max(this.viewWidth, MAP_HEIGHT);
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      MapTileLayer({
        viewport: this.viewport,
        onFailedTiles: (count: number) => {
          this.failedTiles = count;
        }
      })

      if (this.scene.hasArea && this.drawable(this.radiusVp(this.scene.areaRadiusM))) {
        Circle({
          width: this.radiusVp(this.scene.areaRadiusM) * 2,
          height: this.radiusVp(this.scene.areaRadiusM) * 2
        })
          .fill('#260F766E')
          .stroke('#0F766E')
          .strokeWidth(3)
          .strokeDashArray([10, 6])
          .position({
            x: this.screenX(this.scene.areaLng) - this.radiusVp(this.scene.areaRadiusM),
            y: this.screenY(this.scene.areaLat) - this.radiusVp(this.scene.areaRadiusM)
          })
          .accessibilityLevel('no')
      }

      if (this.scene.hasMarker && this.scene.accuracyM > 0 && this.drawable(this.radiusVp(this.scene.accuracyM))) {
        Circle({
          width: this.radiusVp(this.scene.accuracyM) * 2,
          height: this.radiusVp(this.scene.accuracyM) * 2
        })
          .fill('#264338CA')
          .stroke('#804338CA')
          .strokeWidth(1)
          .position({
            x: this.screenX(this.scene.markerLng) - this.radiusVp(this.scene.accuracyM),
            y: this.screenY(this.scene.markerLat) - this.radiusVp(this.scene.accuracyM)
          })
          .accessibilityLevel('no')
      }

      if (this.scene.hasMarker) {
        Row() {
          SymbolGlyph($r('sys.symbol.person_fill'))
            .fontSize(18)
            .fontColor([Color.White])
        }
        .width(36)
        .height(36)
        .borderRadius(18)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.scene.stale ? $r('app.color.text_secondary') : $r('app.color.guardian_accent'))
        .border({ width: 3, color: Color.White })
        .shadow({ radius: 8, color: $r('app.color.card_shadow'), offsetY: 2 })
        .position({ x: this.screenX(this.scene.markerLng) - 18, y: this.screenY(this.scene.markerLat) - 18 })
        .accessibilityLevel('no')
      }

      if (this.failedTiles > 0) {
        mapTilesUnavailable(Math.max(120, this.viewWidth - 80))
      }

      Column({ space: 8 }) {
        mapZoomButton($r('sys.symbol.plus'), 'Zoom in', () => this.changeZoom(1))
        mapZoomButton($r('sys.symbol.minus'), 'Zoom out', () => this.changeZoom(-1))
      }
      .position({ x: this.viewWidth - 56, y: 12 })

      MapScaleBar({ lat: this.centerLat(), zoom: this.viewport.zoom })
        .position({ x: 12, y: MAP_HEIGHT - 50 })

      mapAttribution(MAP_HEIGHT)
    }
    .width('100%')
    .height(MAP_HEIGHT)
    .clip(true)
    .borderRadius(20)
    .backgroundColor($r('app.color.divider'))
    .onAreaChange((oldValue: Area, newValue: Area) => {
      const width = Number(newValue.width);
      if (width !== this.viewWidth) {
        this.viewWidth = width;
        this.relayout();
      }
    })
  }
}
