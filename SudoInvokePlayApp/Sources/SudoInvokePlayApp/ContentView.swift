//
//  ContentView.swift
//  SudoInvokePlayApp
//
//  Created by Kamaal M Farah on 9/6/25.
//

import SwiftUI

struct ContentView: View {
    @State private var hasBackup = false
    @State private var statusMessage = ""
    @State private var isOperationInProgress = false

    var body: some View {
        VStack(spacing: 20) {
            Button(action: sudoInvoke) {
                Text(isOperationInProgress ? "Processing..." : "Sudo invoke")
            }
            .disabled(isOperationInProgress)

            Button(action: restoreHostsFile) {
                Text(isOperationInProgress ? "Processing..." : "Restore hosts file")
            }
            .disabled(!hasBackup || isOperationInProgress)

            Text(hasBackup ? "Backup available" : "No backup found")
                .font(.caption)
                .foregroundColor(hasBackup ? .green : .gray)

            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
        .onAppear(perform: checkForBackup)
    }

    private func sudoInvoke() {
        isOperationInProgress = true
        statusMessage = "Reading hosts file..."

        let hostsFile = URL(fileURLWithPath: "/etc/hosts")
        let hostsFileContent: String
        do {
            hostsFileContent = try String(contentsOf: hostsFile)
        } catch {
            print("❌ Failed to read hosts file content", error)
            statusMessage = "Failed to read hosts file"
            isOperationInProgress = false
            return
        }

        statusMessage = "Creating backup..."
        createBackup(content: hostsFileContent)

        let modifiedContent = hostsFileContent + "\n# No-op comment added by SudoInvokePlay"

        statusMessage = "Waiting for authentication..."
        writeToHostsFile(content: modifiedContent)
    }

    private func createBackup(content: String) {
        let backupURL = getBackupURL()
        do {
            try content.write(to: backupURL, atomically: true, encoding: .utf8)
        } catch {
            print("❌ Failed to create backup: \(error)")
            return
        }

        print("✅ Backup created at: \(backupURL.path)")
        hasBackup = true
    }

    private func restoreHostsFile() {
        isOperationInProgress = true
        statusMessage = "Reading backup..."

        let backupURL = getBackupURL()
        guard FileManager.default.fileExists(atPath: backupURL.path) else {
            print("❌ No backup file found")
            statusMessage = "No backup file found"
            isOperationInProgress = false
            return
        }

        let backupContent: String
        do {
            backupContent = try String(contentsOf: backupURL)
        } catch {
            print("❌ Failed to read backup file: \(error)")
            statusMessage = "Failed to read backup file"
            isOperationInProgress = false
            return
        }

        statusMessage = "Waiting for authentication..."
        writeToHostsFile(content: backupContent)
        print("✅ Restored hosts file from backup")
    }

    private func checkForBackup() {
        let backupURL = getBackupURL()
        hasBackup = FileManager.default.fileExists(atPath: backupURL.path)
    }

    private func getBackupURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("hosts_backup.txt")
    }

    private func writeToHostsFile(content: String) {
        let tempFileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("hosts_temp")
        defer { try? FileManager.default.removeItem(at: tempFileURL) }

        do {
            try content.write(to: tempFileURL, atomically: true, encoding: .utf8)
        } catch {
            print("❌ Failed to write to hosts file", error)
            isOperationInProgress = false
            statusMessage = "❌ Failed to write to hosts file"

            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                statusMessage = ""
            }
            return
        }

        let script = """
        do shell script "cp '\(tempFileURL.path)' /etc/hosts" with administrator privileges
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
        } catch {
            print("❌ Failed to read backup file: \(error)")
            statusMessage = "Failed to read backup file"
            isOperationInProgress = false
            return
        }

        process.waitUntilExit()
        isOperationInProgress = false

        if process.terminationStatus == 0 {
            print("✅ Successfully updated hosts file")
            statusMessage = "✅ Successfully updated hosts file"
        } else {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? "Unknown error"
            if output.contains("-60005") || output.contains("administrator user name or password was incorrect") {
                print("❌ Authentication failed: Incorrect password or cancelled by user")
                print("💡 Please make sure you enter your administrator password when prompted")
                statusMessage = "❌ Authentication failed. Please try again with correct password."
            } else if output.contains("-128") || output.contains("User canceled") {
                print("❌ Operation cancelled by user")
                statusMessage = "❌ Operation cancelled by user"
            } else {
                print("❌ Failed to update hosts file: \(output)")
                statusMessage = "❌ Failed to update hosts file"
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            statusMessage = ""
        }
    }
}

#Preview {
    ContentView()
}
