protocol MockrStringable {
   func toMockString(_ userInfo: [String:String]) -> String
}

extension Array where Element : MockrStringable {
   func toMockString(_ userInfo: [String:String]) -> String {
      let separator = userInfo["separator"] ?? " "
      return self.map { $0.toMockString(userInfo) }.joined(separator: separator)
   }
}
