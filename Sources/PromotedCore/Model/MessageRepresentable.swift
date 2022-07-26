import Foundation
import SwiftProtobuf

/** Models that have a proto representation. */
protocol MessageRepresentable {

  associatedtype Representation: Message

  func asMessage() -> Representation
}
