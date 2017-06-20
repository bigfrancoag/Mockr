import SwiftProtocolParser

extension TypeAliasMember : MockrStringable {
   func toMockString(_ userInfo: [String:String]) -> String {
      //Should be inherited. Not needed for implementation of Mock
      return ""
   }
}
