import SwiftProtocolParser

extension Inheritance : MockrStringable {
   func toMockString(_ userInfo: [String:String]) -> String {
      switch self {
      case .classRequirement:
         return "class"

      case .protocolRequirement(let proto):
         return proto
      }
   }
}
