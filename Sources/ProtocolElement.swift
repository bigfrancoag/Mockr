import Foundation

enum ProtocolElement {
   case property(name: String, type: String)
   case initializer
   case method(name: String, returnType: String?, genericType: String?, parameters: [(outerLabel: String, name: String, type: String)])
   case subscripter
   case importer
   case associatedType
}

extension ProtocolElement {
   func outputForLine(_ line: String) -> String {
      switch self {
      case let .property(varName, varType):
         let setVarName = "\(varName)SetCallCount"
         let getVarName = "\(varName)GetCallCount"

         //TODO: Handle optionals and iuo
         let backingVarName = "_\(varName)LastValue"
         let isOptional = varType.hasSuffix("?") ||  varType.hasSuffix("!") 
         let backingVarType = isOptional ? varType : "\(varType)!"

         return
            "   //MARK: Synthesized Mock Property: \(varName)\n" +
            "   private var \(backingVarName): \(backingVarType)\n" +
            "   private(set) var \(setVarName): Int = 0\n" +
            "   private(set) var \(getVarName): Int = 0\n" +
            "   \(line.trimmingCharacters(in: CharacterSet.whitespaces)) {\n" +
            "      get {\n" +
            "         \(getVarName) = \(getVarName) + 1\n" +
            "         return \(backingVarName)\n" +
            "      }\n" +
            "\n" +
            "      set {\n" +
            "         \(setVarName) = \(setVarName) + 1\n" +
            "         \(backingVarName) = newValue\n" +
            "      }\n" +
            "   }\n" +
            "\n" +
            "   func \(varName)(initialValue value: \(varType)) {\n" +
            "      \(backingVarName) = value\n" +
            "   }\n"

      case let .method(methodName, returnType, genericTypeParams, parameters):
         let paramNamesPart = parameters.map { $0.outerLabel + ":" }.joined(separator: "")
         let fullMethodName = parameters.isEmpty ? methodName : "\(methodName)(\(paramNamesPart))"
         let simpleMethodName = "\(methodName)_\(paramNamesPart)".replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: ":", with: "_")

         //TODO handle optionals and iuo
         let inputParamVarNamesWithTypes: [(varName: String, type: String, argName: String)] = parameters.map {
            let backingParamType: String
            if $0.type.contains("->") {
               backingParamType = "(\($0.type))"
            } else {
               backingParamType = $0.type
            }
            return (varName: "\(methodName)\($0.name)LastValue", type: backingParamType, argName: $0.name)
         }

         let inputParamsAsArgs = inputParamVarNamesWithTypes.map { $0.varName }.joined(separator: ", ")
         let inputParamBackersLine = inputParamVarNamesWithTypes.map { "   private var \($0.varName): \($0.type)!\n" }.joined(separator: "")

         let callCountVarName = "\(simpleMethodName)CallCount"
         let backingVarName = "_\(simpleMethodName)ReturnValue"


         let validateMethodParams = parameters.map { "_ \($0.name): \($0.type)" }.joined(separator: ", ")
         let genericParams = genericTypeParams ?? ""
         let validateMethodLine = validateMethodParams.characters.count > 1 ? "   func validate\(simpleMethodName)\(genericParams)(_ block: (\(validateMethodParams)) -> Void) {\n      block(\(inputParamsAsArgs))\n   }\n" : ""

         //TODO: Handle optionals and iuo
         let needsBackingVar = returnType.map { $0 != "Void" } ?? false
         let backingVarLine = needsBackingVar ? returnType.map { "   private(set) var \(backingVarName): \($0)!\n" } ?? "" : ""
         let returnLine = needsBackingVar ? "      return \(backingVarName)\n" : ""
         let returnSetterLine = needsBackingVar ? returnType.map { "   func \(simpleMethodName)(returns value: \($0)) {\n      \(backingVarName) = value\n   }\n" } ?? "" : ""
         let methodBodyLine = inputParamVarNamesWithTypes.map {"      \($0.varName) = \($0.argName)\n" }.joined(separator: "") 

         return
            "   //MARK: Synthesized Mock Method: \(fullMethodName)\n" +
            "   private(set) var \(callCountVarName): Int = 0\n" +
            backingVarLine +
            inputParamBackersLine +
            "   \(line.trimmingCharacters(in: CharacterSet.whitespaces)) {\n" +
            methodBodyLine +
            returnLine +
            "   }\n" +
            "\n" +
            returnSetterLine +
            validateMethodLine

      default:
         return line
      }
   }
}
