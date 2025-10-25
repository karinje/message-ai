import SwiftUI

struct PriorityBadgeView: View {
    let priority: AIPriority
    let size: BadgeSize
    let showBackground: Bool
    
    init(priority: AIPriority, size: BadgeSize = .medium, showBackground: Bool = true) {
        self.priority = priority
        self.size = size
        self.showBackground = showBackground
    }
    
    var body: some View {
        if priority != .normal {
            HStack(spacing: size.spacing) {
                Image(systemName: priority.icon)
                    .font(size.font)
                    .foregroundColor(priority.color)
                
                if size == .large {
                    Text(priority.rawValue.capitalized)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(priority.color)
                }
            }
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background(showBackground ? priority.backgroundColor : Color.clear)
            .cornerRadius(size.cornerRadius)
        }
    }
    
    enum BadgeSize {
        case small
        case medium
        case large
        
        var font: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .caption
            case .large: return .body
            }
        }
        
        var spacing: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 4
            case .large: return 6
            }
        }
        
        var horizontalPadding: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 6
            case .large: return 8
            }
        }
        
        var verticalPadding: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 3
            case .large: return 4
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 6
            case .large: return 8
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        PriorityBadgeView(priority: .urgent, size: .small)
        PriorityBadgeView(priority: .urgent, size: .medium)
        PriorityBadgeView(priority: .urgent, size: .large)
        
        PriorityBadgeView(priority: .important, size: .small)
        PriorityBadgeView(priority: .important, size: .medium)
        PriorityBadgeView(priority: .important, size: .large)
        
        PriorityBadgeView(priority: .normal)
    }
    .padding()
}
