/// Linux starting implementation of Apple's public `JavaScriptCore` module.
///
/// The C `JS*` overlay, `JSContext`/`JSValue` object model, and a host-local
/// interpreter live in this module. Isolated `test_host.sh` success is not
/// Apple JSC parity and is not an integrated guest-package claim.
public enum JavaScriptCoreModuleInfo {
    public static let linuxInterpreter = true
}
