import SwiftProtocolParser

extension ProtocolMember : MockrStringable {
   func toMockString(_ userInput: [String:String]) -> String {
   switch self {
   case .initializer(let initMember):
      return "TODO: init member here"

   case .property(let propMember):
      return propMember.toMockString(userInput)

   case .method(let methMember):
      return "TODO: meth member here"

   case .sub(let subMember):
      return "TODO: sub member here"

   case .associatedType(let ascTypeMember):
      return ascTypeMember.toMockString(userInput)

   case .typeAlias(let typeAliasMember):
      return "TODO: type alias member here"
   }
   }
}
