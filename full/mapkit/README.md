# MapKit Linux starting point

This directory is an isolated clean-room implementation of Apple's public
`MapKit` module for OpenUIKit on Linux. It produces a real `MapKit` Swift
module and a loadable `libMapKit.dylib`. It is not an Apple behavioral
oracle and it is not a claim of integrated ARM64 package success.

## What is real

- Exact `MKMapPoint` / `MKMapSize` / `MKMapRect` / `MKCoordinateSpan` storage
  and checked finite rectangle algebra, including empty/null/world rectangles,
  negative dimensions, intersection/union/inset/offset, containment, and
  180th-meridian remainder.
- Web Mercator projection helpers used for coordinate round trips and
  meter-per-map-point scaling. The world size is the published 2^28 map-point
  square; live SDK constant equality remains an oracle question.
- Graph-evidenced option sets, enums, POI categories, error codes, and launch
  option constant names.
- In-memory annotation, overlay, map item, address, filter, request, and
  configuration objects.
- Compile-time UIKit / CoreLocation / CoreGraphics signatures behind
  `canImport`, using the real dependency types. No `MapKit.UIView`,
  `MapKit.CLLocation`, or `MapKit.CGRect` stand-ins.

## Fail-closed

Local search, directions, ETA, geocoding, reverse geocoding, snapshots, Look
Around, tile downloads, GeoJSON decode, and `openInMaps` never fabricate
Apple network or service success. Completions are dispatched off-queue,
exactly once, and request-instance scoped. Cancellation still delivers one
fail-closed result.

User location is never invented (`MKUserLocation.isUpdating == false`).
`#Preview` support is out of scope.

## Still deferred

- Isolated-host `UIView` / `UIViewController` MapKit UI types, because UIKit
  is not staged here. Those declarations exist for the later guest package
  and are coverage-`deferred` until that package compiles them.
- `CLLocationCoordinate2D` / `CLPlacemark` / `CLLocation` members for the
  same reason.
- NSCoding round trips, Apple road-width-at-zoom, exact POI NSString payloads,
  and Apple locale distance-formatter copy.

Isolated-host coverage for the 1,153 exact public IDs is `implemented` / `declared` /
`deferred` as recorded in `coverage.tsv`. UIKit ancestry and CoreLocation-bearing
members are gated behind `canImport` and coverage-deferred on this host rather than
replaced with MapKit stand-ins. Exact Apple geometry constants, POI string payloads,
callback queues, and locale formatter copy remain oracle questions.

Central ARM64 package verification still owns integrated Linux success.
