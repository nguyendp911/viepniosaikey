# ViePN AI Keyboard

Ứng dụng iOS (SwiftUI) và bàn phím mở rộng (UIKit), hỗ trợ gõ tiếng Việt/tiếng Anh offline và trợ lý AI khi người dùng chủ động yêu cầu. iOS 16+.

## Các tính năng và cách sử dụng

| Nhóm | Tính năng | Vị trí |
| --- | --- | --- |
| Gõ tiếng Việt | Telex, VNI; song ngữ Việt–Anh; phím dấu lặp để hủy dấu | Ứng dụng → Bàn phím |
| Tốc độ | Xử lý phím ngay khi chạm, từ điển theo tiền tố, gợi ý tính ở nền | Bàn phím |
| Vùng chạm | Mở rộng vùng chạm sang nửa khe trống giữa hai phím, không đổi nội dung gõ tự động | Bàn phím → Gõ thông minh → Vùng chạm phím rộng hơn |
| Sửa lỗi | Gợi ý từ tiếng Anh khi lỡ nhấn phím kề bên; **không tự thay thế** | Thanh gợi ý |
| Vuốt song ngữ | Vuốt qua phím QWERTY để nhập từ tiếng Việt có dấu hoặc tiếng Anh; gợi ý các dấu khác nhau | Bàn phím → Gõ thông minh → Vuốt chữ |
| Vệt vuốt | Vệt sáng xanh cyan, quầng sáng và điểm sáng bám ngón tay, tự mờ khi nhấc tay | Bàn phím → Hiệu ứng vệt sáng khi vuốt |
| Hoàn tác | Backspace lùi theo phím Telex; sau khi chạm một gợi ý từ, nhấn giữ **AI → Hoàn tác sửa từ** | Bàn phím |
| AI viết lại | Nhấn giữ **AI → Viết lại · 3 phiên bản** để lấy 3 cách viết; chọn mẫu rồi chèn hoặc sao chép | Bàn phím, cần quyền và API |
| Giọng văn | Tự lưu tối đa 8 câu mẫu, có thể xóa; chỉ tham khảo giọng văn khi bạn chủ động dùng AI | Ứng dụng → Bàn phím → Phong cách viết cá nhân |
| Hồ sơ người nhận | Chọn thủ công hoặc nhận diện tên từ đoạn hội thoại bạn chủ động dán và cung cấp nhãn người gửi | Ứng dụng → AI / Bàn phím (giữ AI) |
| Dịch | Chọn ngôn ngữ đích trong cài đặt; nhấn giữ AI → Dịch nội dung | Ứng dụng → Bàn phím → Dịch sang |
| Giọng nói | Thu âm và nhận dạng trong **ứng dụng chính**; kiểm tra văn bản và dùng **Đưa sang bàn phím** | Ứng dụng → Trợ lý |
| Clipboard | Bấm Dán để nhập thủ công; nhấn giữ Dán để quản lý các đoạn tự lưu | Bàn phím / Ứng dụng |
| Mẫu gõ | Gõ `;date`, `;time`, `;ten` rồi nhấn dấu cách. Biến `{date}`, `{time}`, `{recipient}` | Ứng dụng → Bàn phím → Mẫu gõ nhanh |
| Keyboard Studio | Chủ đề, chiều cao và khoảng cách phím, rung, một tay, gợi ý, ngôn ngữ | Ứng dụng → Bàn phím |

Tính năng `{recipient}` **chỉ** chèn tên hồ sơ đã được người dùng chọn. Nếu chưa chọn, biến giữ nguyên để tránh đoán sai. Lệnh `;ten` được thêm một lần khi nâng cấp; người dùng có thể xóa hoặc sửa.

### Vuốt tiếng Việt có dấu

Bật **Vuốt chữ để nhập từ**, **Hiệu ứng vệt sáng khi vuốt** và **Tự phân biệt Việt – Anh**. Vuốt trên phím không dấu theo hình dạng từ, thả ngón tay để chèn từ và khoảng trắng:

- Vuốt `c-h-a-o` → đề xuất `chào`.
- Vuốt `t-o-i` → đề xuất `tôi`.
- Vuốt `t-h-u-o-n-g` → đề xuất `thương` hoặc `thường`.
- Vuốt `b-a-n` → có thể chọn `bạn`, `bàn`, `bán` trên thanh gợi ý.
- Vuốt `o-r` → `or` trong tiếng Anh.

Không thể biết dấu tiếng Việt chỉ từ tọa độ ngón tay trong mọi tình huống; từ điển offline và ưu tiên ngôn ngữ được dùng để xếp hạng. Nếu có nhiều từ trùng đường vuốt, **chạm phương án đúng trên thanh gợi ý trước khi tiếp tục gõ**. Chế độ **Chỉ tiếng Anh** không trả từ tiếng Việt có dấu; chế độ **Ưu tiên tiếng Việt** xếp từ tiếng Việt trước. Phải chuyển sang bàn phím khác rồi quay lại ViePN để tải lại thiết lập.

### Tự học lựa chọn dấu sau khi vuốt

Ví dụ: vuốt đường phím `m-i-n-h`. Bàn phím hiển thị thanh lựa chọn cuộn ngang gồm **minh, mình, mính, mĩnh, mỉnh, mịnh** (và các gợi ý khác nếu phù hợp). Bạn có thể chạm chọn đúng biến thể; bàn phím chỉ sửa đoạn từ vừa được tạo bởi lần vuốt và giữ khoảng trắng cuối từ.

- Ban đầu hiển thị đủ sáu kiểu dấu. Từ dự đoán theo từ điển có thể được điền trước nhưng bạn luôn có thể chọn phương án khác.
- Mỗi lần **chạm chọn** một phương án, hệ thống ghi nhận một lượt cho từ chính xác đó. Nếu tiếp tục gõ mà không đổi từ vừa vuốt, hệ thống tính từ đã được chấp nhận một lượt.
- Sau khi ghi nhận ít nhất 5 lần và một lựa chọn đạt ít nhất 3 lần, thanh gợi ý rút còn **những biến thể dùng thường xuyên** (tối đa 3). Nhấn **Tất cả ···** để xem lại mọi biến thể, kể cả những từ chưa từng chọn.
- Tần suất được lưu **trên thiết bị trong App Group**, chỉ là số lượt cho các từ, không lưu đường vuốt hay tọa độ. Bật/tắt ở **Bàn phím → Tự học từ tôi thường chọn khi vuốt**; có nút **Xóa lịch sử học từ vuốt**.
- Các biến thể được tạo theo dấu tiếng Việt, có thể gồm những cách viết rất ít dùng; bàn phím không mặc định khẳng định chúng đều là từ đúng trong mọi ngữ cảnh.

### Ví dụ Telex/song ngữ

- **Tự động**: `or` → `or`; `store` → `store`; `tooi` → `tôi`; `thuongw` → `thương`.
- **Ưu tiên tiếng Việt**: `or` → `ỏ`; thêm `r` lần nữa (`orr`) → `or`.
- Phím xóa lùi theo chuỗi phím đã gõ, kể cả khi một phím đã biến đổi nhiều ký tự.

## Hội thoại cá nhân theo từng người

1. Trong ứng dụng chính, tạo hoặc chọn một **Hồ sơ người nhận** ở trang **AI & API**.
2. Mở **Trợ lý → Hội thoại riêng cho từng người**, dán đoạn chat bạn tự sao chép, có nhãn theo dòng:
   ```text
   Tôi: Hôm nay đi làm có mệt không?
   Bạn ấy: Hơi bận nhưng cũng ổn.
   Tôi: Vậy nhớ nghỉ ngơi nhé.
   ```
3. Kiểm tra nhãn người nói, xóa mật khẩu/số điện thoại/thông tin nhạy cảm rồi bấm **Lưu lịch sử**. Lưu tối đa 150 lượt cho mỗi hồ sơ, tổng cộng 1.000 lượt trên thiết bị; nhập trùng không tăng số lượt.
4. Bấm **Gợi ý trả lời** nếu lượt mới nhất là tin từ người kia; bấm **Nhắn gì hôm nay?** để nhận ba gợi ý chủ động bắt chuyện (không tự gửi).
5. Trên bàn phím ViePN, **nhấn giữ AI → Hôm nay nhắn gì? · Theo lịch sử**, xem ba gợi ý rồi chọn/chỉnh trước khi dùng.

ViePN không tự đọc hay theo dõi Zalo, Messenger hoặc bất kỳ ứng dụng khác. Lịch sử chỉ được lưu **khi bạn bấm Lưu**, tách theo hồ sơ đang chọn và có chức năng **Xóa toàn bộ lịch sử người này**. Khi bạn chủ động dùng AI online, tối đa 14 lượt gần nhất được gửi cho nhà cung cấp AI đã cấu hình, cùng ghi chú và hồ sơ liên quan. Dữ liệu lịch sử đang lưu trong App Group UserDefaults **chưa mã hóa chuyên dụng**; không lưu bí mật hoặc cuộc trò chuyện nhạy cảm. Các tin nhắn đã lưu là dữ liệu tham chiếu cho AI trong lần suy luận, **không phải huấn luyện trọng số mô hình**. Ứng dụng không tự lên lịch gửi tin nhắn.

### Thanh ngữ cảnh trong khoảng trống bên dưới 5 nút công cụ

ViePN có một **vùng gợi ý cố định, không làm thay đổi vị trí hàng phím**:

- **Khi chưa gõ hoặc vừa kết thúc một từ:** hiển thị các emoji được sử dụng thường xuyên và các câu mở đầu hội thoại để bạn tùy ý chèn. Emoji được xếp hạng theo số lượt bạn **chủ động chọn** từ thanh này, không phân tích văn bản trong các ứng dụng khác.
- **Khi bắt đầu gõ:** chuyển ngay sang gợi ý từ theo tiền tố trong tiếng Việt–Anh; hiển thị từ đang gõ trước trong lúc kết quả tính toán offline đang được chuẩn bị.
- **Khi vuốt:** thay bằng các từ nhận diện được, các biến thể dấu tiếng Việt và nút **Tất cả** nếu lịch sử lựa chọn đã rút gọn danh sách.
- **Khi chèn khoảng trắng / xuống dòng để kết thúc từ:** tự quay lại emoji và các câu gợi chuyện.
- Có thể cuộn ngang qua các emoji, mẫu lời nhắn và gợi ý từ. Bấm một chip để chèn nội dung; bàn phím không tự gửi tin nhắn.
- Câu gợi chuyện ở trạng thái chờ là **mẫu offline** có thể dùng tên hồ sơ đã được bạn chọn, không phải câu do AI tự suy luận từ tin nhắn chưa được người dùng chia sẻ. AI lịch sử hội thoại vẫn chỉ chạy khi bạn chủ động yêu cầu.

## Quyền riêng tư và giới hạn iOS

- Không tự đọc Zalo, Messenger, Facebook, danh bạ, email hoặc hội thoại ứng dụng khác. Thông tin người nhận phải do người dùng chọn hoặc tự cung cấp qua nội dung dán.
- Bàn phím bên thứ ba **không truy cập micro trực tiếp**. Ghi âm và nhận dạng giọng nói hoạt động trong ứng dụng ViePN chính.
- Tính năng gõ, Telex, vuốt, gợi ý và mẫu từ hoạt động offline. **AI online chỉ chạy khi người dùng nhấn tác vụ** và bật tùy chọn đồng ý dùng AI; lời nhắn có thể được gửi đến nhà cung cấp AI đã chọn.
- Ví dụ phong cách viết, các hồ sơ người nhận và API key có thể được lưu trong **App Group UserDefaults**, chưa mã hóa bằng Keychain. Không lưu bí mật, mật khẩu, OTP, dữ liệu nhạy cảm; không chia sẻ bản sao ứng dụng có chứa khóa.
- iOS có thể chuyển sang bàn phím hệ thống tại ô mật khẩu và các trường bảo mật. Quyền Full Access là cần thiết với thao tác clipboard/AI qua extension; thao tác gõ offline không cần.
- Vùng chạm mở rộng là cải tiến xác định theo khoảng cách phím, **không** phải hệ thống ML theo dõi tọa độ/chạm. Gợi ý lỗi phím bên cạnh chỉ đề xuất, không tự sửa.
- Chưa có số đo độ trễ trên iPhone thật hoặc bảo đảm hoạt động giống bàn phím hệ thống trong mọi ứng dụng.

## Xây dựng ứng dụng

Yêu cầu macOS, Xcode 16+, [XcodeGen](https://github.com/yonaskolb/XcodeGen), iOS 16+.

```bash
xcodegen generate
xcodebuild -project ViePNAIKeyboard.xcodeproj -scheme ViePNAIKeyboard \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
```

Sau khi cài, mở **Cài đặt iOS → Cài đặt chung → Bàn phím → Các bàn phím → Thêm bàn phím mới** và bật ViePN AI Keyboard. Khi cài IPA ký bằng chứng chỉ Ad Hoc, **cả ứng dụng chính lẫn keyboard extension** phải có provisioning profile tương ứng; App Group phải khớp.

## GitHub Actions / IPA

Mỗi push lên `main` chạy kiểm thử Swift và build iOS qua workflow [iOS Build](.github/workflows/ios.yml). Vào Actions → run mới nhất → Artifacts để tải sản phẩm nếu job tạo artifact. Workflow có đường ký Ad Hoc thủ công theo môi trường và secrets `ios-signing`; IPA chưa ký không thể cài trực tiếp.

## Cấu hình AI

Ứng dụng hỗ trợ khóa Gemini hoặc OpenAI do người dùng nhập (Bring Your Own Key). Chọn model tương thích, bật đồng ý dùng AI và thử kết nối trong ứng dụng; chỉ sử dụng tác vụ online nếu đã có khóa hợp lệ. Nên đặt giới hạn chi tiêu và không công khai khóa trong GitHub/IPA.

Backend Python tham khảo ở `backend/` là tùy chọn, không bắt buộc đối với chế độ gọi trực tiếp. Nếu triển khai backend ra Internet, phải thêm xác thực, rate limit và HTTPS.
