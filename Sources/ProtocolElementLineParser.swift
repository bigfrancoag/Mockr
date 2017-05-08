import Foundation

class ProtocolElementLineParser {
   private let identifierStart = "[A-Za-z_]"
   private lazy var identifier: String = { "\(self.identifierStart)[A-Z-a-z_0-9]*" }() 

   //TODO: Handle Tuple types, Array types, and Dictionary types
   private lazy var typeName: String = { "\(self.identifier)[!\\?]?" }() 
   private lazy var genericType: String = { "<\\s*\(self.identifier)(?:\\s*:\\s*\(self.typeName))?(?:\\s*,\\s*\(self.identifier)(\\s*:\\s*\(self.typeName)))*\\s*>" }()

   let config: Configuration
   init(config: Configuration) {
      self.config = config
   }

   func parseLine(_ line: String) -> (line: String, type: ProtocolElement)? {
      return tryParsePropertyLine(line) ??
         tryParseMethodLine(line)
   }

   private func tryParsePropertyLine(_ line: String) -> (line: String, type: ProtocolElement)? {
      let propertyNameRegexPattern = "\\s+var\\s+(\(identifier))\\s*:\\s*(\(typeName))"
      let regex = try! NSRegularExpression(pattern: propertyNameRegexPattern, options: [])
      let matches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: line.characters.count))
      guard let match = matches.first
         , match.numberOfRanges == 3 else {
         return nil
      }
      let varName = (line as NSString).substring(with: match.rangeAt(1))
      let varType = (line as NSString).substring(with: match.rangeAt(2))
      return (line: line, type: .property(name: varName, type: varType))
   } 

   private func tryParseMethodLine(_ line: String) -> (line: String, type: ProtocolElement)? {
      //TODO: Handle more complex return types.
      let methodNameRegexPattern = "\\s+func\\s+(\(identifier))\\s*(\(genericType))?\\s*\\((.*)\\)\\s*(?:(?:->)\\s*(\(typeName)))?"
      let regex = try! NSRegularExpression(pattern: methodNameRegexPattern, options: [])
      let matches = regex.matches(in: line, options: [], range: NSRange(location: 0, length: line.characters.count))
      guard let match = matches.first
         , match.numberOfRanges >= 3 else {
         config.debug("expected 3 matches in the method, only found \(String(describing: matches.first?.numberOfRanges))")
         return nil
      }

      config.debug("method matches found: \(match.numberOfRanges)")
      if config.isDebug {
         for i in 1..<match.numberOfRanges {
            let rng = match.rangeAt(i)
            config.debug("match \(i) range: Range(location: \(rng.location), length: \(rng.length))")
            if rng.length > 0 {
               let substr = (line as NSString).substring(with: rng)

               config.debug("match \(i) substring: \(substr)")
            } else {
               config.debug("match \(i) substring is 0 length")
            }
         }
      }

      var matchIndex: Int = 1
      func nextMatch() {
         repeat {
             matchIndex = matchIndex + 1
         } while matchIndex < match.numberOfRanges && match.rangeAt(matchIndex).location == NSNotFound
      }

      let methodName = (line as NSString).substring(with: match.rangeAt(matchIndex))
      nextMatch()
      config.debug("found method: \(methodName)")

      let genericTypeOrParametersString = (line as NSString).substring(with: match.rangeAt(matchIndex))
      nextMatch()

      let genericTypeParams: String?
      let parametersString: String
      if genericTypeOrParametersString.hasPrefix("<") {
         genericTypeParams = genericTypeOrParametersString
         if matchIndex < match.numberOfRanges {
            parametersString = (line as NSString).substring(with: match.rangeAt(matchIndex))
         } else {
            parametersString = ""
         }
         nextMatch()
      } else {
         genericTypeParams = nil
         parametersString = genericTypeOrParametersString
      }

      config.debug("genericTypeParams: \(String(describing: genericTypeParams))")
      config.debug("parametersString: \(parametersString)")

      //TODO: Handle tuple types for parameters
      let parameterStringParts: [String] = parametersString.isEmpty ? [] : parametersString.components(separatedBy: CharacterSet(charactersIn: ","))
      let parameters: [(outerLabel: String, name: String, type: String)] = parameterStringParts
         .flatMap { paramString in
            guard !paramString.isEmpty else { return nil }
            let paramParts = paramString.components(separatedBy: CharacterSet(charactersIn: ":"))
               .map { s in s.trimmingCharacters(in: CharacterSet.whitespaces) }
            let namesPart = paramParts[0]
            let namesList = namesPart.components(separatedBy: CharacterSet(charactersIn: " "))
            let outerLabelName = namesList[0]
            let innerLabelName = namesList.count > 1 ? namesList[1] : namesList[0]
            let typePart = paramParts[1]
            return (outerLabel: outerLabelName, name: innerLabelName, type: typePart)
         }

      let returnType: String?
      if matchIndex < match.numberOfRanges {
         returnType = (line as NSString).substring(with: match.rangeAt(matchIndex))
         nextMatch()
      } else {
         returnType = nil
      }
      config.debug("returnType: \(String(describing: returnType))")

      return(line: line, type: .method(name: methodName, returnType: returnType, genericType: genericTypeParams, parameters: parameters))
   }
}
