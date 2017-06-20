import SwiftProtocolParser

extension ProtocolMember : MockrStringable {
   func toMockString(_ userInput: [String:String]) -> String {
   switch self {
   case .initializer(let initMember):
      return initMember.toMockString(userInput)

   case .property(let propMember):
      return propMember.toMockString(userInput)

   case .method(let methMember):
      return methMember.toMockString(userInput)

   case .sub(let subMember):
      return subMember.toMockString(userInput)

   case .associatedType(let ascTypeMember):
      return ascTypeMember.toMockString(userInput)

   case .typeAlias(let typeAliasMember):
      return typeAliasMember.toMockString(userInput)
   }
   }
}
