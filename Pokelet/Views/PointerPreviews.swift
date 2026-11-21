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
    let stageHeight: CGFloat
    var showsSecondaryClick = false

    @Environment(\.colorScheme) private var colourScheme
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var testDark: Bool?
    @State private var secondaryPress = 0

    private var dark: Bool { testDark ?? (colourScheme == .dark) }
    private var ink: Color { dark ? Color(red: 0.96, green: 0.91, blue: 0.99) :
        Color(red: 0.24, green: 0.15, blue: 0.33) }
    private var hint: String {
        if prefs.clickOnly { return "Click to reveal" }
        return prefs.animate ? "Move and click to try" : "Move to try"
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 19)
        VStack(spacing: 0) {
            HStack {
                Label("Pointer preview", systemImage: "viewfinder")
                    .studioFont(.caption, weight: .semibold)
                Spacer()
                Button { testDark = !dark } label: {
                    Image(systemName: dark ? "sun.max" : "moon")
                        .frame(width: 29, height: 27)
                }
                .buttonStyle(StudioButtonStyle(radius: 8))
                .accessibilityLabel(dark ? "Use light preview background" : "Use dark preview background")
                .help(dark ? "Use light preview background" : "Use dark preview background")
            }
            PreviewCanvas(prefs: prefs, reducedMotion: systemReduceMotion || prefs.reducedMotion,
                          secondaryPress: secondaryPress)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            HStack(spacing: 10) {
                Text(prefs.style.title)
                    .studioFont(.body, weight: .semibold)
                Spacer(minLength: 4)
                if showsSecondaryClick {
                    Button { secondaryPress += 1 } label: {
                        Label("Try secondary click", systemImage: "cursorarrow.click.2")
                            .studioFont(.caption, weight: .semibold)
                            .padding(6)
                    }
                    .buttonStyle(StudioButtonStyle(radius: 7))
                    .disabled(!prefs.animate && !prefs.clickOnly)
                } else {
                    Text(hint)
                        .studioFont(.caption)
                        .foregroundStyle(ink.opacity(0.82))
                }
            }
            .padding(.bottom, 5)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 8)
        .frame(height: stageHeight)
        .foregroundStyle(ink)
        .background { PreviewSurface(dark: dark).clipShape(shape) }
        .overlay(shape.strokeBorder(ink.opacity(dark ? 0.15 : 0.20)).allowsHitTesting(false))
    }
}

private struct PreviewSurface: View {
    let dark: Bool

    var body: some View {
        let base = dark ? Color(red: 0.16, green: 0.11, blue: 0.21) :
            Color(red: 0.93, green: 0.88, blue: 0.95)
        let light = dark ? Color(red: 0.29, green: 0.20, blue: 0.38) :
            Color(red: 0.99, green: 0.95, blue: 0.94)
        let dot = dark ? Color(red: 0.78, green: 0.66, blue: 0.92) :
            Color(red: 0.43, green: 0.28, blue: 0.55)
        ZStack {
            base
            EllipticalGradient(colors: [light, base], center: UnitPoint(x: 0.47, y: 0.42),
                               startRadiusFraction: 0.06, endRadiusFraction: 0.77)
            Canvas { context, size in
                let step: CGFloat = 19
                var dots = Path()
                for x in stride(from: size.width.truncatingRemainder(dividingBy: step) / 2,
                                to: size.width, by: step) {
                    for y in stride(from: size.height.truncatingRemainder(dividingBy: step) / 2,
                                    to: size.height, by: step) {
                        dots.addEllipse(in: CGRect(x: x, y: y, width: 1.25, height: 1.25))
                    }
                }
                context.fill(dots, with: .color(dot.opacity(dark ? 0.23 : 0.21)))
            }
        }
        .accessibilityHidden(true)
    }
}

private struct PreviewCanvas: NSViewRepresentable {
    let prefs: Preferences
    let reducedMotion: Bool
    let secondaryPress: Int

    func makeNSView(context: Context) -> StageButton {
        let view = StageButton()
        view.update(prefs: prefs, reducedMotion: reducedMotion, secondaryPress: secondaryPress)
        return view
    }

    func updateNSView(_ view: StageButton, context: Context) {
        view.update(prefs: prefs, reducedMotion: reducedMotion, secondaryPress: secondaryPress)
    }

    static func dismantleNSView(_ view: StageButton, coordinator: ()) {
        view.stopInteraction()
    }

    final class StageButton: NSButton {
        private let pointer = PointerLayer()
        private var prefs = Preferences()
        private var renderedArtwork: Preferences?
        private var renderedScale: CGFloat = 0
        private var reducedMotion = false
        private var cadence = ClickCadence()
        private var motion = CursorMotion()
        private var trackedPoint: CGPoint?
        private var tracking: NSTrackingArea?
        private var reveal: DispatchWorkItem?
        private var stopTimer: Timer?
        private var lastSecondaryPress: Int?
        private var windowObservers: [NSObjectProtocol] = []

        init() {
            super.init(frame: .zero)
            title = ""
            isBordered = false
            setButtonType(.momentaryPushIn)
            setAccessibilityIdentifier("studio.preview")
            target = self
            action = #selector(press)
            wantsLayer = true
            layer?.masksToBounds = true
            layer?.addSublayer(pointer.root)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError() }

        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            if let tracking { removeTrackingArea(tracking) }
            let area = NSTrackingArea(rect: .zero, options: [.inVisibleRect, .activeInKeyWindow,
                                                            .mouseEnteredAndExited, .mouseMoved, .enabledDuringMouseDrag],
                                      owner: self)
            addTrackingArea(area)
            tracking = area
        }

        override func viewWillMove(toWindow newWindow: NSWindow?) {
            super.viewWillMove(toWindow: newWindow)
            let center = NotificationCenter.default
            windowObservers.forEach(center.removeObserver)
            windowObservers.removeAll()
            stopInteraction()
            guard let newWindow else { return }
            for name in [NSWindow.didResignKeyNotification, NSWindow.didChangeOcclusionStateNotification] {
                windowObservers.append(center.addObserver(forName: name, object: newWindow, queue: .main) { [weak self] note in
                    let window = note.object as? NSWindow
                    if name == NSWindow.didResignKeyNotification || window?.occlusionState.contains(.visible) == false {
                        self?.stopInteraction()
                    }
                })
            }
        }

        override func viewDidHide() {
            super.viewDidHide()
            stopInteraction()
        }

        override func layout() {
            super.layout()
            render()
        }

        override func viewDidChangeBackingProperties() {
            super.viewDidChangeBackingProperties()
            render()
        }

        override func mouseEntered(with event: NSEvent) { track(event) }
        override func mouseMoved(with event: NSEvent) { track(event) }
        override func mouseDragged(with event: NSEvent) { track(event) }
        override func rightMouseDragged(with event: NSEvent) { track(event) }
        override func otherMouseDragged(with event: NSEvent) { track(event) }
        override func mouseExited(with event: NSEvent) { stopInteraction() }
        override func mouseDown(with event: NSEvent) { click(event, secondary: false) }
        override func rightMouseDown(with event: NSEvent) { click(event, secondary: true) }
        override func otherMouseDown(with event: NSEvent) { click(event, secondary: true) }

        func update(prefs: Preferences, reducedMotion: Bool, secondaryPress: Int) {
            let styleChanged = self.prefs.style != prefs.style
            let visibilityChanged = self.prefs.clickOnly != prefs.clickOnly
            let motionChanged = self.reducedMotion != reducedMotion || self.prefs.animate != prefs.animate ||
                self.prefs.effects != prefs.effects || self.prefs.celebration != prefs.celebration ||
                self.prefs.directionBounce != prefs.directionBounce
            self.prefs = prefs
            self.reducedMotion = reducedMotion
            if visibilityChanged { cancelReveal() }
            if styleChanged || visibilityChanged || motionChanged {
                pointer.reset()
                cadence = ClickCadence()
                cancelStopTimer()
                motion = CursorMotion()
            }
            isEnabled = prefs.animate || prefs.clickOnly
            setAccessibilityLabel(prefs.animate ? "Try primary click" : prefs.clickOnly ? "Reveal character" : "Pointer preview")
            setAccessibilityHelp("Preview for \(prefs.style.title).")
            render(crossfade: styleChanged && !reducedMotion)
            if let lastSecondaryPress, lastSecondaryPress != secondaryPress { react(secondary: true) }
            lastSecondaryPress = secondaryPress
        }

        func stopInteraction() {
            let wasTracking = trackedPoint != nil
            trackedPoint = nil
            cancelStopTimer()
            cancelReveal()
            cadence = ClickCadence()
            motion = CursorMotion()
            pointer.reset()
            if wasTracking { render() }
        }

        private func cancelReveal() {
            reveal?.cancel()
            reveal = nil
        }

        @objc private func press() { react(secondary: false) }

        private func click(_ event: NSEvent, secondary: Bool) {
            track(event)
            if trackedPoint != nil { react(secondary: secondary) }
        }

        private func track(_ event: NSEvent) {
            let point = convert(event.locationInWindow, from: nil)
            guard visibleRect.contains(point) else { stopInteraction(); return }
            let previous = trackedPoint
            trackedPoint = point
            if previous == nil { render() } else { placeArtwork() }

            guard prefs.directionBounce, !reducedMotion, !prefs.clickOnly || reveal != nil else { return }
            let now = CACurrentMediaTime()
            if let previous, let turn = motion.turn(from: previous, to: point, now: now) {
                pointer.wobble(turn: turn)
            }
            if let stopTimer {
                stopTimer.fireDate = Date(timeIntervalSinceNow: CursorMotion.stopDelay)
            } else {
                let timer = Timer(timeInterval: CursorMotion.stopDelay, repeats: false) { [weak self] _ in
                    guard let self else { return }
                    self.stopTimer = nil
                    if let turn = self.motion.stopped(at: CACurrentMediaTime()) {
                        self.pointer.wobble(turn: turn)
                    }
                }
                stopTimer = timer
                RunLoop.main.add(timer, forMode: .common)
            }
        }

        private func cancelStopTimer() {
            stopTimer?.invalidate()
            stopTimer = nil
        }

        private func react(secondary: Bool) {
            guard window?.isVisible == true, window?.isMiniaturized == false, !isHiddenOrHasHiddenAncestor,
                  !visibleRect.isEmpty, prefs.animate || prefs.clickOnly else { return }
            if prefs.clickOnly {
                cancelReveal()
                let hide = DispatchWorkItem { [weak self] in
                    self?.reveal = nil
                    self?.placeArtwork()
                }
                reveal = hide
                placeArtwork()
                DispatchQueue.main.asyncAfter(deadline: .now() + ClickResponse.revealDuration, execute: hide)
            }
            guard prefs.animate else { return }
            let response = ClickResponse(prefs: prefs, count: cadence.record(at: CACurrentMediaTime()),
                                         reduced: reducedMotion)
            pointer.poke(at: trackedPoint ?? pointer.artworkPosition, energy: response.energy, secondary: secondary, motion: !reducedMotion,
                         effects: response.effects, celebration: response.celebration, reduced: reducedMotion)
        }

        private func render(crossfade: Bool = false) {
            guard bounds.width > 0, bounds.height > 0 else { return }
            var artwork = Preferences()
            artwork.style = prefs.style
            artwork.palette = prefs.palette
            artwork.customColour = prefs.customColour
            artwork.outline = prefs.outline
            artwork.shadow = prefs.shadow
            artwork.size = trackedPoint == nil
                ? min(prefs.size * 2.6, bounds.height * 1.13, bounds.width * 0.73) : prefs.size
            let scale = window?.backingScaleFactor ?? 2
            if renderedArtwork != artwork || renderedScale != scale,
               let image = PointerArt.image(prefs: artwork, scale: scale) {
                renderedArtwork = artwork
                renderedScale = scale
                pointer.configure(image: image, prefs: artwork, crossfade: crossfade)
            }
            placeArtwork()
        }

        private func placeArtwork() {
            guard let size = renderedArtwork?.size else { return }
            if let point = trackedPoint {
                let companion = prefs.keepNative || prefs.clickOnly
                let position = companion ? CursorGeometry.companion(at: point, in: bounds, size: size) : point
                pointer.place(position, visible: !prefs.clickOnly || reveal != nil)
            } else {
                pointer.place(CGPoint(x: bounds.midX - size * 0.25, y: bounds.midY + size * 0.34), visible: true)
            }
        }
    }
}
