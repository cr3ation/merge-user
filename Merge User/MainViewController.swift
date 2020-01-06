//
//  MainViewController.swift
//  Home Folder Migration Tool
//
//  Created by Henrik Engström on 2019-11-27.
//  Copyright © 2019 Schibsted Enterprise Technology AB. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController {

    var users : [User] = []                             // All found users
    var oldUser = User(userName: "")                    // User before namechamge
    let currentUser = User(userName: NSUserName())      // User after namechamge
    
    // Outlets
    @IBOutlet weak var currentUserName: NSTextField!
    @IBOutlet weak var oldUsersComboBox: NSComboBoxCell!
    
    @IBOutlet weak var newUserID: NSTextField!
    @IBOutlet weak var newUserRealName: NSTextField!
    @IBOutlet weak var newUserHomeFolder: NSTextField!
    
    @IBOutlet weak var oldUserRealName: NSTextField!
    @IBOutlet weak var oldUserID: NSTextField!
    @IBOutlet weak var oldUserHomeFolder: NSTextField!
    
    @IBOutlet weak var createAliasButton: NSButton!
    
    // Update GUI when user selected from dropdown
    @IBAction func oldUserComboBoxChanged(_ sender: Any) {
        oldUser = User(userName: oldUsersComboBox.stringValue)
        
        // GUI if no valid user is selected
        if oldUser == nil {
            oldUserRealName.stringValue = ""
            oldUserID.stringValue = ""
            oldUserHomeFolder.stringValue = ""
            createAliasButton.isEnabled = false
            return
        } else {
            // GUI if user selected in dropdown.
            oldUserRealName.stringValue = oldUser?.realName ?? "ERROR"
            oldUserID.stringValue = "\(oldUser?.id ?? 1337)"
            oldUserHomeFolder.stringValue = oldUser?.homeDirectory ?? "ERROR"
            createAliasButton.isEnabled = true
        }
    }
    
    // Actions
    @IBAction func createAlias(_ sender: Any) {
        if currentUser?.isAdmin == false {
            _ = dialogOK(question: "Permission denied", text: "\(NSUserName()) needs to be an Administrator.")
            return
        }
        
        do {
            // Script creation
            try createMigrationScript(newUser: currentUser!, oldUser: oldUser!)
            try createAppleScript(newUser: currentUser!, oldUser: oldUser!)
            
            // Start migration
            let (output, error, status) = runCommand(cmd: "/usr/bin/osascript", args: ["/private/tmp/merge-user-applescript.scpt"])
            printShellOutput(output: output, error: error, exitCode: status)
        }
        catch {
            _ = dialogOK(question: "Ooh nose.", text: "\(error)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
                
        // Find folders in /Users/ and create user-objects
              
        // Setting up GUI
        oldUsersComboBox.removeAllItems()
        
        // Current user
        currentUserName.stringValue = "\(currentUser!.userName)"
        newUserID.stringValue = "\(currentUser?.id ?? 1337)"
        newUserRealName.stringValue = currentUser!.realName!
        newUserHomeFolder.stringValue = currentUser!.homeDirectory
        
        // Old user
        oldUserID.stringValue = ""
        oldUserRealName.stringValue = ""
        oldUserHomeFolder.stringValue = ""
        
        // Add content to dropdown
        do {
            let folders = try FileManager().contentsOfDirectory(atPath: "/Users/")
            for folder in folders{
                // Skip users Shared, root, .localized and woz.
                if folder == "Shared" || folder == "root" || folder == ".localized" || folder == "woz"{
                    continue
                }
                print(folder)
                let user = User(userName: folder)
                if user != nil && user?.id != currentUser?.id {
                    users.append(user!)
                    oldUsersComboBox.addItem(withObjectValue: user!.userName)
                }
            }
        }
        catch {
            _ = dialogOK(question: "Ooh nose.", text: "\(error)");
        }
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    
    // -------------------------------------------------------------
    // --------------- MIGRATION FUNCTIONS -----------------------------
    // -------------------------------------------------------------
    
    private func createMigrationScript(newUser : User, oldUser : User) throws {
        let str = """
        #!/bin/sh
        
        # Change the married spoken name
        dscl . change /Users/\(newUser.userName) RealName "\(newUser.realName ?? "Unknown username")" "Do not use me";
        
        # Change married home directory
        dscl . change /Users/\(newUser.userName) NFSHomeDirectory "\(newUser.homeDirectory)" "\(newUser.homeDirectory).migrated"
        
        # Change the married users username
        dscl . change /Users/\(newUser.userName) RecordName \(newUser.userName) \(newUser.userName).migrated;
              
        # Add married name as alias to the unmarried
        dscl . -merge Users/\(oldUser.userName) RecordName "\(newUser.userName)";
                
        # Move the married users home folder
        mv -f "\(newUser.homeDirectory)" "\(newUser.homeDirectory).migrated"
        
        # Rename unmarried user home folder
        mv -f \(oldUser.homeDirectory) "\(newUser.homeDirectory)" ;
                
        # Update the unmarried spoken name
        dscl . change /Users/\(oldUser.userName) RealName "\(oldUser.realName ?? "Unknown username")" "\(newUser.realName ?? "Unknown username")"
        
        # Update the unmarried home directory
        dscl . change /Users/\(oldUser.userName) NFSHomeDirectory "\(oldUser.homeDirectory)" "\(newUser.homeDirectory)"
        
        echo ""
        echo "DONE! Please reboot the computer to finish migration."
        echo ""
        """
        
        // Migration script
        let fileURL = URL(fileURLWithPath: "/private/tmp/merge-user.sh")
        
        // Write scripts and ensure +x
        // Migration script
        do {
        try str.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
        let (output, error, status) = runCommand(cmd: "/bin/chmod", args: ["+x", "\(fileURL.path)"])
        printShellOutput(output: output, error: error, exitCode: status)
        }
        catch {
            _ = dialogOK(question: "Ooh nose.", text: "\(error)");
        }
    }
    
    private func createAppleScript(newUser : User, oldUser : User) throws {
        let appleScript = """
        tell application "Terminal"
            activate
            set currentTab to do script ("clear;echo;echo Enter password to continue with user migration;echo;echo User: \(newUser.userName);sudo /private/tmp/merge-user.sh")
        end tell
        """

        // Apple Script that starts migration script
        let appleScriptURL = URL(fileURLWithPath: "/private/tmp/merge-user-applescript.scpt")

        do {
            // AppleScript
            try appleScript.write(to: appleScriptURL, atomically: true, encoding: String.Encoding.utf8)
            let (output, error, status) = runCommand(cmd: "/bin/chmod", args: ["+x", "\(appleScriptURL.path)"])
            printShellOutput(output: output, error: error, exitCode: status)
        } catch {
            _ = dialogOK(question: "Ooh nose.", text: "\(error)");
        }
    }
    
    // --------------------------------------------------------------
    // ---------------- HELPER STUFF --------------------------------
    // --------------------------------------------------------------
    private func dialogOK(question: String, text: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        return alert.runModal() == .alertFirstButtonReturn
    }
    
    private func printShellOutput(output: [String], error: [String], exitCode: Int32 ){
        if exitCode > 0 {
            if output.count > 1 {
                var out = ""
                for row in output {
                    out = out + row + "\n"
                }
                let (_) = dialogOK(question: "Ooh nose!", text: "An error was thrown with the following output:\n\n" + out)
            }
            if  error.count > 1 {
                var err = ""
                for row in error {
                    err = err + row + "\n"
                }
                let (_) = dialogOK(question: "Ooh nose!", text: "An error was thrown with the following error:\n\n" + err)
            }
        }
    }
    
    private func runCommandAsRoot(cmd : String) {
        NSAppleScript(source: "do shell script \"\(cmd)\" with administrator " +
            "privileges")!.executeAndReturnError(nil)
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
