import Foundation

/// Keeps "who is who" straight in Couple replies. A pasted message is written
/// by the user's partner, so the words it uses for "I" and "you" are the
/// reverse of what the user must write back.
enum CouplePronouns {
    /// "anh/em" -> how the user calls themselves (`me`) and their partner (`you`).
    static func forms(from address: String) -> (me: String, you: String) {
        let parts = address.split(separator: "/").map { String($0) }
        guard parts.count == 2, !parts[0].isEmpty, !parts[1].isEmpty else {
            return (me: "anh", you: "em")
        }
        // The "bạn/mình" choice lists the partner first.
        if parts[0] == "bạn" && parts[1] == "mình" { return (me: "mình", you: "bạn") }
        return (me: parts[0], you: parts[1])
    }

    private static let kinship: Set<String> = ["anh", "em", "chị"]
    private static let vocatives: Set<String> = ["ơi", "à", "ạ", "nè", "nha", "nhé", "ê", "này"]

    /// When a message opens with "Em ... anh ..." the sender calls themselves
    /// "em" and the reader (the user) "anh". Returns nil when it is not clear.
    static func senderForms(in incoming: String) -> (sender: String, receiver: String)? {
        // In a chat transcript only the other person's last message counts.
        let focus = ScreenshotTranscript.focusMessage(incoming)
        let words = focus.lowercased().split(whereSeparator: { !$0.isLetter }).map { String($0) }
        guard let first = words.first, kinship.contains(first) else { return nil }
        guard let other = words.dropFirst().first(where: { kinship.contains($0) && $0 != first }) else {
            return nil
        }
        // "Anh ơi, em nhớ anh": the opening word is only calling out to me.
        if words.count > 1, vocatives.contains(words[1]) {
            return (sender: other, receiver: first)
        }
        return (sender: first, receiver: other)
    }

    /// The forms to use in the reply: what the message itself shows if that is
    /// clear, otherwise the user's saved choice.
    static func resolved(address: String, incoming: String) -> (me: String, you: String) {
        if let seen = senderForms(in: incoming) {
            return (me: seen.receiver, you: seen.sender)
        }
        return forms(from: address)
    }

    /// Instructions for the AI about who wrote the message and who replies.
    static func rule(address: String, incoming: String) -> String {
        let saved = forms(from: address)
        var text = """
        WHO IS WHO (very important): the pasted incoming message was written by my partner, NOT by me. I am the one replying.
        By my settings, in every reply I call myself "\(saved.me)" and I call my partner "\(saved.you)".
        The pronouns inside the incoming message are from my partner's point of view, so they are reversed for me: the word my partner uses for themselves is the word I use for THEM, and the word my partner uses for me is the word I use for MYSELF.
        Example: my partner writes "Em nhớ anh lắm" (they say "em" for themselves and "anh" for me). My reply is "Anh cũng nhớ em lắm", never "Em cũng nhớ anh".
        Never write as if I were my partner, and never copy my partner's self-pronoun for myself.
        """
        if let seen = senderForms(in: incoming) {
            text += "\nFor THIS message: the sender calls themselves \"\(seen.sender)\" and calls me \"\(seen.receiver)\". So in my replies I call myself \"\(seen.receiver)\" and I call the sender \"\(seen.sender)\". If that differs from my settings above, follow this message."
        }
        return text
    }

    /// Built-in examples are written with "anh" for the user and "em" for the
    /// partner. Rewrite those two words to the forms of this conversation.
    static func adapt(_ text: String, me: String, you: String) -> String {
        if me == "anh" && you == "em" { return text }
        guard let regex = try? NSRegularExpression(
            pattern: "(?<![\\p{L}])(anh|em)(?![\\p{L}])", options: [.caseInsensitive]) else {
            return text
        }
        let source = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: source.length))
        var output = ""
        var cursor = 0
        for match in matches {
            output += source.substring(with: NSRange(location: cursor,
                                                     length: match.range.location - cursor))
            let word = source.substring(with: match.range)
            let replacement = word.lowercased() == "anh" ? me : you
            if word.first?.isUppercase == true {
                output += replacement.prefix(1).uppercased() + replacement.dropFirst()
            } else {
                output += replacement
            }
            cursor = match.range.location + match.range.length
        }
        output += source.substring(from: cursor)
        return output
    }
}
