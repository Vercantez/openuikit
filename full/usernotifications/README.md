# Portable UserNotifications

This module preserves Apple's `UserNotifications` source identity for Linux
Mach-O guests without claiming that a host notification daemon exists.

The default center fails authorization and scheduling closed with
`UNError.notificationsNotAllowed`. A host embedding the platform can opt into
the `OpenUIKitHost` SPI and provide an authorized, volatile notification
session. That session supports request replacement, immutable content
snapshots, pending and delivered queues, category registration, validated
badge state, and async delegate presentation/response delivery. It never
claims durable scheduling, operating-system UI, push transport, or delivery
after process exit.

`tests/UserNotificationsNativeOracle.swift` is typechecked first against the
installed Apple SDK and then against this module. The separate Swift 6
IceCubes-shaped consumer probe preserves the app's exact retroactive
`Sendable`, delegate, authorization, and presentation signatures. The host
runtime gate proves both the unavailable default and the explicit volatile
host boundary.
