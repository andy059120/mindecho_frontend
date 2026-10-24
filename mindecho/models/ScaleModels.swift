import Foundation

struct ScaleQuestion {
    let text: String
    let isReverse: Bool
}

struct ScaleMeta: Identifiable {
    let action: TestAction
    let code: String
    let title: String
    let questionCount: Int
    let instructions: String?
    let reverseIndices: Set<Int>
    
    var id: String { code }
}

struct ScaleItem: Identifiable {
    let id = UUID()
    let type: ItemType
    
    enum ItemType {
        case section(String)
        case question(ScaleQuestion)
    }
    
    static func section(_ title: String) -> ScaleItem {
        ScaleItem(type: .section(title))
    }
    
    static func question(_ text: String, isReverse: Bool = false) -> ScaleItem {
        ScaleItem(type: .question(ScaleQuestion(text: text, isReverse: isReverse)))
    }
}

struct ScaleDefinition: Identifiable {
    let id = UUID()
    let title: String
    let instructions: String?
    let items: [ScaleItem]
}
