import Foundation

class MethodParametersParser {
   private let letters = "A-Za-z"
   private let numbers = "0-9"
   private lazy var identifierHeadChars: String = { "\(self.letters)_" }()
   private lazy var identifierBodyChars: String = { "\(self.identifierHeadChars)\(self.numbers)" }()
   private lazy var identifierHead: String = { "[\(self.identifierHeadChars)]" }()
   private lazy var identifierBody: String = { "[\(self.identifierBodyChars)]" }()
   private lazy var identifier: String = { "\(self.identifierHead)\(self.identifierBody)*" }()
   private lazy var typeName: String { "\(?:inout\\s*)?\(namespacedIdentifier)(?:\\?|\\!)?"

   //TODO: Remove, testing only
   func testParsing(_ lines: [String] ) {
      lines.forEach {
         print("TESTING: \($0)...")
         guard let parsed = parseParameters($0) else {
            print("Failed to parse!")
            return
         }
         print("   found \(parsed.count) params:")
         for (i, param) in parsed.enumerated() {
            print("      param \(i):")
            print("         outerLabel: \(param.outerLabel)")
            print("         name: \(param.name)")
            print("         type: \(param.type)")
         }
      }
   }

   func parseParameters(_ line: String) -> [(outerLabel: String, name: String, type: String)]? {
      var remaining = line.trimmingCharacters(in: CharacterSet.whitespaces)
      var result: [(outerLabel: String, name: String, type: String)]? = nil

      while !remaining.isEmpty {
         guard let colonRange = remaining.rangeOfCharacter(from: CharacterSet([":"])) else {
            print("DEBUG: no colon found in: \(remaining)")
            return result            
         }
         let paramlabels = remaining.substring(with: remaining.startIndex ..< colonRange.lowerBound)
         guard let labels = parseLabels(paramlabels) else {
            print("DEBUG: invalid parameter labels: \(paramlabels)")
            return result
         }

         remaining = remaining.substring(with: colonRange.upperBound ..< remaining.endIndex)

         guard let (type, remainingAfterType) = parseType(remaining) else {
            print("DEBUG: invalid type: \(remaining)")
            return result
         }
         remaining = remainingAfterType

         if result == nil {
            result = []
         }
         result!.append((outerLabel: labels.outer, name: labels.inner, type: type))
      }
      return result
   }

   private func parseLabels(_ paramLabels: String) -> (outer: String, inner: String)? {
      let trimmed = paramLabels.trimmingCharacters(in: CharacterSet.whitespaces)
      let parts = trimmed.components(separatedBy: " ")
      guard !parts.isEmpty else {
         return nil
      }

      let outerLabel = parts[0]

      guard isValidIdentifier(outerLabel) else {
         return nil
      }

      let innerLabel = parts.count > 1 ? parts[1] : parts[0]

      guard isValidIdentifier(innerLabel) else {
         return nil
      }
      return (outer: outerLabel, inner: innerLabel)
   }

   private func parseType(_ line: String) -> (type: String, remaining: String)? {
      var typeLine = line.trimmingCharacters(in: CharacterSet.whitespaces)
      print("DEBUG: parsing type from: \(typeLine)")

      guard !typeLine.isEmpty else {
         return nil
      }


      switch typeLine.characters.first.map({ "\($0)" }) {
      case "["?:
         var remainingCloseBrackets = 1
         var endIndexOffset = 1
         var characters = typeLine.characters.dropFirst().makeIterator()
         while remainingCloseBrackets > 0
            , let nextChar = characters.next() {
            if nextChar == "]" {
               remainingCloseBrackets = remainingCloseBrackets - 1
            } else if nextChar == "[" {
               remainingCloseBrackets = remainingCloseBrackets + 1
            }
            endIndexOffset = endIndexOffset + 1
         }
         let endIndex = typeLine.index(typeLine.startIndex, offsetBy: endIndexOffset)
         let arrayType = typeLine.substring(to: endIndex)
         var remaining = typeLine.substring(from: endIndex)
         remaining = remaining.trimmingCharacters(in: CharacterSet.whitespaces)
         if remaining.hasPrefix(",") {
            remaining = remaining.substring(from: remaining.index(after: remaining.startIndex))
            remaining = remaining.trimmingCharacters(in: CharacterSet.whitespaces)
         }
         return (type: arrayType, remaining: remaining)
   
      case "("?:
         var remainingCloseParenthesis = 1
         var endIndexOffset = 1
         var characters = typeLine.characters.dropFirst().makeIterator()
         while remainingCloseParenthesis > 0
            , let nextChar = characters.next() {
            if nextChar == ")" {
               remainingCloseParenthesis = remainingCloseParenthesis - 1
            } else if nextChar == "(" {
               remainingCloseParenthesis = remainingCloseParenthesis + 1
            }
            endIndexOffset = endIndexOffset + 1
         }
         let endIndex = typeLine.index(typeLine.startIndex, offsetBy: endIndexOffset)
         let tupleType = typeLine.substring(to: endIndex)
         var remaining = typeLine.substring(from: endIndex)
         remaining = remaining.trimmingCharacters(in: CharacterSet.whitespaces)
         if remaining.hasPrefix(",") {
            //This was a tuple
            remaining = remaining.substring(from: remaining.index(after: remaining.startIndex))
            remaining = remaining.trimmingCharacters(in: CharacterSet.whitespaces)
         } else if remaining.hasPrefix("->") {
            //TODO: Handle throws, rethrows, and where clauses
            // This was a function.  TODO: call parseType from remaining after  -> .  Then append that type to this type.
            remaining = remaining.substring(from: remaining.index(remaining.startIndex, offsetBy: 2))
            remaining = remaining.trimmingCharacters(in: CharacterSet.whitespaces)
            
            guard let (functionReturnType, afterFunctionRemaining) = parseType(remaining) else {
               return nil
            }
            let functionType = "\(tupleType) -> \(functionReturnType)"

            return (type: functionType, remaining: afterFunctionRemaining)
         }

         return (type: tupleType, remaining: remaining)

      case "@"?:
         typeLine = typeLine.replacingOccurrences(
            of: "@\(identifier)(?:\\(.*\\))?"
            , with: ""
            , options: .regularExpression
            , range: typeLine.startIndex ..< typeLine.endIndex)

         return parseType(typeLine)

      default:
         //TODO: Handle params..., i.e. print(_ args: Any...)
         //TODO: Handle optionals, IUO
         //TODO: Handle inout
         //TODO: handle generics
         //TODO: handle namespaced identifier
         //TODO: handle protocol composition
         //TODO: handle protocol metatype (i.e: T.Type, T.Protocol)

         guard let commaRange = typeLine.rangeOfCharacter(from: CharacterSet([","])) else {
            return (type: typeLine, remaining: "")
         }

         let expectedIdentifier = typeLine.substring(with: typeLine.startIndex ..< commaRange.lowerBound).trimmingCharacters(in: CharacterSet.whitespaces)
         guard isValidIdentifier(expectedIdentifier) else {
            //Invalid identifier.  the substring between the start of the line and the comma should only be a valid identifier with optional whitespace
            return nil
         }

         let remaining = typeLine.substring(with: commaRange.upperBound ..< typeLine.endIndex)

         return (type: expectedIdentifier, remaining: remaining)
      }
   }

   private func isValidIdentifier(_ s: String) -> Bool {
      guard let _ = s.range(of: "^\(identifier)$", options: .regularExpression, range: s.startIndex ..< s.endIndex) else {
         return false
      }
      return true
   }
}
