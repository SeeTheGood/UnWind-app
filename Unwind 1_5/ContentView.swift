import SwiftUI

struct ContentView: View {
    @State private var messages: [ChatMessage] = []
    @State private var userInput: String = ""
    private let unwind = Unwind1_5() // Instance of Unwind1_5

    var body: some View {
        VStack {
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(messages) { message in
                            HStack {
                                if message.isUser {
                                    Spacer()
                                    Text(message.text)
                                        .padding()
                                        .background(Color.blue.opacity(0.8))
                                        .cornerRadius(8)
                                        .padding(.horizontal)
                                        .foregroundColor(.white)
                                } else {
                                    Text(message.text)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(8)
                                        .padding(.horizontal)
                                }
                            }
                            .id(message.id) // Set the ID for scrolling purposes
                        }
                    }
                    .frame(maxWidth: .infinity) // Ensure VStack has a maximum width
                }
                .onChange(of: messages) {
                    // Scroll to the latest message
                    if let lastMessage = messages.last {
                        withAnimation {
                            scrollViewProxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            HStack {
                TextField("How are you feeling today?", text: $userInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .autocorrectionDisabled(true)

                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .padding()
                }
            }
            .padding(.horizontal)
        }
    }

    private func sendMessage() {
        guard !userInput.isEmpty else { return }
        let newMessage = ChatMessage(id: UUID(), text: userInput, isUser: true)
        messages.append(newMessage)
        userInput = ""
    }
}
