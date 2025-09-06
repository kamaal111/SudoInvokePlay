//
//  ContentView.swift
//  SudoInvokePlayApp
//
//  Created by Kamaal M Farah on 9/6/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Button(action: sudoInvoke) {
                Text("Sudo invoke")
            }
        }
        .padding()
    }

    private func sudoInvoke() {
        print("🐸🐸🐸 Hello")
    }
}

#Preview {
    ContentView()
}
