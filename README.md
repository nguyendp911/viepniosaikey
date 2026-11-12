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

### Ví dụ Telex/song ngữ

- **Tự động**: `or` → `or`; `store` → `store`; `tooi` → `tôi`; `thuongw` → `thương`.
- **Ưu tiên tiếng Việt**: `or` → `ỏ`; thêm `r` lần nữa (`orr`) → `or`.
- Phím xóa lùi theo chuỗi phím đã gõ, kể cả khi một phím đã biến đổi nhiều ký tự.

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
