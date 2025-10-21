import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "message.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
            
            Text("MessageAI")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("MVP Development")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("Building messaging infrastructure...")
                .font(.caption)
                .foregroundStyle(.gray)
                .padding(.top)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

