do {
   let config = try ParsedConfiguration()
   config.debug(config)
   let mockr = Mockr(config: config)
//   mockr.mockEm()
   let paramParser = MethodParametersParser()
   paramParser.testParsing([""
      , "dependencies: Dependencies"
      , "_ result: LoginResult"
      , "username: String, password: String, dbType: DBType, rememberMe: Bool"
      , "byId id:Int, handleResult: @escaping (Result<Asset>) -> Void"
      , "handleResult: @escaping (Result<[Status]>) -> Void"
      , "_ s: String, args: [String]"
      , "array arr: [[Bool]], collapse: Bool"
      , "_ dict: [String:Int], value: T"
      , "username: String, password: String, dbType: DBType, handleResult: @escaping (Result<(user: User, accessToken: String)>) -> Void"
      , "basic: String, outer inner: Int, array: [DBType], arrayOfTupe: [(left: L, right: R)], arrayOfTupleArrays: [(left: [L], right: [R])]"
      , "basic: Blah, runnable: () -> (), supplier: () -> (t: B), consumer: ([S]) -> Void, func: ([T1:T2]) -> R"
   ])
} catch {
   print(ParsedConfiguration.usage)
}
