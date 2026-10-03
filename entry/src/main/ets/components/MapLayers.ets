import { image } from '@kit.ImageKit';
import { CareButtonStyle } from './DesignSystem';
import { formatDistance } from '../models/SeniorLocation';
import { MIN_ZOOM, MapViewport, TILE_SIZE_VP, mapTileCache, metersPerVp, tileKey } from '../services/MapTiles';

const SCALE_STEPS_M: number[] = [10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000, 50000, 100000, 200000,
  500000];
/** Tiles are re-anchored after this much panning, so the layer offset stays small. */
const MAX_ANCHOR_DRIFT_VP: number = 4096;

class TileView {
  cacheKey: string;
  zoom: number;
  x: number;
  y: number;
  left: number;
  top: number;
  pixelMap: image.PixelMap | undefined;

  constructor(zoom: number, x: number, y: number, left: number, top: number) {
    this.cacheKey = tileKey(zoom, x, y);
    this.zoom = zoom;
    this.x = x;
    this.y = y;
    this.left = left;
    this.top = top;
    this.pixelMap = mapTileCache.get(this.cacheKey);
  }
}

/**
 * OpenStreetMap tiles for a viewport. Tiles are placed relative to an anchor
 * and the whole layer is shifted as the viewport pans, so dragging rebuilds the
 * tile list only when another tile comes into view. `onFailedTiles` receives
 * the number of visible tiles that could not be loaded.
 */
@Component
export struct MapTileLayer {
  @Prop @Watch('relayout') viewport: MapViewport = new MapViewport(MIN_ZOOM, 0, 0, 0, 0);
  onFailedTiles: (count: number) => void = () => {};
  @State private tiles: TileView[] = [];
  @State private anchorX: number = 0;
  @State private anchorY: number = 0;
  private layoutZoom: number = -1;
  private layoutRange: string = '';
  private failedKeys: Set<string> = new Set<string>();
  private reportedFailures: number = 0;

  aboutToAppear(): void {
    this.relayout();
  }

  private relayout(): void {
    const view = this.viewport;
    if (view.width <= 0 || view.height <= 0) {
      return;
    }
    const firstX = Math.floor(view.originX / TILE_SIZE_VP);
    const lastX = Math.floor((view.originX + view.width) / TILE_SIZE_VP);
    const firstY = Math.floor(view.originY / TILE_SIZE_VP);
    const lastY = Math.floor((view.originY + view.height) / TILE_SIZE_VP);
    const range = `${firstX},${lastX},${firstY},${lastY}`;
    const reanchor = view.zoom !== this.layoutZoom ||
      Math.max(Math.abs(view.originX - this.anchorX), Math.abs(view.originY - this.anchorY)) > MAX_ANCHOR_DRIFT_VP;
    if (!reanchor && range === this.layoutRange) {
      return;
    }
    if (reanchor) {
      this.anchorX = view.originX;
      this.anchorY = view.originY;
    }
    this.layoutZoom = view.zoom;
    this.layoutRange = range;

    const tileCount = Math.pow(2, view.zoom);
    const tiles: TileView[] = [];
    for (let ty = firstY; ty <= lastY; ty++) {
      if (ty < 0 || ty >= tileCount) {
        continue;
      }
      for (let tx = firstX; tx <= lastX; tx++) {
        const wrappedX = ((tx % tileCount) + tileCount) % tileCount;
        tiles.push(new TileView(view.zoom, wrappedX, ty, tx * TILE_SIZE_VP - this.anchorX,
          ty * TILE_SIZE_VP - this.anchorY));
      }
    }
    this.tiles = tiles;
    this.reportFailures();
    this.loadMissingTiles();
  }

  private loadMissingTiles(): void {
    this.tiles.forEach((tile: TileView) => {
      if (tile.pixelMap !== undefined) {
        return;
      }
      const key = tile.cacheKey;
      mapTileCache.load(tile.zoom, tile.x, tile.y).then((pixelMap: image.PixelMap | undefined) => {
        if (pixelMap === undefined) {
          this.failedKeys.add(key);
        } else {
          this.failedKeys.delete(key);
          this.tiles = this.tiles.map((current: TileView) => {
            if (current.cacheKey !== key || current.pixelMap !== undefined) {
              return current;
            }
            const loaded = new TileView(current.zoom, current.x, current.y, current.left, current.top);
            loaded.pixelMap = pixelMap;
            return loaded;
          });
        }
        this.reportFailures();
      });
    });
  }

  private reportFailures(): void {
    const count = this.tiles.filter((tile: TileView) => tile.pixelMap === undefined &&
      this.failedKeys.has(tile.cacheKey)).length;
    if (count !== this.reportedFailures) {
      this.reportedFailures = count;
      this.onFailedTiles(count);
    }
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
      }, (tile: TileView) => `${tile.cacheKey}@${tile.left},${tile.top}-${tile.pixelMap !== undefined}`)
    }
    .width(this.viewport.width)
    .height(this.viewport.height)
    .translate({ x: this.anchorX - this.viewport.originX, y: this.anchorY - this.viewport.originY })
  }
}

/** Scale bar for the map centre, rounded to a readable distance. */
@Component
export struct MapScaleBar {
  @Prop lat: number = 0;
  @Prop zoom: number = MIN_ZOOM;

  private scaleMeters(): number {
    const perVp = metersPerVp(this.lat, this.zoom);
    let best = SCALE_STEPS_M[0];
    for (const step of SCALE_STEPS_M) {
      if (step / perVp <= 110) {
        best = step;
      }
    }
    return best;
  }

  build() {
    Column({ space: 2 }) {
      Text(formatDistance(this.scaleMeters()))
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
      Row()
        .width(this.scaleMeters() / metersPerVp(this.lat, this.zoom))
        .height(4)
        .borderRadius(2)
        .backgroundColor($r('app.color.text_primary'))
    }
    .alignItems(HorizontalAlign.Start)
    .padding({ left: 8, right: 8, top: 4, bottom: 6 })
    .borderRadius(8)
    .backgroundColor($r('app.color.surface'))
    .opacity(0.9)
    .accessibilityText(`Scale: ${formatDistance(this.scaleMeters())}`)
  }
}

@Builder
export function mapZoomButton(icon: Resource, label: string, onTap: () => void) {
  Button() {
    Row({ space: 6 }) {
      SymbolGlyph(icon)
        .fontSize(22)
        .fontColor([$r('app.color.senior_accent')])
      Text(label).fontSize(15).fontColor($r('app.color.senior_accent'))
    }
  }
  .width(120)
  .height(56)
  .attributeModifier(new CareButtonStyle('secondary'))
  .padding(8)
  .shadow({ radius: 8, color: $r('app.color.card_shadow'), offsetY: 2 })
  .accessibilityText(label)
  .onClick(() => onTap())
}

/** Required credit for OpenStreetMap tiles, along the bottom edge of a map `mapHeight` tall. */
@Builder
export function mapAttribution(mapHeight: number) {
  Row() {
    Text('© OpenStreetMap contributors')
      .fontSize(11)
      .fontColor($r('app.color.text_primary'))
      .padding({ left: 6, right: 6, top: 2, bottom: 2 })
      .backgroundColor($r('app.color.surface'))
  }
  .width('100%')
  .justifyContent(FlexAlign.End)
  .position({ x: 0, y: mapHeight - 20 })
}

@Builder
export function mapTilesUnavailable(maxWidth: number) {
  Text('Map background unavailable. Positions are drawn to scale.')
    .fontSize(13)
    .fontColor($r('app.color.text_primary'))
    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
    .borderRadius(10)
    .backgroundColor($r('app.color.warning_tint'))
    .position({ x: 12, y: 12 })
    .constraintSize({ maxWidth: maxWidth })
}
