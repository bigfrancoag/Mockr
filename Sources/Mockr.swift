import FileUtils
import Foundation
import SwiftProtocolParser

class Mockr {

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
         config.log("Reading file: \(path)")
         let contents = try File.read(atPath: path)
         let parser = SwiftProtocolParser.instance

         let (imports: imports, protocols: protocols) = parser.parse(contents)
         config.log("Found \(imports.count) imports and \(protocols.count) protocols")

         guard protocols.count > 0 else {
            return
         }

         let testableImportStatements = config.importPackages.map { "@testable import \($0)" }.joined(separator: "\n")
         let importStatements = imports.toMockString(["separator" : "\n"])

         for proto in protocols {
            let mockName = "Mock\(proto.name)"
            let fileName = "\(Path.expand(config.outputDirectoryName))/\(mockName).swift"

            let fileContents = "\(testableImportStatements)\n" +
               "\(importStatements)\n" +
               "\n" +
               "\(proto.toMockString([:]))"

            File.create(atPath: fileName)
            try File.write(string: fileContents, toPath: fileName)
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
}

