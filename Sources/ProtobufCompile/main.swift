import ArgumentParser
import Foundation

func runShell(command: String) throws {
  do {
    try shellOut(to: command, outputHandle: .standardOutput, errorHandle:.standardError)
  } catch {
    throw ProtobufCompileError()
  }
}

struct ProtobufCompileError: Error, CustomStringConvertible {
  var description: String {
    "Failed to compile protobufs"
  }
}

struct ProtobufCompule: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "ProtobufCompile",
    abstract: "Compiles .proto dependencies to .swift files",
  )
  
  func run() throws {
    try runShell("echo Hello")
  }
}

ProtobufCompule.main()
