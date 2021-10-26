//
//  ContentView.swift
//  MKMapViewSwfitUI
//
//  Created by Sean Lin on 2021/10/13.
//

import SwiftUI
import MapKit
import Combine

struct CustomMapView: UIViewRepresentable {
    
    var annotations = [MKPointAnnotation]()
    let mapView = MKMapView()
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "id")
            pinAnnotationView.canShowCallout = true
            return pinAnnotationView
        }
    }

    func makeUIView(context: Context) -> MKMapView {
        setupRegionForMap()
        mapView.delegate = context.coordinator
        return mapView
    }
    
    private func setupRegionForMap() {
        let region = MKCoordinateRegion(center: CLLocationCoordinate2DMake(37.7666, -122.427290),
                                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        mapView.setRegion(region, animated: true)
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.annotations.forEach { uiView.removeAnnotation($0) }
        uiView.addAnnotations(annotations)
        uiView.showAnnotations(annotations, animated: true)
    }
    
    typealias UIViewType = MKMapView
    
}

class MapSearchingViewModel:NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var annotations = [MKPointAnnotation]()
    @Published var searchQuery = ""
    
    var cancellabe: AnyCancellable?
    
    override init() {
        super.init()
        cancellabe = $searchQuery.debounce(for: .milliseconds(500), scheduler: RunLoop.main)
                                 .sink(receiveValue: { [weak self] (query) in
                        self?.performSearch(query: query)
                    })
    }
    
    private func performSearch(query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        let region = MKCoordinateRegion(center: CLLocationCoordinate2DMake(37.7666, -122.427290),
                                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        request.region = region
        let localSearch = MKLocalSearch(request: request)
        localSearch.start { resp, err in
            if let error = err {
                print("Local search with error: ", error)
                return
            }
            let annotationsResult: [MKPointAnnotation]? = resp?.mapItems.map {
                let annotation = MKPointAnnotation()
                annotation.title = $0.name
                annotation.coordinate = $0.placemark.coordinate
                return annotation
            }
            self.annotations = annotationsResult ?? []
        }
    }
}

struct MapSearchingView: View {
    @ObservedObject var viewModel = MapSearchingViewModel()
    
    var body: some View {
        ZStack(alignment: .top) {
            CustomMapView(annotations: viewModel.annotations)
                .edgesIgnoringSafeArea(.all)
            HStack {
                TextField("Search text...", text: $viewModel.searchQuery)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
            }.padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MapSearchingView()
    }
}
