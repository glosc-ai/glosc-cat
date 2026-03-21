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

    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppPalette.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        modeSelector
                        activePanel

                        if let errorMessage = viewModel.errorMessage {
                            MessageBanner(
                                title: "这次没有顺利完成",
                                message: errorMessage,
                                accent: AppPalette.coral
                            )
                        }

                        MessageBanner(
                            title: "当前状态",
                            message: viewModel.statusMessage,
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
            isPresented: $viewModel.isImportingAudio,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false,
            onCompletion: { result in viewModel.handleImportedAudio(result, modelContext: modelContext) }
        )
        .onChange(of: viewModel.speechTranscriber.transcript) { _, newValue in
            viewModel.humanText = newValue
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
                        if viewModel.selectedMode != mode, viewModel.speechTranscriber.isTranscribing {
                            viewModel.speechTranscriber.stop()
                        }
                        viewModel.selectedMode = mode
                        viewModel.errorMessage = nil
                        viewModel.statusMessage = mode.subtitle
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
                            .fill(viewModel.selectedMode == mode ? AppPalette.white : AppPalette.white.opacity(0.78))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(viewModel.selectedMode == mode ? AppPalette.coral : AppPalette.white.opacity(0.2), lineWidth: 1.2)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(mode == .catToHuman ? "mode.catToHuman" : "mode.humanToCat")
            }
        }
    }

    @ViewBuilder
    private var activePanel: some View {
        switch viewModel.selectedMode {
        case .catToHuman:
            catToHumanPanel
        case .humanToCat:
            humanToCatPanel
        }
    }

    private var catToHumanPanel: some View {
        VStack(spacing: 18) {
            SectionCard(title: "猫语转人话", subtitle: viewModel.latestInterpretation == nil ? "录下来或导入音频，我会先给你一个温柔、可执行的判断。" : "操作和结果放在一起，听完后能直接看到这次更像在表达什么。") {
                VStack(spacing: 18) {
                    ZStack {
                        Circle()
                            .fill(AppPalette.peach.opacity(0.22))
                            .frame(width: 190, height: 190)
                            .scaleEffect(viewModel.recorder.isRecording ? 1.02 + viewModel.recorder.liveLevel * 0.28 : 1.0)

                        Circle()
                            .fill(AppPalette.white)
                            .frame(width: 150, height: 150)
                            .shadow(color: AppPalette.shadow, radius: 20, x: 0, y: 16)

                        Button {
                            viewModel.toggleRecording(modelContext: modelContext)
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: viewModel.recorder.isRecording ? "pause.fill" : "mic.fill")
                                    .font(.system(size: 32, weight: .semibold))
                                Text(viewModel.recorder.isRecording ? "结束倾听" : "开始录音")
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(AppPalette.ink)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("record.toggle")
                    }
                    .animation(.easeInOut(duration: 0.35), value: viewModel.recorder.isRecording)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.recorder.liveLevel)

                    Text(viewModel.recorder.isRecording ? "继续说吧，我正在听这段情绪和节奏。" : "支持直接录一段猫叫，也支持导入已有音频。")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppPalette.ink.opacity(0.72))
                        .multilineTextAlignment(.center)

                    HStack(spacing: 12) {
                        ActionButton(
                            title: viewModel.isAnalyzingAudio ? "分析中" : "导入音频",
                            subtitle: "本地音频也可以",
                            systemImage: "square.and.arrow.down",
                            fill: AppPalette.white,
                            foreground: AppPalette.ink,
                            bordered: true,
                            action: { viewModel.isImportingAudio = true }
                        )
                        .disabled(viewModel.recorder.isRecording || viewModel.isAnalyzingAudio)
                        .accessibilityIdentifier("analyze.import")

                        ActionButton(
                            title: viewModel.recorder.isRecording ? "完成这次录音" : "分析内置样本",
                            subtitle: viewModel.recorder.isRecording ? "马上给你结果" : "直接看看真实样本判断",
                            systemImage: viewModel.recorder.isRecording ? "sparkles" : "wand.and.stars",
                            fill: AppPalette.coral,
                            foreground: AppPalette.white,
                            bordered: false,
                            action: {
                                if viewModel.recorder.isRecording {
                                    viewModel.stopRecordingAndAnalyze(modelContext: modelContext)
                                } else {
                                    viewModel.analyzeDemoClip(modelContext: modelContext)
                                }
                            }
                        )
                        .disabled(viewModel.isAnalyzingAudio)
                    }

                    if viewModel.isAnalyzingAudio {
                        analysisInPlaceSection
                            .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.96)), removal: .opacity))
                    } else if let latestInterpretation = viewModel.latestInterpretation {
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
                            TextField("比如：来吃饭啦，不要怕，我在这儿", text: $viewModel.humanText, axis: .vertical)
                                .textFieldStyle(.plain)
                                .lineLimit(3, reservesSpace: true)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .accessibilityIdentifier("textInput.human")

                            Button {
                                viewModel.toggleSpeechTranscription()
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: viewModel.speechTranscriber.isTranscribing ? "waveform.circle.fill" : "mic.circle")
                                        .font(.system(size: 20, weight: .semibold))

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(viewModel.speechTranscriber.isTranscribing ? "结束说话并写进输入框" : "语音转文字")
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                        Text(viewModel.speechTranscriber.isTranscribing ? "我在边听边写，你说完再点一次" : "不想打字时，直接说一句就好")
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
                                        .fill(viewModel.speechTranscriber.isTranscribing ? AppPalette.peach.opacity(0.8) : AppPalette.oat.opacity(0.45))
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
                                        viewModel.selectedTone = tone
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
                                            .fill(viewModel.selectedTone == tone ? AppPalette.peach.opacity(0.6) : AppPalette.white)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(viewModel.selectedTone == tone ? AppPalette.coral : AppPalette.oat, lineWidth: 1)
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
                        action: { viewModel.generatePhrase(modelContext: modelContext) }
                    )
                    .accessibilityIdentifier("generate.catPhrase")
                }
            }

            if let generatedPhrase = viewModel.generatedPhrase {
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
                    viewModel.analyzeDemoClip(modelContext: modelContext)
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
                        title: viewModel.samplePlayer.currentSampleID == plan.sampleID && viewModel.samplePlayer.isPlaying ? "猫叫播放中" : "播放对应猫叫",
                        subtitle: "直接播放匹配到的真实猫咪音频",
                        systemImage: viewModel.samplePlayer.currentSampleID == plan.sampleID && viewModel.samplePlayer.isPlaying ? "speaker.wave.3.fill" : "play.fill",
                        fill: AppPalette.coral,
                        foreground: AppPalette.white,
                        bordered: false,
                        action: { viewModel.playMatchedSample(for: plan) }
                    )

                    ActionButton(
                        title: viewModel.isFavorite(plan, favoritePhrases: favoritePhrases) ? "已收藏" : "收藏短语",
                        subtitle: "常用句子以后更快找到",
                        systemImage: viewModel.isFavorite(plan, favoritePhrases: favoritePhrases) ? "heart.fill" : "heart",
                        fill: AppPalette.white,
                        foreground: AppPalette.ink,
                        bordered: true,
                        action: { viewModel.toggleFavorite(for: plan, favoritePhrases: favoritePhrases, modelContext: modelContext) }
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
                                        viewModel.playSample(sample)
                                    } label: {
                                        Label(
                                            viewModel.samplePlayer.currentSampleID == sample.id && viewModel.samplePlayer.isPlaying ? "停止" : "试听",
                                            systemImage: viewModel.samplePlayer.currentSampleID == sample.id && viewModel.samplePlayer.isPlaying ? "stop.fill" : "play.fill"
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
                                        viewModel.analyzeBundledSample(sample, modelContext: modelContext)
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

}

#Preview {
    ContentView()
        .modelContainer(for: [InteractionRecord.self, FavoritePhrase.self], inMemory: true)
}
