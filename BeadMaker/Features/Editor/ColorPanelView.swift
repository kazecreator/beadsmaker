import SwiftUI

struct ColorPanelView: View {
    var viewModel: EditorViewModel
    @Binding var isExpanded: Bool
    let onColorSelected: () -> Void
    private let columns = [GridItem(.adaptive(minimum: 84, maximum: 108), spacing: 10)]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Capsule()
                    .fill(Color(.systemFill))
                    .frame(width: 36, height: 4)
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity)

            // Recent colors
            if !viewModel.recentColors.isEmpty {
                HStack(spacing: 0) {
                    Text("最近")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(viewModel.recentColors, id: \.self) { id in
                                if let bead = BeadColorLibrary.color(id: id) {
                                    RecentColorSwatch(bead: bead, isSelected: viewModel.selectedColorId == id) {
                                        viewModel.selectedColorId = id
                                        onColorSelected()
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                    }
                }
            }

            Divider()

            // Group picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(ColorGroup.allCases, id: \.self) { group in
                        Button {
                            viewModel.selectedColorGroup = group
                        } label: {
                            Text(group.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(viewModel.selectedColorGroup == group ? Color.accentColor : Color(.systemFill))
                                .foregroundStyle(viewModel.selectedColorGroup == group ? .white : .primary)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }

            // Color grid
            let groupColors = BeadColorLibrary.colors(in: viewModel.selectedColorGroup)
            ScrollView(.vertical, showsIndicators: true) {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(groupColors) { bead in
                        ColorSwatch(bead: bead, isSelected: viewModel.selectedColorId == bead.id) {
                            viewModel.selectedColorId = bead.id
                            viewModel.currentTool = .pen
                            onColorSelected()
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .frame(maxHeight: 260)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 12, y: -4)
    }
}

struct ColorSwatch: View {
    @Environment(\.colorScheme) private var colorScheme
    let bead: BeadColor
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Circle()
                    .fill(bead.color)
                    .frame(width: 34, height: 34)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: isSelected ? 3 : 1)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 2)
                if let standardCode = bead.standardCode {
                    Text(standardCode)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(codeBadgeBackground)
                        )
                        .overlay(
                            Capsule()
                                .stroke(codeBadgeStroke, lineWidth: 0.5)
                        )
                }
            }
            .frame(maxWidth: .infinity, minHeight: 74)
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .background(cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(cardStroke, lineWidth: isSelected ? 1.5 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .scaleEffect(isSelected ? 1.04 : 1.0)
        .animation(.spring(duration: 0.2), value: isSelected)
    }

    private var codeBadgeBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.92) : Color.black.opacity(0.88)
    }

    private var codeBadgeStroke: Color {
        bead.color.opacity(0.9)
    }

    private var cardBackground: Color {
        colorScheme == .dark ? Color(.tertiarySystemBackground) : Color(.secondarySystemBackground)
    }

    private var cardStroke: Color {
        isSelected ? .accentColor : Color(.separator).opacity(0.35)
    }
}

struct RecentColorSwatch: View {
    @Environment(\.colorScheme) private var colorScheme
    let bead: BeadColor
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Circle()
                    .fill(bead.color)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: isSelected ? 3 : 1)
                    )
                    .shadow(color: .black.opacity(0.12), radius: 1.5)

                if let standardCode = bead.standardCode {
                    Text(standardCode)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
            }
            .frame(minWidth: 82)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(cardStroke, lineWidth: isSelected ? 1.5 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .scaleEffect(isSelected ? 1.03 : 1.0)
        .animation(.spring(duration: 0.2), value: isSelected)
    }

    private var cardBackground: Color {
        colorScheme == .dark ? Color(.tertiarySystemBackground) : Color(.secondarySystemBackground)
    }

    private var cardStroke: Color {
        isSelected ? .accentColor : Color(.separator).opacity(0.35)
    }
}
