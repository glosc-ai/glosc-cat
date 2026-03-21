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
    @Published var statusMessage = "先选一个方向吧，我会把核心操作放在你手边。"

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

        statusMessage = "我在认真听它说话。"

        Task {
            do {
                try await recorder.start()
            } catch {
                errorMessage = error.localizedDescription
                statusMessage = "这次没能开始录音。"
            }
        }
    }

    func stopRecordingAndAnalyze(modelContext: ModelContext) {
        do {
            let snapshot = try recorder.stop()
            handleSnapshot(snapshot, modelContext: modelContext)
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = "录音结束时出了点小问题。"
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
                errorMessage = "这段音频暂时没能顺利分析，你可以换一段更清晰的猫叫试试。"
                statusMessage = "导入音频时遇到了一点问题。"
            }
        case .failure:
            errorMessage = "没有选中音频文件，这次就先不分析啦。"
        }
    }

    func handleSnapshot(_ snapshot: CatAudioSnapshot, modelContext: ModelContext) {
        errorMessage = nil
        withAnimation(.easeInOut(duration: 0.22)) {
            latestInterpretation = nil
            isAnalyzingAudio = true
        }
        statusMessage = "我在整理它这次更像是在表达什么。"

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
                errorMessage = "没有找到这段内置样本，先检查它是不是已经打进 App 资源里了。"
                statusMessage = "内置样本暂时不可用。"
                return
            }

            let snapshot = try CatAudioAnalyzer.analyzeImportedAudio(url: url)
            handleSnapshot(snapshot, modelContext: modelContext)
        } catch {
            errorMessage = "这段内置样本暂时没能顺利分析，你可以先换一段试听。"
            statusMessage = "样本分析失败。"
        }
    }

    func playSample(_ sample: CatAudioSample, restartIfSame: Bool = false) {
        errorMessage = nil

        if samplePlayer.currentSampleID == sample.id, samplePlayer.isPlaying {
            if restartIfSame {
                samplePlayer.stop()
            } else {
                samplePlayer.stop()
                statusMessage = "已经停下这段猫叫啦。"
                return
            }
        }

        do {
            try samplePlayer.play(sample: sample)
            statusMessage = "正在试听“\(sample.title)”样本。"
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = "真实猫叫没能顺利播放。"
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
            statusMessage = humanText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "这次还没有听到清晰的人话。" : "已经帮你写进输入框，可以直接生成猫语了。"
            return
        }

        statusMessage = "开始听你说话了，我会直接写进输入框。"

        Task {
            do {
                try await speechTranscriber.start()
            } catch {
                errorMessage = error.localizedDescription
                statusMessage = "语音转文字这次没能顺利开始。"
            }
        }
    }

    func generatePhrase(modelContext: ModelContext) {
        if speechTranscriber.isTranscribing {
            speechTranscriber.stop()
        }

        let trimmed = humanText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            errorMessage = "先输入一句你想对它说的话，我才能帮你翻成猫语。"
            statusMessage = "还缺一句原话。"
            return
        }

        errorMessage = nil
        let plan = CatPhraseComposer.generate(text: trimmed, tone: selectedTone)
        generatedPhrase = plan
        statusMessage = "已经替你匹配好对应的真实猫叫，现在直接播放。"
        savePhrase(plan, modelContext: modelContext)
        playMatchedSample(for: plan)
    }

    func playMatchedSample(for plan: CatPhrasePlan) {
        guard let sample = CatAudioSample.builtIn.first(where: { $0.id == plan.sampleID }) else {
            errorMessage = "这句猫语还没找到可播放的真实样本。"
            statusMessage = "对应样本暂时不可用。"
            return
        }

        playSample(sample, restartIfSame: true)
        statusMessage = "正在播放“\(plan.sampleTitle)”这段真实猫叫。"
    }

    private func saveInterpretation(_ interpretation: CatInterpretation, modelContext: ModelContext) {
        let record = InteractionRecord(
            modeRaw: AppMode.catToHuman.rawValue,
            title: interpretation.emotion,
            summary: "\(interpretation.need) · \(interpretation.confidenceNote)",
            detail: "\(interpretation.explanation) 建议：\(interpretation.suggestion)",
            accent: interpretation.emotion
        )
        modelContext.insert(record)
    }

    private func savePhrase(_ plan: CatPhrasePlan, modelContext: ModelContext) {
        let record = InteractionRecord(
            modeRaw: AppMode.humanToCat.rawValue,
            title: plan.catText,
            summary: "语气：\(plan.tone.title)",
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
            statusMessage = "已经帮你从收藏里拿出来了。"
            return
        }

        let favorite = FavoritePhrase(
            originalText: plan.originalText,
            toneRaw: plan.tone.rawValue,
            catText: plan.catText
        )
        modelContext.insert(favorite)
        statusMessage = "这句已经收进常用短语了。"
    }
}
