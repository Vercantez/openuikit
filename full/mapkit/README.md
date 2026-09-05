# Linux `MapKit`

This lane is a **seed-based promotion** of Apple's public `MapKit` surface
(1153 exact IDs from Xcode 26.1 / iPhoneOS 26.1). Geometry, annotations,
overlays, and `MKMapView` stores are real in-process values. Apple Maps
tiles, directions, local search, Look Around, and snapshotter **success**
fail closed with `MKError`.

Before: **411 implemented / 73 declared / 669 deferred**.
After: **1111 implemented / 38 declared / 4 deferred**.

## What is real on the isolated Linux host

- Web Mercator `MKMapPoint` / `MKMapRect` / `MKMapSize` with world size
  `268435456` (Darwin macOS 26.1 MapKit).
- `MKMapPoint(0°, 0°) = (134217728, 134217728)`; NYC
  `(40.7128, -74.006)` → `(79034854.79, 100926577.03)`.
- `MKMetersPerMapPointAtLatitude` from Darwin samples
  `0.14828977333772544` (lat 0) and `0.07470109070817468` (lat 60).
- `MKCoordinateRegion` from meters uses WGS-84 prime-vertical / meridional
  radii: `(0°,0°)` / 1000 m / 2000 m → span
  `(0.009043695025814083, 0.017966310975031877)`.
- `MKGeodesicPolyline` densify: 1° equator → 113 points, 90° → 10020
  (`ceil(metres / 1000) + 1` on sphere `R = 6378137`).
- `MKRoadWidthAtZoomScale`: `z >= 0.75` → `21/z`; `z == 0` → `inf`.
- `MKMapView` as a `UIView` subclass: region/center/camera stores (span
  clamped; Darwin throws on invalid 500×500 span — Linux clamps),
  annotations with reuse, overlays with polyline/polygon/circle
  renderers drawing into `CGContext`,
  `convert(_:toPointTo:)` / `convert(_:toCoordinateFrom:)` via visible
  `MKMapRect` ↔ bounds.
- `MKPlacemark` / `MKMapItem` value semantics; `openInMaps` returns false.
- `MKDistanceFormatter` metric/imperial strings this lane produces.
- `MKPointOfInterestCategory` raw strings `MKPOICategory…` (Darwin macOS 26.1).
- `MKMapCameraZoomDefault = -1`; `MKLocalPointsOfInterestRequest.maxRadius = 2000`.
- `MKError` codes 1…6, domain `MKErrorDomain`.

## Fail-closed / declared

- `MKMapSnapshotter.start`, `MKDirections.calculate`, `MKLocalSearch.start`,
  `MKLookAroundSceneRequest`, `MKGeocodingRequest` complete with `MKError`
  (`.serverFailure` / `.directionsNotFound` / `.placemarkNotFound`).
- Completer: nonempty `queryFragment` → `completer(_:didFailWithError:)`.
- Map tiles: blank `MKMapView` background; `MKTileOverlay.loadTile(at:)`
  is **declared** (async, no tile bytes).
- Unused `MKMapViewDelegate` / Look Around delegate defaults are **declared**.
- Async `openInMaps(from:)` / snapshot `start(with:)` are **declared**.

## Deferred (4)

- GeoToolbox `PlaceDescriptor` (3 IDs).
- `MKPlacemark.init(coordinate:postalAddress:)` (`CNPostalAddress`).

The acceptance host builds `libMapKit.dylib` with Foundation only.
CoreLocation / CoreGraphics / UIKit types are lookalikes in
`MKLookalikes.swift` when those modules are absent; they are never
published when the owner module is present.
