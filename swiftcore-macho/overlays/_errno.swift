// Apple's _errno overlay is a Darwin-ABI shell: Foundation binds
// $s6Darwin5errnos5Int32Vvg against libswift_errno. Compile with
// -module-name _errno -module-link-name swift_errno
// -Xfrontend -module-abi-name -Xfrontend Darwin.
@_exported import _DarwinFoundation1._errno
import Swift

public var errno: Int32 {
  get { __error().pointee }
  set { __error().pointee = newValue }
}
