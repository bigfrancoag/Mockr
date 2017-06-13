import SwiftProtocolParser

extension ImportStatement : MockrStringable {
   func toMockString(_ userInfo: [String:String]) -> String {
      var result = path
      if let kind = kind {
         result = "\(kind) \(result)"
      }
      if attributes.count > 1 {
         result = "\(attributes.toMockString(["separator" : " "])) \(result)"
      }
      return result
   }
}
