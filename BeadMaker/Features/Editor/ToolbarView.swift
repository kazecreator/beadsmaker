import SwiftUI

struct ToolbarView: View {
    var viewModel: EditorViewModel
    let onUndo: () -> Void
    let onRedo: () -> Void
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Undo
            toolButton(icon: "arrow.uturn.backward", label: "撤销", enabled: viewModel.canUndo) {
                onUndo()
            }

            // Redo
            toolButton(icon: "arrow.uturn.forward", label: "重做", enabled: viewModel.canRedo) {
                onRedo()
            }

            Divider().frame(height: 24).padding(.horizontal, 4)

            // Pen
            toolToggle(icon: "pencil", label: "画笔", active: viewModel.currentTool == .pen && !viewModel.isPanMode) {
                viewModel.currentTool = .pen
                viewModel.isPanMode = false
            }

            // Eraser
            toolToggle(icon: "eraser", label: "橡皮", active: viewModel.currentTool == .eraser && !viewModel.isPanMode) {
                viewModel.currentTool = .eraser
                viewModel.isPanMode = false
            }

            Divider().frame(height: 24).padding(.horizontal, 4)

            // Pan mode
            toolToggle(icon: "hand.draw", label: "拖动", active: viewModel.isPanMode) {
                viewModel.isPanMode = true
            }

            Spacer()

            // Selected color preview
            if let bead = BeadColorLibrary.color(id: viewModel.selectedColorId) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(bead.color)
                        .frame(width: 22, height: 22)
                        .overlay(Circle().stroke(Color.gray.opacity(0.4), lineWidth: 1))
                    Text(bead.chineseName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.trailing, 4)
            }

            Button(action: onComplete) {
                Label("完成", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
    }

    @ViewBuilder
    private func toolButton(icon: String, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(label)
                    .font(.system(size: 8))
            }
            .frame(width: 42, height: 42)
            .foregroundStyle(enabled ? .primary : .tertiary)
        }
        .disabled(!enabled)
    }

    @ViewBuilder
    private func toolToggle(icon: String, label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(label)
                    .font(.system(size: 8))
            }
            .frame(width: 42, height: 42)
            .foregroundStyle(active ? Color.accentColor : .secondary)
            .background(active ? Color.accentColor.opacity(0.12) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}
