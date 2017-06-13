import SwiftProtocolParser

extension Attribute : MockrStringable {
   public func toMockString(_ userInfo: [String:String]) -> String {
      return "@\(name)\(argumentsClause ?? "")"
   }
}
