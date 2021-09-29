import Foundation
import ayto_solver
import Logging
import ArgumentParser

@main
struct ayto: ParsableCommand {
    
    enum InputError: Error {
        case jsonFilePathInvalid
    }
    
    @Argument(help: "The JSON file containing the game's data.")
    var jsonFile: String
    
    @Flag(help: "Prints all matching nights including the final matches.")
    var printNights = false
    
    @Flag(help: "Prints the final matrix")
    var printMatrix = false
    
    @Flag(inversion: FlagInversion.prefixedNo, help: "Prints the final solution.")
    var printSolution = true
    
    @Flag(help: "Prints verbose output about deduces matches.") 
    var verbose = false
    
    @Flag(inversion: FlagInversion.prefixedNo, help: "Use colors to make the output easier to read")
    var colors = true
    
    mutating func run() throws {
        var logger = Logger(label: "com.danielkbx.ayto")
        
        if verbose {
            logger.logLevel = .debug
        }
        
        let workingDirectory: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
        let fileUrl = URL(fileURLWithPath: jsonFile, isDirectory: false, relativeTo: workingDirectory)
        
        var fileUrlIsDirectory: ObjCBool = false
        if !FileManager.default.fileExists(atPath: fileUrl.path, isDirectory: &fileUrlIsDirectory) || fileUrlIsDirectory.boolValue {
            throw InputError.jsonFilePathInvalid
        }
        
        let data = try Data(contentsOf: fileUrl)
        
        let game = try Transport.Game.game(fromData: data)
        
        
        let solution = try game.solve(logger: logger)
        
        if printNights {
            for night in game.matchingNights {
                let nightTable = Table()
                print("\(night.title), \(night.hits) hits")
                for (index, pair) in night.pairs.enumerated() {
                    let person1 = pair.person(with: .female)
                    let person2 = try pair.not(person: person1)
                    nightTable.set(value: person1.name, at: (x: 0, y: index))
                    nightTable.set(value: person2.name, at: (x: 1, y: index))
                    
                    let match = game.knownMatches.matches(with: pair).first
                    nightTable.set(value: indicator(forMatch: match), at: (x:2, y: index))
                    
                }
                print(nightTable.stringValue(useColors: self.colors))
            }
        }
        
        if printMatrix {
            var columns = game.persons.with(gender: .male).sorted(by: { $0.name < $1.name })
            columns += game.persons.with(gender: .male).with(role: .extra).sorted(by: { $0.name < $1.name })
            var rows = game.persons.with(gender: .female).with(role: .regular).sorted(by: { $0.name < $1.name })
            rows += game.persons.with(gender: .female).with(role: .extra).sorted(by: { $0.name < $1.name })
            
            let table = Table()
            
            for (indexM, columnPerson) in columns.enumerated() {
                for (indexF, rowPerson) in rows.enumerated() {
                    if let match = game.knownMatches.matches(with: columnPerson, and: rowPerson).first {
                        table.set(value: match.isMatch ? "✓" : "-", at: (x: indexM, y: indexF), color: match.isMatch ? .green : .red)
                    }
                }
            }
            
            let columnCaptions = columns.map { $0.role == .extra ? "\($0.name) (E)" : $0.name }
            let rowCaptions = rows.map { $0.role == .extra ? "\($0.name) (E)" : $0.name }
            print("\nFinal Matrix:")
            print(table.stringValue(useColors: self.colors, header: Table.Captions(columns: columnCaptions, rows: rowCaptions)))
        }
        
        if printSolution {
            print("\nSolution (\(solution.matches.count) matches), took \(solution.calculationLoops) loops:")
            let matchesTable = Table()
            for (index, match) in solution.matches.enumerated() {
                let person1 = match.pair.person(with: .female)
                let person2 = try match.pair.not(person: person1)
                matchesTable.set(value: person1.name, at: (x:0, y: index))
                matchesTable.set(value: person2.name, at: (x:1, y: index))
            }
            print(matchesTable.stringValue(useColors: self.colors))
        }
        
    }
    
    func indicator(forMatch match: Match?) -> String {
        guard let match = match else { return "" }
        switch match.isMatch {
        case true: return "✓"
        case false: return "-"
        }
    }
    
}
