
import Cocoa
import Darwin.Mach
import os

private let machTimebaseRatio: Double = {
    var info = mach_timebase_info_data_t()
    mach_timebase_info(&info)
    return Double(info.numer) / Double(info.denom)
}()

@inline(__always)
private func secondsToMachTicks(_ seconds: Double) -> UInt64 {
    let nanos = seconds * 1_000_000_000.0
    return UInt64(nanos / machTimebaseRatio)
}

@inline(__always)
private func precisionSleep(_ seconds: Double, shouldStop: () -> Bool) {
    guard seconds > 0 else { return }

    let sliceSeconds: Double = 0.005
    let deadline = mach_absolute_time() + secondsToMachTicks(seconds)

    while !shouldStop() {
        let now = mach_absolute_time()
        if now >= deadline { break }

        let remaining = Double(deadline - now) * machTimebaseRatio / 1_000_000_000.0
        let nextSlice = min(remaining, sliceSeconds)
        if nextSlice <= 0 { break }

        mach_wait_until(now + secondsToMachTicks(nextSlice))
    }
}

class ClickEngine {
    private let settings: AppSettings

    private let runningLock = OSAllocatedUnfairLock(initialState: false)

    private var clickThread: Thread?
    private var clickCount = 0
    private let source = CGEventSource(stateID: .combinedSessionState)

    init(settings: AppSettings) {
        self.settings = settings
    }

    func start() {
        print("ClickEngine: START requested")

        let alreadyRunning = runningLock.withLock { state -> Bool in
            if state { return true }
            state = true
            return false
        }
        guard !alreadyRunning else {
            print("ClickEngine: Already running")
            return
        }

        clickCount = 0

        DispatchQueue.main.async { self.settings.isRunning = true }

        let t = Thread(target: self, selector: #selector(runLoop), object: nil)
        t.name = "com.autoclicker.engine"
        t.qualityOfService = .userInteractive
        t.start()
        clickThread = t
    }

    func stop() {
        runningLock.withLock { $0 = false }
    }

    @inline(__always)
    private var isRunning: Bool {
        runningLock.withLock { $0 }
    }

    @objc private func runLoop() {
        print("ClickEngine: Entering runLoop")

        while isRunning {
            let cps = settings.isRandomCPS
                ? Double.random(in: 1.0...max(settings.cps, 1.0))
                : settings.cps

            if settings.isClickLimitEnabled {
                if clickCount >= settings.clickLimit {
                    print("ClickEngine: Click limit reached (\(settings.clickLimit)). Stopping.")
                    runningLock.withLock { $0 = false }
                    break
                }
            }

            let mouseLoc = CGEvent(source: nil)?.location ?? .zero
            let downEvent = createMouseEvent(type: .down, location: mouseLoc)
            let upEvent   = createMouseEvent(type: .up,   location: mouseLoc)

            if settings.isUnlimited {
                downEvent?.post(tap: .cghidEventTap)
                upEvent?.post(tap: .cghidEventTap)
                clickCount += 1
                // Tiny yield so we don't hard-spin and consume a full CPU core.
                precisionSleep(0.0005, shouldStop: { self.isRunning == false })
            } else {
                let totalPeriod  = 1.0 / max(cps, 1.0)
                let dutyCycle    = settings.clickDutyCycle / 100.0
                let holdDuration = totalPeriod * dutyCycle
                let waitDuration = totalPeriod - holdDuration

                if let de = downEvent, let ue = upEvent {
                    de.post(tap: .cghidEventTap)
                    if holdDuration > 0 {
                        // Hold phase: also sliced so stop() is responsive.
                        precisionSleep(holdDuration, shouldStop: { self.isRunning == false })
                    }
                    ue.post(tap: .cghidEventTap)
                    clickCount += 1
                }

                if waitDuration > 0 {
                    precisionSleep(waitDuration, shouldStop: { self.isRunning == false })
                }
            }
        }

        print("ClickEngine: Exiting runLoop")

        DispatchQueue.main.async { [weak self] in
            self?.settings.isRunning = false
        }
    }

    private func createMouseEvent(type: MouseEventType, location: CGPoint) -> CGEvent? {
        let (cgDown, cgUp, cgButton) = mouseButtonMapping(for: settings.mouseButton)
        let actualType = type == .down ? cgDown : cgUp
        return CGEvent(mouseEventSource: source,
                       mouseType: actualType,
                       mouseCursorPosition: location,
                       mouseButton: cgButton)
    }

    private enum MouseEventType {
        case down
        case up
    }

    private func mouseButtonMapping(for button: MouseButton) -> (CGEventType, CGEventType, CGMouseButton) {
        switch button {
        case .left:   return (.leftMouseDown,  .leftMouseUp,   .left)
        case .middle: return (.otherMouseDown, .otherMouseUp,  .center)
        case .right:  return (.rightMouseDown, .rightMouseUp,  .right)
        }
    }
}
