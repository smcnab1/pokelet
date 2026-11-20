// Adapted from Quiet Pointer's ClickMonitor. MIT, see LICENSE.
import Foundation

struct ClickCadence {
    private static let window: TimeInterval = 0.65
    private var times = Array(repeating: -Double.infinity, count: 8)
    private var next = 0
    private var last = -Double.infinity

    mutating func record(at time: TimeInterval) -> Int {
        if time < last { self = ClickCadence() }
        last = time
        times[next] = time
        next = (next + 1) % times.count

        var count = 0
        for earlier in times where time - earlier <= Self.window { count += 1 }
        return count
    }
}
