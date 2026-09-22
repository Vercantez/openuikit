// Fail-closed stand-in for the `Stripe` umbrella of stripe-ios-spm 23.32.0
// (653fc8cf). The real module re-exports StripeCore, StripePayments,
// StripeApplePay and friends; ios-oss imports `Stripe` in
// PostCampaignCheckoutViewModel, PPOContainerViewController,
// PostCampaignCheckoutViewController and PledgeViewController and reaches
// the STP* surface (and the `StripeApplePay.` / `StripePayments.`
// qualifiers) through it. See those modules for the (non-)behaviour.
@_exported import StripeApplePay
@_exported import StripePayments
