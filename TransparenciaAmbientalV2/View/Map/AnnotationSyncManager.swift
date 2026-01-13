import Foundation
import MapKit

final class AnnotationSyncManager {
    let fireReuseID = "fireMarker"
    let clusterReuseID = "clusterMarker"

    func registerViews(on mapView: MKMapView) {
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: fireReuseID)
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: clusterReuseID)
    }

    func sync(on mapView: MKMapView, with incoming: [FireAnnotation]) {
        let existingSet = Set(mapView.annotations.compactMap { ($0 as? FireAnnotation)?.focusID })
        let incomingSet = Set(incoming.map { $0.focusID })

        let toRemove = mapView.annotations.compactMap { ann -> MKAnnotation? in
            if let fa = ann as? FireAnnotation, !incomingSet.contains(fa.focusID) {
                return fa
            }
            return nil
        }
        if !toRemove.isEmpty {
            mapView.removeAnnotations(toRemove)
        }

        let toAdd = incoming.filter { !existingSet.contains($0.focusID) }
        if !toAdd.isEmpty {
            mapView.addAnnotations(toAdd)
        }
    }

    func removeFireAnnotations(from mapView: MKMapView) {
        let toRemove = mapView.annotations.compactMap { $0 as? FireAnnotation }
        if !toRemove.isEmpty {
            mapView.removeAnnotations(toRemove)
        }
    }

    func viewForCluster(_ cluster: MKClusterAnnotation, on mapView: MKMapView) -> MKAnnotationView {
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: clusterReuseID, for: cluster) as! MKMarkerAnnotationView
        view.markerTintColor = .systemRed
        view.glyphImage = UIImage(systemName: "flame")
        view.displayPriority = .defaultHigh
        view.titleVisibility = .adaptive
        return view
    }

    func viewForFire(_ fire: FireAnnotation, on mapView: MKMapView, calloutFactory: CalloutViewFactory) -> MKAnnotationView {
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: fireReuseID, for: fire) as! MKMarkerAnnotationView
        view.markerTintColor = .systemRed
        view.glyphImage = UIImage(systemName: "flame.fill")
        view.clusteringIdentifier = "fire"
        view.canShowCallout = true
        view.displayPriority = .defaultHigh

        view.detailCalloutAccessoryView = calloutFactory.makeDetailView(for: fire)
        let info = UIButton(type: .detailDisclosure)
        view.rightCalloutAccessoryView = info

        return view
    }
}
