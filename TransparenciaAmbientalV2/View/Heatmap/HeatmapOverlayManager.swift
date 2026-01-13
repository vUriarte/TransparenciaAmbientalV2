import Foundation
import MapKit
#if DEBUG
import os
private let overlayLog = OSLog(subsystem: "br.uriarte.transparencia", category: "overlay")
#endif

final class HeatmapOverlayManager {
    private(set) var overlay: HeatmapOverlay?
    private var renderer: HeatmapRenderer?

    private let config: HeatmapConfig

    init(config: HeatmapConfig) {
        self.config = config
    }

    func ensureOverlay(on mapView: MKMapView, with points: [HeatmapPoint]) {
        #if DEBUG
        let sp = OSSignpostID(log: overlayLog)
        os_signpost(.begin, log: overlayLog, name: "overlay.ensure", signpostID: sp, "points=%d", points.count)
        let t0 = CFAbsoluteTimeGetCurrent()
        #endif
        if overlay == nil {
            let ov = HeatmapOverlay(points: points)
            overlay = ov
            mapView.addOverlay(ov, level: .aboveRoads)
        } else if let ov = overlay, !mapView.overlays.contains(where: { $0 === ov }) {
            mapView.addOverlay(ov, level: .aboveRoads)
        }
        
        
        #if DEBUG
        let elapsed = CFAbsoluteTimeGetCurrent() - t0
        os_signpost(.end, log: overlayLog, name: "overlay.ensure", signpostID: sp, "elapsed=%.3fs", elapsed)
        #endif
    }

    func updatePoints(on mapView: MKMapView, points: [HeatmapPoint]) {
        #if DEBUG
        let sp = OSSignpostID(log: overlayLog)
        os_signpost(.begin, log: overlayLog, name: "overlay.updatePoints", signpostID: sp, "points=%d", points.count)
        let t0 = CFAbsoluteTimeGetCurrent()
        #endif
        
        if overlay == nil {
            ensureOverlay(on: mapView, with: points)
        }
        overlay?.points = points

        guard let ov = overlay else { return }

        if let r = mapView.renderer(for: ov) as? HeatmapRenderer {
            r.setNeedsDisplay(mapView.visibleMapRect)
        } else {
            if !mapView.overlays.contains(where: { $0 === ov }) {
                mapView.addOverlay(ov, level: .aboveRoads)
            } else {
                mapView.removeOverlay(ov)
                mapView.addOverlay(ov, level: .aboveRoads)
            }
        }
        #if DEBUG
        let elapsed = CFAbsoluteTimeGetCurrent() - t0
        os_signpost(.end, log: overlayLog, name: "overlay.updatePoints", signpostID: sp, "elapsed=%.3fs", elapsed)
        #endif
    }

    func removeOverlay(from mapView: MKMapView) {
        if let ov = overlay, mapView.overlays.contains(where: { $0 === ov }) {
            mapView.removeOverlay(ov)
        }
        renderer = nil
    }

    // Renderer factory para MKMapViewDelegate
    func makeRenderer(for overlay: MKOverlay) -> MKOverlayRenderer? {
        guard overlay is HeatmapOverlay else { return nil }
        let r = HeatmapRenderer(overlay: overlay)
        r.pointRadiusScreenPoints = config.pointRadiusScreenPoints
        r.minAlpha = config.minAlpha
        r.maxAlpha = config.maxAlpha
        self.renderer = r
        return r
    }
}
