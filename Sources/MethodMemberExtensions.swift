import SwiftProtocolParser

extension MethodMember : MockrStringable {
   func toMockString(_ userInput: [String:String]) -> String {
//      let paramNameEnd = "˸" //\u02f8
//      let nameParamSep = "│" //\u2502

      let paramNameEnd = "_"
      let nameParamSep = "_"
      var result = ""

      let hasParams = !parameters.isEmpty
      let paramName = parameters.map { $0.externalName ?? $0.localName }.map { "\($0)\(paramNameEnd)" }.joined(separator: "")
      let fullMethodName = hasParams ? "\(name)\(nameParamSep)\(paramName)\(nameParamSep)" : name
      let requiresBackingVar = returnType.map { $0 != "Void" } ?? false
      let backingVar = requiresBackingVar ? "_\(fullMethodName)ReturnValue" : ""
      let backingVarTypeIsOptional = returnType.map { $0.hasSuffix("!") || $0.hasSuffix("?") } ?? false
      let backingVarType = returnType.map { backingVarTypeIsOptional ? $0 : "\($0)!" } ?? ""
      let countVar = "\(fullMethodName)CallCount"

      let paramBackingVar = hasParams ? "_\(fullMethodName)Params" : ""
      let paramBackingType: String
      if hasParams {
         if parameters.count == 1 {
            let param = parameters[0]
            if param.type.hasSuffix("!") || param.type.hasSuffix("?") {
               paramBackingType = param.type
            } else {
               paramBackingType = "\(param.type)!"
            }
         } else {
            paramBackingType = "(" + parameters.map { "\($0.localName): \($0.type)" }.joined(separator: ", ") + ")!"
         }
      } else {
         paramBackingType = ""
      }

      let backingVarDeclaration = requiresBackingVar ? "   private var \(backingVar): \(backingVarType)\n" : ""
      let paramBackingDeclaration = hasParams ? "   private var \(paramBackingVar): \(paramBackingType)\n" : ""
      let countVarDeclaration = "   private(set) var \(countVar): Int = 0\n"

      var copy = userInput
      copy["separator"] = ", "
      let funcParams = parameters.toMockString(copy)
      let genericsDecl = genericsClause ?? ""
      let throwsDecl = throwsType.map { " \($0.toMockString(userInput))" } ?? ""
      let returnDecl = returnType.map { " -> \($0)" } ?? ""
      let whereDecl = whereClause.map { " \($0)" } ?? ""
      var funcDeclaration = "func \(name)\(genericsDecl)(\(funcParams))\(throwsDecl)\(returnDecl)\(whereDecl)"

      if modifiers.count > 0 {
         var copy = userInput
         copy["separator"] = " "
         funcDeclaration = modifiers.toMockString(copy) + " " + funcDeclaration
      }

      if attributes.count > 0 {
         var copy = userInput
         copy["separator"] = " "
         funcDeclaration = attributes.toMockString(copy) + " " + funcDeclaration
      }

      funcDeclaration = "   \(funcDeclaration) {\n" +
         "      \(countVar) = \(countVar) + 1\n"

      if hasParams {
         let paramBackingValue = parameters.map { $0.localName }.joined(separator: ", ")
         if parameters.count == 1 {
            funcDeclaration = funcDeclaration + "      \(paramBackingVar) = \(paramBackingValue)\n"
         } else {
            funcDeclaration = funcDeclaration + "      \(paramBackingVar) = (\(paramBackingValue))\n"
         }
      }

      funcDeclaration = funcDeclaration + "   }\n"

      var returnFuncDeclaration = ""

      if requiresBackingVar {
         returnFuncDeclaration = "   func returnValueFor\(fullMethodName)(_ value: \(returnType!)) {\n" +
            "      \(backingVar) = value\n" +
            "   }\n"
      }

      var validateFuncDeclaration = ""

      if hasParams {
         
         let paramCall: String
         if parameters.count == 1 {
            paramCall = paramBackingVar
         } else {
            paramCall = parameters.map { "\(paramBackingVar).\($0.localName)" }.joined(separator: ", ")
         }
         let paramTypes = parameters.map { $0.type }.joined(separator: ", ")
         validateFuncDeclaration = "   func validate\(fullMethodName)(_ block: (\(paramTypes)) -> Void) {\n" +
            "      block(\(paramCall))\n" +
            "   }\n"
      }

      result = "   //MARK: Synthesized Mock Method: \(fullMethodName)\n" +
         backingVarDeclaration + "\n" +
         paramBackingDeclaration + "\n" +
         countVarDeclaration + "\n" +
         funcDeclaration + "\n" +
         returnFuncDeclaration + "\n" +
         validateFuncDeclaration
      
      return result
   }
}
