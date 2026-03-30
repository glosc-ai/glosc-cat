import Combine
import Foundation
import SwiftData
import SwiftUI

@MainActor
final class ContentViewModel: ObservableObject {
    let recorder = CatAudioRecorder()
    let samplePlayer = CatSamplePlayer()
    let speechTranscriber = HumanSpeechTranscriber()

    @Published var selectedMode: AppMode = .catToHuman
    @Published var latestInterpretation: CatInterpretation?
    @Published var generatedPhrase: CatPhrasePlan?
    @Published var humanText = ""
    @Published var selectedTone: CatTone = .soothe
    @Published var isImportingAudio = false
    @Published var isAnalyzingAudio = false
    @Published var errorMessage: String?
    @Published var statusMessage = L10n.tr("status.idle")

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Forward changes from nested observable objects to self
        recorder.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
        
        samplePlayer.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
            
        speechTranscriber.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    func toggleRecording(modelContext: ModelContext) {
        errorMessage = nil

        if recorder.isRecording {
            stopRecordingAndAnalyze(modelContext: modelContext)
            return
        }

        statusMessage = L10n.tr("status.recording.listening")

        Task {
            do {
                try await recorder.start()
            } catch {
                errorMessage = error.localizedDescription
                statusMessage = L10n.tr("status.recording.start_failed")
            }
        }
    }

    func stopRecordingAndAnalyze(modelContext: ModelContext) {
        do {
            let snapshot = try recorder.stop()
            handleSnapshot(snapshot, modelContext: modelContext)
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = L10n.tr("status.recording.stop_failed")
        }
    }

    func analyzeDemoClip(modelContext: ModelContext) {
        analyzeBundledSample(CatAudioSample.builtIn[0], modelContext: modelContext)
    }

    func handleImportedAudio(_ result: Result<[URL], Error>, modelContext: ModelContext) {
        errorMessage = nil

        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            do {
                let granted = url.startAccessingSecurityScopedResource()
                defer {
                    if granted {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                let snapshot = try CatAudioAnalyzer.analyzeImportedAudio(url: url)
                handleSnapshot(snapshot, modelContext: modelContext)
            } catch {
                errorMessage = L10n.tr("error.import.analysis_failed")
                statusMessage = L10n.tr("status.import.failed")
            }
        case .failure:
            errorMessage = L10n.tr("error.import.no_file_selected")
        }
    }

    func handleSnapshot(_ snapshot: CatAudioSnapshot, modelContext: ModelContext) {
        errorMessage = nil
        withAnimation(.easeInOut(duration: 0.22)) {
            latestInterpretation = nil
            isAnalyzingAudio = true
        }
        statusMessage = L10n.tr("status.analysis.running")

        let interpretation = CatAudioAnalyzer.interpret(snapshot)
        saveInterpretation(interpretation, modelContext: modelContext)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.84)) {
                self.latestInterpretation = interpretation
                self.isAnalyzingAudio = false
            }
            self.statusMessage = interpretation.confidenceNote
        }
    }

    func analyzeBundledSample(_ sample: CatAudioSample, modelContext: ModelContext) {
        errorMessage = nil
        do {
            guard let url = sample.bundleURL else {
                errorMessage = L10n.tr("error.sample.missing_in_bundle")
                statusMessage = L10n.tr("status.sample.unavailable")
                return
            }

            let snapshot = try CatAudioAnalyzer.analyzeImportedAudio(url: url)
            handleSnapshot(snapshot, modelContext: modelContext)
        } catch {
            errorMessage = L10n.tr("error.sample.analysis_failed")
            statusMessage = L10n.tr("status.sample.analysis_failed")
        }
    }

    func playSample(_ sample: CatAudioSample, restartIfSame: Bool = false) {
        errorMessage = nil

        if samplePlayer.currentSampleID == sample.id, samplePlayer.isPlaying {
            if restartIfSame {
                samplePlayer.stop()
            } else {
                samplePlayer.stop()
                statusMessage = L10n.tr("status.sample.stopped")
                return
            }
        }

        do {
            try samplePlayer.play(sample: sample)
            statusMessage = L10n.format("status.sample.previewing", sample.title)
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = L10n.tr("status.sample.playback_failed")
        }
    }

    func playTonePreview(for tone: CatTone) {
        let sample = CatAudioSample.demoSample(for: tone)
        playSample(sample)
    }

    func toggleSpeechTranscription() {
        errorMessage = nil

        if speechTranscriber.isTranscribing {
            speechTranscriber.stop()
            statusMessage = humanText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? L10n.tr("status.transcription.empty") : L10n.tr("status.transcription.completed")
            return
        }

        statusMessage = L10n.tr("status.transcription.listening")

        Task {
            do {
                try await speechTranscriber.start()
            } catch {
                errorMessage = error.localizedDescription
                statusMessage = L10n.tr("status.transcription.start_failed")
            }
        }
    }

    func generatePhrase(modelContext: ModelContext) {
        if speechTranscriber.isTranscribing {
            speechTranscriber.stop()
        }

        let trimmed = humanText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            errorMessage = L10n.tr("error.phrase.empty_input")
            statusMessage = L10n.tr("status.phrase.missing_input")
            return
        }

        errorMessage = nil
        let plan = CatPhraseComposer.generate(text: trimmed, tone: selectedTone)
        generatedPhrase = plan
        statusMessage = L10n.tr("status.phrase.generated")
        savePhrase(plan, modelContext: modelContext)
        playMatchedSample(for: plan)
    }

    func playMatchedSample(for plan: CatPhrasePlan) {
        guard let sample = CatAudioSample.builtIn.first(where: { $0.id == plan.sampleID }) else {
            errorMessage = L10n.tr("error.phrase.sample_missing")
            statusMessage = L10n.tr("status.phrase.sample_unavailable")
            return
        }

        playSample(sample, restartIfSame: true)
        statusMessage = L10n.format("status.phrase.playing_sample", plan.sampleTitle)
    }

    private func saveInterpretation(_ interpretation: CatInterpretation, modelContext: ModelContext) {
        let record = InteractionRecord(
            modeRaw: AppMode.catToHuman.rawValue,
            title: interpretation.emotion,
            summary: "\(interpretation.need) · \(interpretation.confidenceNote)",
            detail: L10n.format("record.interpretation.detail", interpretation.explanation, interpretation.suggestion),
            accent: interpretation.emotion
        )
        modelContext.insert(record)
    }

    private func savePhrase(_ plan: CatPhrasePlan, modelContext: ModelContext) {
        let record = InteractionRecord(
            modeRaw: AppMode.humanToCat.rawValue,
            title: plan.catText,
            summary: L10n.format("record.phrase.summary", plan.tone.title),
            detail: plan.explanation,
            accent: plan.tone.title
        )
        modelContext.insert(record)
    }

    func isFavorite(_ plan: CatPhrasePlan, favoritePhrases: [FavoritePhrase]) -> Bool {
        favoritePhrases.contains {
            $0.originalText == plan.originalText && $0.toneRaw == plan.tone.rawValue
        }
    }

    func toggleFavorite(for plan: CatPhrasePlan, favoritePhrases: [FavoritePhrase], modelContext: ModelContext) {
        if let existing = favoritePhrases.first(where: {
            $0.originalText == plan.originalText && $0.toneRaw == plan.tone.rawValue
        }) {
            modelContext.delete(existing)
            statusMessage = L10n.tr("status.favorite.removed")
            return
        }

        let favorite = FavoritePhrase(
            originalText: plan.originalText,
            toneRaw: plan.tone.rawValue,
            catText: plan.catText
        )
        modelContext.insert(favorite)
        statusMessage = L10n.tr("status.favorite.added")
    }
}
