//
//  ContentView.swift
//  Test_MoveSentences_ChatGPT
//
//  Created by Tom Flahive on 6/11/23.
//

import SwiftUI
import UniformTypeIdentifiers

struct SentenceSelectionView: View {
    @State private var attributedText = NSMutableAttributedString(string: "This is a sample sentence. Here's another one. And one more for good measure.")

    var body: some View {
        VStack {
            CustomTextView(attributedText: $attributedText)
                .frame(height: 200)
        }
    }
}

struct CustomTextView: UIViewRepresentable {
    @Binding var attributedText: NSMutableAttributedString

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.isEditable = false
        textView.isSelectable = true
        textView.attributedText = attributedText
        textView.isUserInteractionEnabled = true
        
        // Setup Drag Interaction
        let dragInteraction = UIDragInteraction(delegate: context.coordinator)
        textView.addInteraction(dragInteraction)
        
        // Setup Drop Interaction
        let dropInteraction = UIDropInteraction(delegate: context.coordinator)
        textView.addInteraction(dropInteraction)
        
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = attributedText
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate, UIDragInteractionDelegate, UIDropInteractionDelegate {
        var parent: CustomTextView
        var selectedSentenceRange: NSRange?

        init(_ parent: CustomTextView) {
            self.parent = parent
        }

        // Drag Interaction
        // Drag Interaction
        func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
            guard let range = selectedSentenceRange else {
                return []
            }
            let sentence = parent.attributedText.attributedSubstring(from: range)
            let itemProvider = NSItemProvider(object: sentence.string as NSString)
            return [UIDragItem(itemProvider: itemProvider)]
        }

        
        // Drop Interaction
        func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
            return session.hasItemsConforming(toTypeIdentifiers: [UTType.plainText.identifier]) && selectedSentenceRange != nil

        }
        
        // Drop Interaction
        func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
            guard let textView = interaction.view as? UITextView,
                  let textPosition = textView.closestPosition(to: session.location(in: textView)),
                  let textRange = textView.tokenizer.rangeEnclosingPosition(textPosition, with: .sentence, inDirection: UITextDirection.storage(.backward)),
                  let targetRange = textView.textRange(from: textRange.start, to: textRange.end),
                  let range = selectedSentenceRange else {
                return
            }
            
            let sentence = parent.attributedText.attributedSubstring(from: range)
            
            let nsRange = textView.offset(from: textView.beginningOfDocument, to: targetRange.start)..<textView.offset(from: textView.beginningOfDocument, to: targetRange.end)
            
            // Removing the old sentence
            parent.attributedText.deleteCharacters(in: range)
            
            // Inserting the dragged sentence at the new position
            parent.attributedText.insert(sentence, at: nsRange.lowerBound)
            
            textView.attributedText = parent.attributedText
            selectedSentenceRange = nil
        }


        
        // Detecting Sentence Selection
        func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            guard let text = textView.attributedText?.string else { return true }
            let nsString = text as NSString
            guard let sentenceRange = nsString.rangeOfSentence(for: characterRange) else { return true }

            // Clear previous highlights
            parent.attributedText.removeAttribute(.backgroundColor, range: NSRange(location: 0, length: parent.attributedText.length))

            // Highlight the selected sentence
            parent.attributedText.addAttribute(.backgroundColor, value: UIColor.yellow, range: sentenceRange)
            textView.attributedText = parent.attributedText

            // Storing the range of the selected sentence
            selectedSentenceRange = sentenceRange

            return false
        }
    }
}

extension NSString {
    func rangeOfSentence(for characterRange: NSRange) -> NSRange? {
        let punctuationCharacters = CharacterSet(charactersIn: ".!?")
        let fullRange = NSRange(location: 0, length: self.length)
        let range = self.rangeOfCharacter(from: punctuationCharacters,
                                           options: .backwards,
                                           range: NSRange(location: 0, length: characterRange.location))
        let start = range.location != NSNotFound ? range.upperBound : fullRange.location
        let endRange = self.rangeOfCharacter(from: punctuationCharacters,
                                             options: [],
                                             range: NSRange(location: characterRange.upperBound, length: self.length - characterRange.upperBound))
        let end = endRange.location != NSNotFound ? endRange.upperBound : fullRange.upperBound
        return NSRange(location: start, length: end - start)
    }
}


struct SentenceSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        SentenceSelectionView()
    }
}

