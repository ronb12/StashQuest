import SwiftData

extension ModelContext {
    func commitSave() {
        try? save()
        WidgetDataSync.updateFromContext(self)
    }
}
