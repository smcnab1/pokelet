import QuartzCore
import SwiftUI

/// Two fixed swatches show the same artwork against a light and dark surface.
struct SplitPointerPreview: View {
    let prefs: Preferences
    let style: PointerStyle

    var body: some View {
        Canvas { context, size in
            let artworkSize = min(size.height - 4, size.width - 4, max(36, prefs.size * 0.72))
            context.withCGContext { cg in
                var preview = prefs
                preview.style = style
                cg.translateBy(x: (size.width - artworkSize) / 2 - 5, y: (size.height - artworkSize) / 2 - 3)
                cg.scaleBy(x: artworkSize / PointerArt.canvas, y: artworkSize / PointerArt.canvas)
                PointerArt.draw(in: cg, prefs: preview)
            }
        }
        .background {
            HStack(spacing: 0) {
                Color(nsColor: NSColor(srgbRed: 0.93, green: 0.91, blue: 0.88, alpha: 1))
                Color(nsColor: NSColor(srgbRed: 0.17, green: 0.16, blue: 0.19, alpha: 1))
            }
            .clipShape(.rect(cornerRadius: 6))
        }
        .accessibilityHidden(true)
    }
}

struct AnimationPreview: View {
    let prefs: Preferences
    let reducedMotion: Bool
    @State private var cadence = ClickCadence()
    @State private var click: PreviewClick?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PreviewCanvas(prefs: prefs, click: click, reducedMotion: reducedMotion)
                .frame(height: 153)
                .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 7))
                .accessibilityHidden(true)
            HStack {
                Button("Try Left Click") { play(secondary: false) }
                Button("Try Right Click") { play(secondary: true) }
            }
            .disabled(!prefs.animate)
        }
        .onChange(of: prefs.style) { _, _ in cadence = ClickCadence() }
    }

    private func play(secondary: Bool) {
        let now = CACurrentMediaTime()
        click = PreviewClick(when: now, count: cadence.record(at: now), secondary: secondary)
    }
}

private struct PreviewClick: Equatable {
    let when: CFTimeInterval
    let count: Int
    let secondary: Bool
}

private struct PreviewCanvas: NSViewRepresentable {
    let prefs: Preferences
    let click: PreviewClick?
    let reducedMotion: Bool

    func makeNSView(context: Context) -> LayerView { LayerView() }

    func updateNSView(_ view: LayerView, context: Context) {
        view.update(prefs: prefs, click: click, reducedMotion: reducedMotion)
    }

    final class LayerView: NSView {
        private let pointer = PointerLayer()
        private var cachedPrefs: Preferences?
        private var lastClick: PreviewClick?
        private var lastReducedMotion = false
        private var scale: CGFloat = 0

        init() {
            super.init(frame: .zero)
            wantsLayer = true
            layer?.masksToBounds = true
            layer?.addSublayer(pointer.root)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError() }

        override func layout() {
            super.layout()
            pointer.place(CGPoint(x: bounds.midX - 12, y: bounds.midY + 30), visible: true)
        }

        override func viewDidChangeBackingProperties() {
            super.viewDidChangeBackingProperties()
            if let cachedPrefs { render(cachedPrefs) }
        }

        fileprivate func update(prefs: Preferences, click: PreviewClick?, reducedMotion: Bool) {
            render(prefs)
            if reducedMotion != lastReducedMotion { pointer.reset() }
            lastReducedMotion = reducedMotion
            guard prefs.animate, let click, click != lastClick else { return }
            lastClick = click
            let response = ClickResponse(prefs: prefs, count: click.count, reduced: reducedMotion)
            pointer.poke(energy: response.energy, secondary: click.secondary, motion: !reducedMotion,
                         effects: response.effects, celebration: response.celebration, reduced: reducedMotion)
        }

        private func render(_ prefs: Preferences) {
            let nextScale = window?.backingScaleFactor ?? 2
            guard cachedPrefs != prefs || scale != nextScale else { return }
            cachedPrefs = prefs
            scale = nextScale
            if let image = PointerArt.image(prefs: prefs, scale: scale) {
                pointer.configure(image: image, prefs: prefs)
            }
        }
    }
}
