import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "figure.run")
                    .imageScale(.large)
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("Goro")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Goro Maker")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Goro")
        }
    }
}

#Preview {
    ContentView()
}
