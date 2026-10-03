import { http } from '@kit.NetworkKit';
import { image } from '@kit.ImageKit';

/**
 * OpenStreetMap raster tiles and Web Mercator math for the guardian map.
 *
 * HarmonyOS Map Kit (`MapComponent`) needs the Map service enabled in
 * AppGallery Connect and a signed app; this project has neither, so the map is
 * drawn from public OSM tiles instead. Tiles are fetched with an identifying
 * User-Agent, as the OSM tile usage policy requires, and cached in memory only.
 * The screen must show "© OpenStreetMap contributors".
 */
const TILE_SERVER: string = 'https://tile.openstreetmap.org';
const USER_AGENT: string = 'Carely/1.0 (HarmonyOS elderly-care hackathon demo)';
const MAX_CACHED_TILES: number = 48;
const EARTH_CIRCUMFERENCE_M: number = 40075016.686;
const MAX_LATITUDE: number = 85.0511;

/** Display size of one 256 px tile, in vp. */
export const TILE_SIZE_VP: number = 192;
export const MIN_ZOOM: number = 3;
export const MAX_ZOOM: number = 18;

export function worldX(lng: number, zoom: number): number {
  return (lng + 180) / 360 * Math.pow(2, zoom) * TILE_SIZE_VP;
}

export function worldY(lat: number, zoom: number): number {
  const clamped = Math.max(-MAX_LATITUDE, Math.min(MAX_LATITUDE, lat)) * Math.PI / 180;
  return (1 - Math.log(Math.tan(clamped) + 1 / Math.cos(clamped)) / Math.PI) / 2 * Math.pow(2, zoom) * TILE_SIZE_VP;
}

export function metersPerVp(lat: number, zoom: number): number {
  return EARTH_CIRCUMFERENCE_M * Math.cos(lat * Math.PI / 180) / (Math.pow(2, zoom) * TILE_SIZE_VP);
}

/** Largest zoom at which `halfExtentM` metres fit in `halfViewVp` vp around `lat`. */
export function fitZoom(lat: number, halfExtentM: number, halfViewVp: number): number {
  const ratio = EARTH_CIRCUMFERENCE_M * Math.cos(lat * Math.PI / 180) * halfViewVp / (TILE_SIZE_VP * halfExtentM);
  const zoom = Math.floor(Math.log(ratio) / Math.LN2);
  return Math.max(MIN_ZOOM, Math.min(MAX_ZOOM, isFinite(zoom) ? zoom : MIN_ZOOM));
}

export function tileKey(zoom: number, x: number, y: number): string {
  return `${zoom}/${x}/${y}`;
}

export class MapTileCache {
  private readonly tiles: Map<string, image.PixelMap> = new Map<string, image.PixelMap>();
  private readonly pending: Map<string, Promise<image.PixelMap | undefined>> = new Map<string, Promise<image.PixelMap | undefined>>();

  get(key: string): image.PixelMap | undefined {
    return this.tiles.get(key);
  }

  /** Resolves to undefined when the tile cannot be fetched or decoded. Never throws. */
  load(zoom: number, x: number, y: number): Promise<image.PixelMap | undefined> {
    const key = tileKey(zoom, x, y);
    const cached = this.tiles.get(key);
    if (cached !== undefined) {
      return Promise.resolve(cached);
    }
    const inFlight = this.pending.get(key);
    if (inFlight !== undefined) {
      return inFlight;
    }
    const task = this.fetchTile(zoom, x, y).then((pixelMap: image.PixelMap | undefined) => {
      this.pending.delete(key);
      if (pixelMap !== undefined) {
        this.remember(key, pixelMap);
      }
      return pixelMap;
    });
    this.pending.set(key, task);
    return task;
  }

  /**
   * Drops the oldest entries. PixelMaps are not released explicitly because an
   * evicted tile may still be on screen; the runtime frees them once unused.
   */
  private remember(key: string, pixelMap: image.PixelMap): void {
    this.tiles.set(key, pixelMap);
    while (this.tiles.size > MAX_CACHED_TILES) {
      const oldest = this.tiles.keys().next();
      if (oldest.done) {
        break;
      }
      this.tiles.delete(oldest.value);
    }
  }

  private async fetchTile(zoom: number, x: number, y: number): Promise<image.PixelMap | undefined> {
    const request = http.createHttp();
    try {
      const response = await request.request(`${TILE_SERVER}/${zoom}/${x}/${y}.png`, {
        method: http.RequestMethod.GET,
        header: { 'User-Agent': USER_AGENT },
        expectDataType: http.HttpDataType.ARRAY_BUFFER,
        connectTimeout: 10000,
        readTimeout: 10000
      });
      if (response.responseCode !== 200) {
        return undefined;
      }
      const source = image.createImageSource(response.result as ArrayBuffer);
      try {
        return await source.createPixelMap();
      } finally {
        await source.release();
      }
    } catch (error) {
      console.error(`[MapTiles] tile ${zoom}/${x}/${y} failed`);
      return undefined;
    } finally {
      request.destroy();
    }
  }
}

export const mapTileCache: MapTileCache = new MapTileCache();
