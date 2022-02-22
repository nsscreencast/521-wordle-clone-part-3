import SwiftUI

final class GuessState: ObservableObject {
    @Published var guess: String = ""
    @Published private(set) var guesses: [String] = []

    func validateGuess() {
        while guess.count > 5 {
            guess.removeLast()
        }

        guess = guess.trimmingCharacters(in: .letters.inverted)
    }

    func checkCompleteGuess() {
        if guess.count == 5 {
            guesses.append(guess)
            guess = ""
        }
    }
}

struct ContentView: View {
    @ObservedObject var state = GuessState()

    var body: some View {
        ScrollView {
            VStack {
                Header()
                TextInput(text: $state.guess, onEnterPressed: {
                    state.checkCompleteGuess()
                })
                .opacity(0)
                LetterGrid(guess: state.guess, guesses: state.guesses)
                    .padding()
            }
        }
        .onChange(of: state.guess) { _ in
            state.validateGuess()
        }
    }
}

struct Header: View {
    var body: some View {
        VStack(spacing: 3) {
            HStack {
                Text("Wurdle".uppercased())
                    .font(.largeTitle)
                    .bold()
            }
            Rectangle().fill(Color.gray)
                .frame(height: 1)
        }
    }
}

struct TextInput: View {
    @Binding var text: String
    @FocusState var isFocused: Bool
    let onEnterPressed: () -> Void
    var body: some View {
        TextField("Word", text: $text)
            .textInputAutocapitalization(.characters)
            .keyboardType(.asciiCapable)
            .disableAutocorrection(true)
            .focused($isFocused)
            .onChange(of: isFocused, perform: { newFocus in
                if !newFocus {
                    onEnterPressed()
                    isFocused = true
                }
            })
            .task {
                try? await Task.sleep(nanoseconds: NSEC_PER_SEC/4)
                isFocused = true
            }
    }
}

struct LetterGrid: View {
    let width = 5
    let height = 6
    
    let guess: String
    let guesses: [String]

    var body: some View {
        VStack {
            ForEach(0..<height, id: \.self) { row in
                HStack {
                    ForEach(0..<width, id: \.self) { col in
                        LetterView(letter: character(row: row, col: col))
                    }
                }
            }
        }
    }
    
    private func character(row: Int, col: Int) -> Character {
        let string: String
        if row < guesses.count {
            string = guesses[row]
        } else if row == guesses.count {
            string = guess
        } else {
            return " "
        }
        guard col < string.count else { return  " " }
        return string[
            string.index(string.startIndex, offsetBy: col)
        ]
    }
}

struct LetterView: View {
    var letter: Character = " "
    @State var filled = false

    private let scaleAmount: CGFloat = 1.2

    var body: some View {
        Color.clear
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                    .opacity(filled ? 0 : 1)
                    .animation(.none, value: filled)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.black, lineWidth: 2)
                    .scaleEffect(filled ? 1 : scaleAmount)
                    .opacity(filled ? 1 : 0)
            )
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                Text(String(letter))
                    .font(.system(size: 100))
                    .fontWeight(.heavy)
                    .minimumScaleFactor(0.1)
                    .scaleEffect(filled ? 1 : scaleAmount)
                    .padding(2)
            )
            .onChange(of: letter, perform: { newLetter in
                withAnimation {
                    if letter.isWhitespace && !newLetter.isWhitespace {
                        filled = true
                    } else if !letter.isWhitespace && newLetter.isWhitespace {
                        filled = false
                    }
                }
            })
    }

    var strokeColor: Color {
        if letter.isWhitespace {
            return Color.gray.opacity(0.3)
        } else {
            return Color.black
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
