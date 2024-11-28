import SwiftUICore
import SwiftUI

struct WordInputView: View {
    @Binding var word: String
    var onSubmit: () -> Void
    
    var body: some View {
        HStack {
            TextField("Enter word", text: $word)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Button(action: {
                onSubmit()
            }) {
                Text("Submit")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(word.isEmpty)
        }
        .padding()
    }
}
