import SwiftData

extension ModelContext {
    /// Persists changes and syncs widget defaults. Returns `false` if save failed (context unchanged aside from failed attempt).
    @discardableResult
    func commitSave() -> Bool {
        do {
            try save()
            WidgetDataSync.updateFromContext(self)
            return true
        } catch {
            return false
        }
    }

    func commitSaveThrowing() throws {
        try save()
        WidgetDataSync.updateFromContext(self)
    }
}
