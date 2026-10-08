import SwiftUI
import UniformTypeIdentifiers

struct ContentUpdatesView: View {
    @EnvironmentObject private var model: AppModel
    @State private var address=""
    @State private var importing=false
    @State private var operation: Task<Void,Never>?
    @State private var busy=false
    @State private var error: String?
    @State private var rollback=false
    var body: some View {
        Form {
            Section {
                Label("Your lesson library",systemImage:"books.vertical").font(.headline)
                Text("Add a newer lesson library from a JSON file or a trusted update feed. Once installed, lessons stay available offline.").font(.subheadline)
                LabeledContent("Installed",value:"Version \(model.pack?.contentVersion ?? 0)")
                    .accessibilityElement(children:.ignore).accessibilityLabel("Installed lesson library").accessibilityValue("Version \(model.pack?.contentVersion ?? 0)").accessibilityIdentifier("lesson-installed-version")
                if let version=model.stagedVersion {
                    Label("Version \(version) waiting",systemImage:"checkmark.circle.fill").foregroundStyle(Palette.green).accessibilityIdentifier("lesson-update-staged")
                    Text("Quit Foxlingo from the app switcher, then reopen it to activate this version. Your current lesson stays as it is.").font(.caption)
                    Button("Remove waiting update") {perform {try model.cancelLessonUpdate()}}.disabled(busy)
                }
                if let message=model.updateMessage {Text(message).font(.subheadline).accessibilityIdentifier("lesson-update-message")}
                if let error {Text(error).foregroundStyle(Palette.red).accessibilityIdentifier("lesson-update-error")}
            }
            Section("From a file") {
                Button("Import lesson JSON",systemImage:"doc.badge.plus") {importing=true}.disabled(busy).accessibilityIdentifier("lesson-import")
            }
            Section("From an update feed") {
                TextField("HTTPS manifest address",text:$address).textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL).accessibilityIdentifier("lesson-feed-address")
                if busy {HStack {ProgressView();Text("Preparing lessons…");Spacer();Button("Cancel") {operation?.cancel()}}}
                else {Button("Check for lessons",systemImage:"arrow.down.circle") {
                    error=nil;busy=true
                    operation=Task {@MainActor in
                        defer {busy=false;operation=nil}
                        do {try await model.checkForLessons(address)}
                        catch is CancellationError {error="Update check cancelled. Installed lessons are still available."}
                        catch {self.error=error.localizedDescription}
                    }
                }.disabled(address.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty).accessibilityIdentifier("lesson-check")}
                Text("Use a feed from someone you trust. Compatibility checks protect the app and learning history; supporting sources still need editorial review.").font(.caption)
            }
            if let previous=model.rollbackVersion,previous != model.pack?.contentVersion {
                Section("Previous library") {
                    Button("Restore version \(previous)") {rollback=true}.disabled(busy).accessibilityIdentifier("lesson-rollback")
                    Text("Restores lessons on the next launch. Earned cards and practice history remain yours.").font(.caption)
                }
            }
        }.navigationTitle("Lesson updates")
        .onAppear {address=model.updateAddress}
        .onDisappear {operation?.cancel()}
        .confirmationDialog("Restore the previous lesson library?",isPresented:$rollback,titleVisibility:.visible) {Button("Restore on next launch") {perform {try model.rollbackLessons()}}}
        .fileImporter(isPresented:$importing,allowedContentTypes:[.json]) {result in
            error=nil;busy=true
            operation=Task {@MainActor in
                defer {busy=false;operation=nil}
                do {
                    let file=try result.get()
                    let work=Task.detached {try ContentImport.read(file)}
                    let data=try await withTaskCancellationHandler(operation:{try await work.value},onCancel:{work.cancel()})
                    try Task.checkCancellation();try await model.importLessons(data)
                } catch is CancellationError {error="Import cancelled. Installed lessons are still available."}
                catch {self.error=error.localizedDescription}
            }
        }
    }
    private func perform(_ work: () throws -> Void) {error=nil;do {try work()} catch {self.error=error.localizedDescription}}
}
