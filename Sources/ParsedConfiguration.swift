import Foundation

class ParsedConfiguration : Configuration {
   let sourceDirectoryName: String
   let outputDirectoryName: String
   let isVerbose: Bool
   let isDebug: Bool
   let isRecursive: Bool

   static let usage = "Mockr - Generate mocks for protocols\n" +
      "\n" +
      "Usage:\n" +
      "\tmockr [options] -i <input directory> -o <output directory>\n" +
      "\tmockr -h | --help\n" +
      "\n" +
      "Required:\n" +
      String(format: "\t%@ %@\n", "-i --input-dir".padding(toLength: 17, withPad: " ", startingAt: 0), "Input Directory") + 
      String(format: "\t%@ %@\n", "-o --output-dir".padding(toLength: 17, withPad: " ", startingAt: 0), "Output Directory") + 
      "\n" +
      "Options:\n" +
      String(format: "\t%@ %@\n", "-r --recursive".padding(toLength: 17, withPad: " ", startingAt: 0), "Search recursively") +
      String(format: "\t%@ %@\n", "-h --help".padding(toLength: 17, withPad: " ", startingAt: 0), "Show this usage screen") + 
      String(format: "\t%@ %@\n", "-v --verbose".padding(toLength: 17, withPad: " ", startingAt: 0), "Enable verbose logging") + 
      String(format: "\t%@ %@\n", "--debug".padding(toLength: 17, withPad: " ", startingAt: 0), "Enable debug mode") 

   private enum OptMode {
      case normal
      case inputDir
      case outputDir
   }

   enum Error : Swift.Error {
      case missingInputDirectoryOption
      case missingInputDirectoryValue
      case missingOutputDirectoryOption
      case missingOutputDirectoryValue
      case help
   }

   init(_ args: [String] = CommandLine.arguments) throws {
      let opts = args.dropFirst()

      var optMode: OptMode = .normal
      var inputDir: String? = nil
      var outputDir: String? = nil
      var verbose: Bool? = nil
      var debug: Bool? = nil
      var recursive: Bool? = nil

      for opt in opts {
         switch optMode {
            case .inputDir:
               if opt.hasPrefix("-") {
                  throw Error.missingInputDirectoryValue
               }

               inputDir = opt
               optMode = .normal
 
            case .outputDir:
               if opt.hasPrefix("-") {
                  throw Error.missingOutputDirectoryValue
               }

               outputDir = opt
               optMode = .normal
               
            case .normal:
            switch opt {
            case "-i": fallthrough
            case "--input-dir":
               optMode = .inputDir

            case "-o": fallthrough
            case "--output-dir":
               optMode = .outputDir

            case "-r": fallthrough
            case "--recursive":
               recursive = true

            case "-v": fallthrough
            case "--verbose":
               verbose = true

            case "--debug":
               debug = true

            case "-h": fallthrough
            case "--help":
               throw Error.help

            default:
               break
            }
         }
      }

      guard let inputDirectory = inputDir else {
         throw Error.missingInputDirectoryOption
      }

      guard let outputDirectory = outputDir else {
         throw Error.missingOutputDirectoryOption
      }

      self.sourceDirectoryName = inputDirectory
      self.outputDirectoryName = outputDirectory
      self.isVerbose = verbose ?? false
      self.isDebug = debug ?? false
      self.isRecursive = recursive ?? false
   }
}

extension ParsedConfiguration : CustomStringConvertible {
   var description: String {
      var desc = "Config [Source: \(sourceDirectoryName)"
      desc += ", Output: \(outputDirectoryName)"

      if isRecursive {
         desc += ", Recursive"
      }

      if isVerbose {
         desc += ", Verbose"
      }

      if isDebug {
         desc += ", Debug"
      }
      desc += "]"
      return desc
   }
}
