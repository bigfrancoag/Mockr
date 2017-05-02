import FileUtils
import Foundation

struct Mockr {
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
         let originalContents = try File.read(atPath: path)

         //remove get/set for properties.  Will make them all var get/set in the mocks
         //Also makes parsing way easier!
         let contents = originalContents
            .replacingOccurrences(
               of: "\\{\\s*get\\s*(set\\s*)?\\}"
               , with: ""
               , options: .regularExpression
               , range: originalContents.startIndex ..< originalContents.endIndex)

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
/*
      while let protocolRange = contents.range(of: "protocol", range: searchRange) {
      

            //TODO: handle properties

            //TODO: handle protocol accessLevel
            //TODO: handle imports 
            //TODO: handle funcs
            //TODO: handle subscripts
            //TODO: handle inits
            //TODO: handle associated types (create a Thunk?)
      }
*/
      let fileContents = 
         "class \(mockName) : \(protocolName) {\n" +
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
}
