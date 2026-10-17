import Foundation

enum Mood: String, CaseIterable, Codable, Identifiable {
    case happy
    case loved
    case calm
    case excited
    case tired
    case sad
    case thinking

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .happy: return "😄"
        case .loved: return "🥰"
        case .calm: return "😌"
        case .excited: return "🤩"
        case .tired: return "😮‍💨"
        case .sad: return "😢"
        case .thinking: return "🤔"
        }
    }

    var displayName: String {
        switch self {
        case .happy: return "开心"
        case .loved: return "心动"
        case .calm: return "平静"
        case .excited: return "兴奋"
        case .tired: return "疲惫"
        case .sad: return "难过"
        case .thinking: return "沉思"
        }
    }
}
