import Foundation
import ayto_solver
import Logging
import ArgumentParser
import Darwin

@main
struct ayto: ParsableCommand {
        
    enum InputError: Error {
        case jsonFilePathInvalid
    }
    
    @Argument(help: "The JSON file containing the game's data.")
    var jsonFile: String
    
    @Flag(help: "Prints all matching nights including the final matches.")
    var printNights = false
    
    @Flag(help: "Prints the final matrix.")
    var printMatrix = false
    
    @Flag(inversion: .prefixedNo, help: "Prints the final solution.")
    var printSolution = true
    
    @Flag(help: "Prints verbose output about deduces matches.") 
    var verbose = false
    
    @Flag(inversion: .prefixedNo, help: "Use colors to make the output easier to read.")
    var colors = true
    
    @Flag(inversion: .prefixedNo, help: "Enables extended calculation so that more pairs can be excluded. Might take a couple of seconds.")
    var extendedCalculations = true
    
    func run() throws {
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
        
        do {
            let solution = try game.solve(logger: logger, extendedCalculations: self.extendedCalculations) { loop, game, nights in
                guard self.verbose else { return true }
                
                for night in nights.sorted(by: { $0.title < $1.title }) {
                    self.printNight(night, game: game)
                }
                print("\nMatrix after loop \(loop):")
                self.printMatrix(game)
                print("= End Loop \(loop) ====================================================\n")
                return true
            }
            
            if printNights {
                print("\nFinal Matching Nights:")
                for night in game.matchingNights {
                    self.printNight(night, game: game)
                }
            }
            
            if printMatrix {
                print("\nFinal Matrix:")
                printMatrix(game)
            }
            
            if printSolution {
                print("\nSolution (\(solution.matches.count) matches), took \(solution.calculationLoops) loops and \(solution.exclusionTries) extended tries:")
                let matchesTable = Table()
                for (index, match) in solution.matches.enumerated() {
                    let person1 = match.pair.person(with: .female)
                    let person2 = try match.pair.not(person: person1)
                    matchesTable.set(value: person1.name, at: (x:0, y: index))
                    matchesTable.set(value: person2.name, at: (x:1, y: index))
                    let color: ASCIIColor = person1.role == .extra || person2.role == .extra ? .yellow : .green
                    matchesTable.set(color: color, at: (x:0, y: index))
                    matchesTable.set(color: color, at: (x:1, y: index))
                }
                print(matchesTable.stringValue(useColors: self.colors))
            }
        } catch Game.SolveError.conflictingMatches(let pair) {
            print("Pair has conflicting matches: \(pair.person1.name), \(pair.person2.name)")
            Darwin.exit(1)
        } catch Game.SolveError.contradictoryMatches(let matches) {
            print("Contradictory matches: \(matches.map({ "\($0.pair.person1.name) + \($0.pair.person2.name): \($0.isMatch ? "match" : "no match")" }))")
            Darwin.exit(2)
        } catch Game.SolveError.matchingNightExceedsHits(let night) {
            print("More matches than hits in matching night\n")
            self.printNight(night, game: game)
            Darwin.exit(3)
        } catch Game.SolveError.matchingNightExceedsNoHits(let night) {
            print("More no matches than no hits in matching night\n")
            self.printNight(night, game: game)
            Darwin.exit(4)
        } catch Game.SolveError.matchingNightNotUnique(let night, let person) {
            print("Person \(person.name) in one than 1 pair in matching night\n")
            self.printNight(night, game: game)
            Darwin.exit(5)
        } catch Game.ConstrainsError.personsGenderNotBalanced(let male, let female) {
            print("Number of persons must be balanced, have \(female) female and \(male) male persons")
            Darwin.exit(6)
        } catch {
            throw error
        }
    }
    
    func indicator(forMatch match: Match?) -> String {
        guard let match = match else { return "" }
        switch match.isMatch {
        case true: return "✓"
        case false: return "x"
        }
    }
    
    func printMatrix(_ game: Game) {
        var columns = game.persons.with(gender: .male).with(role: .regular).sorted(by: { $0.name < $1.name })
        columns += game.persons.with(gender: .male).with(role: .extra).sorted(by: { $0.name < $1.name })
        var rows = game.persons.with(gender: .female).with(role: .regular).sorted(by: { $0.name < $1.name })
        rows += game.persons.with(gender: .female).with(role: .extra).sorted(by: { $0.name < $1.name })
        
        let table = Table()
        
        for (indexM, columnPerson) in columns.enumerated() {
            for (indexF, rowPerson) in rows.enumerated() {
                if let match = game.knownMatches.matches(with: columnPerson, and: rowPerson).first {
                    table.set(value: match.isMatch ? "✓" : "x", at: (x: indexM, y: indexF), color: match.isMatch ? .green : .red)
                }
            }
        }
        
        let columnCaptions = columns.map { $0.role == .extra ? "\($0.name) (E)" : $0.name }
        let rowCaptions = rows.map { $0.role == .extra ? "\($0.name) (E)" : $0.name }
        print(table.stringValue(useColors: self.colors, header: Table.Captions(columns: columnCaptions, rows: rowCaptions)))
    }
    
    func printNight(_ night: MatchingNight, game: Game) {
        let nightTable = Table()
        print("\(night.title), \(night.hits) hits")
        for (index, pair) in night.pairs.enumerated() {
            let person1 = pair.person(with: .female)
            let person2 = try! pair.not(person: person1)
            nightTable.set(value: person1.name, at: (x: 0, y: index))
            nightTable.set(value: person2.name, at: (x: 1, y: index))
            
            let match = game.knownMatches.matches(with: pair).first
            nightTable.set(value: indicator(forMatch: match), at: (x:2, y: index))
            if let match = match {
                nightTable.set(color: match.isMatch ? .green : .red, at: (x:0, y: index))
                nightTable.set(color: match.isMatch ? .green : .red, at: (x:1, y: index))
                nightTable.set(color: match.isMatch ? .green : .red, at: (x:2, y: index))
            }
            
        }
        print(nightTable.stringValue(useColors: self.colors))
    }
    
}
