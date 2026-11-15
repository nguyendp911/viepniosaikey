import Foundation

/// Offline "add accents" suggestion for Vietnamese typed without diacritics:
/// "toi di an com" -> "tôi đi ăn cơm". Each accent-free syllable maps to its
/// likely accented forms (most frequent first); a small Viterbi pass then
/// picks the best chain using the built-in word pairs and the user's own
/// learned pairs. It is always offered as a tap-able suggestion, never
/// applied silently, because many accent-free syllables are ambiguous.
enum DiacriticRestorer {
    // MARK: Folding

    /// Accent-free lowercase key ("Đường" -> "duong").
    static func fold(_ text: String) -> String {
        text.lowercased()
            .folding(options: [.diacriticInsensitive], locale: Locale(identifier: "vi_VN"))
            .replacingOccurrences(of: "đ", with: "d")
    }

    // MARK: Lexicon

    /// Common Vietnamese chat syllables, most frequent first. For syllables
    /// that share an accent-free spelling, the earlier one wins by default.
    private static let rawSyllables = """
    là có không và của một những các được này đó với cho trong để khi thì mà cũng như nhưng \
    ra vào lên đi đến về làm nói biết thấy muốn cần phải sẽ đã đang vẫn còn rất lắm quá hơn nhất \
    nhiều ít tôi em anh chị bạn mình ta họ nó người ai gì sao đâu nào bao nhiêu mấy thế vậy hả nhỉ \
    chứ à ạ ơi nhé nha nè đấy đây kia ấy ngày nay mai hôm qua sáng trưa chiều tối đêm khuya giờ \
    phút năm tháng tuần lúc ăn uống ngủ nghe nhìn xem đọc viết học hiểu nghĩ nhớ quên thích yêu \
    thương lấy mua bán gửi nhận gọi hỏi trả lời giúp đợi chờ gặp xong hết bắt đầu tiếp tục chơi \
    cười khóc hát nhảy chạy đứng ngồi nằm mở đóng tắt bật cầm mang đưa đem giữ bỏ thôi luôn \
    thường hay lại nữa chỉ vừa mới sau trước giữa ngoài trên dưới trái phải cao thấp dài ngắn \
    nhanh chậm tốt xấu đẹp xinh vui buồn mệt khỏe khoẻ đói no nóng lạnh lớn nhỏ cũ giỏi khó dễ \
    đúng sai thật giả nhà trường lớp công việc tiền cơm phở bún nước cà phê trà bia xe điện thoại \
    máy tính phim nhạc sách bài thầy cô bè gia đình vợ chồng bố mẹ ba con cái trời mưa nắng gió \
    hoa quà tin nhắn chuyện chỗ nơi phố đường thành quê chúc mừng sinh nhật hẹn mạnh bình an \
    hạnh phúc cố gắng thành công may mắn tuyệt vời cảm ơn xin lỗi chào tạm biệt \
    việc người đời tình yêu cuộc sống thời gian mọi nhau cả tất nhưng vì nên nếu hoặc bởi \
    tại sao thôi chắc chắn lẽ phần đồ ngon dở thơm đắt rẻ giá bao lâu xa gần sớm muộn nhé \
    ngoài trong khác giống cùng riêng chung hai ba bốn năm sáu bảy tám chín mười trăm nghìn ngàn \
    triệu đồng đầu cuối giờ rồi chưa xong đủ thiếu hơn kém bằng theo từ tới đối với về cho \
    đây đó kia nào đâu sao gì thế vậy luôn mãi mới cũ trẻ già lớn bé \
    tối tới tồi bạn bán bản cô cố cơ cỏ nhà nhá nhờ nhở nhỏ nhỡ nhẹ nhè \
    cũng cùng cung đời đợi đổi đôi đòi đau đầu đấu đáu đẹp đệp \
    ở ô ơ ơn ốm ôm hôn hơn hồn hỏi hối hội \
    mà má mã ma mạ mả mẹ mẻ mệt mét mết \
    lá lạ lả la lâm lắm lạm làm lăm \
    rồi rối rời rơi rỡ rõ rộ rỗi \
    trời trới trợ trở trả trả trễ trẻ trẹ \
    ngủ ngu ngứ ngụ ngũ ngừ ngừng ngưng ngưỡng \
    thế thể thê thề thẻ thệ thể thấy thầy thây thẩy thậy \
    chờ chợ chỗ chó chồ chơ chở chớ chỡ \
    sông sống sổng sồng sỏ số sổ sở sợ sờ \
    bị bỉ bí bì bĩ bịt bít bịch \
    vì ví vị vỉ vĩ vịt vít \
    sáu sau sâu sấu sẩu sầu \
    nặng nắng nâng nằng nẵng năng \
    ngay ngày ngáy ngây ngẩy ngấy ngầy \
    tuổi tuối tuôi tuổi \
    nên nến nện nền \
    quả quá qua quạ quã quà \
    hay hãy hẩy hày hậy \
    dạ dà dã da dả dá \
    còn con cón cọn cổn \
    cả cá cà cạ cã cầ \
    khỏe khoẻ khoe khóe khỏa khoả \
    mới mời mỡi mởi mối mồi mỗi mội \
    đã đá đả đạ đa đà đã \
    giờ giỏi giới giỡ giở giá già giã giả giạ \
    gần gắn gẩn gận gấn \
    nhanh nhạnh nhãnh nhành \
    muốn muộn muôn muồn mượn mướn mường \
    đúng đụng đùng đũng đừng đứng đưng đựng \
    hiểu hiếu hiểm hiệu hiền hiện \
    biết biệt biển biến biên biện \
    cần cân cán căn cẩn cận cấn cẩm \
    thích thịch thích thính thịnh thình \
    tình tính tinh tịnh tĩnh tính tỉnh \
    hoàn hoa hòa hóa hỏa họa hoá \
    quên quyên quyền quyển quyết quyến \
    nhớ nhờ nhở nhợ nhỏ nho nhỏ \
    lòng lồng lộng long lỏng lõng \
    việt viết viếng viện viên viễn \
    xuống xuông xuống xương xướng xưởng \
    uống ướng ương uồng uông \
    cười cưới cửa cưa cứ cừ cự cứu cựu cứng cừng \
    được dược đước đuợc \
    nước nức nứt nừ nữ nữa nửa nữa \
    phải phái phải phai phài phãi phái \
    cơm cớm cờm cởm \
    phở phố phỏ phờ phớ phô phổ phô \
    bún bứn bụn bủn \
    trà tra trá trả trạ trã \
    xe xẻ xẹ xé xế xề \
    máy mày mảy mấy mầy mẩy \
    sách sạch sắc sác sạc sách \
    bài bái bãi bại bải bãi \
    gửi gửi gủi gùi gụi \
    tin tín tìm tỉn tịn \
    nhắn nhẵn nhặn nhằn nhẳn \
    chuyện chuyển chuyên chuyền \
    chỗ chồ chộ chổ chơ \
    nơi nới nồi nối nỗi nội \
    đường đương đưởng đượng \
    hẹn hện hèn hén hển \
    mạnh mạn mảnh mành mãnh mẫn \
    bình bịnh bỉnh bính \
    an án ản ạn àn ân ấn ẩn \
    hạnh hành hanh hánh hảnh \
    phúc phục phức phực phụ phủ phù phú phu \
    cố cổ cỗ cô cố cổ cơ \
    gắng gang gạng gảng gáng \
    thành thanh thánh thảnh thạnh thãnh \
    công cống cộng cồng cổng cống \
    may mây mày mẩy mầy mấy \
    mắn mặn mằn mắng măng mằng \
    tuyệt tuyết tuyên tuyền tuyển \
    vời với vội vòi vỡi vợi vởi \
    cảm cám cạm cầm cấm cẩm \
    ơn ơi ớn ờn ợn ớ \
    xin xìn xỉn xịn xĩn xín \
    lỗi lối lỗi lồi lội lôi lối \
    chào cháo chảo chạo chạo \
    tạm tâm tám tằm tẩm tầm tấm \
    biệt biết biêt biếc biện \
    """

    /// accent-free key -> accented forms, best first. Built once from the
    /// syllable list above plus every word used by the next-word tables.
    private static let lexicon: [String: [String]] = {
        var table: [String: [String]] = [:]
        func add(_ syllable: String) {
            let word = syllable.lowercased().precomposedStringWithCanonicalMapping
            let key = DiacriticRestorer.fold(word)
            guard !key.isEmpty else { return }
            if let existing = table[key], existing.contains(word) { return }
            table[key, default: []].append(word)
        }
        let separators = CharacterSet.whitespacesAndNewlines
        for syllable in rawSyllables.components(separatedBy: separators) where !syllable.isEmpty {
            add(syllable)
        }
        for (key, list) in NextWordPredictor.seedBigrams {
            add(key)
            for word in list { add(word) }
        }
        for (key, list) in NextWordPredictor.seedTrigrams {
            for word in key.components(separatedBy: " ") { add(word) }
            for word in list { add(word) }
        }
        return table
    }()

    // MARK: Tokens

    private struct Piece {
        var text: String
        var isWord: Bool
        var options: [String] = []   // lowercase candidates for a word piece
        var fixed: Bool = false      // keep the text exactly as typed
    }

    private static func split(_ text: String) -> [Piece] {
        var pieces: [Piece] = []
        var current = ""
        var currentIsWord = false
        for ch in text {
            let isLetter = ch.isLetter
            if current.isEmpty {
                current.append(ch)
                currentIsWord = isLetter
            } else if isLetter == currentIsWord {
                current.append(ch)
            } else {
                pieces.append(Piece(text: current, isWord: currentIsWord))
                current = String(ch)
                currentIsWord = isLetter
            }
        }
        if !current.isEmpty { pieces.append(Piece(text: current, isWord: currentIsWord)) }
        return pieces
    }

    private static func isBoundary(_ ch: Character) -> Bool {
        ch == "." || ch == "!" || ch == "?" || ch == "…" || ch.isNewline
    }

    private static func isAccentFreeASCII(_ word: String) -> Bool {
        for scalar in word.unicodeScalars where scalar.value >= 128 { return false }
        return true
    }

    private static func applyCase(of original: String, to chosen: String) -> String {
        if original.count > 1 && original == original.uppercased()
            && original != original.lowercased() {
            return chosen.uppercased()
        }
        if original.first?.isUppercase == true {
            return chosen.prefix(1).uppercased() + chosen.dropFirst()
        }
        return chosen
    }

    // MARK: Restoring

    /// How many words of `text` could be restored (accent-free syllables that
    /// have a known accented form) and the total word count.
    static func coverage(of text: String,
                         isProtected: (String) -> Bool = { _ in false }) -> (restorable: Int, total: Int) {
        var restorable = 0
        var total = 0
        for piece in split(text) where piece.isWord {
            total += 1
            let key = piece.text.lowercased()
            if isAccentFreeASCII(piece.text), !isProtected(key), lexicon[fold(key)] != nil {
                restorable += 1
            }
        }
        return (restorable, total)
    }

    /// The text with accents added to accent-free syllables. Words that
    /// already have accents, unknown words and `isProtected` words (for
    /// example English) are left exactly as typed.
    static func restore(_ text: String,
                        model: NextWordModel = NextWordModel(),
                        isProtected: (String) -> Bool = { _ in false }) -> String {
        var pieces = split(text)
        var wordIndexes: [Int] = []
        for index in pieces.indices where pieces[index].isWord {
            let word = pieces[index].text
            let lower = word.lowercased().precomposedStringWithCanonicalMapping
            if isAccentFreeASCII(word), !isProtected(lower),
               let options = lexicon[fold(lower)], !options.isEmpty {
                pieces[index].options = options
            } else {
                pieces[index].options = [lower]
                pieces[index].fixed = true
            }
            wordIndexes.append(index)
        }
        guard !wordIndexes.isEmpty else { return text }

        // Is there a sentence boundary between two consecutive words?
        var resets: [Bool] = []
        for position in wordIndexes.indices {
            var reset = position == 0
            if position > 0 {
                let from = wordIndexes[position - 1] + 1
                let to = wordIndexes[position]
                if from < to {
                    for piece in pieces[from..<to] {
                        for ch in piece.text where isBoundary(ch) { reset = true }
                    }
                }
            }
            resets.append(reset)
        }

        // Viterbi over the candidate chain.
        var scores: [[Int]] = []
        var back: [[Int]] = []
        for position in wordIndexes.indices {
            let options = pieces[wordIndexes[position]].options
            var rowScores: [Int] = []
            var rowBack: [Int] = []
            for (optionIndex, candidate) in options.enumerated() {
                let unigram = max(0, 5 - optionIndex)
                if resets[position] {
                    rowScores.append(unigram)
                    rowBack.append(-1)
                    continue
                }
                let previousOptions = pieces[wordIndexes[position - 1]].options
                var bestScore = Int.min
                var bestPrevious = 0
                for (previousIndex, previous) in previousOptions.enumerated() {
                    let total = scores[position - 1][previousIndex]
                        + pairBonus(previous: previous, next: candidate, model: model)
                    if total > bestScore {
                        bestScore = total
                        bestPrevious = previousIndex
                    }
                }
                rowScores.append(unigram + bestScore)
                rowBack.append(bestPrevious)
            }
            scores.append(rowScores)
            back.append(rowBack)
        }

        // Backtrack from the best final state.
        var chosen = [Int](repeating: 0, count: wordIndexes.count)
        var last = 0
        var bestFinal = Int.min
        for (index, score) in scores[scores.count - 1].enumerated() where score > bestFinal {
            bestFinal = score
            last = index
        }
        var position = wordIndexes.count - 1
        while position >= 0 {
            chosen[position] = last
            let previous = back[position][last]
            if previous < 0 {
                // Chain starts again after a boundary: pick that segment's best.
                if position > 0 {
                    var best = Int.min
                    var bestIndex = 0
                    for (index, score) in scores[position - 1].enumerated() where score > best {
                        best = score
                        bestIndex = index
                    }
                    last = bestIndex
                }
            } else {
                last = previous
            }
            position -= 1
        }

        var output = ""
        for index in pieces.indices {
            let piece = pieces[index]
            guard piece.isWord, let position = wordIndexes.firstIndex(of: index) else {
                output += piece.text
                continue
            }
            if piece.fixed {
                output += piece.text
            } else {
                output += applyCase(of: piece.text, to: piece.options[chosen[position]])
            }
        }
        return output
    }

    private static func pairBonus(previous: String, next: String,
                                  model: NextWordModel) -> Int {
        var bonus = 0
        if let list = NextWordPredictor.seedBigrams[previous],
           let rank = list.firstIndex(of: next) {
            bonus += max(6, 12 - rank)
        }
        if let count = model.bigrams[previous]?[next] {
            bonus += 14 + min(count, 20)
        }
        return bonus
    }

    // MARK: Suggestion for the keyboard

    /// The sentence being typed: text after the last . ! ? or newline,
    /// limited to roughly `maxChars`, starting at a word boundary.
    static func sentenceTail(of text: String, maxChars: Int = 160) -> String {
        let tail = String(text.suffix(maxChars))
        var cutIndex = tail.startIndex
        var index = tail.endIndex
        while index > tail.startIndex {
            let previous = tail.index(before: index)
            if isBoundary(tail[previous]) {
                cutIndex = index
                break
            }
            index = previous
        }
        var result = String(tail[cutIndex...])
        // The window may have cut a word in half: drop the partial word.
        let wasTruncated = text.index(text.endIndex, offsetBy: -(maxChars + 1),
                                      limitedBy: text.startIndex) != nil
        if cutIndex == tail.startIndex && wasTruncated,
           let space = result.firstIndex(of: " ") {
            result = String(result[space...])
        }
        while let first = result.first, first.isWhitespace { result.removeFirst() }
        return result
    }

    /// A restored version of `sentence` when it looks like accent-free
    /// Vietnamese (at least three words, mostly restorable) and restoring
    /// actually changes something; otherwise nil.
    static func suggestion(for sentence: String,
                           model: NextWordModel = NextWordModel(),
                           isProtected: (String) -> Bool = { _ in false }) -> String? {
        guard sentence.count >= 8 else { return nil }
        let counts = coverage(of: sentence, isProtected: isProtected)
        guard counts.total >= 3,
              Double(counts.restorable) / Double(counts.total) >= 0.6 else { return nil }
        let restored = restore(sentence, model: model, isProtected: isProtected)
        return restored == sentence ? nil : restored
    }
}
