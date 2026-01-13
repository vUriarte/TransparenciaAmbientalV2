import SwiftUI
import MapKit
#if DEBUG
import os
private let modeLog = OSLog(subsystem: "br.uriarte.transparencia", category: "mode")
#endif


struct ClusteredMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var annotations: [FireAnnotation]
    var heatmapPoints: [HeatmapPoint]

    // Configurações injetáveis
    var mapConfig: MapConfig
    var heatmapConfig: HeatmapConfig
    var displayPolicy: MapDisplayModePolicy

    init(
        region: Binding<MKCoordinateRegion>,
        annotations: [FireAnnotation],
        heatmapPoints: [HeatmapPoint],
        mapConfig: MapConfig = MapConfig(),
        heatmapConfig: HeatmapConfig = HeatmapConfig(),
        displayPolicy: MapDisplayModePolicy = MapDisplayModePolicy()
    ) {
        self._region = region
        self.annotations = annotations
        self.heatmapPoints = heatmapPoints
        self.mapConfig = mapConfig
        self.heatmapConfig = heatmapConfig
        self.displayPolicy = displayPolicy
    }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView(frame: .zero)
        map.delegate = context.coordinator

        // Configuração do mapa
        map.mapType = mapConfig.mapType
        map.isRotateEnabled = true
        map.showsCompass = mapConfig.showsCompass
        map.pointOfInterestFilter = mapConfig.pointOfInterestFilter
        context.coordinator.annotationManager.registerViews(on: map)

        map.setRegion(region, animated: false)
        map.cameraZoomRange = MKMapView.CameraZoomRange(maxCenterCoordinateDistance: mapConfig.cameraMaxCenterCoordinateDistance)

        // Inicializa overlay de heatmap e modo
        context.coordinator.heatmapManager.ensureOverlay(on: map, with: heatmapPoints)
        context.coordinator.updateMode(on: map, region: region, annotations: annotations, heatmapPoints: heatmapPoints)

        return map
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        if !uiView.region.isApproximatelyEqual(to: region, epsilon: mapConfig.regionApproxEpsilon) {
            context.coordinator.isProgrammaticRegionChange = true
            uiView.setRegion(region, animated: true)
        }

        context.coordinator.heatmapManager.updatePoints(on: uiView, points: heatmapPoints)

        // Alterna entre heatmap e pins se necessário
        context.coordinator.updateMode(on: uiView, region: region, annotations: annotations, heatmapPoints: heatmapPoints)

        // Se estamos no modo pins, sincroniza anotações incrementalmente
        if context.coordinator.mode == .pins {
            context.coordinator.annotationManager.sync(on: uiView, with: annotations)
        } else {
            // No modo heatmap, remova anotações de FireAnnotation (reduz peso)
            context.coordinator.annotationManager.removeFireAnnotations(from: uiView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: ClusteredMapView
        var isProgrammaticRegionChange = false

        fileprivate var mode: MapDisplayMode = .heatmap
        let heatmapManager: HeatmapOverlayManager
        let annotationManager: AnnotationSyncManager
        let calloutFactory: CalloutViewFactory

        init(parent: ClusteredMapView) {
            self.parent = parent
            self.heatmapManager = HeatmapOverlayManager(config: parent.heatmapConfig)
            self.annotationManager = AnnotationSyncManager()
            self.calloutFactory = CalloutViewFactory()
        }

        // MARK: - Modo (Heatmap vs Pins)

        func updateMode(on mapView: MKMapView, region: MKCoordinateRegion, annotations: [FireAnnotation], heatmapPoints: [HeatmapPoint]) {
            let desired = parent.displayPolicy.mode(for: region, threshold: parent.mapConfig.heatmapLatitudeDeltaThreshold)

#if DEBUG
let sp = OSSignpostID(log: modeLog)
os_signpost(.begin, log: modeLog, name: "map.updateMode", signpostID: sp, "from=%{public}@ to=%{public}@", String(describing: mode), String(describing: desired))
let t0 = CFAbsoluteTimeGetCurrent()
#endif

            switch (mode, desired) {
            case (.heatmap, .heatmap):
                heatmapManager.ensureOverlay(on: mapView, with: heatmapPoints)

            case (.heatmap, .pins):
                mode = .pins
                heatmapManager.removeOverlay(from: mapView)
                annotationManager.sync(on: mapView, with: annotations)

            case (.pins, .pins):
                break

            case (.pins, .heatmap):
                mode = .heatmap
                annotationManager.removeFireAnnotations(from: mapView)
                heatmapManager.ensureOverlay(on: mapView, with: heatmapPoints)
                if let ov = heatmapManager.overlay, let renderer = mapView.renderer(for: ov) {
                    renderer.setNeedsDisplay(mapView.visibleMapRect)
                }
            }
            #if DEBUG
            let elapsed = CFAbsoluteTimeGetCurrent() - t0
            os_signpost(.end, log: modeLog, name: "map.updateMode", signpostID: sp, "elapsed=%.3fs", elapsed)
            #endif
            
        }

        // MARK: - MKMapViewDelegate

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            if isProgrammaticRegionChange {
                isProgrammaticRegionChange = false
                return
            }
            let newRegion = mapView.region
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.parent.region = newRegion
            }
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let r = heatmapManager.makeRenderer(for: overlay) {
                return r
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if let cluster = annotation as? MKClusterAnnotation {
                return annotationManager.viewForCluster(cluster, on: mapView)
            }
            guard let fire = annotation as? FireAnnotation else {
                return nil
            }
            return annotationManager.viewForFire(fire, on: mapView, calloutFactory: calloutFactory)
        }
    }
}
