import SwiftUI

struct ReflectionPromptsCard: View {
    let readingId: String

    @State private var responses: [ReflectionPrompt: String] = [:]
    @State private var savedDates: [ReflectionPrompt: Date] = [:]
    @State private var saveTasks: [ReflectionPrompt: Task<Void, Never>] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Write what the reading stirred up. These notes stay in your private on-device journal.")
                .font(DesignSystem.FontToken.body(14, italic: true))
                .foregroundStyle(DesignSystem.ColorToken.textSecondary)
                .lineSpacing(2)

            ForEach(ReflectionPrompt.allCases) { prompt in
                promptEditor(prompt)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.ColorToken.goldCream.opacity(0.055))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg, style: .continuous)
                .stroke(DesignSystem.ColorToken.goldCream.opacity(0.20), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.cardLg, style: .continuous))
        .onAppear(perform: loadExisting)
        .onDisappear(perform: cancelPendingSaves)
    }

    private func promptEditor(_ prompt: ReflectionPrompt) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(prompt.question.uppercased())
                .font(DesignSystem.FontToken.caps(9))
                .tracking(2.4)
                .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(0.78))

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.cardMd, style: .continuous)
                    .fill(DesignSystem.ColorToken.skyDeep.opacity(0.34))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.cardMd, style: .continuous)
                            .stroke(DesignSystem.ColorToken.goldCream.opacity(0.18), lineWidth: 1)
                    )

                if response(for: prompt).isEmpty {
                    Text(prompt.placeholder)
                        .font(DesignSystem.FontToken.body(15, italic: true))
                        .foregroundStyle(DesignSystem.ColorToken.textTertiary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }

                TextEditor(text: binding(for: prompt))
                    .font(DesignSystem.FontToken.body(15))
                    .foregroundStyle(DesignSystem.ColorToken.textPrimary)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .frame(minHeight: 92)
                    .accessibilityLabel(prompt.question)
            }
            .frame(minHeight: 104)

            Text(statusLine(for: prompt))
                .font(DesignSystem.FontToken.caps(8))
                .tracking(1.8)
                .foregroundStyle(DesignSystem.ColorToken.goldCream.opacity(response(for: prompt).isEmpty ? 0.42 : 0.64))
        }
    }

    private func binding(for prompt: ReflectionPrompt) -> Binding<String> {
        Binding(
            get: { response(for: prompt) },
            set: { newValue in
                responses[prompt] = newValue
                scheduleSave(prompt: prompt, text: newValue)
            }
        )
    }

    private func response(for prompt: ReflectionPrompt) -> String {
        responses[prompt, default: ""]
    }

    private func loadExisting() {
        let existing = ReadingReflectionStore.load(forReadingId: readingId)
        var loadedResponses: [ReflectionPrompt: String] = [:]
        var loadedDates: [ReflectionPrompt: Date] = [:]

        for reflection in existing {
            guard let prompt = ReflectionPrompt(rawValue: reflection.promptKey) else { continue }
            loadedResponses[prompt] = reflection.response
            loadedDates[prompt] = reflection.updatedAt
        }

        responses = loadedResponses
        savedDates = loadedDates
    }

    private func scheduleSave(prompt: ReflectionPrompt, text: String) {
        saveTasks[prompt]?.cancel()
        saveTasks[prompt] = Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                let saved = ReadingReflectionStore.upsert(readingId: readingId, prompt: prompt, response: text)
                if saved.response.isEmpty {
                    savedDates[prompt] = nil
                    responses[prompt] = ""
                } else {
                    savedDates[prompt] = saved.updatedAt
                    responses[prompt] = saved.response
                }
                saveTasks[prompt] = nil
            }
        }
    }

    private func cancelPendingSaves() {
        for task in saveTasks.values { task.cancel() }
        saveTasks.removeAll()
    }

    private func statusLine(for prompt: ReflectionPrompt) -> String {
        let value = response(for: prompt).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return "PRIVATE PROMPT" }
        guard let date = savedDates[prompt] else { return "SAVING…" }
        return "SAVED · \(relativeTime(from: date))"
    }

    private func relativeTime(from date: Date) -> String {
        let seconds = max(0, Int(Date().timeIntervalSince(date)))
        if seconds < 60 { return "JUST NOW" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)M AGO" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)H AGO" }
        let days = hours / 24
        return "\(days)D AGO"
    }
}

#Preview {
    ZStack {
        DarkScreenBackground()
        ReflectionPromptsCard(readingId: "preview")
            .padding()
    }
}
