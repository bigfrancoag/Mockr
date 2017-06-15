import SwiftProtocolParser

extension MethodParameter : MockrStringable {
   public func toMockString(_ userInfo: [String:String]) -> String {
      var result = "\(localName): \(type)"
      if let external = externalName {
         result = "\(external) \(result)"
      }

      if isParams {
         result = "\(result)..."
      }

      if let def = defaultClause {
         result = "\(result) = \(def)"
      }

      return result
   }
}
