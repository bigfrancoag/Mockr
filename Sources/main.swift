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
      , "username: String, password: String, dbType: DBType, handleResult: @escaping (Result<(user: User, accessToken: String)>) -> Void"
   ])
} catch {
   print(ParsedConfiguration.usage)
}
