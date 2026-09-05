import Foundation

/// Documented Apple Pay `PKPaymentRequest` field checks for this isolated host.
/// Apple's payment sheet asserts these at presentation; Linux has no sheet, so
/// `PKPaymentAuthorizationController.present` records the issues and fails closed.
public enum PassKitPaymentRequestIssue: String, Equatable, Sendable {
    case missingMerchantIdentifier
    case missingSupportedNetworks
    case missingMerchantCapabilities
    case invalidCountryCode
    case invalidCurrencyCode
    case missingPaymentSummaryItems
    case emptyPaymentSummaryItemLabel
    case pendingTotalMustBeZero
    case recurringMissingPaymentDescription
    case recurringMissingIntervalCount
    case recurringMissingManagementURL
    case reloadMissingPaymentDescription
    case reloadMissingManagementURL
    case deferredMissingPaymentDescription
    case deferredMissingDate
    case deferredMissingManagementURL
    case couponCodeWithoutSupport
    case shippingMethodMissingIdentifier
    case shippingMethodMissingLabel
}

public enum PassKitPaymentRequestValidation {
    public static func issues(for request: PKPaymentRequest) -> [PassKitPaymentRequestIssue] {
        var issues: [PassKitPaymentRequestIssue] = []
        if request.merchantIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.missingMerchantIdentifier)
        }
        if request.supportedNetworks.isEmpty {
            issues.append(.missingSupportedNetworks)
        }
        let capabilities = request.merchantCapabilities
        if !capabilities.contains(.threeDSecure) && !capabilities.contains(.emv) {
            issues.append(.missingMerchantCapabilities)
        }
        if !isISO3166Alpha2(request.countryCode) {
            issues.append(.invalidCountryCode)
        }
        if !isISO4217(request.currencyCode) {
            issues.append(.invalidCurrencyCode)
        }
        let items = request.paymentSummaryItems
        if items.isEmpty {
            issues.append(.missingPaymentSummaryItems)
        } else {
            for item in items {
                if item.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    issues.append(.emptyPaymentSummaryItemLabel)
                    break
                }
            }
            if let total = items.last, total.type == .pending,
               total.amount.compare(NSDecimalNumber.zero) != .orderedSame {
                issues.append(.pendingTotalMustBeZero)
            }
        }
        if let recurring = request.recurringPaymentRequest {
            if recurring.paymentDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                issues.append(.recurringMissingPaymentDescription)
            }
            if recurring.regularBilling.intervalCount < 1 {
                issues.append(.recurringMissingIntervalCount)
            }
            if !isAbsoluteHTTPURL(recurring.managementURL) {
                issues.append(.recurringMissingManagementURL)
            }
        }
        if let reload = request.automaticReloadPaymentRequest {
            if reload.paymentDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                issues.append(.reloadMissingPaymentDescription)
            }
            if !isAbsoluteHTTPURL(reload.managementURL) {
                issues.append(.reloadMissingManagementURL)
            }
        }
        if let deferred = request.deferredPaymentRequest {
            if deferred.paymentDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                issues.append(.deferredMissingPaymentDescription)
            }
            if deferred.deferredBilling.deferredDate == Date.distantPast {
                issues.append(.deferredMissingDate)
            }
            if !isAbsoluteHTTPURL(deferred.managementURL) {
                issues.append(.deferredMissingManagementURL)
            }
        }
        if let coupon = request.couponCode, !coupon.isEmpty, !request.supportsCouponCode {
            issues.append(.couponCodeWithoutSupport)
        }
        if let methods = request.shippingMethods {
            for method in methods {
                if (method.identifier ?? "").isEmpty {
                    issues.append(.shippingMethodMissingIdentifier)
                    break
                }
                if method.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    issues.append(.shippingMethodMissingLabel)
                    break
                }
            }
        }
        return issues
    }

    static func isISO3166Alpha2(_ code: String) -> Bool {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count == 2 else { return false }
        return trimmed.unicodeScalars.allSatisfy { CharacterSet.letters.contains($0) }
    }

    static func isISO4217(_ code: String) -> Bool {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count == 3 else { return false }
        return trimmed.unicodeScalars.allSatisfy { CharacterSet.letters.contains($0) }
    }

    static func isAbsoluteHTTPURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        return (scheme == "https" || scheme == "http") && url.host != nil
    }
}
