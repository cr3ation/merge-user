//
//  HelperClasses.swift
//  Home Folder Migration Tool
//
//  Created by Henrik Engström on 2019-11-27.
//  Copyright © 2019 Schibsted Enterprise Technology AB. All rights reserved.
//

import Foundation

class User {
    // Public properties
    let userName : String
    let homeDirectory : String
    //let homeDirectoryURL : URL
    var id : Int?
    var realName : String?
    var isAdmin : Bool?
    
    // Constructor
    init?(userName: String) {
        let homeDirectory = NSHomeDirectoryForUser(userName) ?? ""
        if homeDirectory == "" {
            return nil
        }

        self.userName = userName
        self.homeDirectory = homeDirectory
        //self.homeDirectoryURL = FileManager.default.homeDirectoryForCurrentUser
        
        // User numeric ID (eg. 501)
        var (out, _, _) = runCommand(cmd: "/usr/bin/id", args: ["-u", userName])
        guard let userId = Int(out[0]) else {
            return nil
        }
        self.id = userId
        
        // RealName (eg. "Henrik Engström")
        (out, _, _) = runCommand(cmd: "/usr/bin/dscl", args: [".", "-read", "/Users/\(userName)", "RealName"])
        let realName = out[1].trimmingCharacters(in: .whitespacesAndNewlines)
        self.realName = realName
        
        // Is Admin (member of group 80)?
        (out, _, _) = runCommand(cmd: "/usr/bin/id", args: ["-G", "\(userName)"])
        self.isAdmin = out[0].contains(" 80 ")
    }
    
    // HELPER FUNCTIONS
    private func directoryExistsAtPath(_ path: String) -> Bool {
        var isDirectory = ObjCBool(true)
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
    
    // Run shell command
    private func runCommand(cmd : String, args : [String]) -> (output: [String], error: [String], exitCode: Int32) {
        
        var output : [String] = []
        var error : [String] = []
        
        let task = Process()
        task.launchPath = cmd
        task.arguments = args
        task.currentDirectoryPath = "/"
        
        let outpipe = Pipe()
        task.standardOutput = outpipe
        let errpipe = Pipe()
        task.standardError = errpipe
        
        task.launch()
        
        let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
        if var string = String(data: outdata, encoding: .utf8) {
            string = string.trimmingCharacters(in: .newlines)
            output = string.components(separatedBy: "\n")
        }
        
        let errdata = errpipe.fileHandleForReading.readDataToEndOfFile()
        if var string = String(data: errdata, encoding: .utf8) {
            string = string.trimmingCharacters(in: .newlines)
            error = string.components(separatedBy: "\n")
        }
        
        task.waitUntilExit()
        let status = task.terminationStatus
        
        return (output, error, status)
    }
}
