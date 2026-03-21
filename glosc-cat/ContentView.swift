//
//  ContentView.swift
//  glosc-cat
//
//  Created by XiaoM on 2026/3/21.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \InteractionRecord.createdAt, order: .reverse) private var records: [InteractionRecord]
    @Query(sort: \FavoritePhrase.createdAt, order: .reverse) private var favoritePhrases: [FavoritePhrase]

    @StateObject private var recorder = CatAudioRecorder()
    @StateObject private var samplePlayer = CatSamplePlayer()
    @StateObject private var speechTranscriber = HumanSpeechTranscriber()

    @State private var selectedMode: AppMode = .catToHuman
    @State private var latestInterpretation: CatInterpretation?
    @State private var generatedPhrase: CatPhrasePlan?
    @State private var humanText = ""
    @State private var selectedTone: CatTone = .soothe
    @State private var isImportingAudio = false
    @State private var isAnalyzingAudio = false
    @State private var errorMessage: String?
    @State private var statusMessage = "先选一个方向吧，我会把核心操作放在你手边。"

    var body: some View {
        NavigationStack {
            ZStack {
                AppPalette.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        modeSelector
                        activePanel

                        if let errorMessage {
                            MessageBanner(
                                title: "这次没有顺利完成",
                                message: errorMessage,
                                accent: AppPalette.coral
                            )
                        }

                        MessageBanner(
                            title: "当前状态",
                            message: statusMessage,
                            accent: AppPalette.sage
                        )

                        heroSection
                        recentRecordsSection

                        if !favoritePhrases.isEmpty {
                            favoritesSection
                        }

                        gentleTipsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
        }
        .fileImporter(
            isPresented: $isImportingAudio,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false,
            onCompletion: handleImportedAudio
        )
        .onChange(of: speechTranscriber.transcript) { _, newValue in
            humanText = newValue
        }
    }

    private var heroSection: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppPalette.peach, AppPalette.cream, AppPalette.oat],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(AppPalette.white.opacity(0.65))
                        .frame(width: 110, height: 110)
                        .offset(x: 18, y: -22)
                }
                .overlay(alignment: .bottomLeading) {
                    Circle()
                        .fill(AppPalette.coral.opacity(0.14))
                        .frame(width: 90, height: 90)
                        .offset(x: -18, y: 20)
                }

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "cat.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(AppPalette.ink)

                    Text("说猫语")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(AppPalette.ink)
                        .accessibilityIdentifier("screen.title")
                }

                Text("让听不懂和不会说，都变成温柔、轻松、可爱的日常互动。")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(AppPalette.ink.opacity(0.82))
                    .lineSpacing(3)

                HStack(spacing: 12) {
                    HighlightPill(icon: "waveform", text: "录音识别")
                    HighlightPill(icon: "text.bubble", text: "猫语生成")
                    HighlightPill(icon: "heart", text: "陪伴建议")
                }
            }
            .padding(24)
        }
        .shadow(color: AppPalette.shadow, radius: 22, x: 0, y: 16)
    }

    private var modeSelector: some View {
        HStack(spacing: 12) {
            ForEach(AppMode.allCases) { mode in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        if selectedMode != mode, speechTranscriber.isTranscribing {
                            speechTranscriber.stop()
                        }
                        selectedMode = mode
                        errorMessage = nil
                        statusMessage = mode.subtitle
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(mode.title)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                        Text(mode == .catToHuman ? "听懂它的情绪和需求" : "把你的话变成喵语节奏")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(AppPalette.ink.opacity(0.68))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(selectedMode == mode ? AppPalette.white : AppPalette.white.opacity(0.78))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(selectedMode == mode ? AppPalette.coral : AppPalette.white.opacity(0.2), lineWidth: 1.2)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(mode == .catToHuman ? "mode.catToHuman" : "mode.humanToCat")
            }
        }
    }

    @ViewBuilder
    private var activePanel: some View {
        switch selectedMode {
        case .catToHuman:
            catToHumanPanel
        case .humanToCat:
            humanToCatPanel
        }
    }

    private var catToHumanPanel: some View {
        VStack(spacing: 18) {
            SectionCard(title: "猫语转人话", subtitle: latestInterpretation == nil ? "录下来或导入音频，我会先给你一个温柔、可执行的判断。" : "操作和结果放在一起，听完后能直接看到这次更像在表达什么。") {
                VStack(spacing: 18) {
                    ZStack {
                        Circle()
                            .fill(AppPalette.peach.opacity(0.22))
                            .frame(width: 190, height: 190)
                            .scaleEffect(recorder.isRecording ? 1.02 + recorder.liveLevel * 0.28 : 1.0)

                        Circle()
                            .fill(AppPalette.white)
                            .frame(width: 150, height: 150)
                            .shadow(color: AppPalette.shadow, radius: 20, x: 0, y: 16)

                        Button {
                            toggleRecording()
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: recorder.isRecording ? "pause.fill" : "mic.fill")
                                    .font(.system(size: 32, weight: .semibold))
                                Text(recorder.isRecording ? "结束倾听" : "开始录音")
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(AppPalette.ink)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("record.toggle")
                    }
                    .animation(.easeInOut(duration: 0.35), value: recorder.isRecording)
                    .animation(.easeInOut(duration: 0.2), value: recorder.liveLevel)

                    Text(recorder.isRecording ? "继续说吧，我正在听这段情绪和节奏。" : "支持直接录一段猫叫，也支持导入已有音频。")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppPalette.ink.opacity(0.72))
                        .multilineTextAlignment(.center)

                    HStack(spacing: 12) {
                        ActionButton(
                            title: isAnalyzingAudio ? "分析中" : "导入音频",
                            subtitle: "本地音频也可以",
                            systemImage: "square.and.arrow.down",
                            fill: AppPalette.white,
                            foreground: AppPalette.ink,
                            bordered: true,
                            action: { isImportingAudio = true }
                        )
                        .disabled(recorder.isRecording || isAnalyzingAudio)
                        .accessibilityIdentifier("analyze.import")

                        ActionButton(
                            title: recorder.isRecording ? "完成这次录音" : "分析内置样本",
                            subtitle: recorder.isRecording ? "马上给你结果" : "直接看看真实样本判断",
                            systemImage: recorder.isRecording ? "sparkles" : "wand.and.stars",
                            fill: AppPalette.coral,
                            foreground: AppPalette.white,
                            bordered: false,
                            action: {
                                if recorder.isRecording {
                                    stopRecordingAndAnalyze()
                                } else {
                                    analyzeDemoClip()
                                }
                            }
                        )
                        .disabled(isAnalyzingAudio)
                    }

                    if isAnalyzingAudio {
                        analysisInPlaceSection
                            .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.96)), removal: .opacity))
                    } else if let latestInterpretation {
                        integratedResultSection(interpretation: latestInterpretation)
                            .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.94)), removal: .opacity))
                    }
                }
            }

            sampleLibrarySection
        }
    }

    private var analysisInPlaceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                AnalysisPulseView()

                VStack(alignment: .leading, spacing: 5) {
                    Text("正在替你听懂这段猫语")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(AppPalette.ink)
                    Text("我在先和本地真实样本做对比，再结合时长、响度和节奏，把它整理成更好理解的话。")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(AppPalette.ink.opacity(0.68))
                        .lineSpacing(2)
                }

                Spacer(minLength: 0)
            }

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppPalette.peach.opacity(0.22), AppPalette.white, AppPalette.cream.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 78)
                .overlay {
                    VStack(spacing: 10) {
                        HStack(spacing: 8) {
                            ForEach(0..<5, id: \.self) { index in
                                Capsule(style: .continuous)
                                    .fill(index.isMultiple(of: 2) ? AppPalette.coral.opacity(0.8) : AppPalette.sage.opacity(0.75))
                                    .frame(width: 8, height: CGFloat([18, 30, 22, 34, 16][index]))
                            }
                        }

                        Text("分析完成后会直接在这里展开结果")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(AppPalette.ink.opacity(0.62))
                    }
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppPalette.white.opacity(0.82))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppPalette.peach.opacity(0.9), lineWidth: 1)
        )
    }

    private var humanToCatPanel: some View {
        VStack(spacing: 18) {
            SectionCard(title: "人话转猫语", subtitle: "输入一句你想说的话，再挑一个语气，我来把它变成更像喵语的节奏。") {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("你想对它说什么")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppPalette.ink.opacity(0.76))

                        VStack(alignment: .leading, spacing: 12) {
                            TextField("比如：来吃饭啦，不要怕，我在这儿", text: $humanText, axis: .vertical)
                                .textFieldStyle(.plain)
                                .lineLimit(3, reservesSpace: true)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .accessibilityIdentifier("textInput.human")

                            Button {
                                toggleSpeechTranscription()
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: speechTranscriber.isTranscribing ? "waveform.circle.fill" : "mic.circle")
                                        .font(.system(size: 20, weight: .semibold))

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(speechTranscriber.isTranscribing ? "结束说话并写进输入框" : "语音转文字")
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                        Text(speechTranscriber.isTranscribing ? "我在边听边写，你说完再点一次" : "不想打字时，直接说一句就好")
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                            .foregroundStyle(AppPalette.ink.opacity(0.66))
                                    }

                                    Spacer()
                                }
                                .foregroundStyle(AppPalette.ink)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(speechTranscriber.isTranscribing ? AppPalette.peach.opacity(0.8) : AppPalette.oat.opacity(0.45))
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("speechToText.toggle")
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(AppPalette.white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(AppPalette.oat, lineWidth: 1)
                        )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("语气模板")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppPalette.ink.opacity(0.76))

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(CatTone.allCases) { tone in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.84)) {
                                        selectedTone = tone
                                    }
                                } label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(tone.title)
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                            .foregroundStyle(AppPalette.ink)
                                        Text(tone.subtitle)
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                            .foregroundStyle(AppPalette.ink.opacity(0.68))
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .fill(selectedTone == tone ? AppPalette.peach.opacity(0.6) : AppPalette.white)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(selectedTone == tone ? AppPalette.coral : AppPalette.oat, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    ActionButton(
                        title: "生成猫语",
                        subtitle: "保留原意，换成更像猫咪的节奏",
                        systemImage: "sparkles.rectangle.stack",
                        fill: AppPalette.coral,
                        foreground: AppPalette.white,
                        bordered: false,
                        action: generatePhrase
                    )
                    .accessibilityIdentifier("generate.catPhrase")
                }
            }

            if let generatedPhrase {
                generatedPhraseSection(plan: generatedPhrase)
            }
        }
    }

    private func integratedResultSection(interpretation: CatInterpretation) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("这次更像是在说")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(AppPalette.ink.opacity(0.62))
                    Text(interpretation.emotion)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(AppPalette.ink)
                        .accessibilityIdentifier("result.emotion")
                    Text(interpretation.sourceLabel)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppPalette.ink.opacity(0.58))
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 8) {
                    Text("主要需求")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(AppPalette.ink.opacity(0.55))
                    Text(interpretation.need)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AppPalette.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(
                            Capsule(style: .continuous)
                                .fill(AppPalette.sage.opacity(0.22))
                        )
                }
            }

            InterpretationShowcase(interpretation: interpretation)
            DetailCard(title: "这次怎么判断的", text: interpretation.analysisSummary)

            if let matchedSample = interpretation.matchedSample {
                DetailCard(
                    title: "最接近的真实样本",
                    text: "\(matchedSample.sampleTitle) · \(matchedSample.sampleIntent)。当前相似度约 \(Int((matchedSample.similarity * 100).rounded()))%。\(matchedSample.comparisonSummary)"
                )
            }

            HStack(spacing: 12) {
                ShareLink(item: interpretation.shareText) {
                    Label("分享结果", systemImage: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(AppPalette.white)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    analyzeDemoClip()
                } label: {
                    Label("再试一次", systemImage: "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(AppPalette.peach.opacity(0.65))
                        )
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppPalette.ink)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppPalette.white, AppPalette.card, AppPalette.peach.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(AppPalette.white.opacity(0.94), lineWidth: 1.2)
        )
        .shadow(color: AppPalette.shadow.opacity(0.7), radius: 14, x: 0, y: 10)
    }

    private func generatedPhraseSection(plan: CatPhrasePlan) -> some View {
        SectionCard(title: "你的猫语版本", subtitle: "原话：\(plan.originalText)") {
            VStack(alignment: .leading, spacing: 14) {
                Text(plan.catText)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(AppPalette.ink)
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(AppPalette.peach.opacity(0.35))
                    )

                DetailCard(title: "语气说明", text: plan.explanation)
                DetailCard(title: "将播放的猫叫样本", text: "\(plan.sampleTitle) · \(plan.sampleIntent)。现在默认直接播放这段真实猫叫，不再用生硬的 AI 朗读代替。")

                HStack(spacing: 12) {
                    ActionButton(
                        title: samplePlayer.currentSampleID == plan.sampleID && samplePlayer.isPlaying ? "猫叫播放中" : "播放对应猫叫",
                        subtitle: "直接播放匹配到的真实猫咪音频",
                        systemImage: samplePlayer.currentSampleID == plan.sampleID && samplePlayer.isPlaying ? "speaker.wave.3.fill" : "play.fill",
                        fill: AppPalette.coral,
                        foreground: AppPalette.white,
                        bordered: false,
                        action: { playMatchedSample(for: plan) }
                    )

                    ActionButton(
                        title: isFavorite(plan) ? "已收藏" : "收藏短语",
                        subtitle: "常用句子以后更快找到",
                        systemImage: isFavorite(plan) ? "heart.fill" : "heart",
                        fill: AppPalette.white,
                        foreground: AppPalette.ink,
                        bordered: true,
                        action: { toggleFavorite(for: plan) }
                    )
                }

                ShareLink(item: plan.shareText) {
                    Label("分享这句猫语", systemImage: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(AppPalette.white)
                        )
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppPalette.ink)
            }
        }
    }

    private var sampleLibrarySection: some View {
        SectionCard(title: "内置猫叫样本", subtitle: "这些真实样本现在既能直接试听，也会作为本地语义对比库，帮助判断录音更像在表达什么。") {
            VStack(alignment: .leading, spacing: 14) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(CatAudioSample.builtIn) { sample in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(sample.title)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppPalette.ink)

                                Text(sample.intent)
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppPalette.coral)

                                Text(sample.detail)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(AppPalette.ink.opacity(0.72))
                                    .lineSpacing(2)
                                    .lineLimit(3)

                                Text(sample.license)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppPalette.ink.opacity(0.7))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule(style: .continuous)
                                            .fill(AppPalette.peach.opacity(0.45))
                                    )

                                HStack(spacing: 8) {
                                    Button {
                                        playSample(sample)
                                    } label: {
                                        Label(
                                            samplePlayer.currentSampleID == sample.id && samplePlayer.isPlaying ? "停止" : "试听",
                                            systemImage: samplePlayer.currentSampleID == sample.id && samplePlayer.isPlaying ? "stop.fill" : "play.fill"
                                        )
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .fill(AppPalette.white)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(AppPalette.ink)

                                    Button {
                                        analyzeBundledSample(sample)
                                    } label: {
                                        Label("分析", systemImage: "waveform.path.ecg")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                    .fill(AppPalette.coral)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(AppPalette.white)
                                }
                            }
                            .frame(width: 240, alignment: .leading)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .fill(AppPalette.white)
                            )
                        }
                    }
                }

                Text("当前应用内优先接入 mp3 和 wav 样本做试听与识别；其余 ogg 资源先保留在仓库里，后续统一转码后再开放。")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(AppPalette.ink.opacity(0.6))
                    .lineSpacing(2)
            }
        }
    }

    private var recentRecordsSection: some View {
        SectionCard(title: "最近互动", subtitle: records.isEmpty ? "还没有记录，做完一次识别或生成就会出现在这里。" : "帮你把最近几次沟通收在一起，回看会更方便。") {
            if records.isEmpty {
                DetailCard(
                    title: "现在还是空空的",
                    text: "你可以先试一次录音识别，或者把一句常说的话翻成猫语，这里就会开始有记忆了。"
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(records.prefix(3))) { record in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(record.mode.title)
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppPalette.coral)
                                Spacer()
                                Text(record.createdAt, style: .time)
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundStyle(AppPalette.ink.opacity(0.5))
                            }

                            Text(record.title)
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(AppPalette.ink)

                            Text(record.summary)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(AppPalette.ink.opacity(0.72))

                            Text(record.detail)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(AppPalette.ink.opacity(0.64))
                                .lineSpacing(2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(AppPalette.white)
                        )
                    }
                }
            }
        }
    }

    private var favoritesSection: some View {
        SectionCard(title: "收藏短语", subtitle: "高频常用句先放在这里，下次不用重新输入。") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(favoritePhrases.prefix(6))) { favorite in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(favorite.tone.title)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(AppPalette.coral)

                            Text(favorite.originalText)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(AppPalette.ink)
                                .lineLimit(2)

                            Text(favorite.catText)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(AppPalette.ink.opacity(0.66))
                                .lineLimit(2)
                        }
                        .frame(width: 190, alignment: .leading)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(AppPalette.white)
                        )
                    }
                }
            }
        }
        .accessibilityIdentifier("favorites.section")
    }

    private var gentleTipsSection: some View {
        SectionCard(title: "互动小贴士", subtitle: "结果只是帮助你更快理解它，不替代你对猫咪状态的持续观察。") {
            VStack(alignment: .leading, spacing: 10) {
                TipRow(text: "如果它连续高频、急促地叫，先排查食物、水、猫砂盆和门窗。")
                TipRow(text: "如果叫声拉长又比较轻，多半更适合温柔回应，而不是马上逗它。")
                TipRow(text: "人话转猫语更适合做陪伴互动，不建议长时间连续播放。")
            }
        }
    }

    private func toggleRecording() {
        errorMessage = nil

        if recorder.isRecording {
            stopRecordingAndAnalyze()
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

    private func stopRecordingAndAnalyze() {
        do {
            let snapshot = try recorder.stop()
            handleSnapshot(snapshot)
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = "录音结束时出了点小问题。"
        }
    }

    private func analyzeDemoClip() {
        analyzeBundledSample(CatAudioSample.builtIn[0])
    }

    private func handleImportedAudio(_ result: Result<[URL], Error>) {
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
                handleSnapshot(snapshot)
            } catch {
                errorMessage = "这段音频暂时没能顺利分析，你可以换一段更清晰的猫叫试试。"
                statusMessage = "导入音频时遇到了一点问题。"
            }
        case .failure:
            errorMessage = "没有选中音频文件，这次就先不分析啦。"
        }
    }

    private func handleSnapshot(_ snapshot: CatAudioSnapshot) {
        errorMessage = nil
        withAnimation(.easeInOut(duration: 0.22)) {
            latestInterpretation = nil
            isAnalyzingAudio = true
        }
        statusMessage = "我在整理它这次更像是在表达什么。"

        let interpretation = CatAudioAnalyzer.interpret(snapshot)
        saveInterpretation(interpretation)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.84)) {
                latestInterpretation = interpretation
                isAnalyzingAudio = false
            }
            statusMessage = interpretation.confidenceNote
        }
    }

    private func analyzeBundledSample(_ sample: CatAudioSample) {
        errorMessage = nil
        do {
            guard let url = sample.bundleURL else {
                errorMessage = "没有找到这段内置样本，先检查它是不是已经打进 App 资源里了。"
                statusMessage = "内置样本暂时不可用。"
                return
            }

            let snapshot = try CatAudioAnalyzer.analyzeImportedAudio(url: url)
            handleSnapshot(snapshot)
        } catch {
            errorMessage = "这段内置样本暂时没能顺利分析，你可以先换一段试听。"
            statusMessage = "样本分析失败。"
        }
    }

    private func playSample(_ sample: CatAudioSample, restartIfSame: Bool = false) {
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

    private func playTonePreview(for tone: CatTone) {
        let sample = CatAudioSample.demoSample(for: tone)
        playSample(sample)
    }

    private func toggleSpeechTranscription() {
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

    private func generatePhrase() {
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
        savePhrase(plan)
        playMatchedSample(for: plan)
    }

    private func playMatchedSample(for plan: CatPhrasePlan) {
        guard let sample = CatAudioSample.builtIn.first(where: { $0.id == plan.sampleID }) else {
            errorMessage = "这句猫语还没找到可播放的真实样本。"
            statusMessage = "对应样本暂时不可用。"
            return
        }

        playSample(sample, restartIfSame: true)
        statusMessage = "正在播放“\(plan.sampleTitle)”这段真实猫叫。"
    }

    private func saveInterpretation(_ interpretation: CatInterpretation) {
        let record = InteractionRecord(
            modeRaw: AppMode.catToHuman.rawValue,
            title: interpretation.emotion,
            summary: "\(interpretation.need) · \(interpretation.confidenceNote)",
            detail: "\(interpretation.explanation) 建议：\(interpretation.suggestion)",
            accent: interpretation.emotion
        )
        modelContext.insert(record)
    }

    private func savePhrase(_ plan: CatPhrasePlan) {
        let record = InteractionRecord(
            modeRaw: AppMode.humanToCat.rawValue,
            title: plan.catText,
            summary: "语气：\(plan.tone.title)",
            detail: plan.explanation,
            accent: plan.tone.title
        )
        modelContext.insert(record)
    }

    private func isFavorite(_ plan: CatPhrasePlan) -> Bool {
        favoritePhrases.contains {
            $0.originalText == plan.originalText && $0.toneRaw == plan.tone.rawValue
        }
    }

    private func toggleFavorite(for plan: CatPhrasePlan) {
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

private struct SectionCard<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(AppPalette.ink)
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppPalette.ink.opacity(0.68))
                    .lineSpacing(2)
            }

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppPalette.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppPalette.white.opacity(0.82), lineWidth: 1)
        )
        .shadow(color: AppPalette.shadow, radius: 20, x: 0, y: 14)
    }
}

private struct HighlightPill: View {
    let icon: String
    let text: String

    var body: some View {
        Label(text, systemImage: icon)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(AppPalette.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(AppPalette.white.opacity(0.82))
            )
    }
}

private struct MessageBanner: View {
    let title: String
    let message: String
    let accent: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(accent)
                .frame(width: 10, height: 10)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(AppPalette.ink)
                Text(message)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppPalette.ink.opacity(0.72))
                    .lineSpacing(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppPalette.white.opacity(0.78))
        )
    }
}

private struct ActionButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let fill: Color
    let foreground: Color
    let bordered: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .opacity(0.78)
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(foreground)
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(bordered ? AppPalette.oat : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(AppPalette.ink.opacity(0.58))
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(AppPalette.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(tint.opacity(0.16))
        )
    }
}

private struct InterpretationShowcase: View {
    let interpretation: CatInterpretation

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                MetricCard(title: "情绪", value: interpretation.emotion, tint: AppPalette.coral)
                MetricCard(title: "需求", value: interpretation.need, tint: AppPalette.sage)
            }

            DetailCard(title: "为什么这样判断", text: interpretation.explanation)
            DetailCard(title: "你现在可以怎么做", text: interpretation.suggestion)
        }
    }
}

private struct AnalysisPulseView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Circle()
                .fill(AppPalette.peach.opacity(0.32))
                .frame(width: 56, height: 56)
                .scaleEffect(isAnimating ? 1.12 : 0.9)

            Circle()
                .stroke(AppPalette.coral.opacity(0.3), lineWidth: 1.4)
                .frame(width: 70, height: 70)
                .scaleEffect(isAnimating ? 1.18 : 0.95)
                .opacity(isAnimating ? 0.15 : 0.45)

            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppPalette.coral)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

private struct DetailCard: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(AppPalette.ink.opacity(0.64))
            Text(text)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AppPalette.ink.opacity(0.86))
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppPalette.white)
        )
    }
}

private struct TipRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppPalette.coral)
                .padding(.top, 2)

            Text(text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppPalette.ink.opacity(0.78))
                .lineSpacing(2)
        }
    }
}

private enum AppPalette {
    static let background = Color(red: 0.99, green: 0.96, blue: 0.93)
    static let card = Color(red: 1.0, green: 0.98, blue: 0.96)
    static let white = Color.white
    static let peach = Color(red: 0.98, green: 0.84, blue: 0.80)
    static let cream = Color(red: 0.99, green: 0.93, blue: 0.86)
    static let oat = Color(red: 0.90, green: 0.84, blue: 0.77)
    static let sage = Color(red: 0.76, green: 0.84, blue: 0.76)
    static let coral = Color(red: 0.90, green: 0.53, blue: 0.44)
    static let ink = Color(red: 0.31, green: 0.24, blue: 0.22)
    static let shadow = Color(red: 0.54, green: 0.41, blue: 0.34).opacity(0.13)
}

#Preview {
    ContentView()
        .modelContainer(for: [InteractionRecord.self, FavoritePhrase.self], inMemory: true)
}
