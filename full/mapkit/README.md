# Linux `MapKit` starting point

This lane is a **seed-based promotion**. The canonical fan-out branch
`cursor/port-canonical-mapkit-to-linux-ebb9` on
`github.com/Vercantez/openuikit-linux-platform` (legacy PR #72) was **unavailable**
to this GitHub App token (installation is scoped to `Vercantez/openuikit`).
The 4191-line platform tree was not byte-copied. The monorepo
`full/mapkit/reference/` dossier is kept (it is the only `reference/` present).

## What is real on the isolated Linux host

- `MKMapPoint` / `MKMapSize` / `MKMapRect` geometry, world/null constants,
  contains/intersection/union/inset/offset, 180th-meridian remainder, and the
  C string/equality helpers.
- Linux Mercator meter conversion (`MKMetersPerMapPointAtLatitude` and friends).
  This is not an Apple-oracle geodesic.
- Option sets (`MKDirectionsTransportType`, `MKAddressFilter.Options`,
  local-search result types, `MKMapFeatureOptions`) and public enumerations
  whose raw values follow the pinned macios/header order.
- In-process `MKAddressFilter` and `MKPointOfInterestFilter`.
- `MKDistanceFormatter` for strings this lane itself produces.
- `MKError` codes 1…6 and the C-identifier domain string `MKErrorDomain`.

## Fail-closed / deferred

- No Apple Maps tiles, directions, geocoder, local search network, Look Around,
  or snapshotter success.
- No `CLLocationCoordinate2D` / `UIView` / `CGPoint` stand-ins. APIs that
  require those dependency-owned types stay `deferred`.
- `MKPointOfInterestCategory` string payloads use the exported C identifier;
  Apple NSString bytes are unobserved (`declared`).
- `MKMapView` and other UIKit map UI stay deferred.

The acceptance host builds `libMapKit.dylib` with Foundation only.
