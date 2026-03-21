//
//  CatServices.swift
//  glosc-cat
//
//  Created by GitHub Copilot on 2026/3/21.
//

import AVFoundation
import Combine
import Foundation
import Speech

enum CatAudioAnalyzer {
    static func analyzeImportedAudio(url: URL) throws -> CatAudioSnapshot {
        let fileValues = try url.resourceValues(forKeys: [.fileSizeKey, .localizedNameKey])
        let sourceLabel = fileValues.localizedName ?? "导入音频"

        do {
            return try analyzeAudioFile(url: url, sourceLabel: sourceLabel)
        } catch {
            let player = try AVAudioPlayer(contentsOf: url)
            let duration = max(player.duration, 0.4)
            let fileSize = Double(fileValues.fileSize ?? 32_000)
            let bytesPerSecond = fileSize / duration
            let averageIntensity = clamp(sqrt(bytesPerSecond / 72_000), lower: 0.08, upper: 0.92)
            let peakIntensity = clamp(averageIntensity + 0.16, lower: 0.18, upper: 1.0)
            let activityScore = clamp((0.75 / duration) + (averageIntensity * 0.55), lower: 0.1, upper: 1.0)

            return CatAudioSnapshot(
                duration: duration,
                averageIntensity: averageIntensity,
                peakIntensity: peakIntensity,
                activityScore: activityScore,
                zeroCrossingRate: clamp(averageIntensity * 0.48, lower: 0.08, upper: 0.46),
                silenceRatio: clamp(0.46 - averageIntensity * 0.32, lower: 0.08, upper: 0.58),
                sourceLabel: sourceLabel
            )
        }
    }

    static func analyzeRecordedAudio(url: URL, fallbackDuration: TimeInterval, meterSamples: [Float], sourceLabel: String) -> CatAudioSnapshot {
        if let snapshot = try? analyzeAudioFile(url: url, sourceLabel: sourceLabel) {
            return snapshot
        }

        return analyzeMeterSamples(duration: fallbackDuration, meterSamples: meterSamples, sourceLabel: sourceLabel)
    }

    static func interpret(_ snapshot: CatAudioSnapshot) -> CatInterpretation {
        let rankedMatches = rankedSemanticMatches(for: snapshot)

        if let bestMatch = rankedMatches.first,
           let sample = CatAudioSample.builtIn.first(where: { $0.id == bestMatch.sampleID }),
           bestMatch.similarity >= 0.58 {
            let similarityText = Int((bestMatch.similarity * 100).rounded())

            return CatInterpretation(
                emotion: sample.semanticEmotion,
                need: sample.semanticNeed,
                explanation: "这段录音和内置真实样本“\(sample.title)”最接近，相似度约 \(similarityText)%。\(bestMatch.comparisonSummary) \(sample.semanticExplanation)",
                suggestion: sample.semanticSuggestion,
                confidenceNote: confidenceNote(for: bestMatch.similarity),
                sourceLabel: snapshot.sourceLabel,
                matchedSample: bestMatch,
                analysisSummary: "这次先把录音和本地真实猫叫样本逐个做了比对，再结合时长、响度、停顿和节奏变化整理成语义解释。"
            )
        }

        return interpretHeuristically(snapshot, bestMatch: rankedMatches.first)
    }

    private static func analyzeMeterSamples(duration: TimeInterval, meterSamples: [Float], sourceLabel: String) -> CatAudioSnapshot {
        let normalized = meterSamples.map(normalizedLevel(from:))
        let averageIntensity = clamp(normalized.average, lower: 0.05, upper: 0.95)
        let peakIntensity = clamp(normalized.max() ?? averageIntensity, lower: 0.1, upper: 1.0)
        let deltas = zip(normalized, normalized.dropFirst()).map { abs($0 - $1) }
        let activityScore = clamp(deltas.average * 4.6, lower: 0.08, upper: 1.0)
        let zeroCrossings = zip(normalized, normalized.dropFirst()).filter {
            ($0 < 0.18 && $1 > 0.18) || ($0 > 0.18 && $1 < 0.18)
        }.count
        let zeroCrossingRate = clamp(Double(zeroCrossings) / Double(max(normalized.count, 1)) * 3.4, lower: 0.04, upper: 0.9)
        let silenceRatio = clamp(Double(normalized.filter { $0 < 0.1 }.count) / Double(max(normalized.count, 1)), lower: 0.04, upper: 0.95)

        return CatAudioSnapshot(
            duration: max(duration, 0.4),
            averageIntensity: averageIntensity,
            peakIntensity: peakIntensity,
            activityScore: activityScore,
            zeroCrossingRate: zeroCrossingRate,
            silenceRatio: silenceRatio,
            sourceLabel: sourceLabel
        )
    }

    private static func interpretHeuristically(_ snapshot: CatAudioSnapshot, bestMatch: CatSemanticMatch?) -> CatInterpretation {
        let duration = snapshot.duration
        let intensity = snapshot.averageIntensity
        let peak = snapshot.peakIntensity
        let activity = snapshot.activityScore
        let analysisSummary: String

        if let bestMatch {
            analysisSummary = "这段录音和“\(bestMatch.sampleTitle)”有一定相似度，但还不够高，所以这次主要按录音本身的时长、响度和节奏做推断。"
        } else {
            analysisSummary = "这次没有找到足够接近的本地样本，结果主要来自录音本身的时长、响度和节奏变化。"
        }

        if duration < 0.9 && peak > 0.72 {
            return CatInterpretation(
                emotion: "有点急切",
                need: "想马上得到回应",
                explanation: "这段叫声偏短，但峰值比较高，像是在快速提醒你留意它，通常会出现在等吃饭、被门挡住，或想立刻获得关注的时候。",
                suggestion: "先看看它是不是在饭盆、门口或你常放玩具的位置附近，再用轻声回应它。",
                confidenceNote: "本地样本相似度一般，这次更像提醒型叫声",
                sourceLabel: snapshot.sourceLabel,
                matchedSample: nil,
                analysisSummary: analysisSummary
            )
        }

        if duration > 2.5 && intensity < 0.2 {
            return CatInterpretation(
                emotion: "想撒娇",
                need: "想靠近你或要一点陪伴",
                explanation: "这段声音拖得更长、整体力度也比较轻，比较像放松状态下的黏人表达，不太像紧张或抗拒。",
                suggestion: "可以蹲下来跟它说话，或者轻轻摸摸下巴，看看它会不会继续靠近。",
                confidenceNote: "本地样本相似度一般，这次更像亲近型叫声",
                sourceLabel: snapshot.sourceLabel,
                matchedSample: nil,
                analysisSummary: analysisSummary
            )
        }

        if activity > 0.62 && peak > 0.58 {
            return CatInterpretation(
                emotion: "有点不安",
                need: "想确认环境是不是安全",
                explanation: "声音变化比较快，起伏也明显，说明它当下对周围环境更敏感，可能是在确认声音来源、陌生人，或者新出现的气味。",
                suggestion: "先帮它把环境安静下来，再观察耳朵和尾巴姿态，避免一下子离它太近。",
                confidenceNote: "本地样本相似度一般，这次更像环境刺激触发",
                sourceLabel: snapshot.sourceLabel,
                matchedSample: nil,
                analysisSummary: analysisSummary
            )
        }

        if intensity > 0.42 && duration > 1.1 {
            return CatInterpretation(
                emotion: "想互动",
                need: "希望你看看它或陪它玩一会儿",
                explanation: "这段叫声时长和响度都比较均衡，像是在稳定地向你发起互动，不像单纯抱怨，也不像特别紧张。",
                suggestion: "可以先看它是不是把你往玩具、窗边或者常待的位置带，再顺着它的节奏回应。",
                confidenceNote: "本地样本相似度一般，这次更像邀请型叫声",
                sourceLabel: snapshot.sourceLabel,
                matchedSample: nil,
                analysisSummary: analysisSummary
            )
        }

        return CatInterpretation(
            emotion: "在轻声试探",
            need: "想确认你有没有在听它",
            explanation: "整体音量不高，节奏也不算急，通常更像一段日常的小提醒，可能只是想让你看它一眼，或者确认你会不会回应。",
            suggestion: "先叫叫它的名字，慢一点回应它，再看它会不会继续靠近或带你去某个位置。",
            confidenceNote: "本地样本相似度一般，这次更像日常沟通型叫声",
            sourceLabel: snapshot.sourceLabel,
            matchedSample: nil,
            analysisSummary: analysisSummary
        )
    }

    private static func rankedSemanticMatches(for snapshot: CatAudioSnapshot) -> [CatSemanticMatch] {
        CatAudioSample.builtIn
            .map { sample in
                let signature = referenceSignature(for: sample)
                let similarity = snapshot.signature.similarity(to: signature)

                return CatSemanticMatch(
                    sampleID: sample.id,
                    sampleTitle: sample.title,
                    sampleIntent: sample.intent,
                    similarity: similarity,
                    comparisonSummary: comparisonSummary(for: snapshot.signature, against: signature, sampleTitle: sample.title)
                )
            }
            .sorted { $0.similarity > $1.similarity }
    }

    private static func referenceSignature(for sample: CatAudioSample) -> CatAudioSignature {
        guard let url = sample.bundleURL,
              let snapshot = try? analyzeAudioFile(url: url, sourceLabel: sample.title) else {
            return sample.referenceSignature
        }

        return snapshot.signature
    }

    private static func analyzeAudioFile(url: URL, sourceLabel: String) throws -> CatAudioSnapshot {
        let audioFile = try AVAudioFile(forReading: url)
        let inputFormat = audioFile.processingFormat
        let inputFrameCount = AVAudioFrameCount(audioFile.length)

        guard inputFrameCount > 0 else {
            throw AudioAnalysisError.emptyAudio
        }

        guard let inputBuffer = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: inputFrameCount) else {
            throw AudioAnalysisError.bufferCreationFailed
        }

        try audioFile.read(into: inputBuffer)

        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: inputFormat.sampleRate,
            channels: 1,
            interleaved: false
        ) else {
            throw AudioAnalysisError.converterCreationFailed
        }

        let estimatedFrameCount = Double(max(inputBuffer.frameLength, 1)) * (targetFormat.sampleRate / inputFormat.sampleRate)
        let outputFrameCapacity = AVAudioFrameCount(estimatedFrameCount.rounded(.up)) + 32

        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: targetFormat,
            frameCapacity: outputFrameCapacity
        ) else {
            throw AudioAnalysisError.bufferCreationFailed
        }

        guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            throw AudioAnalysisError.converterCreationFailed
        }

        var conversionError: NSError?
        let status = converter.convert(to: outputBuffer, error: &conversionError) { _, outStatus in
            outStatus.pointee = .haveData
            return inputBuffer
        }

        guard status != .error, conversionError == nil else {
            throw conversionError ?? AudioAnalysisError.conversionFailed
        }

        guard let channelData = outputBuffer.floatChannelData else {
            throw AudioAnalysisError.channelDataMissing
        }

        let frameLength = Int(outputBuffer.frameLength)
        guard frameLength > 0 else {
            throw AudioAnalysisError.emptyAudio
        }

        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))
        return analyzePCM(samples: samples, sampleRate: targetFormat.sampleRate, sourceLabel: sourceLabel)
    }

    private static func analyzePCM(samples: [Float], sampleRate: Double, sourceLabel: String) -> CatAudioSnapshot {
        let safeSamples = samples.map { min(max(Double($0), -1), 1) }
        let absoluteSamples = safeSamples.map(abs)
        let duration = max(Double(safeSamples.count) / sampleRate, 0.4)
        let rms = sqrt(absoluteSamples.map { $0 * $0 }.average)
        let peak = absoluteSamples.max() ?? rms
        let windowSize = max(512, Int(sampleRate / 24))

        let envelope = stride(from: 0, to: absoluteSamples.count, by: windowSize).map { start in
            let end = min(start + windowSize, absoluteSamples.count)
            return Array(absoluteSamples[start..<end]).average
        }
        let envelopeDeltas = zip(envelope, envelope.dropFirst()).map { abs($0 - $1) }
        var crossings = 0
        if safeSamples.count > 1 {
            for index in 1..<safeSamples.count {
                let previous = safeSamples[index - 1]
                let current = safeSamples[index]
                if (previous >= 0 && current < 0) || (previous < 0 && current >= 0) {
                    crossings += 1
                }
            }
        }
        let silenceThreshold = max(rms * 0.32, 0.015)
        let silenceRatio = Double(absoluteSamples.filter { $0 < silenceThreshold }.count) / Double(max(absoluteSamples.count, 1))

        return CatAudioSnapshot(
            duration: duration,
            averageIntensity: clamp(rms * 4.2, lower: 0.05, upper: 0.98),
            peakIntensity: clamp(peak * 1.08, lower: 0.08, upper: 1.0),
            activityScore: clamp(envelopeDeltas.average * 7.5, lower: 0.05, upper: 1.0),
            zeroCrossingRate: clamp(Double(crossings) / Double(max(safeSamples.count, 1)) * 18.0, lower: 0.02, upper: 1.0),
            silenceRatio: clamp(silenceRatio, lower: 0.01, upper: 0.98),
            sourceLabel: sourceLabel
        )
    }

    private static func comparisonSummary(for lhs: CatAudioSignature, against rhs: CatAudioSignature, sampleTitle: String) -> String {
        let dimensions: [(String, Double)] = [
            ("时长", min(abs(lhs.duration - rhs.duration) / max(max(lhs.duration, rhs.duration), 0.6), 1)),
            ("平均响度", abs(lhs.averageIntensity - rhs.averageIntensity)),
            ("峰值强度", abs(lhs.peakIntensity - rhs.peakIntensity)),
            ("节奏起伏", abs(lhs.activityScore - rhs.activityScore)),
            ("高频摩擦感", abs(lhs.zeroCrossingRate - rhs.zeroCrossingRate)),
            ("停顿比例", abs(lhs.silenceRatio - rhs.silenceRatio))
        ]
        let bestDimensions = dimensions.sorted { $0.1 < $1.1 }.prefix(2).map(\.0)
        let dimensionText = bestDimensions.joined(separator: "、")
        return "在\(dimensionText)上都更接近“\(sampleTitle)”这段样本。"
    }

    private static func confidenceNote(for similarity: Double) -> String {
        switch similarity {
        case 0.82...:
            return "和本地真实样本非常接近"
        case 0.7..<0.82:
            return "和本地真实样本比较接近"
        default:
            return "和本地真实样本有一定相似度"
        }
    }

    private static func normalizedLevel(from decibel: Float) -> Double {
        let clamped = min(max(decibel, -80), 0)
        return pow(10, Double(clamped) / 20)
    }

    private static func clamp(_ value: Double, lower: Double, upper: Double) -> Double {
        min(max(value, lower), upper)
    }

    private enum AudioAnalysisError: LocalizedError {
        case emptyAudio
        case bufferCreationFailed
        case converterCreationFailed
        case conversionFailed
        case channelDataMissing

        var errorDescription: String? {
            switch self {
            case .emptyAudio:
                return "音频内容太短了，这次还不够分析。"
            case .bufferCreationFailed, .converterCreationFailed, .conversionFailed, .channelDataMissing:
                return "这段音频暂时没能顺利转成可分析的数据。"
            }
        }
    }
}

enum CatPhraseComposer {
    static func generate(text: String, tone: CatTone) -> CatPhrasePlan {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let shortened = String(cleaned.prefix(24))
        let count = max(2, min(6, Int(ceil(Double(max(shortened.count, 4)) / 4.0))))
        let matchedSample = CatAudioSample.bestMatch(for: shortened, tone: tone)

        let units: [String]
        let explanation: String

        switch tone {
        case .soothe:
            units = ["咪呜", "呼噜", "喵呜"]
            explanation = "这句会更偏绵软、收尾更轻，适合在安抚、陪睡或它有点紧张的时候播放。"
        case .call:
            units = ["喵", "喵呀", "咪"]
            explanation = "这句节奏会更清楚，像在温柔地叫它过来，适合吃饭、回家或提醒它看向你。"
        case .praise:
            units = ["咪呀", "喵呜", "嗯喵"]
            explanation = "这句起伏更圆润，像在夸它好乖、好棒，适合奖励和贴贴时使用。"
        case .play:
            units = ["喵嗷", "啾咪", "喵"]
            explanation = "这句会更灵动一点，适合逗猫棒、追逐游戏或想把气氛带热的时候使用。"
        }

        let catText = (0..<count).map { units[$0 % units.count] }.joined(separator: " ")
        let playbackText = catText.replacingOccurrences(of: " ", with: "，")

        return CatPhrasePlan(
            originalText: shortened,
            tone: tone,
            catText: catText,
            explanation: explanation + " 我已经把它对应到“\(matchedSample.title)”这段真实猫叫，播放时会优先用这段样本。",
            playbackText: playbackText,
            sampleID: matchedSample.id,
            sampleTitle: matchedSample.title,
            sampleIntent: matchedSample.intent
        )
    }
}

@MainActor
final class CatAudioRecorder: NSObject, ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var liveLevel: Double = 0.08

    private var recorder: AVAudioRecorder?
    private var meterTimer: Timer?
    private var meterSamples: [Float] = []
    private var startedAt: Date?

    func start() async throws {
        guard await requestPermission() else {
            throw RecorderError.permissionDenied
        }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let recordingURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("cat-recording-\(UUID().uuidString).m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let recorder = try AVAudioRecorder(url: recordingURL, settings: settings)
        recorder.isMeteringEnabled = true
        recorder.prepareToRecord()

        meterSamples = []
        startedAt = .now

        guard recorder.record() else {
            throw RecorderError.startFailed
        }

        self.recorder = recorder
        isRecording = true
        startMetering()
    }

    func stop() throws -> CatAudioSnapshot {
        guard let recorder else {
            throw RecorderError.noActiveRecording
        }

        recorder.stop()
        stopMetering()
        isRecording = false

        let duration = Date().timeIntervalSince(startedAt ?? .now)
        let snapshot = CatAudioAnalyzer.analyzeRecordedAudio(
            url: recorder.url,
            fallbackDuration: duration,
            meterSamples: meterSamples,
            sourceLabel: "刚才这段录音"
        )

        self.recorder = nil
        startedAt = nil

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        return snapshot
    }

    private func startMetering() {
        stopMetering()
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            guard let self, let recorder = self.recorder, self.isRecording else { return }
            recorder.updateMeters()
            let power = recorder.averagePower(forChannel: 0)
            self.meterSamples.append(power)
            let normalizedLevel = pow(10, Double(min(max(power, -80), 0)) / 20)
            let liveSnapshot = CatAudioSnapshot(
                duration: 1,
                averageIntensity: max(0.08, normalizedLevel),
                peakIntensity: max(0.12, normalizedLevel),
                activityScore: 0.12,
                zeroCrossingRate: 0.16,
                silenceRatio: 0.22,
                sourceLabel: "live"
            )
            self.liveLevel = liveSnapshot.averageIntensity
        }
    }

    private func stopMetering() {
        meterTimer?.invalidate()
        meterTimer = nil
        liveLevel = 0.08
    }

    private func requestPermission() async -> Bool {
        let session = AVAudioSession.sharedInstance()

        switch session.recordPermission {
        case .granted:
            return true
        case .denied:
            return false
        case .undetermined:
            return await withCheckedContinuation { continuation in
                session.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        @unknown default:
            return false
        }
    }

    enum RecorderError: LocalizedError {
        case permissionDenied
        case startFailed
        case noActiveRecording

        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "需要先打开麦克风权限，才能帮你听懂它现在在说什么。"
            case .startFailed:
                return "录音没能顺利开始，你可以稍后再试一次。"
            case .noActiveRecording:
                return "现在还没有正在进行的录音。"
            }
        }
    }
}

@MainActor
final class HumanSpeechTranscriber: NSObject, ObservableObject {
    @Published private(set) var isTranscribing = false
    @Published private(set) var transcript = ""

    private let audioEngine = AVAudioEngine()
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh_CN"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    func start() async throws {
        guard let recognizer else {
            throw TranscriberError.notSupported
        }

        guard recognizer.isAvailable else {
            throw TranscriberError.temporarilyUnavailable
        }

        guard await requestSpeechPermission() else {
            throw TranscriberError.speechPermissionDenied
        }

        guard await requestMicrophonePermission() else {
            throw TranscriberError.microphonePermissionDenied
        }

        stop()

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        transcript = ""

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = false
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        isTranscribing = true

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result {
                Task { @MainActor in
                    self.transcript = result.bestTranscription.formattedString
                }

                if result.isFinal {
                    Task { @MainActor in
                        self.stop()
                    }
                }
            }

            if error != nil {
                Task { @MainActor in
                    self.stop()
                }
            }
        }
    }

    func stop() {
        recognitionTask?.cancel()
        recognitionTask = nil

        if audioEngine.isRunning {
            audioEngine.stop()
        }

        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        isTranscribing = false

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func requestSpeechPermission() async -> Bool {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status == .authorized)
                }
            }
        @unknown default:
            return false
        }
    }

    private func requestMicrophonePermission() async -> Bool {
        let session = AVAudioSession.sharedInstance()

        switch session.recordPermission {
        case .granted:
            return true
        case .denied:
            return false
        case .undetermined:
            return await withCheckedContinuation { continuation in
                session.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        @unknown default:
            return false
        }
    }

    enum TranscriberError: LocalizedError {
        case notSupported
        case temporarilyUnavailable
        case speechPermissionDenied
        case microphonePermissionDenied

        var errorDescription: String? {
            switch self {
            case .notSupported:
                return "这台设备暂时不支持语音转文字。"
            case .temporarilyUnavailable:
                return "语音识别现在不可用，你可以稍后再试。"
            case .speechPermissionDenied:
                return "需要先打开语音识别权限，我才能帮你把人话写成文字。"
            case .microphonePermissionDenied:
                return "需要先打开麦克风权限，我才能听清你刚才说的话。"
            }
        }
    }
}

@MainActor
final class CatSpeechPlayer: NSObject, ObservableObject {
    @Published private(set) var isSpeaking = false

    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func play(plan: CatPhrasePlan) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: plan.playbackText)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.volume = 0.95

        switch plan.tone {
        case .soothe:
            utterance.rate = 0.39
            utterance.pitchMultiplier = 1.18
        case .call:
            utterance.rate = 0.48
            utterance.pitchMultiplier = 1.26
        case .praise:
            utterance.rate = 0.44
            utterance.pitchMultiplier = 1.34
        case .play:
            utterance.rate = 0.52
            utterance.pitchMultiplier = 1.42
        }

        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

}

@MainActor
final class CatSamplePlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var isPlaying = false
    @Published private(set) var currentSampleID: String?

    private var player: AVAudioPlayer?

    func play(sample: CatAudioSample) throws {
        guard let url = sample.bundleURL else {
            throw SamplePlayerError.resourceMissing(sample.fullFileName)
        }

        stop()

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let player = try AVAudioPlayer(contentsOf: url)
        player.delegate = self
        player.prepareToPlay()

        guard player.play() else {
            throw SamplePlayerError.playbackFailed
        }

        self.player = player
        isPlaying = true
        currentSampleID = sample.id
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        currentSampleID = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stop()
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        stop()
    }

    enum SamplePlayerError: LocalizedError {
        case resourceMissing(String)
        case playbackFailed

        var errorDescription: String? {
            switch self {
            case .resourceMissing(let fileName):
                return "没有找到内置样本 \(fileName)，可以检查资源是不是已经加入应用目标。"
            case .playbackFailed:
                return "这段猫叫没能顺利播放，你可以换一个样本再试。"
            }
        }
    }
}

extension CatSpeechPlayer: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = true
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = false
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = false
        }
    }
}

private extension Collection where Element == Double {
    var average: Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}