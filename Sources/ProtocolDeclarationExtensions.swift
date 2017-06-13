import SwiftProtocolParser

extension ProtocolDeclaration : MockrStringable {
   func toMockString(_ userInfo: [String:String]) -> String {
      let className = "Mock\(name)"

      //create thunks for each associated type
      let associatedTypes: [AssociatedTypeMember] = members.flatMap { 
         guard case .associatedType(let ascType) = $0 else { return nil }
         return ascType
      }

      let associatedTypeGenerics: [(name: String, generic: String)] = associatedTypes
         .enumerated()
         .map { (name: $0.element.name, generic: "T\($0.offset + 1)") }

      var thunkClause = associatedTypeGenerics.map { $0.generic }.joined(separator: ", ")

      if !thunkClause.isEmpty {
         thunkClause = "<\(thunkClause)>"
      }

      var result = "class \(className)\(thunkClause) : \(name) {\n"

      if let modifier = accessModifier {
         result = "\(modifier.toMockString(userInfo)) \(result)"
      }

      if attributes.count > 0 {
         var copy = userInfo
         copy["separator"] = " "
         result = "\(attributes.toMockString(copy)) \(result)"
      }

      if members.count > 0 {
         var copy = userInfo
         copy["separator"] = "\n"


         associatedTypeGenerics.forEach {
               copy[$0.name] = $0.generic
            }
         
         let memberString = members.toMockString(copy)
         result = "\(result)\(memberString)"
      }

      result = "\(result)\n}"
      return result
   }
}
