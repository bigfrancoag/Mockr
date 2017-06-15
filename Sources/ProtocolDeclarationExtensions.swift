import SwiftProtocolParser

extension ProtocolDeclaration : MockrStringable {
   func toMockString(_ userInfo: [String:String]) -> String {
      let className = "Mock\(name)"

      //create thunks for each associated type
      let associatedTypes: [AssociatedTypeMember] = members.flatMap { 
         guard case .associatedType(let ascType) = $0 else { return nil }
         return ascType
      }

      var copy = userInfo
      copy["separator"] = ", "

      let associatedTypeGenerics: [(name: String, generic: String, genericThunk: String)] = associatedTypes
         .enumerated()
         .map {
            let inheritanceType = $0.element.inheritance.isEmpty ? "" : " : " + $0.element.inheritance.toMockString(copy)
            return (name: $0.element.name, generic: "T\($0.offset + 1)", genericThunk: "T\($0.offset + 1)\(inheritanceType)")
         }

      var thunkClause = associatedTypeGenerics.map { $0.genericThunk }.joined(separator: ", ")

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

         if let modifier = accessModifier, modifier != .internalAccess {
            copy["protocolModifier"] = modifier.toMockString(copy)
         }
         
         let memberString = members.toMockString(copy)
         result = "\(result)\(memberString)"
      }

      result = "\(result)\n}"
      return result
   }
}
