import SwiftProtocolParser

extension DeclarationModifier : MockrStringable {
   func toMockString(_ userInfo: [String:String]) -> String {
      switch self {
      case .access(let modifier):
         return modifier.toMockString(userInfo)

      case .setterAccess(let modifier):
         return "\(modifier.toMockString(userInfo))(set)"

      case .isMutating:
         return "mutating"

      case .isNonmutating:
         return "nonmutating"

      case .isStatic:
         return "static"

      case .isOptional:
         return "optional"
      }
   }
}
