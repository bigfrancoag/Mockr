import SwiftProtocolParser

extension AccessModifier : MockrStringable {
   func toMockString(_ userInfo: [String:String]) -> String {
      return self.rawValue + " "
   }
}
