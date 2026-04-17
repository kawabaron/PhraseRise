import Foundation
import SwiftData

@MainActor
final class SourceCaptureDraftRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetch(id: UUID) -> SourceCaptureDraft? {
        let descriptor = FetchDescriptor<SourceCaptureDraft>(predicate: #Predicate<SourceCaptureDraft> { draft in
            draft.id == id
        })
        return (try? context.fetch(descriptor))?.first
    }

    @discardableResult
    func create(tempFileURL: URL, durationSec: Double) -> SourceCaptureDraft {
        let draft = SourceCaptureDraft(tempFileURL: tempFileURL, durationSec: durationSec)
        context.insert(draft)
        save()
        return draft
    }

    func save(_ draft: SourceCaptureDraft) {
        draft.durationSec = max(0, draft.durationSec)
        save()
    }

    func delete(_ draft: SourceCaptureDraft) {
        context.delete(draft)
        save()
    }

    private func save() {
        try? context.save()
    }
}
