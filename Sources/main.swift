do {
   let config = try ParsedConfiguration()
   config.debug(config)
   let mockr = Mockr(config: config)
   mockr.mockEm()
} catch {
   print(ParsedConfiguration.usage)
}
