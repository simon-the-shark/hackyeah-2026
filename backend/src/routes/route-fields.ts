import { z } from "zod";
import { lat, lng } from "../schemas.js";

type RoutePoint = { lat: number; lng: number };

/** Optional route on trips and routines; `null` on update clears it. */
export const routeField = z.array(z.object({ lat, lng })).min(2).max(200).nullable().optional();
export const corridorField = z.number().int().min(20).max(2000).nullable().optional();

/** A corridor is the allowed distance from a route, so a body cannot set one while clearing the route. */
export const corridorNeedsRoute = {
  check: (b: { route?: RoutePoint[] | null; corridorM?: number | null }) =>
    !(b.corridorM != null && b.route === null),
  message: { message: "corridorM needs a route", path: ["corridorM"] },
};

/**
 * Update semantics for route fields: an omitted field keeps the stored value, `null` clears it, and
 * clearing the route also clears the corridor. Editing only a trip's time window never drops its route.
 */
export function routeUpdate(b: { route?: RoutePoint[] | null; corridorM?: number | null }) {
  const set: { route?: RoutePoint[] | null; corridorM?: number | null } = {};
  if (b.route !== undefined) set.route = b.route;
  if (b.corridorM !== undefined) set.corridorM = b.corridorM;
  if (b.route === null) set.corridorM = null;
  return set;
}

/** True when the update sets a corridor and relies on the stored route, which must then exist. */
export const needsStoredRoute = (b: { route?: RoutePoint[] | null; corridorM?: number | null }) =>
  b.corridorM != null && b.route === undefined;
