import RevenueCat

@main
private enum RevenueCatLibraryRuntime {
    static func main() {
        let levels = LogLevel.allCases.map(\.description)
        precondition(levels == ["VERBOSE", "DEBUG", "INFO", "WARN", "ERROR"])
        precondition(Store.allCases.count == 12)
        precondition(Store.appStore.rawValue == 0)
        precondition(Store.galaxy.rawValue == 11)
        precondition(PeriodType.allCases.count == 4)
        precondition(PeriodType.normal.rawValue == 0)
        precondition(PeriodType.prepaid.rawValue == 3)
        print(
            "REVENUECAT_LIBRARY_MACHO_OK "
                + "api=LogLevel,Store,PeriodType log=INFO stores=12 periods=4"
        )
    }
}
