import Foundation
import SwiftUI

// MARK: - Item Category

enum ItemCategory: String, Codable, CaseIterable, Identifiable {
    case uncategorized
    case keep
    case donate
    case trash
    case sell

    var id: String { rawValue }

    var label: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .uncategorized: return .gray
        case .keep: return .blue
        case .donate: return .green
        case .trash: return .red
        case .sell: return .orange
        }
    }

    var icon: String {
        switch self {
        case .uncategorized: return "questionmark.circle"
        case .keep: return "checkmark.circle.fill"
        case .donate: return "heart.circle.fill"
        case .trash: return "trash.circle.fill"
        case .sell: return "dollarsign.circle.fill"
        }
    }
}

// MARK: - Task Frequency

enum TaskFrequency: String, Codable, CaseIterable, Identifiable {
    case daily
    case weekly
    case monthly

    var id: String { rawValue }

    var label: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .daily: return .blue
        case .weekly: return .purple
        case .monthly: return .orange
        }
    }

    var calendarComponent: Calendar.Component {
        switch self {
        case .daily: return .day
        case .weekly: return .weekOfYear
        case .monthly: return .month
        }
    }

    var intervalDays: Int {
        switch self {
        case .daily: return 1
        case .weekly: return 7
        case .monthly: return 30
        }
    }
}

// MARK: - Room Icon

enum RoomIcon: String, Codable, CaseIterable, Identifiable {
    case kitchen
    case livingRoom
    case bedroom
    case bathroom
    case office
    case garage
    case basement
    case attic
    case diningRoom
    case laundry
    case closet
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .livingRoom: return "Living Room"
        case .diningRoom: return "Dining Room"
        default: return rawValue.capitalized
        }
    }

    var systemImage: String {
        switch self {
        case .kitchen: return "fork.knife"
        case .livingRoom: return "sofa.fill"
        case .bedroom: return "bed.double.fill"
        case .bathroom: return "shower.fill"
        case .office: return "desktopcomputer"
        case .garage: return "car.fill"
        case .basement: return "stairs"
        case .attic: return "triangle.fill"
        case .diningRoom: return "cup.and.saucer.fill"
        case .laundry: return "washer.fill"
        case .closet: return "door.left.hand.closed"
        case .other: return "square.grid.2x2.fill"
        }
    }

    var defaultCleaningTasks: [(name: String, frequency: TaskFrequency)] {
        switch self {
        case .kitchen:
            return [
                ("Wipe counters", .daily),
                ("Do dishes", .daily),
                ("Mop floor", .weekly),
                ("Clean oven", .monthly),
                ("Clean refrigerator", .monthly)
            ]
        case .livingRoom:
            return [
                ("Vacuum floor", .weekly),
                ("Dust surfaces", .weekly),
                ("Clean windows", .monthly)
            ]
        case .bedroom:
            return [
                ("Make bed", .daily),
                ("Vacuum floor", .weekly),
                ("Change sheets", .weekly),
                ("Dust furniture", .monthly)
            ]
        case .bathroom:
            return [
                ("Wipe sink and counter", .daily),
                ("Clean toilet", .weekly),
                ("Scrub shower/tub", .weekly),
                ("Mop floor", .weekly),
                ("Deep clean grout", .monthly)
            ]
        case .office:
            return [
                ("Tidy desk", .daily),
                ("Vacuum floor", .weekly),
                ("Dust electronics", .monthly)
            ]
        case .garage:
            return [
                ("Sweep floor", .weekly),
                ("Organize tools", .monthly)
            ]
        case .basement:
            return [
                ("Check for moisture", .weekly),
                ("Sweep floor", .monthly),
                ("Organize storage", .monthly)
            ]
        case .attic:
            return [
                ("Check for leaks", .monthly),
                ("Organize storage", .monthly)
            ]
        case .diningRoom:
            return [
                ("Wipe table", .daily),
                ("Vacuum floor", .weekly),
                ("Polish furniture", .monthly)
            ]
        case .laundry:
            return [
                ("Wipe machines", .weekly),
                ("Clean lint trap", .weekly),
                ("Deep clean washer", .monthly)
            ]
        case .closet:
            return [
                ("Organize clothes", .monthly),
                ("Vacuum floor", .monthly)
            ]
        case .other:
            return [
                ("General tidy", .weekly),
                ("Deep clean", .monthly)
            ]
        }
    }
}
