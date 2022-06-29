import ArgumentParser
import Darwin
import Foundation

let SSMURL = URL(fileURLWithPath: "/Library/Managed Installs/manifests/SelfServeManifest")

struct SSMEntries {
    var installs: [String] = []
    var uninstalls: [String] = []
    
    mutating func load() throws {
        do {
            let data = try Data(contentsOf: SSMURL)
            if let ssm = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String:[String]] {
                installs = ssm["managed_installs"]!
                uninstalls = ssm["managed_uninstalls"]!
            }
        } catch {
            print(error)
            throw ExitCode.init(-1)
        }
    }
    
    func save() throws {
        let plist = [ "managed_installs": self.installs,
                      "managed_uninstalls": self.uninstalls ]
        
        if let stream = OutputStream.init(url: SSMURL, append: false) {
            stream.open()
            let written = PropertyListSerialization.writePropertyList(plist, to: stream, format: .xml, options: 0, error: nil)
            
            if written == 0 {
                print("Couldn't write \(SSMURL.path) - are you not root?")
                throw ExitCode.init(-2)
            }
        } else {
            print("Couldn't open \(SSMURL.path) for writing")
            throw ExitCode.init(-2)
        }
    }
}

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
        
        mutating func run() throws {
            var entries = SSMEntries()
            try entries.load()
            
            if entries.installs.contains(where: { $0.lowercased() == packageName.lowercased() }) == false {
                if options.verbose { print("Adding \(packageName)") }
                entries.installs.append(packageName)
            } else {
                if options.verbose { print("\(packageName) already in SSM") }
            }

            try entries.save()
        }
    }
}

extension MunkiSSMEditor {
    struct Remove: ParsableCommand {
        static var configuration = CommandConfiguration(
            abstract: "Remove a package from the install list"
        )

        @OptionGroup var options: Options
        
        @Flag(help: "Add the removed package to the uninstall list")
        var uninstall: Bool = false

        @Argument
        var packageName: String
        
        mutating func run() throws {
            var entries = SSMEntries()
            try entries.load()

            if entries.installs.contains(where: { $0.lowercased() == packageName.lowercased() }) {
                if options.verbose { print("Removing \(packageName)") }

                entries.installs.removeAll() { entry in
                    entry.lowercased() == packageName.lowercased()
                }
                
                if uninstall {
                    if entries.uninstalls.contains(where: { $0.lowercased() == packageName.lowercased() }) == false {
                        entries.uninstalls.append(packageName)
                        if options.verbose { print("...adding \(packageName) to managed_uninstalls") }
                    } else {
                        if options.verbose { print("\(packageName) already in managed_uninstalls")}
                    }
                }

            } else {
                if options.verbose { print("\(packageName) not in SSM") }
            }

            try entries.save()
            
        }
    }
}

extension MunkiSSMEditor {
    struct Replace: ParsableCommand {
        static var configuration = CommandConfiguration(
            abstract: "Swap a package name with another"
        )
        
        @OptionGroup var options: Options

        @Flag(help: "Add the removed package to the uninstall list")
        var uninstall: Bool = false

        @Argument
        var oldPackageName: String
        
        @Argument
        var newPackageName: String
        
        mutating func run() throws {
            var entries = SSMEntries()
            try entries.load()

            if entries.installs.contains(where: { $0.lowercased() == oldPackageName.lowercased() }) == false {
                if options.verbose { print("\(oldPackageName) not in SSM, can't replace") }
                return
            }
            
            entries.installs = entries.installs.map { entry in
                if entry.lowercased() == oldPackageName.lowercased() {
                    if options.verbose { print("replacing \(oldPackageName) with \(newPackageName)") }
                    if uninstall {
                        if options.verbose { print("...adding \(oldPackageName) to managed_uninstalls") }
                        entries.uninstalls.append(oldPackageName)
                    }
                    return newPackageName
                } else {
                    return entry
                }
            }

            try entries.save()
        }
    }
}
