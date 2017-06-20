import SwiftProtocolParser

extension SubscriptMember : MockrStringable {
   func toMockString(_ userInput: [String:String]) -> String {
      let paramName = parameters.map { $0.externalName ?? $0.localName }.map { "\($0)_" }.joined(separator: "")
      let name = "subscript_\(paramName)"
      let backingVar = "_\(name)ReturnValue"

      let isOptional = returnType.hasSuffix("!") || returnType.hasSuffix("?")
      let backingVarType = isOptional ? returnType : "\(returnType)!"
      let backingVarDeclaration = "   private var \(backingVar): \(backingVarType)\n"

      let paramBackingVar = "_\(name)Params"
      let paramBackingType: String

      if parameters.count == 1 { 
         let param = parameters[0]
         if param.type.hasSuffix("!") || param.type.hasSuffix("?") {
            paramBackingType = stripAttributes(param.type)
         } else if param.type.contains("->") {
            paramBackingType = "(\(stripAttributes(param.type)))!"
         } else {
            paramBackingType = "\(stripAttributes(param.type))!"
         }   
      } else {
         paramBackingType = "(" + parameters.map { "\($0.localName): \(stripAttributes($0.type))" }.joined(separator: ", ") + ")!"
      }
      let paramBackingVarDeclaration = "   private var \(paramBackingVar): \(paramBackingType)\n"
   
      let getCountVar = "\(name)GetCallCount"
      let setCountVar = "\(name)SetCallCount"

      let getCountVarDeclaration = "   private(set) var \(backingVar): Int = 0\n"
      let setCountVarDeclaration = "   private(set) var \(backingVar): Int = 0\n"

      var subLine = "subscript"

      if modifiers.count > 0 {
         var copy = userInput
         copy["separator"] = " "
         subLine = "\(modifiers.toMockString(copy)) \(subLine)"
      }

      if attributes.count > 0 {
         var copy = userInput
         copy["separator"] = " "
         subLine = "\(attributes.toMockString(copy)) \(subLine)"
      }

      if parameters.count > 0 {
         var copy = userInput
         copy["separator"] = ", "
         subLine = "\(subLine)(\(parameters.toMockString(copy)))"
      } else {
         subLine = "\(subLine)()"
      }

      subLine = "\(subLine) ->"

      if returnAttributes.count > 0 {
         var copy = userInput
         copy["separator"] = " "
         subLine = "\(subLine) \(returnAttributes.toMockString(copy))"
      }

      subLine = "\(subLine) \(returnType)"
      let getterPart = "      \(getterClause) {\n" +
         "         \(getCountVar) = \(getCountVar) + 1\n" +
         "         return \(backingVar)\n" + 
         "      }\n"
      
      let setterPart: String 
      if setterClause.isEmpty {
         setterPart = ""
      } else {
         let backingSavePart: String
         let paramBackingValue = parameters.map { $0.localName }.joined(separator: ", ")
         if parameters.count == 1 {
            backingSavePart = "\(paramBackingVar) = \(paramBackingValue)"
         } else {
            backingSavePart = "\(paramBackingVar) = (\(paramBackingValue))"
         }

         setterPart = "      \(setterClause) {\n" +
            "         \(setCountVar) = \(setCountVar) + 1\n" +
            "         \(backingSavePart)\n" +
            "      }\n"
      }

      let fullSubscriptDeclaration = "   \(subLine) {\n" +
         getterPart + "\n" +
         setterPart +
         "   }\n"

      let getterReturnFuncDeclaration = "   func returnValueFor\(name)(_ value: \(returnType)) {\n" +
         "      \(backingVar) = value\n" +
         "   }\n"

      let paramCall: String
      if parameters.count == 1 {
         paramCall = paramBackingVar
      } else {
         paramCall = parameters.map { "\(paramBackingVar).\($0.localName)" }.joined(separator: ", ")
      }

      let paramTypes = parameters.map { $0.type }.joined(separator: ", ")
      let validateFuncDeclaration = "   func validate\(name)(_ block: (\(paramTypes)) -> Void) {\n" +
         "      block(\(paramCall))\n" +
         "   }\n"
      
      let result = "   //MARK: Synthesized subscript: \(name)\n" +
         backingVarDeclaration + "\n" +
         paramBackingVarDeclaration + "\n" +
         getCountVarDeclaration + "\n" +
         setCountVarDeclaration + "\n" +
         fullSubscriptDeclaration + "\n" +
         getterReturnFuncDeclaration + "\n" +
         validateFuncDeclaration

      return result
   }

   private func stripAttributes(_ type: String) -> String {
      return type.replacingOccurrences(of: "@[A-Za-z_][A-Za-z_0-9]*(\\(.*\\))?"
         , with: ""
         , options: .regularExpression
         , range: type.startIndex ..< type.endIndex)
   }
}
