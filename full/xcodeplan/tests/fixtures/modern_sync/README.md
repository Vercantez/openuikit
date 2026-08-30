This fixture is a minimal Xcode 16-style project. `ModernApp` and `Helper`
share the filesystem-synchronized `App` root and have different membership
exceptions, so shared-scheme selection and target-specific membership are
observable in either direction. Both targets spell `PRODUCT_NAME` explicitly;
negative tests remove it to reproduce Xcode's otherwise empty native product
stem rather than relying on PBX presentation metadata.

The fixture intentionally contains hidden and membership-excluded files. They
must be reported as ignored, never as sources or resources.
