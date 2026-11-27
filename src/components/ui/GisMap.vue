<script setup lang="ts">
/**
 * GIS 地图组件（Leaflet 1.9 + 高德底图）
 *
 * 真实 GIS 能力：
 *  - 矢量 / 影像 / 无底图三种底图，支持深浅色
 *  - 地块面要素渲染、悬浮高亮、点击选中、常驻标注
 *  - 设备点位渲染（在线 / 离线 / 故障）
 *  - 框选（拖拽矩形，发回真实地理范围 + 兼容旧画布坐标）
 *  - 地块边界绘制 / 顶点拖拽编辑，实时面积与周长（球面计算，见 utils/geo.ts）
 *  - 比例尺、经纬度读数、缩放控件、视野自适应
 *
 * 数据兼容：Plot.polygon 里若带 lng / lat 直接用，否则按园区范围把历史画布坐标
 * 投影成经纬度（utils/geo.ts），因此老数据无需迁移也能落到真实底图。
 */
import { computed, onBeforeUnmount, onMounted, ref, shallowRef, watch } from 'vue'
import * as L from 'leaflet'
import type { Device, MapPoint, Plot } from '@/data/types'
import { useTheme } from '@/composables/useTheme'
import {
  PARK_CENTER,
  buildBoundary,
  formatAreaSqm,
  formatLngLat,
  latLngsToPolygon,
  lngLatToCanvas,
  polygonAreaSqm,
  polygonCentroid,
  polygonToLatLngs,
  type Basemap,
  type DrawnBoundary,
  type SelectionArea,
} from '@/utils/geo'

const props = withDefaults(
  defineProps<{
    plots: Plot[]
    devices?: Device[]
    selectedId?: string
    showDevices?: boolean
    boxSelect?: boolean
    dark?: boolean
    hideLegend?: boolean
    height?: number
    /** 底图类型 */
    basemap?: Basemap
    /** 初始缩放级别 */
    zoom?: number
    /** 初始中心 [lat, lng] */
    center?: [number, number]
    /** 数据加载后自动缩放到全部地块 */
    autoFit?: boolean
    /** 常驻地块标注 */
    showLabels?: boolean
    /** 内置工具条 */
    showToolbar?: boolean
    /** 比例尺 */
    showScale?: boolean
    /** 经纬度读数 */
    showCoords?: boolean
    /** 缩放控件 */
    showZoom?: boolean
    /** 开启边界绘制（绘制完成后 emit draw-complete） */
    drawable?: boolean
    /** 允许拖拽当前选中地块的顶点（emit edit-complete） */
    editable?: boolean
    /** 待确认的边界（绘制结果预览，蓝色虚线） */
    pending?: MapPoint[]
    /** 飞行定位到选中地块 */
    panToSelected?: boolean
    toolbarPosition?: 'top-left' | 'top-right'
  }>(),
  {
    devices: () => [],
    selectedId: '',
    showDevices: true,
    boxSelect: false,
    dark: false,
    hideLegend: false,
    height: 360,
    basemap: 'vector',
    zoom: 16,
    center: undefined,
    autoFit: true,
    showLabels: true,
    showToolbar: true,
    showScale: true,
    showCoords: true,
    showZoom: true,
    drawable: false,
    pending: undefined,
    editable: false,
    panToSelected: false,
    toolbarPosition: 'top-right',
  },
)

const emit = defineEmits<{
  'select-plot': [id: string]
  'select-device': [id: string]
  'select-area': [area: SelectionArea]
  'draw-complete': [boundary: DrawnBoundary]
  'edit-complete': [boundary: DrawnBoundary]
  'draft-change': [vertices: number]
  'update:basemap': [value: Basemap]
  ready: []
}>()

const { theme } = useTheme()
const darkMode = computed(() => props.dark || theme.value === 'dark')

const mapEl = ref<HTMLDivElement | null>(null)
const mapRef = shallowRef<L.Map | null>(null)

const currentBasemap = ref<Basemap>(props.basemap)
const drawing = ref(false)
const boxActive = ref(false)
const draftCount = ref(0)
const draftArea = ref(0)
const coords = ref('')

/* ------------------------------ 图层状态（非响应式，交给 Leaflet 管理） ------------------------------ */

const plotsLayer = L.layerGroup()
const devicesLayer = L.layerGroup()
let baseLayer: L.Layer | null = null
const plotLayers = new Map<string, L.Polygon>()
let pendingLayer: L.Polygon | null = null

let draftPoints: L.LatLng[] = []
let draftPolygon: L.Polygon | null = null
let draftLine: L.Polyline | null = null
let draftRubber: L.Polyline | null = null
let draftHandles: L.Marker[] = []
let editHandles: L.Marker[] = []
let boxStart: L.LatLng | null = null
let boxRect: L.Rectangle | null = null

const DRAFT_COLOR = '#007aff'
const TILE_ATTRIBUTION = '底图 &copy; 高德地图 · 云岭智慧农业示范园'

/* ------------------------------ 初始化 ------------------------------ */

onMounted(() => {
  if (!mapEl.value) return
  const map = L.map(mapEl.value, {
    center: props.center ?? [PARK_CENTER.lat, PARK_CENTER.lng],
    zoom: props.zoom,
    zoomControl: false,
    attributionControl: true,
    minZoom: 3,
    maxZoom: 19,
    zoomSnap: 0.5,
    preferCanvas: true,
  })
  mapRef.value = map

  map.attributionControl.setPrefix('')
  if (props.showZoom) L.control.zoom({ position: 'bottomright', zoomInTitle: '放大', zoomOutTitle: '缩小' }).addTo(map)
  if (props.showScale) L.control.scale({ position: 'bottomright', imperial: false, metric: true }).addTo(map)

  plotsLayer.addTo(map)
  devicesLayer.addTo(map)

  applyBasemap()
  renderPlots()
  renderPending()
  renderDevices()
  if (props.autoFit && props.plots.length > 0) {
    autoFitDone = true
    fitAll(false)
  }

  map.on('mousemove', (event: L.LeafletMouseEvent) => {
    coords.value = formatLngLat({ lng: event.latlng.lng, lat: event.latlng.lat })
    onDrawMove(event)
  })
  map.on('mouseout', () => {
    coords.value = ''
  })
  map.on('click', onMapClick)
  map.on('mousedown', onBoxStart)
  map.on('mouseup', onBoxEnd)
  window.addEventListener('keydown', onKeydown)

  resizeObserver = new ResizeObserver(() => map.invalidateSize())
  if (mapEl.value) resizeObserver.observe(mapEl.value)

  emit('ready')
})

let resizeObserver: ResizeObserver | null = null
/** 数据晚于地图到达时，补一次「缩放到全部地块」 */
let autoFitDone = false

onBeforeUnmount(() => {
  window.removeEventListener('keydown', onKeydown)
  resizeObserver?.disconnect()
  mapRef.value?.remove()
  mapRef.value = null
})

function onKeydown(event: KeyboardEvent) {
  if (event.key !== 'Escape') return
  if (drawing.value) cancelDraw()
  if (boxActive.value) stopBoxSelect()
}

/* ------------------------------ 底图 ------------------------------ */

function amapLayer(style: 6 | 7 | 8) {
  return L.tileLayer(
    `https://wprd0{s}.is.autonavi.com/appmaptile?x={x}&y={y}&z={z}&lang=zh_cn&size=1&scl=1&style=${style}`,
    {
      subdomains: ['1', '2', '3', '4'],
      minZoom: 3,
      maxZoom: 19,
      attribution: TILE_ATTRIBUTION,
    },
  )
}

function applyBasemap() {
  const map = mapRef.value
  if (!map) return
  if (baseLayer) {
    map.removeLayer(baseLayer)
    baseLayer = null
  }
  const kind = currentBasemap.value
  if (kind === 'blank') return
  if (kind === 'satellite') {
    baseLayer = L.layerGroup([
      amapLayer(6),
      L.tileLayer('https://webst0{s}.is.autonavi.com/appmaptile?style=8&x={x}&y={y}&z={z}', {
        subdomains: ['1', '2', '3', '4'],
        minZoom: 3,
        maxZoom: 19,
      }),
    ]).addTo(map)
  } else {
    baseLayer = amapLayer(7).addTo(map)
  }
}

function setBasemap(value: Basemap) {
  currentBasemap.value = value
  emit('update:basemap', value)
  applyBasemap()
}

/* ------------------------------ 地块 ------------------------------ */

function escapeHtml(text: string): string {
  return text.replace(/[&<>"']/g, (char) => {
    const map: Record<string, string> = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }
    return map[char] ?? char
  })
}

function plotTooltip(plot: Plot): string {
  const computedArea = polygonAreaSqm(plot.polygon)
  return `<div class="gis-tip__title">${escapeHtml(plot.name)}</div>
    <div class="gis-tip__row">${escapeHtml(plot.crop)} · ${escapeHtml(plot.variety)}</div>
    <div class="gis-tip__row">档案 ${plot.area} 亩 · 图形 ${formatAreaSqm(computedArea)}</div>
    <div class="gis-tip__row">${escapeHtml(plot.manager)} · ${escapeHtml(plot.status)}</div>`
}

function plotLabel(plot: Plot): string {
  return `<div class="gis-label__title">${escapeHtml(plot.name)}</div>
    <div class="gis-label__meta">${escapeHtml(plot.crop)} · ${plot.area} 亩</div>`
}

function renderPlots() {
  const map = mapRef.value
  if (!map) return
  plotsLayer.clearLayers()
  plotLayers.clear()

  props.plots.forEach((plot) => {
    if (plot.polygon.length < 3) return
    const selected = plot.id === props.selectedId
    const color = plot.color || '#4fae74'
    const polygon = L.polygon(polygonToLatLngs(plot.polygon), {
      color: selected ? '#ffffff' : color,
      weight: selected ? 3.5 : 1.6,
      opacity: 1,
      fillColor: color,
      fillOpacity: selected ? 0.46 : 0.24,
      lineJoin: 'round',
    })

    polygon.bindTooltip(props.showLabels ? plotLabel(plot) : plotTooltip(plot), {
      permanent: props.showLabels,
      sticky: !props.showLabels,
      direction: props.showLabels ? 'center' : 'top',
      className: props.showLabels ? 'gis-label' : 'gis-tip',
      opacity: 1,
    })

    polygon.on('mouseover', () => {
      polygon.setStyle({ fillOpacity: 0.5, weight: selected ? 3.5 : 2.6 })
      polygon.bringToFront()
    })
    polygon.on('mouseout', () => {
      polygon.setStyle({ fillOpacity: selected ? 0.46 : 0.24, weight: selected ? 3.5 : 1.6 })
    })
    polygon.on('click', () => {
      if (drawing.value || boxActive.value) return
      emit('select-plot', plot.id)
    })

    polygon.addTo(plotsLayer)
    plotLayers.set(plot.id, polygon)
  })

  renderEditHandles()
}

/* ------------------------------ 待确认边界 ------------------------------ */

function renderPending() {
  const map = mapRef.value
  if (!map) return
  pendingLayer?.remove()
  pendingLayer = null
  if (!props.pending || props.pending.length < 3) return
  pendingLayer = L.polygon(polygonToLatLngs(props.pending), {
    color: '#007aff',
    weight: 2.5,
    dashArray: '8 6',
    fillColor: '#007aff',
    fillOpacity: 0.24,
  }).addTo(map)
  pendingLayer.bringToFront()
}

/* ------------------------------ 设备点位 ------------------------------ */

const DEVICE_TONE: Record<string, string> = {
  在线: 'online',
  离线: 'offline',
  故障: 'fault',
}

function renderDevices() {
  devicesLayer.clearLayers()
  if (!props.showDevices) return
  const counters: Record<string, number> = {}

  props.devices
    .filter((device) => device.type !== '传感器' && device.type !== '网关')
    .forEach((device) => {
      const plot = props.plots.find((item) => item.id === device.plotId)
      if (!plot || plot.polygon.length === 0) return
      const center = polygonCentroid(plot.polygon)
      const index = counters[device.plotId] ?? 0
      counters[device.plotId] = index + 1
      const position = L.latLng(center.lat, center.lng)
      const marker = L.marker(position, {
        icon: L.divIcon({
          className: 'gis-device',
          html: `<span class="gis-device__dot gis-device__dot--${DEVICE_TONE[device.status] ?? 'offline'}"></span>`,
          iconSize: [12, 12],
          iconAnchor: [6, 6],
        }),
        zIndexOffset: 400 + index,
        title: `${device.name} · ${device.status}`,
      })
      marker.on('click', () => {
        if (drawing.value || boxActive.value) return
        emit('select-device', device.id)
      })
      marker.addTo(devicesLayer)
    })
}

/* ------------------------------ 视野 ------------------------------ */

function plotBounds(plot: Plot): L.LatLngBounds | null {
  if (plot.polygon.length === 0) return null
  return L.latLngBounds(polygonToLatLngs(plot.polygon))
}

function fitAll(animate = true) {
  const map = mapRef.value
  if (!map) return
  const latlngs: L.LatLngExpression[] = []
  props.plots.forEach((plot) => {
    polygonToLatLngs(plot.polygon).forEach((position) => latlngs.push(position))
  })
  if (latlngs.length === 0) {
    map.setView(props.center ?? [PARK_CENTER.lat, PARK_CENTER.lng], props.zoom, { animate })
    return
  }
  map.fitBounds(L.latLngBounds(latlngs), { padding: [40, 40], maxZoom: 19, animate })
}

function fitToPlot(id: string, animate = true) {
  const map = mapRef.value
  if (!map) return
  const plot = props.plots.find((item) => item.id === id)
  const bounds = plot ? plotBounds(plot) : null
  if (!bounds) return
  map.fitBounds(bounds, { padding: [48, 48], maxZoom: 19, animate })
}

function focus(lng: number, lat: number, zoom = 18) {
  mapRef.value?.setView([lat, lng], zoom, { animate: true })
}

/* ------------------------------ 框选 ------------------------------ */

const BOX_STYLE: L.PathOptions = {
  color: '#007aff',
  weight: 1.5,
  dashArray: '6 4',
  fillColor: '#007aff',
  fillOpacity: 0.1,
}

function toggleBoxSelect() {
  if (boxActive.value) stopBoxSelect()
  else startBoxSelect()
}

function startBoxSelect() {
  const map = mapRef.value
  if (!map) return
  if (drawing.value) cancelDraw()
  boxActive.value = true
  map.dragging.disable()
  map.getContainer().classList.add('gis-map__surface--box')
}

function stopBoxSelect() {
  const map = mapRef.value
  if (!map) return
  boxActive.value = false
  boxStart = null
  boxRect?.remove()
  boxRect = null
  map.dragging.enable()
  map.getContainer().classList.remove('gis-map__surface--box')
}

function onBoxStart(event: L.LeafletMouseEvent) {
  if (!boxActive.value) return
  boxStart = event.latlng
  boxRect?.remove()
  boxRect = L.rectangle(L.latLngBounds(event.latlng, event.latlng), BOX_STYLE).addTo(mapRef.value as L.Map)
}

function onBoxEnd(event: L.LeafletMouseEvent) {
  if (!boxActive.value || !boxStart) return
  const start = boxStart
  const bounds = L.latLngBounds(start, event.latlng)
  boxRect?.remove()
  boxRect = null
  boxStart = null
  stopBoxSelect()

  if (Math.abs(bounds.getNorth() - bounds.getSouth()) < 1e-7) return
  if (Math.abs(bounds.getEast() - bounds.getWest()) < 1e-7) return

  const southWest = lngLatToCanvas({ lng: bounds.getWest(), lat: bounds.getSouth() })
  const northEast = lngLatToCanvas({ lng: bounds.getEast(), lat: bounds.getNorth() })
  emit('select-area', {
    x: Math.min(southWest.x, northEast.x),
    y: Math.min(southWest.y, northEast.y),
    width: Math.abs(northEast.x - southWest.x),
    height: Math.abs(northEast.y - southWest.y),
    bounds: {
      south: bounds.getSouth(),
      west: bounds.getWest(),
      north: bounds.getNorth(),
      east: bounds.getEast(),
    },
  })
}

/* ------------------------------ 边界绘制 ------------------------------ */

function handleIcon(kind: 'vertex' | 'first' | 'edit'): L.DivIcon {
  return L.divIcon({
    className: `gis-handle gis-handle--${kind}`,
    html: '<span></span>',
    iconSize: [16, 16],
    iconAnchor: [8, 8],
  })
}

function startDraw() {
  const map = mapRef.value
  if (!map) return
  if (drawing.value) return
  if (boxActive.value) stopBoxSelect()
  clearEditHandles()
  clearDraft()
  drawing.value = true
  map.doubleClickZoom.disable()
  map.getContainer().classList.add('gis-map__surface--draw')
}

function cancelDraw() {
  const map = mapRef.value
  drawing.value = false
  clearDraft()
  map?.doubleClickZoom.enable()
  map?.getContainer().classList.remove('gis-map__surface--draw')
  renderEditHandles()
}

function clearDraft() {
  draftPoints = []
  draftPolygon?.remove()
  draftLine?.remove()
  draftRubber?.remove()
  draftPolygon = null
  draftLine = null
  draftRubber = null
  draftHandles.forEach((handle) => handle.remove())
  draftHandles = []
  draftCount.value = 0
  draftArea.value = 0
  emit('draft-change', 0)
}

function undoDraw() {
  if (draftPoints.length === 0) return
  draftPoints.pop()
  syncDraft()
}

function refreshDraftShape() {
  const latlngs = draftPoints.map((point) => [point.lat, point.lng] as [number, number])
  draftPolygon?.setLatLngs(latlngs)
  draftLine?.setLatLngs(latlngs)
}

function updateDraftMetrics() {
  draftCount.value = draftPoints.length
  draftArea.value =
    draftPoints.length >= 3 ? polygonAreaSqm(latLngsToPolygon(draftPoints.map((p) => [p.lat, p.lng]))) : 0
  emit('draft-change', draftPoints.length)
}

function syncDraft() {
  const map = mapRef.value
  if (!map) return
  draftHandles.forEach((handle) => handle.remove())
  draftHandles = []
  draftPolygon?.remove()
  draftLine?.remove()
  draftPolygon = null
  draftLine = null

  if (draftPoints.length >= 3) {
    draftPolygon = L.polygon(draftPoints, {
      color: DRAFT_COLOR,
      weight: 2,
      dashArray: '7 5',
      fillColor: DRAFT_COLOR,
      fillOpacity: 0.18,
    }).addTo(map)
  } else if (draftPoints.length === 2) {
    draftLine = L.polyline(draftPoints, { color: DRAFT_COLOR, weight: 2, dashArray: '7 5' }).addTo(map)
  }

  draftPoints.forEach((latlng, index) => {
    const marker = L.marker(latlng, {
      icon: handleIcon(index === 0 && draftPoints.length >= 3 ? 'first' : 'vertex'),
      draggable: true,
      keyboard: false,
      zIndexOffset: 700,
    })
    marker.on('drag', () => {
      draftPoints[index] = marker.getLatLng()
      refreshDraftShape()
      updateDraftMetrics()
    })
    marker.on('dragend', () => {
      refreshDraftShape()
      updateDraftMetrics()
    })
    marker.on('click', (event: L.LeafletMouseEvent) => {
      L.DomEvent.stopPropagation(event)
      if (index === 0 && draftPoints.length >= 3) finishDraw()
    })
    marker.addTo(map)
    draftHandles.push(marker)
  })

  updateDraftMetrics()
}

function onMapClick(event: L.LeafletMouseEvent) {
  if (!drawing.value) return
  if (draftPoints.length >= 3) {
    const first = mapRef.value?.latLngToContainerPoint(draftPoints[0] as L.LatLng)
    const current = mapRef.value?.latLngToContainerPoint(event.latlng)
    if (first && current && first.distanceTo(current) < 14) {
      finishDraw()
      return
    }
  }
  draftPoints.push(event.latlng)
  syncDraft()
}

function onDrawMove(event: L.LeafletMouseEvent) {
  if (!drawing.value || draftPoints.length === 0) return
  const tail = draftPoints[draftPoints.length - 1] as L.LatLng
  const line = [
    [tail.lat, tail.lng],
    [event.latlng.lat, event.latlng.lng],
  ] as Array<[number, number]>
  if (!draftRubber) {
    draftRubber = L.polyline(line, { color: DRAFT_COLOR, weight: 1.5, dashArray: '3 5', opacity: 0.7 }).addTo(
      mapRef.value as L.Map,
    )
  } else {
    draftRubber.setLatLngs(line)
  }
}

function finishDraw() {
  if (draftPoints.length < 3) return
  const polygon: MapPoint[] = latLngsToPolygon(draftPoints.map((point) => [point.lat, point.lng]))
  const boundary = buildBoundary(polygon)
  cancelDraw()
  emit('draw-complete', boundary)
}

/* ------------------------------ 顶点编辑 ------------------------------ */

function clearEditHandles() {
  editHandles.forEach((handle) => handle.remove())
  editHandles = []
}

function renderEditHandles() {
  clearEditHandles()
  const map = mapRef.value
  if (!map || !props.editable || drawing.value || !props.selectedId) return
  const plot = props.plots.find((item) => item.id === props.selectedId)
  const target = plotLayers.get(props.selectedId)
  if (!plot || !target || plot.polygon.length < 3) return

  polygonToLatLngs(plot.polygon).forEach((position, index) => {
    const marker = L.marker(position, {
      icon: handleIcon('edit'),
      draggable: true,
      keyboard: false,
      zIndexOffset: 800,
    })
    marker.on('drag', () => {
      const rings = target.getLatLngs() as L.LatLng[][]
      const ring = rings[0]
      if (!ring) return
      ring[index] = marker.getLatLng()
      target.setLatLngs([ring])
    })
    marker.on('dragend', () => {
      const rings = target.getLatLngs() as L.LatLng[][]
      const ring = rings[0]
      if (!ring) return
      const polygon = latLngsToPolygon(ring.map((point) => [point.lat, point.lng]))
      emit('edit-complete', buildBoundary(polygon))
    })
    marker.addTo(map)
    editHandles.push(marker)
  })
}

/* ------------------------------ 同步 ------------------------------ */

watch(
  () => props.plots.length,
  (length) => {
    if (autoFitDone || !props.autoFit || length === 0) return
    autoFitDone = true
    fitAll(false)
  },
)

watch(
  () => [props.plots, props.selectedId, props.showLabels],
  () => {
    renderPlots()
    if (props.panToSelected && props.selectedId) fitToPlot(props.selectedId)
  },
  { deep: true },
)

watch(
  () => [props.devices, props.showDevices, props.plots],
  () => renderDevices(),
  { deep: true },
)

watch(
  () => props.editable,
  () => renderEditHandles(),
)

watch(
  () => props.pending,
  () => renderPending(),
  { deep: true },
)

watch(
  () => props.basemap,
  (value) => {
    if (value !== currentBasemap.value) {
      currentBasemap.value = value
      applyBasemap()
    }
  },
)

watch(
  () => props.height,
  () => mapRef.value?.invalidateSize(),
)

defineExpose({ fitAll, fitToPlot, focus, startDraw, cancelDraw, finishDraw, undoDraw, toggleBoxSelect, setBasemap })

const legendItems = [
  { color: '#4fae74', label: '正常地块' },
  { color: '#c9973f', label: '预警地块' },
  { color: '#2f9e5a', label: '在线设备' },
  { color: '#c93e3e', label: '离线设备' },
]
</script>

<template>
  <div
    class="gis-map"
    :class="{
      'gis-map--dark': darkMode,
      'gis-map--satellite': currentBasemap === 'satellite',
      'gis-map--blank': currentBasemap === 'blank',
    }"
    :style="{ height: `${height}px` }"
  >
    <div ref="mapEl" class="gis-map__surface" />

    <div v-if="showToolbar" class="gis-toolbar" :class="`gis-toolbar--${toolbarPosition}`">
      <button class="gis-tool" type="button" title="缩放到全园地块" @click="fitAll(true)">全园</button>
      <button
        v-if="boxSelect"
        class="gis-tool"
        :class="{ 'is-active': boxActive }"
        type="button"
        title="在地图上拖拽框选地块"
        @click="toggleBoxSelect"
      >
        框选
      </button>
      <template v-if="drawable">
        <button v-if="!drawing" class="gis-tool gis-tool--primary" type="button" title="绘制地块边界" @click="startDraw">
          绘制边界
        </button>
        <template v-else>
          <button class="gis-tool" type="button" :disabled="draftCount === 0" @click="undoDraw">撤销</button>
          <button class="gis-tool gis-tool--primary" type="button" :disabled="draftCount < 3" @click="finishDraw">完成</button>
          <button class="gis-tool" type="button" @click="cancelDraw">取消</button>
        </template>
      </template>
      <span class="gis-toolbar__sep" />
      <div class="gis-basemap">
        <button
          type="button"
          :class="{ 'is-active': currentBasemap === 'vector' }"
          @click="setBasemap('vector')"
        >
          矢量
        </button>
        <button
          type="button"
          :class="{ 'is-active': currentBasemap === 'satellite' }"
          @click="setBasemap('satellite')"
        >
          影像
        </button>
        <button
          type="button"
          :class="{ 'is-active': currentBasemap === 'blank' }"
          @click="setBasemap('blank')"
        >
          纯色
        </button>
      </div>
    </div>

    <div v-if="drawing" class="gis-draft-bar">
      <span>点击地图添加顶点，点首个顶点或「完成」闭合边界</span>
      <b>{{ draftCount }} 顶点<template v-if="draftCount >= 3"> · {{ formatAreaSqm(draftArea) }}</template></b>
    </div>

    <div v-if="!hideLegend" class="gis-map__legend">
      <span v-for="item in legendItems" :key="item.label"><i :style="{ background: item.color }" />{{ item.label }}</span>
    </div>

    <div v-if="showCoords" class="gis-map__coords" :class="{ 'is-empty': !coords }">
      {{ coords || '经纬度 WGS84' }}
    </div>

    <div v-if="boxActive && !drawing" class="gis-map__hint">按住鼠标拖拽框选区域 · Esc 退出</div>
  </div>
</template>

<style scoped>
.gis-map {
  position: relative;
  border: 1px solid var(--border-card);
  border-radius: var(--radius-sm);
  background: var(--bg-page);
  overflow: hidden;
  isolation: isolate;
}

.gis-map__surface {
  width: 100%;
  height: 100%;
  background: var(--bg-page);
}

.gis-map--blank .gis-map__surface {
  background-color: var(--bg-page);
  background-image:
    linear-gradient(var(--border-card) 1px, transparent 1px),
    linear-gradient(90deg, var(--border-card) 1px, transparent 1px);
  background-size: 48px 48px;
}

/* 深色底图：对瓦片做反相 + 色相旋转，规避高德无深色瓦片的问题 */
.gis-map--dark :deep(.leaflet-tile-pane) {
  filter: invert(1) hue-rotate(180deg) brightness(0.86) contrast(0.92) saturate(0.75);
}

.gis-map--dark.gis-map--satellite :deep(.leaflet-tile-pane) {
  filter: brightness(0.62) saturate(0.9) contrast(1.05);
}

.gis-map--dark :deep(.leaflet-container) {
  background: #0a0d0b;
}

.gis-map :deep(.leaflet-container) {
  font-family: var(--font);
  background: transparent;
}

.gis-map :deep(.leaflet-control-attribution) {
  border-radius: 6px 0 0 0;
  background: rgba(255, 255, 255, 0.72);
  font-size: 10px;
  color: var(--text-tertiary);
}

.gis-map--dark :deep(.leaflet-control-attribution) {
  background: rgba(8, 16, 11, 0.72);
  color: rgba(217, 245, 228, 0.5);
}

.gis-map--dark :deep(.leaflet-bar a) {
  border-color: rgba(255, 255, 255, 0.1);
  background: rgba(12, 22, 16, 0.86);
  color: #d9f5e4;
}

.gis-map--dark :deep(.leaflet-bar a:hover) {
  background: rgba(30, 50, 38, 0.92);
}

.gis-map :deep(.leaflet-bar) {
  border: 0;
  border-radius: 10px;
  overflow: hidden;
  box-shadow: var(--shadow-card);
}

.gis-map :deep(.leaflet-control-scale-line) {
  border-color: var(--border-strong);
  border-top: 0;
  background: rgba(255, 255, 255, 0.7);
  color: var(--text-secondary);
  font-size: 10px;
}

.gis-map--dark :deep(.leaflet-control-scale-line) {
  background: rgba(8, 16, 11, 0.6);
  color: rgba(217, 245, 228, 0.62);
}

/* 工具条 */
.gis-toolbar {
  position: absolute;
  top: 12px;
  z-index: 950;
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  justify-content: flex-end;
  gap: 4px;
  max-width: calc(100% - 24px);
  padding: 5px;
  border: 1px solid var(--border-card);
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.9);
  box-shadow: var(--shadow-card);
  backdrop-filter: blur(12px);
}

.gis-toolbar--top-left {
  left: 12px;
}

.gis-toolbar--top-right {
  right: 12px;
}

.gis-tool {
  height: 26px;
  padding: 0 9px;
  border: 0;
  border-radius: 8px;
  background: transparent;
  font-family: inherit;
  font-size: 11.5px;
  font-weight: 600;
  color: var(--text-secondary);
  cursor: pointer;
  transition: background 0.16s, color 0.16s;
}

.gis-tool:hover {
  background: var(--bg-subtle-3);
  color: var(--text-primary);
}

.gis-tool.is-active {
  background: var(--primary);
  color: #fff;
}

.gis-tool--primary {
  background: var(--primary-soft);
  color: var(--primary);
}

.gis-tool--primary:hover {
  background: var(--primary);
  color: #fff;
}

.gis-tool:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

@media (max-width: 560px) {
  .gis-toolbar {
    gap: 2px;
    padding: 4px;
  }

  .gis-tool {
    padding: 0 7px;
    font-size: 11px;
  }

  .gis-basemap button {
    padding: 0 6px;
  }
}

.gis-toolbar__sep {
  width: 1px;
  height: 16px;
  margin: 0 3px;
  background: var(--border-strong);
}

.gis-basemap {
  display: flex;
  gap: 2px;
  padding: 2px;
  border-radius: 8px;
  background: var(--bg-subtle-2);
}

.gis-basemap button {
  height: 22px;
  padding: 0 8px;
  border: 0;
  border-radius: 6px;
  background: transparent;
  font-family: inherit;
  font-size: 11px;
  color: var(--text-secondary);
  cursor: pointer;
}

.gis-basemap button.is-active {
  background: var(--bg-card-solid);
  color: var(--text-primary);
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.12);
}

/* 绘制提示 */
.gis-draft-bar {
  position: absolute;
  left: 50%;
  top: 12px;
  z-index: 960;
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 6px 12px;
  border-radius: 999px;
  background: rgba(0, 122, 255, 0.94);
  font-size: 11px;
  color: #fff;
  transform: translateX(-50%);
  box-shadow: var(--shadow-float);
  white-space: nowrap;
}

.gis-draft-bar b {
  font-family: var(--font-num), monospace;
  font-weight: 700;
}

/* 图例与读数 */
.gis-map__legend {
  position: absolute;
  left: 12px;
  bottom: 10px;
  z-index: 900;
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
  padding: 5px 9px;
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.86);
  font-size: 10.5px;
  color: var(--text-secondary);
  backdrop-filter: blur(6px);
}

.gis-map--dark .gis-map__legend {
  background: rgba(6, 18, 12, 0.76);
  color: rgba(200, 247, 221, 0.66);
}

.gis-map__legend span {
  display: flex;
  align-items: center;
  gap: 5px;
}

.gis-map__legend i {
  width: 7px;
  height: 7px;
  border-radius: 50%;
}

.gis-map__coords {
  position: absolute;
  left: 12px;
  bottom: 44px;
  z-index: 900;
  padding: 4px 8px;
  border-radius: 7px;
  background: rgba(255, 255, 255, 0.86);
  font-family: var(--font-num), monospace;
  font-size: 10px;
  color: var(--text-secondary);
  pointer-events: none;
}

.gis-map__coords.is-empty {
  opacity: 0.6;
}

.gis-map--dark .gis-map__coords {
  background: rgba(6, 18, 12, 0.76);
  color: rgba(200, 247, 221, 0.7);
}

.gis-map__hint {
  position: absolute;
  right: 12px;
  top: 56px;
  z-index: 940;
  padding: 4px 8px;
  border-radius: 6px;
  background: rgba(255, 255, 255, 0.9);
  font-size: 10px;
  color: var(--text-tertiary);
}

.gis-map__surface.gis-map__surface--box,
.gis-map__surface.gis-map__surface--draw {
  cursor: crosshair;
}

.gis-map__surface.gis-map__surface--box :deep(.leaflet-grab),
.gis-map__surface.gis-map__surface--draw :deep(.leaflet-grab) {
  cursor: crosshair;
}
</style>
