import SwiftProtocolParser

extension AssociatedTypeMember : MockrStringable {
   func toMockString(_ userInfo: [String:String]) -> String {
      let concreteType = userInfo[name] ?? "Any"

      var line = "typealias \(name) = \(concreteType)"

      if let modifier = accessModifier {
         line = modifier.toMockString(userInfo) + " " + line
      }

      if attributes.count > 0 { var copy = userInfo
         copy["separator"] = " "
         line = attributes.toMockString(copy) + " " + line
      }
      
      return "   \(line)"
   }
}
