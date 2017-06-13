import SwiftProtocolParser

extension MethodMember : MockrStringable {
   func toMockString(_ userInput: [String:String]) -> String {
      let paramNameEnd = "˸" //\u02f8
      var result = ""

      let paramName = parameters.map { $0.externalName ?? $0.localName }.map { "\($0)\(paramNameEnd)" }.joined(separator: "")
      let fullMethodName = parameters.isEmpty ? name : "\(name)_\(paramName)"
      let requiresBackingVar = returnType.map { $0 != "Void" } ?? false
      let backingVar = requiresBackingVar ? "_\(name)ReturnValue" : ""
      let countVar = "\(name)GetCallCount"
      let isOptional = type.hasSuffix("!") || type.hasSuffix("?")
      let backingVarType = isOptional ? type : "\(type)!"
      let backingVarDeclaration = "   private var \(backingVar): \(backingVarType)\n"
     
      var propDeclaration = "var \(name): \(type)" 

      if modifiers.count > 0 {
         var copy = userInput
         copy["separator"] = " "
         propDeclaration = modifiers.toMockString(copy) + " " + propDeclaration
      }

      if attributes.count > 0 {
         var copy = userInput
         copy["separator"] = " "
         propDeclaration = attributes.toMockString(copy) + " " + propDeclaration
      }

      propDeclaration = "   \(propDeclaration) {\n"

      let getterDeclaration = "      \(getterClause) {\n" + 
         "         \(getCountVar) = \(getCountVar) + 1\n" +
         "         return \(backingVar)\n" +
         "      }\n"
      let getCountVarDeclaration = "   private(set) var \(getCountVar): Int = 0\n"

      let setterDeclaration: String 
      let setCountVarDeclaration: String
      if setterClause.isEmpty {
         setterDeclaration = ""
         setCountVarDeclaration = ""
      } else {
         setCountVarDeclaration = "   private(set) var \(setCountVar): Int = 0\n"
         setterDeclaration = "      \(setterClause) {\n" + 
            "         \(setCountVar) = \(setCountVar) + 1\n" +
            "         \(backingVar) = newValue\n" +
            "      }\n"
      }

      propDeclaration = "\(propDeclaration)\(getterDeclaration)\(setterDeclaration)   }\n"

      let capVarName = String(name.characters.prefix(1)).uppercased() + String(name.characters.dropFirst())
      let funcDeclaration = "   func returnValueFor\(capVarName)(_ value: \(type)) {\n" +
         "      \(backingVar) = value\n" +
         "   }\n"

      result = "   //MARK: Synthesized Mock Property: \(name)\n" +
         backingVarDeclaration + "\n" +
         getCountVarDeclaration + "\n" +
         setCountVarDeclaration + "\n" +
         propDeclaration + "\n" +
         funcDeclaration
      
      return result
   }
}
