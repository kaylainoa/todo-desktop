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
                    colors: [.themeLight, .themeDark],
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
                .foregroundStyle(Color.theme)
            Text("To-do")
                .font(.system(size: 14, weight: .semibold))
            // Re-checks every minute so the date rolls over at midnight.
            TimelineView(.periodic(from: .now, by: 60)) { context in
                Text(context.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
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
                .help("Tip: use commas for subtasks — \"Project 1, write analysis, finalize\"")
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
                    VStack(spacing: 0) {
                        ForEach(store.orderedTodos) { todo in
                            TodoRow(
                                todo: todo,
                                toggle: { withAnimation(.reorder) { store.toggle(todo) } },
                                delete: { store.delete(todo) },
                                toggleSubtask: { subtask in
                                    withAnimation(.reorder) { store.toggleSubtask(subtask, in: todo) }
                                },
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
                CheckCircle(done: todo.done, size: 16, action: toggle)

                Text(todo.title)
                    .font(.system(size: 13))
                    .scribbledOut(todo.done)
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

            ForEach(todo.subtasks.doneLast) { subtask in
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
            CheckCircle(done: subtask.done, size: 13, action: toggle)

            Text(subtask.title)
                .font(.system(size: 12))
                .scribbledOut(subtask.done)
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
    }
}


/// The round checkbox. On hover it grows a little and previews the checkmark.
struct CheckCircle: View {
    let done: Bool
    let size: CGFloat
    let action: () -> Void

    @State private var hovering = false
    // A local copy of `done`, animated on its own so the fill pops right away
    // while the row's slide (and its delay) moves the circle with the text.
    @State private var shownDone: Bool

    init(done: Bool, size: CGFloat, action: @escaping () -> Void) {
        self.done = done
        self.size = size
        self.action = action
        _shownDone = State(initialValue: done)
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: shownDone ? "checkmark.circle.fill" : (hovering ? "checkmark.circle" : "circle"))
                .font(.system(size: size))
                .foregroundStyle(shownDone || hovering ? Color.theme : .secondary)
                .scaleEffect(hovering ? 1.18 : 1)
        }
        .buttonStyle(.plain)
        .onHover { isHovering in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) { hovering = isHovering }
        }
        .onChange(of: done) { newValue in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { shownDone = newValue }
        }
        .help(done ? "Mark as not done" : "Mark as done")
    }
}

// MARK: - Helpers

extension Color {
    /// The app's main color. Change these three to re-theme everything.
    static let theme = Color(red: 102 / 255, green: 87 / 255, blue: 245 / 255)        // #6657F5
    static let themeLight = Color(red: 120 / 255, green: 107 / 255, blue: 255 / 255)  // #786BFF
    static let themeDark = Color(red: 77 / 255, green: 61 / 255, blue: 224 / 255)     // #4D3DE0
}

extension Animation {
    /// Used when checking items off, so they glide to their new spot.
    /// The short delay lets the scribble finish drawing before the row slides away.
    static let reorder = Animation.spring(response: 0.5, dampingFraction: 0.95).delay(0.3)
}

/// A straight line across the middle of whatever it's drawn over.
struct StrikeLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY + 0.5
        path.move(to: CGPoint(x: rect.minX - 1, y: midY))
        path.addLine(to: CGPoint(x: rect.maxX + 1, y: midY))
        return path
    }
}

/// Crosses a view out with a gray line that draws itself left to right.
struct ScribbledOut: ViewModifier {
    let done: Bool
    // How much of the line is drawn (0 to 1). Animated on its own, separate from
    // the row sliding, so the line stays glued to the text while it moves.
    @State private var progress: CGFloat

    init(done: Bool) {
        self.done = done
        _progress = State(initialValue: done ? 1 : 0)
    }

    func body(content: Content) -> some View {
        content
            .overlay(
                StrikeLine()
                    .trim(from: 0, to: progress)
                    .stroke(Color.secondary, style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))
            )
            .onChange(of: done) { newValue in
                withAnimation(.easeInOut(duration: 0.3)) { progress = newValue ? 1 : 0 }
            }
    }
}

extension View {
    func scribbledOut(_ done: Bool) -> some View {
        modifier(ScribbledOut(done: done))
    }
}

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
