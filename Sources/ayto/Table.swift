import Foundation

public class Table {
    
    public typealias Address = (x: Int, y: Int)
    
    struct Cell {
        let address: Address
        let value: String
        let color: ASCIIColor?
        
        public init(address: Address, value: String, color: ASCIIColor? = nil) {
            self.address = address
            self.value = value
            self.color = color
        }
    }
    
    public struct Captions {
        public let columns: [String]
        public let rows: [String]
        public init(columns: [String], rows: [String]? = nil) {
            self.columns = columns
            self.rows = rows ?? []
        }
        
        public init(rows: [String]) {
            self.columns = []
            self.rows = rows
        }
    }
    
    private var values: [Cell] = []
    var paddingString: String = " "
    
    private func index(of address: Address) -> Int? {
        values.firstIndex(where: { $0.address == address })
    }
    
    @discardableResult
    private func remove(cellAt address: Address) -> Cell? {
        guard let index = index(of: address) else { return nil }
        let cell = values[index]
        values.remove(at: index)
        return cell
    }
    
    public func value(at address: Address) -> String? {
        values.cell(at: address)?.value
    }
    
    public func set(value: String?, at address: Address, color: ASCIIColor? = nil) {
        remove(cellAt: address)
        
        if let newValue = value {
            values.append(Cell(address:address, value: newValue, color: color))
        }
    }
    
    public func set(color: ASCIIColor, at address: Address) {
        guard let cell = values.cell(at: address) else { return }
        
        remove(cellAt: address)
        set(value: cell.value, at: cell.address, color: color)
    }
            
    public func stringValue(useColors: Bool, header: Captions? = nil) -> String {
        var resultRows: [String] = []
        var cells = self.values
        
        var hasColumnHeader: Bool = false
        if let columnsHeader = header?.columns, columnsHeader.count > 0 {
            var cellsWithColumnsHeader: [Cell] = []
            for cell in cells {
                let shiftedCell = Cell(address: (x: cell.address.x, y: cell.address.y + 1), value: cell.value, color: cell.color)
                cellsWithColumnsHeader.append(shiftedCell)
            }
            for (index, columnCaption) in columnsHeader.enumerated() {
                cellsWithColumnsHeader.append(Cell(address: (x: index, y: 0), value: columnCaption))
            }
            cells = cellsWithColumnsHeader
            hasColumnHeader = true
        }
        
        if let rowsHeader = header?.rows, rowsHeader.count > 0 {
            var cellWithRowsHeader: [Cell] = []
            for cell in cells {
                let shiftedCell = Cell(address: (x: cell.address.x + 1, y: cell.address.y), value: cell.value, color: cell.color)
                cellWithRowsHeader.append(shiftedCell)
            }
            for (index, rowHeader) in rowsHeader.enumerated() {
                let rowIndex = index + ((hasColumnHeader) ? 1 : 0)
                cellWithRowsHeader.append(Cell(address: (x: 0, y: rowIndex), value: rowHeader))
            }
            cells = cellWithRowsHeader
        }
        
        let numberOfColumns = cells.numberOfColumns
        let numberOfRows = cells.numberOfRows
        guard numberOfRows > 0 && numberOfColumns > 0 else { return "" }
        
        var widths: [Int] = []
        
        for i in 0 ..< numberOfColumns {
            let cells = cells.cells(inColumn: i)
            if let maxWidth = cells.map({ $0.value.length }).max() {
                widths.append(maxWidth + (2 * self.paddingString.count))
            } else {
                widths.append(0)
            }
        }
        
        var lineLength: Int = 0
                        
        for row in 0 ..< numberOfRows {
            var rowLength: Int = 0
            var resultRowColumns: [String] = []
            let cellsInRow = cells.cells(inRow: row)
            for column in 0 ..< numberOfColumns {
                let columnWidth = widths[column]
                var value: String = ""
                let cell = cellsInRow.cell(at: (x: column, y: row))
                if let cellValue = cell?.value {
                    value = cellValue.tableStringValue
                }
                let color = useColors ? cell?.color : nil
                resultRowColumns.append(value.center(in: columnWidth, padding: self.paddingString, color: color))
                rowLength += columnWidth + 1
            }
            resultRows.append("|" + resultRowColumns.joined(separator: "|") + "|")
            lineLength = max(lineLength, rowLength + 1)
        }
        
        var result: String = ""
        
        if lineLength > 0 {
            result += "┌" + "─".repeat(lineLength - 2) + "┐\n"
        }
        
        for (rowNumber, line) in resultRows.enumerated() {
            result += line + "\n"
            if rowNumber < resultRows.count - 1 {
                result += "├"
                for (index, width) in widths.enumerated() {
                    result += "─".repeat(width)
                    if index < widths.count - 1 {
                        result += "┼"
                    }
                }
                result += "┤\n"
            }
        }
        
        if lineLength > 0 {
            result += "└"
            for (index, width) in widths.enumerated() {
                result += "─".repeat(width)
                if index < widths.count - 1 {
                    result += "┴"
                }
            }
            result += "┘\n"
        }
        
        return result
    }
}

public protocol Layoutable {
    var length: Int { get }
    var tableStringValue: String { get }
}

extension String: Layoutable {
    public var length: Int { count }
    public var tableStringValue: String { self }
    
    
}

extension String {
    public func `repeat`(_ times: Int) -> String {
        var result = ""
        for _ in 0 ..< times {
            result += self
        }
        return result
    }
    
    public func center(in width: Int, padding: String, color: ASCIIColor? = nil) -> String {
        let spaceLeft = width - self.count
        let halfSpaceLeft: Float = Float(spaceLeft) / 2.0
        var layoutedValue: String = padding.repeat(Int(halfSpaceLeft.rounded(.down)))
        let valueLength = layoutedValue.count + self.count
        if let color = color {
            layoutedValue += "\(self, color: color)"
        } else {
            layoutedValue += self
        }
        layoutedValue += padding.repeat(width - valueLength)
        return layoutedValue
    }
}

extension Int {
    var isEven: Bool { self % 2 == 0 }
    var isOdd: Bool { !isEven }
}

extension Sequence where Element == Table.Cell {
    func cells(inRow y: Int) -> [Table.Cell] {
        filter { $0.address.y ==  y }
    }
    
    func cells(inColumn x: Int) -> [Table.Cell] {
        filter { $0.address.x == x }
    }
    
    func cell(at address: Table.Address) -> Table.Cell? {
        first(where: { $0.address == address })
    }
    
    var numberOfRows: Int {
        guard let maxIndex = map({ $0.address.y }).max() else { return 0 }
        return maxIndex + 1
    }
    
    var numberOfColumns: Int {
        guard let maxIndex = map({ $0.address.x }).max() else { return 0 }
        return maxIndex + 1
    }
}

public enum ASCIIColor: String {
    case black = "\u{001B}[0;30m"
    case red = "\u{001B}[0;31m"
    case green = "\u{001B}[0;32m"
    case yellow = "\u{001B}[0;33m"
    case blue = "\u{001B}[0;34m"
    case magenta = "\u{001B}[0;35m"
    case cyan = "\u{001B}[0;36m"
    case white = "\u{001B}[0;37m"
    case `default` = "\u{001B}[0;0m"
}

extension DefaultStringInterpolation {
    mutating func appendInterpolation<T: CustomStringConvertible>(_ value: T, color: ASCIIColor) {
            appendInterpolation("\(color.rawValue)\(value)\(ASCIIColor.default.rawValue)")        
    }
}
