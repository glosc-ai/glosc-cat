import SwiftUI

enum AppPalette {
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

struct SectionCard<Content: View>: View {
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

struct HighlightPill: View {
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

struct MessageBanner: View {
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

struct ActionButton: View {
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

struct MetricCard: View {
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

struct InterpretationShowcase: View {
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

struct AnalysisPulseView: View {
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

struct DetailCard: View {
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

struct TipRow: View {
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
