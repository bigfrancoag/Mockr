import SwiftProtocolParser

extension InitializerMember : MockrStringable {
   func toMockString(_ userInput: [String:String]) -> String {
      var initLine = "init"

      if modifiers.count > 0 {
         var copy = userInput
         copy["separator"] = " "
         initLine = "\(modifiers.toMockString(copy)) \(initLine)"
      }

      if attributes.count > 0 {
         var copy = userInput
         copy["separator"] = " "
         initLine = "\(attributes.toMockString(copy)) \(initLine)"
      }

      initLine = "\(initLine)"

      if isOptional {
         initLine = "\(initLine)?"
      } else if isIUO {
         initLine = "\(initLine)!"
      }

      if let genericsClause = genericsClause {
         initLine = "\(initLine)\(genericsClause)"
      }

      if parameters.count > 0 {
         var copy = userInput
         copy["separator"] = ", "
         let paramsPart = parameters.toMockString(copy)
         initLine = "\(initLine)(\(paramsPart))"
      } else {
         initLine = "\(initLine)()"
      }

      if let throwsType = throwsType {
         initLine = "\(initLine) \(throwsType.toMockString(userInput))"
      }

      if let whereClause = whereClause {
         initLine = "\(initLine) \(whereClause)"
      }

      let result = "   //MARK: - Required init implementation\n" +
         "   \(initLine) {\n" +
         "      //TODO: set properties, etc.\n" +
         "   }\n"

      return result
   }
}
