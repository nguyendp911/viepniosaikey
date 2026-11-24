import Foundation

struct PremiumCommand: Identifiable, Equatable {
    let id: String
    let title: String
    let symbol: String
    let instruction: String
    let category: String
    var isAI: Bool { category == "AI" }
}
enum PremiumCommands {
    static let all: [PremiumCommand] = [
        .init(id:"hamy", title:"Thấu hiểu hội thoại", symbol:"brain", instruction:"Phân tích điều được nói rõ, các cách hiểu có thể có, dấu hiệu trong câu chữ và điều chưa biết. Không suy đoán chắc chắn cảm xúc, ý định hay danh tính. Đề xuất câu hỏi làm rõ và cách phản hồi tôn trọng. Viết tiếng Việt.", category:"AI"),
        .init(id:"camxuc", title:"Điều chỉnh cảm xúc", symbol:"heart", instruction:"Viết lại bằng tiếng Việt bình tĩnh, chân thành; chuyển trách móc thành chia sẻ cảm xúc và nhu cầu, giữ ranh giới, không ép buộc và không bịa thêm tình tiết.", category:"AI"),
        .init(id:"mophong", title:"Mô phỏng phản hồi", symbol:"arrow.triangle.branch", instruction:"Đưa ra ba kịch bản phản hồi giả định khác nhau, ghi rõ đây chỉ là mô phỏng, kèm cách tiếp tục tôn trọng trong mỗi trường hợp. Không dự đoán xác suất hoặc khẳng định cảm xúc người thật.", category:"AI"),
        .init(id:"lanhlung", title:"Lạnh lùng, điềm tĩnh", symbol:"snowflake", instruction:"Viết lại ngắn, điềm tĩnh, giữ khoảng cách nhưng lịch sự, không trừng phạt im lặng hoặc gây áp lực.", category:"AI"),
        .init(id:"truongthanh", title:"Trưởng thành", symbol:"person.crop.circle", instruction:"Viết lại trưởng thành, tự tin, tôn trọng, rõ ràng, giữ nguyên sự thật.", category:"AI"),
        .init(id:"tinhcam", title:"Tình cảm, tinh tế", symbol:"heart.text.square", instruction:"Viết lại ấm áp, tinh tế, không tạo áp lực, không suy diễn hoặc thêm kỷ niệm không có.", category:"AI"),
        .init(id:"haihuoc", title:"Hài hước", symbol:"face.smiling", instruction:"Viết lại dí dỏm nhẹ nhàng, không chế giễu, giữ nguyên ý nghĩa.", category:"AI"),
        .init(id:"chuyennghiep", title:"Chuyên nghiệp", symbol:"briefcase", instruction:"Viết lại chuyên nghiệp, lịch sự, không thêm cam kết, giá tiền hay dữ kiện.", category:"AI"),
        .init(id:"cophong", title:"Cổ phong", symbol:"book", instruction:"Viết lại tiếng Việt cổ phong trang nhã, giữ ý nghĩa.", category:"AI"),
        .init(id:"bian", title:"Bí ẩn, tinh tế", symbol:"moon.stars", instruction:"Viết lại súc tích, kín đáo, không dùng thủ thuật thao túng hoặc gây áp lực.", category:"AI"),
        .init(id:"danhgia", title:"Message Guardian", symbol:"shield", instruction:"Chỉ ra điểm dễ gây hiểu lầm, giọng điệu, xưng hô chưa rõ và câu nên sửa. Không khẳng định ý định; phân biệt quan sát với giả định. Đề xuất bản sửa lịch sự.", category:"AI"),
        .init(id:"dichhan", title:"Dịch tiếng Hàn", symbol:"globe", instruction:"Dịch trung thành sang tiếng Hàn tự nhiên, giữ ý và tên riêng.", category:"AI"),
        .init(id:"traloi", title:"Tạo câu trả lời", symbol:"bubble.left", instruction:"Soạn một câu trả lời tự nhiên, tôn trọng, không bịa dữ kiện.", category:"AI"),
        .init(id:"lamhoa", title:"Lời làm hòa", symbol:"heart.circle", instruction:"Soạn lời làm hòa chân thành, không nhận lỗi thay người dùng về sự kiện chưa biết, không gây áp lực.", category:"AI"),
        .init(id:"tomtat", title:"Tóm tắt", symbol:"text.alignleft", instruction:"Tóm tắt ngắn gọn bằng tiếng Việt, giữ dữ kiện và nêu điều chưa rõ.", category:"AI"),
        .init(id:"suachinh", title:"Sửa chính tả", symbol:"checkmark.seal", instruction:"Sửa chính tả, ngữ pháp và dấu câu, giữ nguyên nghĩa.", category:"AI"),
        .init(id:"tinh", title:"Máy tính", symbol:"calculator", instruction:"", category:"Offline"),
        .init(id:"canhbao", title:"Kiểm tra riêng tư", symbol:"lock.shield", instruction:"", category:"Offline"),
        .init(id:"gon", title:"Dọn khoảng trắng", symbol:"text.alignleft", instruction:"", category:"Offline"),
        .init(id:"danhsach", title:"Danh sách", symbol:"list.bullet", instruction:"", category:"Offline"),
        .init(id:"hoachu", title:"CHỮ HOA", symbol:"textformat", instruction:"", category:"Offline"),
        .init(id:"thuong", title:"chữ thường", symbol:"textformat.size", instruction:"", category:"Offline"),
        .init(id:"ngay", title:"Ngày hiện tại", symbol:"calendar", instruction:"", category:"Offline"),
        .init(id:"gio", title:"Giờ hiện tại", symbol:"clock", instruction:"", category:"Offline")
    ]
    static let personalities = ["lanhlung","truongthanh","tinhcam","haihuoc","chuyennghiep","cophong","bian"]
    static func find(_ id: String) -> PremiumCommand? { all.first { $0.id == id } }
    static func search(_ query: String) -> [PremiumCommand] {
        let q = fold(query).replacingOccurrences(of:"/", with:"").filter { !$0.isWhitespace }
        return q.isEmpty ? all : all.filter { fold($0.id + $0.title).filter { !$0.isWhitespace }.contains(q) }
    }
    private static func fold(_ text: String) -> String {
        text.lowercased().folding(options:.diacriticInsensitive, locale:Locale(identifier:"vi_VN")).replacingOccurrences(of:"đ",with:"d")
    }
}
