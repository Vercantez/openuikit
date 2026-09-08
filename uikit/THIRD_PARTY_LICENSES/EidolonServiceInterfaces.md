# Service interface authorities

These entries accompany the bounded OpenUIKit adapters, not a claim that the
original service SDKs run in the guest. Complete carried licenses are in
`Sources/EidolonServiceShims/Provenance/`.

| authority | pinned source | license | used material |
|---|---|---|---|
| ARAnalytics 5.0.1 | `https://github.com/orta/ARAnalytics.git` at `888744016bb4f53ad5b652819406645bd21f80c7` | MIT; `Sources/EidolonServiceShims/Provenance/ARAnalytics-LICENSE` | Called declarations, 3 configuration constant values, podspec metadata. |
| Stripe 12.1.0 | `https://github.com/stripe/stripe-ios.git` at `e3c35c97963b938baac22612e4f4aae4b1cab8eb` | MIT; `Sources/EidolonServiceShims/Provenance/Stripe-LICENSE` | Called declarations, card-brand enum ordering, podspec metadata. Podfile requests 14.0.1 while the lock pins this version. |
| CardFlight-v4 4.3.1 | Source named by `Sources/EidolonServiceShims/Provenance/CardFlight-v4.podspec.json`; repository unavailable | Commercial; copyright 2018 Cardflight, Inc., all rights reserved | Podspec metadata only. No SDK, binary, header, or shim implementation copied. |

Keys property names originate in Eidolon's pinned Podfile; values are local
unavailable markers, not generated credentials or an upstream secret file.
