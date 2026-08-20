import SwiftUI
import UIKit

extension SaveKind {
    var amountColor: Color {
        switch self {
        case .spent: return .orange
        case .gave: return .red
        default: return .primary
        }
    }

    var challengeLedgerColor: Color {
        switch self {
        case .spent: return .orange
        case .gave: return .red
        default: return .teal
        }
    }
}

enum AppAnimations {
    static let snappy = Animation.spring(response: 0.35, dampingFraction: 0.72)
    static let smooth = Animation.spring(response: 0.55, dampingFraction: 0.82)
    static let bouncy = Animation.spring(response: 0.45, dampingFraction: 0.62)
    static let gentle = Animation.easeInOut(duration: 0.35)
    static let countUp = Animation.spring(response: 0.9, dampingFraction: 0.78)
    static let vaultFill = Animation.spring(response: 0.65, dampingFraction: 0.68)
}

struct AnimatedCurrencyText: View {
    let amount: Double
    var font: Font = .title2.bold()
    var color: Color = .primary
    var accentColor: Color = .teal
    var decreaseAccentColor: Color = .orange
    var showsIncreaseEffects: Bool = true
    var showsDecreaseEffects: Bool = true

    @State private var displayedAmount: Double = 0

    var body: some View {
        AnimatableCurrencyValue(value: displayedAmount, font: font, color: color)
            .onAppear {
                displayedAmount = amount
            }
            .onChange(of: amount) { _, new in
                withAnimation(AppAnimations.smooth) {
                    displayedAmount = new
                }
            }
    }
}

private struct AnimatableCurrencyValue: View, Animatable {
    var value: Double
    var font: Font
    var color: Color

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Text(SavingsCalculator.formatCurrency(value))
            .font(font)
            .foregroundStyle(color)
            .monospacedDigit()
            .contentTransition(.numericText())
    }
}

struct StaggeredAppearModifier: ViewModifier {
    let index: Int
    @State private var visible = false

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 14)
            .onAppear {
                withAnimation(AppAnimations.smooth.delay(Double(index) * 0.05)) {
                    visible = true
                }
            }
    }
}

extension View {
    func staggeredAppear(index: Int) -> some View {
        modifier(StaggeredAppearModifier(index: index))
    }

    func popOnTap(scale: CGFloat = 0.96) -> some View {
        buttonStyle(PopButtonStyle(scale: scale))
    }
}

struct PopButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(AppAnimations.snappy, value: configuration.isPressed)
    }
}

enum HapticFeedback {
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
