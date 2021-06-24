import Foundation

class TabularLogFormatter {

  enum Alignment {
    case left
    case right
  }

  private struct FieldFormat {
    let name: String

    let width: Int

    let alignment: Alignment

    var columnFormatted: String {
      name.columnFormatted(width: width, alignment: alignment)
    }

    func columnFormatted(value: Any) -> String {
      String(describing: value).columnFormatted(width: width, alignment: alignment)
    }
  }

  private struct Row {
    let values: [Any]
  }

  private var fields: [FieldFormat]
  private var rows: [Row]

  public let name: String
  public var leftPadding: Int = 1
  public var rightPadding: Int = 1
  public var columnPadding: Int = 1
  public var columnSeparator: String = "|"

  init(name: String) {
    self.name = name
    self.fields = []
    self.rows = []
  }

  func addField(name: String, width: Int = 10, alignment: Alignment = .left) {
    let field = FieldFormat(name: name, width: width, alignment: alignment)
    fields.append(field)
  }

  func addRow(_ values: Any...) {
    guard values.count == fields.count else { return }
    rows.append(Row(values: values))
  }

  func asStringArray() -> [String] {
    var result: [String] = [name]
    let leftPadding = String(repeating: " ", count: leftPadding)
    let columnSpacing = String(repeating: " ", count: columnPadding)
    let columnDelimiter = columnSpacing + columnSeparator + columnSpacing
    let rightPadding = String(repeating: " ", count: rightPadding)

    var header = leftPadding
    header += fields.map(\.columnFormatted).joined(separator: columnDelimiter)
    header += rightPadding
    result.append(header)
    result.append(String(repeating: "-", count: header.count))

    for row in rows {
      var rowValueStrings: [String] = []
      for (field, value) in zip(fields, row.values) {
        rowValueStrings.append(field.columnFormatted(value: value))
      }
      var rowString = leftPadding
      rowString += rowValueStrings.joined(separator: columnDelimiter)
      rowString += rightPadding
      result.append(rowString)
    }

    return result
  }

  func asNewlineJoinedString() -> String {
    return asStringArray().joined(separator: "\n")
  }
}

fileprivate extension String {
  func columnFormatted(width: Int, alignment: TabularLogFormatter.Alignment) -> String {
    let diff = width - self.count
    if diff <= 0 { return String(self.prefix(width)) }
    let padding = String(repeating: " ", count: diff)
    switch alignment {
    case .left:
      return self + padding
    case .right:
      return padding + self
    }
  }
}
