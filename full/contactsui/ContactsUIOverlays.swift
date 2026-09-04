import Foundation

// Overlay members that require Contacts and UIKit (`UIApplicationShortcutIcon.init(contact:)`,
// `CNMutableContact.id`) stay behind `canImport` in a future guest build. This
// isolated compile does not declare module-local stand-ins for those types.
