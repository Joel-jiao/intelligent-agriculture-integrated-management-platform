/**
 * GIS 空间计算与坐标适配
 *
 * 项目历史数据（plots.polygon / plot_audits.polygon）是 1000 × 600 的「虚拟画布」坐标，
 * 只用于 SVG 演示。接入真实 Leaflet 底图后需要 WGS84 经纬度，这里做双向适配：
 *
 *  1. 新数据：MapPoint 直接带 lng / lat（Leaflet 地图上绘制得到的就是它）；
 *  2. 历史数据：按园区中心 + 固定实地跨度线性投影，落成真实经纬度，同时反算出 x / y，
 *     保证老页面读 p.x / p.y 依然正确。
 *
 * 这样一套数据既能喂真实底图，也不破坏任何按 x / y 取值的旧代码。
 */
import type { MapPoint } from '@/data/types'

/** 历史虚拟画布尺寸 */
export const VIRTUAL_CANVAS = { width: 1000, height: 600 }

/** 园区中心（重庆市璧山区现代农业园区，大兴镇片区） */
export const PARK_CENTER = { lng: 106.1560, lat: 29.5470 }

/**
 * 虚拟画布对应的实地跨度（米）：1000 × 600 的画布等比缩放到 580 × 348 米。
 * 该比例按库中 6 个地块「申报面积 / 图形面积」标定，使量算结果与档案面积同量级。
 */
export const PARK_SPAN_METERS = { width: 580, height: 348 }

const METERS_PER_DEG_LAT = 111132
const METERS_PER_DEG_LNG = 111320

/** 1 亩 = 666.6667 平方米 */
export const SQM_PER_MU = 666.6667

export interface LngLat {
  lng: number
  lat: number
}

/** 底图类型 */
export type Basemap = 'vector' | 'satellite' | 'blank'

export interface GeoBounds {
  south: number
  west: number
  north: number
  east: number
}

/** 框选结果：保留旧字段（虚拟画布像素）并新增真实地理范围 */
export interface SelectionArea {
  x: number
  y: number
  width: number
  height: number
  bounds: GeoBounds
}

/** 绘制 / 编辑完成后的地块边界数据 */
export interface DrawnBoundary {
  polygon: MapPoint[]
  /** 平方米 */
  area: number
  /** 亩 */
  areaMu: number
  /** 周长（米） */
  perimeter: number
  /** GeoJSON Polygon，可直接入库或对接第三方 */
  geojson: GeoJsonPolygon
}

export interface GeoJsonPolygon {
  type: 'Polygon'
  coordinates: number[][][]
}

const rad = Math.PI / 180

function spanDegrees() {
  const latSpan = PARK_SPAN_METERS.height / METERS_PER_DEG_LAT
  const lngSpan = PARK_SPAN_METERS.width / (METERS_PER_DEG_LNG * Math.cos(PARK_CENTER.lat * rad))
  return { latSpan, lngSpan }
}

/** 虚拟画布坐标 → 经纬度 */
export function canvasToLngLat(point: { x: number; y: number }): LngLat {
  const { latSpan, lngSpan } = spanDegrees()
  return {
    lng: PARK_CENTER.lng + (point.x / VIRTUAL_CANVAS.width - 0.5) * lngSpan,
    lat: PARK_CENTER.lat - (point.y / VIRTUAL_CANVAS.height - 0.5) * latSpan,
  }
}

/** 经纬度 → 虚拟画布坐标（与 canvasToLngLat 互为逆运算） */
export function lngLatToCanvas(position: LngLat): { x: number; y: number } {
  const { latSpan, lngSpan } = spanDegrees()
  return {
    x: ((position.lng - PARK_CENTER.lng) / lngSpan + 0.5) * VIRTUAL_CANVAS.width,
    y: (0.5 - (position.lat - PARK_CENTER.lat) / latSpan) * VIRTUAL_CANVAS.height,
  }
}

/** 取点位经纬度：优先真实 lng/lat，缺失时按历史画布坐标投影 */
export function pointToLngLat(point: MapPoint): LngLat {
  if (typeof point.lng === 'number' && typeof point.lat === 'number') {
    return { lng: point.lng, lat: point.lat }
  }
  return canvasToLngLat(point)
}

/** 经纬度 → MapPoint（同时写入 x / y，保持旧消费者可用） */
export function lngLatToPoint(position: LngLat): MapPoint {
  const canvas = lngLatToCanvas(position)
  return {
    lng: Number(position.lng.toFixed(7)),
    lat: Number(position.lat.toFixed(7)),
    x: Math.round(canvas.x * 10) / 10,
    y: Math.round(canvas.y * 10) / 10,
  }
}

/** 地块边界 → Leaflet 需要的 [lat, lng][] */
export function polygonToLatLngs(points: MapPoint[]): Array<[number, number]> {
  return points.map((point) => {
    const position = pointToLngLat(point)
    return [position.lat, position.lng]
  })
}

/** Leaflet [lat, lng][] → 地块边界 */
export function latLngsToPolygon(latlngs: Array<[number, number]>): MapPoint[] {
  return latlngs.map(([lat, lng]) => lngLatToPoint({ lat, lng }))
}

/**
 * 球面多边形面积（Chamberlain & Duquette 公式），单位平方米。
 * 相比平面投影，跨纬度更准确，也不依赖 turf 之类的额外依赖。
 */
export function polygonArea(ring: LngLat[]): number {
  if (ring.length < 3) return 0
  const earthRadius = 6378137
  let total = 0
  for (let index = 0; index < ring.length; index += 1) {
    const current = ring[index] as LngLat
    const next = ring[(index + 1) % ring.length] as LngLat
    total +=
      (next.lng - current.lng) * rad * (2 + Math.sin(current.lat * rad) + Math.sin(next.lat * rad))
  }
  return Math.abs((total * earthRadius * earthRadius) / 2)
}

/** 地块面积（平方米） */
export function polygonAreaSqm(points: MapPoint[]): number {
  return polygonArea(points.map(pointToLngLat))
}

/** 地块面积（亩） */
export function polygonAreaMu(points: MapPoint[]): number {
  return polygonAreaSqm(points) / SQM_PER_MU
}

/** 地块周长（米），按相邻顶点球面距离累加 */
export function polygonPerimeter(points: MapPoint[]): number {
  if (points.length < 2) return 0
  const ring = points.map(pointToLngLat)
  let total = 0
  for (let index = 0; index < ring.length; index += 1) {
    const current = ring[index] as LngLat
    const next = ring[(index + 1) % ring.length] as LngLat
    total += haversine(current, next)
  }
  return total
}

/** 两点球面距离（米） */
export function haversine(from: LngLat, to: LngLat): number {
  const earthRadius = 6378137
  const dLat = (to.lat - from.lat) * rad
  const dLng = (to.lng - from.lng) * rad
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(from.lat * rad) * Math.cos(to.lat * rad) * Math.sin(dLng / 2) ** 2
  return 2 * earthRadius * Math.asin(Math.min(1, Math.sqrt(a)))
}

/** 地块形心（经纬度平均值，足够定位与文字标注使用） */
export function polygonCentroid(points: MapPoint[]): LngLat {
  if (points.length === 0) return { ...PARK_CENTER }
  const sum = points.reduce(
    (acc, point) => {
      const position = pointToLngLat(point)
      return { lng: acc.lng + position.lng, lat: acc.lat + position.lat }
    },
    { lng: 0, lat: 0 },
  )
  return { lng: sum.lng / points.length, lat: sum.lat / points.length }
}

/** 边界是否闭合（GIS 判定：至少 3 个顶点且首尾不重合造成退化） */
export function isBoundaryClosed(points: MapPoint[]): boolean {
  if (points.length < 3) return false
  return polygonAreaSqm(points) > 1
}

/** 地块边界 → GeoJSON Feature（Polygon 自动闭合） */
export function polygonToGeoJson(points: MapPoint[], properties: Record<string, unknown> = {}) {
  const ring = points.map(pointToLngLat).map((position) => [
    Number(position.lng.toFixed(7)),
    Number(position.lat.toFixed(7)),
  ])
  if (ring.length > 0) {
    const first = ring[0] as number[]
    const last = ring[ring.length - 1] as number[]
    if (first[0] !== last[0] || first[1] !== last[1]) ring.push([first[0] as number, first[1] as number])
  }
  return {
    type: 'Feature' as const,
    properties,
    geometry: { type: 'Polygon' as const, coordinates: [ring] },
  }
}

/** 构建统一的绘制结果 */
export function buildBoundary(points: MapPoint[]): DrawnBoundary {
  const area = polygonAreaSqm(points)
  return {
    polygon: points,
    area,
    areaMu: area / SQM_PER_MU,
    perimeter: polygonPerimeter(points),
    geojson: polygonToGeoJson(points).geometry,
  }
}

/** 面积友好展示：小于 1 亩时用平方米 */
export function formatAreaSqm(areaSqm: number): string {
  if (areaSqm <= 0) return '—'
  if (areaSqm >= SQM_PER_MU) {
    return `${(areaSqm / SQM_PER_MU).toFixed(2)} 亩`
  }
  return `${areaSqm.toFixed(0)} ㎡`
}

/** 经纬度友好展示（6 位小数，约 0.1 米精度） */
export function formatLngLat(position: LngLat): string {
  return `${position.lng.toFixed(6)}, ${position.lat.toFixed(6)}`
}

/** 是否落在给定地理范围内 */
export function boundsContain(bounds: GeoBounds, position: LngLat): boolean {
  return (
    position.lat >= bounds.south &&
    position.lat <= bounds.north &&
    position.lng >= bounds.west &&
    position.lng <= bounds.east
  )
}
