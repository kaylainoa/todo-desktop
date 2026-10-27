import AppKit
import SwiftUI

struct RootView: View {
    @ObservedObject var controller: PanelController
    @ObservedObject var store: TodoStore

    var body: some View {
        Group {
            if controller.expanded {
                CardView(store: store, collapse: controller.collapse)
            } else {
                BubbleView(remaining: store.remaining)
                    .modifier(MovesWindow(onClick: controller.toggle))
                    .contextMenu {
                        Button("Hide  (⌃⌥T to show)", action: controller.hide)
                        Toggle("Open at Login", isOn: Binding(
                            get: { LoginItem.isEnabled },
                            set: { LoginItem.set($0) }
                        ))
                        Divider()
                        Button("Quit Floating Todo") { NSApp.terminate(nil) }
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Collapsed bubble

struct BubbleView: View {
    let remaining: Int

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(LinearGradient(
                    colors: [Color(red: 0.47, green: 0.42, blue: 1.0), Color(red: 0.30, green: 0.24, blue: 0.88)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 52, height: 52)
                .overlay(
                    Image(systemName: "checklist")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(.white)
                )
                .shadow(color: .black.opacity(0.28), radius: 6, y: 3)

            if remaining > 0 {
                Text("\(remaining)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .frame(minWidth: 19, minHeight: 19)
                    .background(Capsule().fill(Color(red: 1.0, green: 0.27, blue: 0.33)))
                    .offset(x: 4, y: -4)
            }
        }
        .contentShape(Circle())
    }
}

// MARK: - Expanded card

struct CardView: View {
    @ObservedObject var store: TodoStore
    let collapse: () -> Void

    @State private var draft = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.5)
            input
            Divider().opacity(0.5)
            list
            footer
        }
        .background(VisualEffectBackground())
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08))
        )
        .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
        .padding(10)
        .onExitCommand(perform: collapse)
        .onAppear { inputFocused = true }
    }

    private var header: some View {
        HStack {
            Image(systemName: "checklist")
                .foregroundStyle(Color(red: 0.40, green: 0.34, blue: 0.96))
            Text("To-do")
                .font(.system(size: 14, weight: .semibold))
            Spacer()
            Button(action: collapse) {
                Image(systemName: "minus")
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(Color.primary.opacity(0.08)))
            }
            .buttonStyle(.plain)
            .help("Minimize (Esc)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .modifier(MovesWindow())
    }

    private var input: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
            TextField("Add a task…", text: $draft)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($inputFocused)
                .onSubmit {
                    store.add(draft)
                    draft = ""
                }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var list: some View {
        Group {
            if store.todos.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 22))
                    Text("Nothing to do. Nice!")
                        .font(.system(size: 12))
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(store.todos) { todo in
                            TodoRow(
                                todo: todo,
                                toggle: { store.toggle(todo) },
                                delete: { store.delete(todo) },
                                toggleSubtask: { subtask in store.toggleSubtask(subtask, in: todo) },
                                deleteSubtask: { subtask in store.deleteSubtask(subtask, in: todo) },
                                addSubtask: { title in store.addSubtask(to: todo, title: title) }
                            )
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var footer: some View {
        HStack {
            Text(store.remaining == 1 ? "1 left" : "\(store.remaining) left")
            Spacer()
            if store.todos.contains(where: \.done) {
                Button("Clear done", action: store.clearDone)
                    .buttonStyle(.plain)
            }
            Button {
                PanelController.shared.hide()
            } label: {
                Image(systemName: "eye.slash")
            }
            .buttonStyle(.plain)
            .help("Hide — press ⌃⌥T to bring it back")
            .padding(.leading, 8)
        }
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.03))
    }
}

struct TodoRow: View {
    let todo: Todo
    let toggle: () -> Void
    let delete: () -> Void
    let toggleSubtask: (Subtask) -> Void
    let deleteSubtask: (Subtask) -> Void
    let addSubtask: (String) -> Void

    @State private var hovering = false
    @State private var addingSubtask = false
    @State private var subtaskDraft = ""
    @FocusState private var subtaskFocused: Bool


    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button(action: toggle) {
                    Image(systemName: todo.done ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16))
                        .foregroundStyle(todo.done ? Color(red: 0.40, green: 0.34, blue: 0.96) : .secondary)
                }
                .buttonStyle(.plain)

                Text(todo.title)
                    .font(.system(size: 13))
                    .strikethrough(todo.done)
                    .foregroundStyle(todo.done ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    addingSubtask = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .opacity(hovering ? 1 : 0)
                .help("Add subtask")




                        
                Button(action: delete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .opacity(hovering ? 1 : 0)
                .help("Delete")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(hovering ? Color.primary.opacity(0.06) : .clear)
            .contentShape(Rectangle())
            .onHover { hovering = $0 }
            .onTapGesture(count: 1, perform: toggle)

            ForEach(todo.subtasks) { subtask in
                SubtaskRow(
                    subtask: subtask,
                    toggle: { toggleSubtask(subtask) },
                    delete: { deleteSubtask(subtask) }
                )
            }

            if addingSubtask {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                    TextField("Add a subtask…", text: $subtaskDraft)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .focused($subtaskFocused)
                        .onAppear { subtaskFocused = true }
                        .onSubmit {
                            if subtaskDraft.trimmingCharacters(in: .whitespaces).isEmpty {
                                addingSubtask = false
                            } else {
                                addSubtask(subtaskDraft)
                                subtaskDraft = ""
                            }
                        }
                        .onExitCommand {
                            subtaskDraft = ""
                            addingSubtask = false
                        }
                }
                .padding(.leading, 41)
                .padding(.trailing, 14)
                .padding(.vertical, 5)
            }
        }
    }
}

struct SubtaskRow: View {
    let subtask: Subtask
    let toggle: () -> Void
    let delete: () -> Void

    @State private var hovering = false

    var body: some View {
        HStack(spacing: 8) {
            Button(action: toggle) {
                Image(systemName: subtask.done ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 13))
                    .foregroundStyle(subtask.done ? Color(red: 0.40, green: 0.34, blue: 0.96) : .secondary)
            }
            .buttonStyle(.plain)

            Text(subtask.title)
                .font(.system(size: 12))
                .strikethrough(subtask.done)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: delete) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .opacity(hovering ? 1 : 0)
            .help("Delete subtask")
        }
        .padding(.leading, 40)
        .padding(.trailing, 14)
        .padding(.vertical, 4)
        .background(hovering ? Color.primary.opacity(0.06) : .clear)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .onTapGesture(count: 1, perform: toggle)
    }
}


// MARK: - Helpers

/// Lets a view drag the floating window around. If the mouse barely moved,
/// it counts as a click instead.
struct MovesWindow: ViewModifier {
    var onClick: (() -> Void)? = nil

    @State private var startMouse: NSPoint?
    @State private var startOrigin = NSPoint.zero
    @State private var dragging = false

    func body(content: Content) -> some View {
        content.gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard let panel = PanelController.shared.panel else { return }
                    let mouse = NSEvent.mouseLocation
                    if startMouse == nil {
                        startMouse = mouse
                        startOrigin = panel.frame.origin
                        dragging = false
                    }
                    guard let start = startMouse else { return }
                    let dx = mouse.x - start.x
                    let dy = mouse.y - start.y
                    if !dragging && hypot(dx, dy) > 3 { dragging = true }
                    if dragging {
                        panel.setFrameOrigin(NSPoint(x: startOrigin.x + dx, y: startOrigin.y + dy))
                    }
                }
                .onEnded { _ in
                    if !dragging { onClick?() }
                    startMouse = nil
                    dragging = false
                    PanelController.shared.savePosition()
                }
        )
    }
}

/// Frosted-glass background that blurs whatever is behind the window.
struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .popover
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
