import AppKit
import SwiftUI

/// Borderless panel that can still take keyboard focus (for typing todos)
/// without activating the app or stealing focus from whatever you're in.
final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

final class PanelController: ObservableObject {
    static let shared = PanelController()

    static let bubbleSize = NSSize(width: 72, height: 72)
    static let cardSize = NSSize(width: 320, height: 440)

    @Published private(set) var expanded = false
    let store = TodoStore()
    private(set) var panel: FloatingPanel!

    private var bubbleOrigin = NSPoint.zero
    private var cardFrameAtExpand = NSRect.zero
    // Which corner of the card lines up with the bubble, so it opens toward the screen center.
    private var anchorRight = false
    private var anchorTop = true

    func setup() {
        let origin = savedOrigin() ?? defaultOrigin()
        panel = FloatingPanel(
            contentRect: NSRect(origin: origin, size: Self.bubbleSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false

        let host = NSHostingView(rootView: RootView(controller: self, store: store))
        host.sizingOptions = []
        panel.contentView = host
        panel.orderFrontRegardless()
    }

    func toggle() {
        expanded ? collapse() : expand()
    }

    /// What the keyboard shortcut does: bring the button back if it's hidden,
    /// then open or close the list.
    func summon() {
        if !panel.isVisible {
            panel.orderFrontRegardless()
        }
        toggle()
    }

    func hide() {
        collapse()
        panel.orderOut(nil)
    }

    func expand() {
        guard !expanded else { return }
        let bubble = panel.frame
        bubbleOrigin = bubble.origin

        let visible = (panel.screen ?? NSScreen.main)?.visibleFrame ?? bubble
        anchorRight = bubble.midX > visible.midX
        anchorTop = bubble.midY > visible.midY

        let size = Self.cardSize
        var frame = NSRect(
            x: anchorRight ? bubble.maxX - size.width : bubble.minX,
            y: anchorTop ? bubble.maxY - size.height : bubble.minY,
            width: size.width,
            height: size.height
        )
        frame = clamp(frame, to: visible)
        cardFrameAtExpand = frame

        expanded = true
        panel.setFrame(frame, display: true)
        panel.makeKey()
    }

    func collapse() {
        guard expanded else { return }
        let card = panel.frame
        let size = Self.bubbleSize
        // If the card was dragged, drop the bubble where the card now is.
        let origin = card == cardFrameAtExpand ? bubbleOrigin : NSPoint(
            x: anchorRight ? card.maxX - size.width : card.minX,
            y: anchorTop ? card.maxY - size.height : card.minY
        )
        expanded = false
        panel.setFrame(NSRect(origin: origin, size: size), display: true)
        savePosition()
    }

    func savePosition() {
        guard !expanded else { return }
        UserDefaults.standard.set(panel.frame.minX, forKey: "bubbleX")
        UserDefaults.standard.set(panel.frame.minY, forKey: "bubbleY")
    }

    private func savedOrigin() -> NSPoint? {
        let d = UserDefaults.standard
        guard d.object(forKey: "bubbleX") != nil else { return nil }
        let p = NSPoint(x: d.double(forKey: "bubbleX"), y: d.double(forKey: "bubbleY"))
        let rect = NSRect(origin: p, size: Self.bubbleSize)
        // Ignore positions on a monitor that's no longer connected.
        return NSScreen.screens.contains { $0.visibleFrame.intersects(rect) } ? p : nil
    }

    private func defaultOrigin() -> NSPoint {
        let visible = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        return NSPoint(x: visible.maxX - Self.bubbleSize.width - 24,
                       y: visible.maxY - Self.bubbleSize.height - 24)
    }

    private func clamp(_ frame: NSRect, to visible: NSRect) -> NSRect {
        var r = frame
        r.origin.x = min(max(r.minX, visible.minX), visible.maxX - r.width)
        r.origin.y = min(max(r.minY, visible.minY), visible.maxY - r.height)
        return r
    }
}
