import FileUtils
import Foundation

class Mockr {
   private let identifierStart = "[A-Za-z_]"
   private lazy var identifier: String = { "\(self.identifierStart)[A-Z-a-z_0-9]*" }()

   //TODO: Handle Tuple types, Array types, and Dictionary types
   private lazy var typeName: String = { "\(self.identifier)[!\\?]?" }()
   private lazy var genericType: String = { "<\\s*\(self.identifier)(?:\\s*:\\s*\(self.typeName))?(?:\\s*,\\s*\(self.identifier)(\\s*:\\s*\(self.typeName)))*\\s*>" }()

   private let config: Configuration

   init(config: Configuration) {
      self.config = config
   }

   func mockEm() {
      do {
         let basePath = Path.expand(config.sourceDirectoryName)
         let files: [String]
         if config.isRecursive {
            config.debug("finding files recursively")
            files = findFilesRecursively(paths: [basePath], files: [])
         } else {
            config.debug("finding files in \(config.sourceDirectoryName)")
            guard let (subfiles, _) = Directory.contents(ofDirectory: basePath) else {
               config.log("WARNING: Could not find any files in directory: \(config.sourceDirectoryName)")
               return
            }
            files = subfiles.map { "\(basePath)/\($0)" }
         }

         for file in files {
            generateMocksForProtocols(inFile: file)
         }
      }
   }

   private func findFilesRecursively(paths: [String], files: [String]) -> [String] {
      guard let path = paths.first else {
         config.debug("No more files to check")
         return files
      }
      config.debug("checking files in \(path)")

      var remainingPaths = Array(paths.dropFirst())

      guard Path.exists(path) else {
         config.debug("path \(path) does not exist!")
         return findFilesRecursively(paths: remainingPaths, files: files)
      }

      switch Path.type(ofPath: path) {
      case .file:
         config.debug("path \(path) added")
         var newFiles = files
         newFiles.append(path)
         return findFilesRecursively(paths: remainingPaths, files: newFiles)
         
      case .directory:
         guard let (subfiles, directories) = Directory.contents(ofDirectory: Path.expand(config.sourceDirectoryName)) else {
            return findFilesRecursively(paths: remainingPaths, files: files)
         }

         config.debug("paths \(subfiles) added")
         var newFiles = files
         newFiles.append(contentsOf: subfiles.map({ "\(path)/\($0)" }))
         remainingPaths.append(contentsOf: directories)
         return findFilesRecursively(paths: remainingPaths, files: newFiles)

      default:
         config.debug("path \(path) is neither a file nor a directory")
         return files
      }
   }
   
   private func generateMocksForProtocols(inFile path: String) {
      do {
         var contents = try File.read(atPath: path)

         //remove get/set for properties.  Will make them all var get/set in the mocks
         //strip attributes.
         //Also makes parsing way easier!
         contents = contents
            .replacingOccurrences(
               of: "\\{\\s*get\\s*(set\\s*)?\\}"
               , with: ""
               , options: .regularExpression
               , range: contents.startIndex ..< contents.endIndex)

         contents = contents
            .replacingOccurrences(
               of: "@\(identifier)(\\(.*\\))?" 
               , with: ""
               , options: .regularExpression
               , range: contents.startIndex ..< contents.endIndex)

         var searchRange = contents.startIndex ..< contents.endIndex

         while let protocolRange = contents.range(of: "protocol", range: searchRange) {
            guard let closeBracketRange = contents.range(of: "}", range: protocolRange.upperBound ..< contents.endIndex) else {
               config.debug("Invalid protocol file \(path). No closing bracket after protocol definition")
               searchRange = protocolRange.upperBound ..< contents.endIndex
               continue
            }

            buildMockProtocol(contents: contents, range: protocolRange.upperBound ..< closeBracketRange.lowerBound)

            searchRange = closeBracketRange.upperBound ..< contents.endIndex
         }
      } catch FileError.fileNotFound {
         config.log("WARNING: Could not find the file: \(path)")
         return
      } catch FileError.cantReadFile {
         config.log("WARNING: Could not read the contents in the file: \(path)")
      } catch {
         config.log("WARNING: Unexpected error while reading the file: \(path)")
      }
   }

   func buildMockProtocol(contents: String, range: Range<String.Index>) {
      guard let openBracketRange = contents.range(of: "{", range: range) else {
         config.debug("Invalid protocol file. No opening bracket after protocol definition")
         return
      }
      let protocolNameSearchRange = range.lowerBound ..< openBracketRange.lowerBound
      let protocolNameSubstring = contents.substring(with: protocolNameSearchRange)
      let parts = protocolNameSubstring
         .components(separatedBy: CharacterSet.whitespacesAndNewlines)
         .filter { !$0.isEmpty }

      guard let protocolName = parts.first else {
         config.debug("Invalid protocol file. No name between \"protocol\" and opening bracket")
         return 
      }

      config.debug("found protocol name: \(protocolName)")
      let mockName = "Mock\(protocolName)"
      let fileName = "\(Path.expand(config.outputDirectoryName))/\(mockName).swift"
      //TODO: Filter multiline comments
      //TODO: Filter single line comments
      let lines = contents.substring(with: openBracketRange.upperBound ..< range.upperBound)
         .components(separatedBy: CharacterSet.newlines)
         
      let elements = lines.flatMap { self.parseLine($0) }

      config.debug("\(elements.count) elements found")

      elements.forEach { 
         config.debug($0.line)
         config.debug($0.type)
      }
      
/*
      while let protocolRange = contents.range(of: "protocol", range: searchRange) {
      

            //TODO: handle properties
               // - internal|public|private|fileprivate|open (set)?
               // - dynamic/optional/(mutating|nonmutating)/static

            //TODO: handle protocol accessLevel
               // - internal|public|private|fileprivate

            //TODO: handle imports 

            //TODO: handle funcs
               // - internal|public|private|fileprivate|open (set)?

            //TODO: handle subscripts
               // - internal|public|private|fileprivate|open (set)?

            //TODO: handle inits
               // - internal|public|private|fileprivate|open (set)?
               // - add required to implementation

            //TODO: handle associated types (create a Thunk?)
      }
*/

      let imports = config.importPackages.map { "import \($0)" }.joined(separator: "\n")
      let fileContents =
         imports +
         "\n" +
         "class \(mockName) : \(protocolName) {\n" +
         elements.map({ outputForLine($0.line, type: $0.type) }).joined(separator: "\n") +
         "}\n"

      File.create(atPath: fileName) 
      do {
         try File.write(string: fileContents, toPath: fileName)
      } catch FileError.fileNotFound {
         config.log("WARNING: Could not find the file: \(fileName)")
         return
      } catch FileError.cantReadFile {
         config.log("WARNING: Could not read the contents in the file: \(fileName)")
      } catch {
         config.log("WARNING: Unexpected error while writing the file: \(fileName)")
      }
   }

   private func parseLine(_ line: String) -> (line: String, type: ProtocolElement)? {
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
         parametersString = (line as NSString).substring(with: match.rangeAt(matchIndex))
         nextMatch()
      } else {
         genericTypeParams = nil
         parametersString = genericTypeOrParametersString
      }
     
      config.debug("genericTypeParams: \(String(describing: genericTypeParams))")
      config.debug("parametersString: \(parametersString)")

      //TODO: handle inner and outer param labels
      let parameterStringParts: [String] = parametersString.components(separatedBy: CharacterSet(charactersIn: ","))
      let parameters: [(name: String, type: String)] = parameterStringParts
         .map { paramString in
            let paramParts = paramString.components(separatedBy: CharacterSet(charactersIn: ":"))
               .map { s in s.trimmingCharacters(in: CharacterSet.whitespaces) }
            return (name: paramParts[0], type: paramParts[1])
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

   private func outputForLine(_ line: String, type: ProtocolElement) -> String {
      switch type {
      case .property(let varName, let varType):
         let setVarName = "\(varName)SetCallCount"
         let getVarName = "\(varName)GetCallCount"

         //TODO: Handle optionals and iuo
         let backingVarName = "_\(varName)LastValue"
         let capitalizedVarName = String(varName.characters.prefix(1)).uppercased() + String(varName.characters.dropFirst())

         return 
            "\t//MARK: Synthesized Mock Property: \(varName)\n" +
            "\tprivate var \(backingVarName): \(varType)? = nil\n" +
            "\tprivate(set) var \(setVarName): Int = 0\n" +
            "\tprivate(set) var \(getVarName): Int = 0\n" +
            "\t\(line.trimmingCharacters(in: CharacterSet.whitespaces)) {\n" + 
            "\t\tget {\n" +
            "\t\t\t\(getVarName) = \(getVarName) + 1\n" +
            "\t\t\treturn \(backingVarName)!\n" +
            "\t\t}\n" +
            "\n" + 
            "\t\tset {\n" +
            "\t\t\t\(setVarName) = \(setVarName) + 1\n" +
            "\t\t\t\(backingVarName) = newValue\n" +
            "\t\t}\n" +
            "\t}\n" +
            "\n" +
            "\tfunc returnValueFor\(capitalizedVarName)(_ value: \(varType)) {\n" +
            "\t\t\(backingVarName) = value\n" +
            "\t}\n"

      case let .method(methodName, returnType, genericTypeParams, parameters):
         let paramNamesPart = parameters.map { $0.name + ":" }.joined(separator: "")
         let fullMethodName = parameters.isEmpty ? methodName : "\(methodName)(\(paramNamesPart))"
         let simpleMethodName = "\(methodName)_\(paramNamesPart)".replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: ":", with: "_")

         //TODO handle optionals and iuo
         let inputParamVarNamesWithTypes = parameters.map { (varName: "\(methodName)\($0.name)LastValue", type: $0.type) }
         let inputParamsAsArgs = inputParamVarNamesWithTypes.map { "\($0.varName)" }.joined(separator: ", ")
         let inputParamBackersLine = inputParamVarNamesWithTypes.map { "\tprivate var \($0.varName): \($0.type)?\n" }.joined(separator: "")

         let callCountVarName = "\(simpleMethodName)CallCount"
         let backingVarName = "_\(simpleMethodName)ReturnValue"
        
         let needsBackingVar = returnType.map { $0 != "Void" } ?? false 

         let validateMethodParams = parameters.map { "_ \($0.name): \($0.type)" }.joined(separator: ", ")

         //TODO: copy generics type from main func
         let genericParams = genericTypeParams ?? ""
         let validateMethodLine = validateMethodParams.characters.count > 1 ? "\t func validate\(simpleMethodName)\(genericParams)(_ block: (\(validateMethodParams)) -> Void) {\n\t\tblock(\(inputParamsAsArgs)!)\n\t}\n" : ""

         //TODO: Handle optionals and iuo
         let backingVarLine = needsBackingVar ? returnType.map { "\tprivate(set) var \(backingVarName): \($0)?\n" } ?? "" : ""
         let returnLine = needsBackingVar ? "\t\treturn \(backingVarName)!\n" : ""

         return
            "\t//MARK: Synthesized Mock Method: \(fullMethodName)\n" +
            "\tprivate(set) var \(callCountVarName): Int = 0\n" +
            backingVarLine +
            inputParamBackersLine +
            "\t\(line.trimmingCharacters(in: CharacterSet.whitespaces)) {\n" +
            returnLine +
            "\t}\n" +
            "\n" +
            validateMethodLine

      default:
         return line
      }
   }
}

enum ProtocolElement {
   case property(name: String, type: String)
   case initializer
   case method(name: String, returnType: String?, genericType: String?, parameters: [(name: String, type: String)])
   case subscripter
   case importer
   case associatedType
}
