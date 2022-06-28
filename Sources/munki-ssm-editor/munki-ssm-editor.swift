import ArgumentParser
import Darwin

@main
struct MunkiSSMEditor: ParsableCommand {
    static var configuration = CommandConfiguration(
        // Optional abstracts and discussions are used for help output.
        abstract: "Edits the Munki Self Service Manifest",

        // Commands can define a version for automatic '--version' support.
        version: "1.0.0",

        // Pass an array to `subcommands` to set up a nested tree of subcommands.
        // With language support for type-level introspection, this could be
        // provided by automatically finding nested `ParsableCommand` types.
        subcommands: [Add.self, Replace.self, Remove.self],

        // A default subcommand, when provided, is automatically selected if a
        // subcommand is not given on the command line.
        defaultSubcommand: Add.self
    )
    
    static var entries: [String] = []
    
    static func loadEntries() {
        entries = [ "A", "B", "packagename", "C" ]
    }
    
    static func saveEntries() {
        print("saving \(entries)")
    }
}

struct Options: ParsableArguments {
    @Flag
    var verbose: Bool = false
}

extension MunkiSSMEditor {
    struct Add: ParsableCommand {
        static var configuration = CommandConfiguration(
            abstract: "Add a package name"
        )
        
        @OptionGroup var options: Options

        @Argument
        var packageName: String
        
        mutating func run() {
            loadEntries()
            
            if entries.contains(packageName) == false {
                if options.verbose { print("Adding \(packageName)") }
                entries.append(packageName)
            } else {
                if options.verbose { print("\(packageName) already in SSM") }
            }

            saveEntries()
        }
    }
}

extension MunkiSSMEditor {
    struct Remove: ParsableCommand {
        static var configuration = CommandConfiguration(
            abstract: "Remove a package name"
        )

        @OptionGroup var options: Options

        @Argument
        var packageName: String
        
        mutating func run() {
            loadEntries()
            
            if entries.contains(packageName) {
                if options.verbose { print("Removing \(packageName)") }

                entries.removeAll() { entry in
                    entry == packageName
                }

            } else {
                if options.verbose { print("\(packageName) not in SSM") }
            }

            saveEntries()
        }
    }
}

extension MunkiSSMEditor {
    struct Replace: ParsableCommand {
        static var configuration = CommandConfiguration(
            abstract: "Swap a package name with another"
        )
        
        @OptionGroup var options: Options

        @Argument
        var oldPackageName: String
        
        @Argument
        var newPackageName: String
        
        mutating func run() {
            loadEntries()
            
            if entries.contains(oldPackageName) == false {
                if options.verbose { print("\(oldPackageName) not in SSM, can't replace") }
                return
            }
            
            entries = entries.map { entry in
                if entry == oldPackageName {
                    if options.verbose { print("swapping \(oldPackageName) to \(newPackageName)") }
                    return newPackageName
                } else {
                    return entry
                }
            }
            
            saveEntries()
        }
    }
}
