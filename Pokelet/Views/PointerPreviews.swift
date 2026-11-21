import QuartzCore
import SwiftUI

struct CharacterThumbnail: View {
    let style: PointerStyle

    var body: some View {
        Canvas { context, size in
            let width = min(size.width, size.height)
            var prefs = Preferences()
            prefs.style = style
            prefs.shadow = false
            context.withCGContext { cg in
                let factor = width / PointerArt.canvas
                cg.translateBy(x: (size.width - width) / 2 - 11 * factor, y: (size.height - width) / 2)
                cg.scaleBy(x: factor, y: factor)
                PointerArt.draw(in: cg, prefs: prefs)
            }
        }
        .accessibilityHidden(true)
    }
}

struct CharacterPreview: View {
    let prefs: Preferences
    let expanded: Bool
    var showsSecondaryClick = false
    @Environment(\.colorScheme) private var colourScheme
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var testDark: Bool?
    @State private var cadence = ClickCadence()
    @State private var click: PreviewClick?

    private var dark: Bool { testDark ?? (colourScheme == .dark) }
    private var reduced: Bool { systemReduceMotion || prefs.reducedMotion }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 20)
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Label(showsSecondaryClick ? "Click the preview to try it" : "Live preview", systemImage: "viewfinder")
                    .studioFont(.callout, weight: .semibold)
                Spacer()
                Button { testDark = !dark } label: {
                    Image(systemName: dark ? "sun.max" : "moon")
                        .studioFont(.callout)
                        .frame(width: 30, height: 27)
                }
                .buttonStyle(StudioButtonStyle(radius: 8))
                .accessibilityLabel(dark ? "Use light preview background" : "Use dark preview background")
                .help(dark ? "Use light preview background" : "Use dark preview background")
            }
            .padding(.leading, 15)
            .padding(.trailing, 10)
            .padding(.top, 8)

            Button { play(secondary: false) } label: {
                PreviewCanvas(prefs: prefs, click: click, reducedMotion: reduced)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                    .frame(height: expanded ? 200 : 139)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(StudioButtonStyle(radius: 12, dimWhenDisabled: false))
            .accessibilityHidden(!prefs.animate)
            .disabled(!prefs.animate)
            .padding(.horizontal, 12)
            .accessibilityLabel("Try primary click")
            .accessibilityHint("Plays the selected click animation for \(prefs.style.title)")
            .accessibilityIdentifier("studio.preview")

            HStack(spacing: 8) {
                Text(prefs.style.title).studioFont(.callout, weight: .semibold)
                Spacer()
                if showsSecondaryClick {
                    Button("Try secondary click") { play(secondary: true) }
                        .buttonStyle(StudioButtonStyle(radius: 7))
                        .disabled(!prefs.animate)
                } else {
                    Text(prefs.animate ? "Click to try" : "Animation off")
                }
            }
            .studioFont(.callout)
            .padding(.horizontal, 15)
            .padding(.vertical, 11)
        }
        .foregroundStyle(dark ? Color(red: 0.95, green: 0.91, blue: 0.98) : Color(red: 0.24, green: 0.16, blue: 0.32))
        .background {
            PreviewSurface(dark: dark)
                .clipShape(shape)
        }
        .overlay(shape.strokeBorder(StudioTheme.line).allowsHitTesting(false))
        .onChange(of: prefs.style) { _, _ in cadence = ClickCadence() }
        .onChange(of: prefs.animate) { _, _ in
            cadence = ClickCadence()
            click = nil
        }
    }

    private func play(secondary: Bool) {
        let now = CACurrentMediaTime()
        click = PreviewClick(when: now, count: cadence.record(at: now), secondary: secondary)
    }
}

private struct PreviewSurface: View {
    let dark: Bool

    var body: some View {
        let base = dark ? Color(red: 0.15, green: 0.11, blue: 0.20) : Color(red: 0.94, green: 0.90, blue: 0.97)
        let halo = dark ? Color(red: 0.31, green: 0.22, blue: 0.43) : Color(red: 0.83, green: 0.74, blue: 0.93)
        let ink = dark ? Color(red: 0.73, green: 0.60, blue: 0.89) : Color(red: 0.42, green: 0.26, blue: 0.58)
        ZStack {
            base
            RadialGradient(colors: [halo, base], center: .center, startRadius: 9, endRadius: 248)
            Canvas { context, size in
                let step: CGFloat = 15
                var dots = Path()
                for x in stride(from: size.width.truncatingRemainder(dividingBy: step) / 2,
                                to: size.width, by: step) {
                    for y in stride(from: size.height.truncatingRemainder(dividingBy: step) / 2,
                                    to: size.height, by: step) {
                        dots.addEllipse(in: CGRect(x: x, y: y, width: 1.25, height: 1.25))
                    }
                }
                context.fill(dots, with: .color(ink.opacity(dark ? 0.24 : 0.20)))
            }
        }
        .accessibilityHidden(true)
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
        private var artwork = Preferences()
        private var renderedArtwork: Preferences?
        private var lastClick: PreviewClick?
        private var lastReducedMotion = false
        private var scale: CGFloat = 0
        private var animated = true

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
            render()
        }

        override func viewDidChangeBackingProperties() {
            super.viewDidChangeBackingProperties()
            render()
        }

        fileprivate func update(prefs: Preferences, click: PreviewClick?, reducedMotion: Bool) {
            artwork.style = prefs.style
            artwork.palette = prefs.palette
            artwork.customColour = prefs.customColour
            artwork.size = prefs.size
            artwork.outline = prefs.outline
            artwork.shadow = prefs.shadow
            render()
            if reducedMotion != lastReducedMotion || prefs.animate != animated { pointer.reset() }
            lastReducedMotion = reducedMotion
            animated = prefs.animate
            guard prefs.animate, let click, click != lastClick else { return }
            lastClick = click
            let response = ClickResponse(prefs: prefs, count: click.count, reduced: reducedMotion)
            pointer.poke(energy: response.energy, secondary: click.secondary, motion: !reducedMotion,
                         effects: response.effects, celebration: response.celebration, reduced: reducedMotion)
        }

        private func render() {
            guard bounds.width > 0, bounds.height > 0 else { return }
            var preview = artwork
            preview.size = min(artwork.size * (bounds.height > 150 ? 2.2 : 1.42),
                               bounds.height * 1.25, bounds.width * 0.8)
            let nextScale = window?.backingScaleFactor ?? 2
            guard renderedArtwork != preview || scale != nextScale else { return }
            guard let image = PointerArt.image(prefs: preview, scale: nextScale) else { return }
            renderedArtwork = preview
            scale = nextScale
            pointer.configure(image: image, prefs: preview)
            placeArtwork()
        }

        private func placeArtwork() {
            guard let size = renderedArtwork?.size else { return }
            pointer.place(CGPoint(x: bounds.midX - size * 0.27, y: bounds.midY + size * 0.36), visible: true)
        }

        override func setFrameSize(_ newSize: NSSize) {
            super.setFrameSize(newSize)
            placeArtwork()
        }
    }
}
