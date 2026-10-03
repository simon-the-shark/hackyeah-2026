import { PHONE, WATCH, distanceMeters } from '../models/SeniorLocation';
import { MAX_ZOOM, MIN_ZOOM, MapViewport, fitZoom, metersPerVp, worldX, worldY } from '../services/MapTiles';
import { MapScaleBar, MapTileLayer, mapAttribution, mapTilesUnavailable, mapZoomButton } from './MapLayers';

const MAP_HEIGHT: number = 300;
const PIN_SIZE: number = 36;
const MIN_EXTENT_M: number = 150;
const MAX_ZOOM_DELTA: number = 2;
const MIN_ZOOM_DELTA: number = -3;

/** One device's position on the map. */
export class MapMarker {
  /** `PHONE`, `WATCH`, or empty when the source is unknown; picks the icon. */
  kind: string = PHONE;
  lat: number = 0;
  lng: number = 0;
  accuracyM: number = -1;
  /** Turns the marker red when the position is old. */
  stale: boolean = false;
}

/** What the map shows. Replace the whole object to trigger a redraw. */
export class MapScene {
  /** At most one per device, phone first. */
  markers: MapMarker[] = [];
  hasArea: boolean = false;
  areaLat: number = 0;
  areaLng: number = 0;
  areaRadiusM: number = 0;
}

export function markerIcon(kind: string): Resource {
  return kind === WATCH ? $r('sys.symbol.watch_fill') :
    kind === PHONE ? $r('sys.symbol.phone_fill_1') : $r('sys.symbol.map_badge_local');
}

export function markerLabel(kind: string): string {
  return kind === WATCH ? 'Watch' : kind === PHONE ? 'Phone' : 'Reported location';
}

/**
 * Self-drawn map: OpenStreetMap raster tiles underneath, with the last position
 * of the senior's phone and of the watch (each with its own icon and accuracy)
 * and the safe-area circle drawn to scale on top. If the
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

  /** The midpoint of the markers, or the safe area when no device has a position. */
  private centerLat(): number {
    const markers = this.scene.markers;
    if (markers.length === 0) {
      return this.scene.areaLat;
    }
    return markers.reduce((sum: number, marker: MapMarker) => sum + marker.lat, 0) / markers.length;
  }

  private centerLng(): number {
    const markers = this.scene.markers;
    if (markers.length === 0) {
      return this.scene.areaLng;
    }
    return markers.reduce((sum: number, marker: MapMarker) => sum + marker.lng, 0) / markers.length;
  }

  private relayout(): void {
    if (this.viewWidth <= 0 || (this.scene.markers.length === 0 && !this.scene.hasArea)) {
      return;
    }
    const lat = this.centerLat();
    const lng = this.centerLng();
    // Fit every marker with its accuracy, so a phone left at home and a watch on a walk are both in view.
    let extent = MIN_EXTENT_M;
    this.scene.markers.forEach((marker: MapMarker) => {
      extent = Math.max(extent, distanceMeters(lat, lng, marker.lat, marker.lng) + Math.max(0, marker.accuracyM));
    });
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

  /**
   * Phone and watch are usually carried together, so their markers would cover
   * each other; when they are that close, they are drawn side by side.
   */
  private pinShiftX(index: number): number {
    const markers = this.scene.markers;
    if (markers.length !== 2) {
      return 0;
    }
    const dx = this.screenX(markers[1].lng) - this.screenX(markers[0].lng);
    const dy = this.screenY(markers[1].lat) - this.screenY(markers[0].lat);
    if (Math.sqrt(dx * dx + dy * dy) >= PIN_SIZE) {
      return 0;
    }
    return index === 0 ? -PIN_SIZE / 2 - 2 : PIN_SIZE / 2 + 2;
  }

  /** Keys include the viewport so markers move when the map pans or zooms. */
  private markerKey(marker: MapMarker, index: number): string {
    return `${index}-${marker.kind}-${marker.lat}-${marker.lng}-${marker.accuracyM}-${marker.stale}-` +
      `${this.viewport.zoom}-${this.viewport.originX}-${this.viewport.originY}`;
  }

  /** Circles far larger than the view are skipped; the view would be entirely inside them. */
  private drawable(radius: number): boolean {
    return radius >= 1 && radius < 4 * Math.max(this.viewWidth, MAP_HEIGHT);
  }

  @Builder
  legend() {
    Row({ space: 16 }) {
      ForEach(this.scene.markers, (marker: MapMarker) => {
        Row({ space: 6 }) {
          Row() {
            SymbolGlyph(markerIcon(marker.kind))
              .fontSize(14)
              .fontColor([Color.White])
          }
          .width(24)
          .height(24)
          .borderRadius(12)
          .justifyContent(FlexAlign.Center)
          .backgroundColor(marker.stale ? $r('app.color.action_danger') : $r('app.color.action_primary'))
          Text(markerLabel(marker.kind))
            .fontSize(15)
            .fontColor($r('app.color.text_primary'))
        }
        .accessibilityGroup(true)
      }, (marker: MapMarker, index: number) => `legend-${index}-${marker.kind}-${marker.stale}`)
    }
    .width('100%')
    .padding({ left: 4, right: 4 })
  }

  build() {
    Column({ space: 8 }) {
      this.map()
      if (this.scene.markers.length > 0) {
        this.legend()
      }
    }
    .width('100%')
  }

  @Builder
  map() {
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
          .fill($r('app.color.map_area_fill'))
          .stroke($r('app.color.action_primary'))
          .strokeWidth(3)
          .strokeDashArray([10, 6])
          .position({
            x: this.screenX(this.scene.areaLng) - this.radiusVp(this.scene.areaRadiusM),
            y: this.screenY(this.scene.areaLat) - this.radiusVp(this.scene.areaRadiusM)
          })
          .accessibilityLevel('no')
      }

      ForEach(this.scene.markers, (marker: MapMarker) => {
        if (marker.accuracyM > 0 && this.drawable(this.radiusVp(marker.accuracyM))) {
          Circle({
            width: this.radiusVp(marker.accuracyM) * 2,
            height: this.radiusVp(marker.accuracyM) * 2
          })
            .fill($r('app.color.map_accuracy_fill'))
            .stroke($r('app.color.action_primary'))
            .strokeWidth(1)
            .position({
              x: this.screenX(marker.lng) - this.radiusVp(marker.accuracyM),
              y: this.screenY(marker.lat) - this.radiusVp(marker.accuracyM)
            })
            .accessibilityLevel('no')
        }
      }, (marker: MapMarker, index: number) => `accuracy-${this.markerKey(marker, index)}`)

      ForEach(this.scene.markers, (marker: MapMarker, index: number) => {
        Row() {
          SymbolGlyph(markerIcon(marker.kind))
            .fontSize(18)
            .fontColor([Color.White])
        }
        .width(PIN_SIZE)
        .height(PIN_SIZE)
        .borderRadius(PIN_SIZE / 2)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(marker.stale ? $r('app.color.action_danger') : $r('app.color.action_primary'))
        .border({ width: 3, color: Color.White })
        .shadow({ radius: 8, color: $r('app.color.card_shadow'), offsetY: 2 })
        .position({
          x: this.screenX(marker.lng) - PIN_SIZE / 2 + this.pinShiftX(index),
          y: this.screenY(marker.lat) - PIN_SIZE / 2
        })
        .accessibilityLevel('no')
      }, (marker: MapMarker, index: number) => `pin-${this.markerKey(marker, index)}`)

      if (this.failedTiles > 0) {
        mapTilesUnavailable(Math.max(120, this.viewWidth - 156))
      }

      Column({ space: 8 }) {
        mapZoomButton($r('sys.symbol.plus'), 'Zoom in', () => this.changeZoom(1))
        mapZoomButton($r('sys.symbol.minus'), 'Zoom out', () => this.changeZoom(-1))
      }
      .position({ x: this.viewWidth - 132, y: 12 })

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
