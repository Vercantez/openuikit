// Tasks demo app — data model. Owner: demo app (M7.5 second app).
//
// A todo app built on OpenUIKit exactly like the Settings demo: plain
// UIViewController subclasses, addTarget closures, UIView.animate for every
// state change. Hosted by `openhost --app tasks`.
//
// The model is deliberately tiny and reference-typed: a TaskItem is shared
// between the row that displays it and the detail screen that edits it, so
// an edit on the detail screen is already visible in the list by the time
// the pop transition finishes.

import OpenUIKit

/// Task priority. Drives the checkbox ring / fill color, the trailing dot,
/// the detail picker and the statistics bars.
public enum TaskPriority: Int, Hashable, CaseIterable {
    case low = 0, medium = 1, high = 2

    /// Picker/statistics label.
    public var title: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Med"
        case .high: return "High"
        }
    }

    /// Long form (statistics rows read better spelled out).
    public var longTitle: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    /// Semantic color so the app is dark-mode correct without a second
    /// palette (systemBlue/Orange/Red all have dark variants).
    public var color: UIColor {
        switch self {
        case .low: return .systemBlue
        case .medium: return .systemOrange
        case .high: return .systemRed
        }
    }
}

public final class TaskItem {
    public var title: String
    public var notes: String
    public var priority: TaskPriority
    public var isDone: Bool

    public init(title: String, notes: String, priority: TaskPriority,
                isDone: Bool = false) {
        self.title = title
        self.notes = notes
        self.priority = priority
        self.isDone = isDone
    }
}

/// Canned content: the seed list plus the pool "+ New Task" draws from.
public enum TasksData {
    public static func seed() -> (open: [TaskItem], done: [TaskItem]) {
        let open = [
            TaskItem(title: "Ship the layer cache",
                     notes: "Subtree composites are stable for two frames before they are flattened. Measure a sustained scroll at scale 2 afterwards and write the numbers into the performance table.",
                     priority: .high),
            TaskItem(title: "Review scroll physics",
                     notes: "Deceleration is 0.998 per millisecond and the rubber-band constant is 0.55. Re-check the bounce-back spring against the oracle capture before calling it done.",
                     priority: .high),
            TaskItem(title: "Draw the new icon set",
                     notes: "There are no SF Symbols in the portable stack, so every glyph is a Canvas path tuned to read at 29 points.",
                     priority: .medium),
            TaskItem(title: "Write the release notes",
                     notes: "Lead with the performance work, then the navigation transitions. Keep the honest list of what did not ship.",
                     priority: .medium),
            TaskItem(title: "Answer the design review",
                     notes: "Two open questions: the nav bar large-title behavior, and whether the back-swipe should scrub the scrim.",
                     priority: .low),
            TaskItem(title: "Water the office plants",
                     notes: "The fiddle-leaf fig by the window is the thirsty one. Everything else is on a two week rhythm.",
                     priority: .low),
            TaskItem(title: "Reply to the font vendor",
                     notes: "They want to know which variation axes we actually rasterize. Weight and optical size, nothing else so far.",
                     priority: .medium),
            TaskItem(title: "Order more coffee",
                     notes: "The good beans, whole, two kilos. The grinder setting is written on the tin.",
                     priority: .low),
        ]
        let done = [
            TaskItem(title: "Fix the switch animation",
                     notes: "The knob spring and the track fill now run on one clock, so a mid-flight toggle reverses instead of snapping.",
                     priority: .medium, isDone: true),
            TaskItem(title: "Book the offsite",
                     notes: "Three nights, twelve people, the place with the good coffee.",
                     priority: .low, isDone: true),
        ]
        return (open, done)
    }

    /// "+ New Task" pool, drawn in order and then wrapped around.
    public static let pool: [TaskItem] = [
        TaskItem(title: "Profile the render pass",
                 notes: "Find out where the first frame after a push spends its 40 milliseconds. Cold caches are the obvious suspect.",
                 priority: .high),
        TaskItem(title: "Sync the quartz patches",
                 notes: "Patch 004 landed upstream. Re-run the sync script and diff the vendored tree before committing.",
                 priority: .medium),
        TaskItem(title: "Pick up the dry cleaning",
                 notes: "Ticket is in the desk drawer. They close at six on weekdays.",
                 priority: .low),
        TaskItem(title: "Rename the golden fixtures",
                 notes: "The scene names drifted from the file names somewhere around the fortieth scene.",
                 priority: .medium),
        TaskItem(title: "Call the framing shop",
                 notes: "Ask whether they can do the oversize print without a mat.",
                 priority: .low),
        TaskItem(title: "Audit the touch pipeline",
                 notes: "Cancellation distance, delayed content touches and the pan slop all interact. Write the state machine down.",
                 priority: .high),
    ]

    /// A fresh copy of pool entry `index` (wrapping), so repeated taps never
    /// insert the same object twice.
    public static func newTask(at index: Int) -> TaskItem {
        let t = pool[index % pool.count]
        return TaskItem(title: t.title, notes: t.notes, priority: t.priority)
    }
}
