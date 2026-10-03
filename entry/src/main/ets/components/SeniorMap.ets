import { image } from '@kit.ImageKit';
import { distanceMeters, formatDistance } from '../models/SeniorLocation';
import {
  MAX_ZOOM,
  MIN_ZOOM,
  TILE_SIZE_VP,
  fitZoom,
  mapTileCache,
  metersPerVp,
  tileKey,
  worldX,
  worldY
} from '../services/MapTiles';

const MAP_HEIGHT: number = 300;
const MIN_EXTENT_M: number = 150;
const MAX_ZOOM_DELTA: number = 2;
const MIN_ZOOM_DELTA: number = -3;
const SCALE_STEPS_M: number[] = [10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000, 50000, 100000, 200000,
  500000];

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

class TileView {
  key: string;
  zoom: number;
  x: number;
  y: number;
  left: number;
  top: number;
  pixelMap: image.PixelMap | undefined;

  constructor(zoom: number, x: number, y: number, left: number, top: number) {
    this.key = tileKey(zoom, x, y);
    this.zoom = zoom;
    this.x = x;
    this.y = y;
    this.left = left;
    this.top = top;
    this.pixelMap = mapTileCache.get(this.key);
  }
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
  @State private zoom: number = MIN_ZOOM;
  @State private zoomDelta: number = 0;
  @State private originX: number = 0;
  @State private originY: number = 0;
  @State private tiles: TileView[] = [];
  @State private failedTiles: number = 0;
  private layoutGeneration: number = 0;

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
    this.zoom = zoom;
    this.originX = worldX(lng, zoom) - this.viewWidth / 2;
    this.originY = worldY(lat, zoom) - MAP_HEIGHT / 2;

    const tileCount = Math.pow(2, zoom);
    const tiles: TileView[] = [];
    const firstX = Math.floor(this.originX / TILE_SIZE_VP);
    const lastX = Math.floor((this.originX + this.viewWidth) / TILE_SIZE_VP);
    const firstY = Math.floor(this.originY / TILE_SIZE_VP);
    const lastY = Math.floor((this.originY + MAP_HEIGHT) / TILE_SIZE_VP);
    for (let ty = firstY; ty <= lastY; ty++) {
      if (ty < 0 || ty >= tileCount) {
        continue;
      }
      for (let tx = firstX; tx <= lastX; tx++) {
        const wrappedX = ((tx % tileCount) + tileCount) % tileCount;
        tiles.push(new TileView(zoom, wrappedX, ty, tx * TILE_SIZE_VP - this.originX, ty * TILE_SIZE_VP - this.originY));
      }
    }
    this.tiles = tiles;
    this.failedTiles = 0;
    this.loadMissingTiles(++this.layoutGeneration);
  }

  private loadMissingTiles(generation: number): void {
    this.tiles.forEach((tile: TileView) => {
      if (tile.pixelMap !== undefined) {
        return;
      }
      mapTileCache.load(tile.zoom, tile.x, tile.y).then((pixelMap: image.PixelMap | undefined) => {
        if (generation !== this.layoutGeneration) {
          return;
        }
        if (pixelMap === undefined) {
          this.failedTiles++;
          return;
        }
        this.tiles = this.tiles.map((current: TileView) => {
          if (current.key !== tile.key || current.pixelMap !== undefined) {
            return current;
          }
          const loaded = new TileView(current.zoom, current.x, current.y, current.left, current.top);
          loaded.pixelMap = pixelMap;
          return loaded;
        });
      });
    });
  }

  private changeZoom(step: number): void {
    const next = Math.max(MIN_ZOOM_DELTA, Math.min(MAX_ZOOM_DELTA, this.zoomDelta + step));
    if (next !== this.zoomDelta) {
      this.zoomDelta = next;
      this.relayout();
    }
  }

  private screenX(lng: number): number {
    return worldX(lng, this.zoom) - this.originX;
  }

  private screenY(lat: number): number {
    return worldY(lat, this.zoom) - this.originY;
  }

  private radiusVp(meters: number): number {
    return meters / metersPerVp(this.centerLat(), this.zoom);
  }

  /** Circles far larger than the view are skipped; the view would be entirely inside them. */
  private drawable(radius: number): boolean {
    return radius >= 1 && radius < 4 * Math.max(this.viewWidth, MAP_HEIGHT);
  }

  private scaleMeters(): number {
    const perVp = metersPerVp(this.centerLat(), this.zoom);
    let best = SCALE_STEPS_M[0];
    for (const step of SCALE_STEPS_M) {
      if (step / perVp <= 110) {
        best = step;
      }
    }
    return best;
  }

  @Builder
  zoomButton(icon: Resource, label: string, step: number) {
    Button({ type: ButtonType.Circle }) {
      SymbolGlyph(icon)
        .fontSize(22)
        .fontColor([$r('app.color.text_primary')])
    }
    .width(44)
    .height(44)
    .backgroundColor($r('app.color.surface'))
    .shadow({ radius: 8, color: $r('app.color.card_shadow'), offsetY: 2 })
    .accessibilityText(label)
    .onClick(() => this.changeZoom(step))
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      ForEach(this.tiles, (tile: TileView) => {
        if (tile.pixelMap !== undefined) {
          Image(tile.pixelMap)
            .width(TILE_SIZE_VP)
            .height(TILE_SIZE_VP)
            .position({ x: tile.left, y: tile.top })
            .draggable(false)
            .accessibilityLevel('no')
        }
      }, (tile: TileView) => `${tile.key}-${tile.pixelMap !== undefined}`)

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
        Text('Map background unavailable. Positions are drawn to scale.')
          .fontSize(13)
          .fontColor($r('app.color.text_primary'))
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .borderRadius(10)
          .backgroundColor($r('app.color.warning_tint'))
          .position({ x: 12, y: 12 })
          .constraintSize({ maxWidth: Math.max(120, this.viewWidth - 80) })
      }

      Column({ space: 8 }) {
        this.zoomButton($r('sys.symbol.plus'), 'Zoom in', 1)
        this.zoomButton($r('sys.symbol.minus'), 'Zoom out', -1)
      }
      .position({ x: this.viewWidth - 56, y: 12 })

      Column({ space: 2 }) {
        Text(formatDistance(this.scaleMeters()))
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        Row()
          .width(this.scaleMeters() / metersPerVp(this.centerLat(), this.zoom))
          .height(4)
          .borderRadius(2)
          .backgroundColor($r('app.color.text_primary'))
      }
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 8, right: 8, top: 4, bottom: 6 })
      .borderRadius(8)
      .backgroundColor($r('app.color.surface'))
      .opacity(0.9)
      .position({ x: 12, y: MAP_HEIGHT - 50 })
      .accessibilityText(`Scale: ${formatDistance(this.scaleMeters())}`)

      Row() {
        Text('© OpenStreetMap contributors')
          .fontSize(11)
          .fontColor('#1C1B1A')
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .backgroundColor('#CCFFFFFF')
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
      .position({ x: 0, y: MAP_HEIGHT - 20 })
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
