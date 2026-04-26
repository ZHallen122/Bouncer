import SwiftUI

struct StableActionButtonStyle: ButtonStyle {
    enum Prominence {
        case filled
        case tintedBorder
    }

    let color: Color
    var prominence: Prominence = .filled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundColor(foregroundColor)
            .background(backgroundColor(isPressed: configuration.isPressed))
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

    private var foregroundColor: Color {
        switch prominence {
        case .filled:
            return .white
        case .tintedBorder:
            return color
        }
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        let baseOpacity: Double
        switch prominence {
        case .filled:
            baseOpacity = isPressed ? 0.78 : 0.95
        case .tintedBorder:
            baseOpacity = isPressed ? 0.24 : 0.14
        }
        return color.opacity(baseOpacity)
    }

    private var borderColor: Color {
        switch prominence {
        case .filled:
            return color.opacity(0.95)
        case .tintedBorder:
            return color.opacity(0.65)
        }
    }
}
