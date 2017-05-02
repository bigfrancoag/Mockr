import Foundation

protocol Configuration {
   var sourceDirectoryName: String { get }
   var outputDirectoryName: String { get }
   var isVerbose: Bool { get }
   var isDebug: Bool { get }
   var isRecursive: Bool { get }
}

extension Configuration {
   func log(_ object: Any, verbose: Bool = false) {
      if !verbose || isVerbose {
         let dateFormatter = DateFormatter()
         dateFormatter.locale = Locale(identifier: "en_US_POSIX")
         dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
         let date = Date()
         let prettyDate = dateFormatter.string(from: date)
         print("\(prettyDate) \(object)")
      }
   }

   func debug(_ object: Any) {
      if isDebug {
         let dateFormatter = DateFormatter()
         dateFormatter.locale = Locale(identifier: "en_US_POSIX")
         dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
         let date = Date()
         let prettyDate = dateFormatter.string(from: date)
         print(prettyDate, terminator: " ")
         debugPrint(object)
      }
   }
}
