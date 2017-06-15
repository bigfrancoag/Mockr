import SwiftProtocolParser

extension ThrowsType : MockrStringable {
   func toMockString(_ userInfo: [String:String]) -> String {
      switch self {
      case .throwsError:
         return "throws"

      case .rethrowsError:
         return "rethrows"
      }
   }
}
