import SwiftUI
import CryptoKit
import UniformTypeIdentifiers
import UIKit

private struct EverydayLearningArchive:Codable {
    let version:Int
    let phrases:PersonalPhraseModel
    let words:[String:Int]
    let dictionary:[String]
    let glide:[String:Int]
    let corrections:TypingProFeedback
    static func capture()->Self {
        .init(version:1,phrases:PersonalPhraseStore.readForManagement(),words:KeyboardSettings.learnedWords,dictionary:PersonalDictionary.words,glide:KeyboardSettings.glideUsageCounts,corrections:TypingProFeedback.current)
    }
    func restore()->Bool {
        guard version==1,!KeyboardSettings.privateTypingMode,PersonalPhraseStore.modify({$0.merge(phrases);return true}) else{return false}
        let filtered=words.filter{PersonalPhraseModel.token($0.key) != nil && (1...10000).contains($0.value)}
        KeyboardSettings.learnedWords=KeyboardSettings.learnedWords.merging(filtered,uniquingKeysWith:max)
        PersonalDictionary.words=PersonalDictionary.words+dictionary
        let safeGlide=glide.filter{key,value in
            let tokens=key.split(separator:"|",omittingEmptySubsequences:false)
            return tokens.count==2 && tokens.allSatisfy{PersonalPhraseModel.token(String($0)) != nil} && (1...10000).contains(value)
        }
        KeyboardSettings.glideUsageCounts=KeyboardSettings.glideUsageCounts.merging(safeGlide,uniquingKeysWith:max)
        var merged=TypingProFeedback.current;merged.mergeBackup(corrections)
        KeyboardSettings.defaults.set(UUID().uuidString,forKey:TypingProFeedback.key+".revision");TypingProFeedback.current=merged
        return true
    }
}
private struct EverydayEncryptedFile:FileDocument{
    static var readableContentTypes:[UTType]{[.data]}
    var data=Data()
    init(data:Data=Data()){self.data=data}
    init(configuration:ReadConfiguration)throws{guard let bytes=configuration.file.regularFileContents,bytes.count<=1_000_000 else{throw CocoaError(.fileReadCorruptFile)};data=bytes}
    func fileWrapper(configuration:WriteConfiguration)throws->FileWrapper{FileWrapper(regularFileWithContents:data)}
}
struct EverydayBackupView:View {
    @State private var key=""
    @State private var document=EverydayEncryptedFile()
    @State private var exporting=false
    @State private var importing=false
    @State private var status=""
    @State private var showKey=false
    @State private var confirmation:EverydayLearningArchive?
    var body:some View {
        VStack(alignment:.leading,spacing:15){
            Text("Learning Backup").font(.title.bold())
            Text("AES-256-GCM · Khóa ngẫu nhiên 256 bit. Không gồm API key, tin nhắn clipboard hay hồ sơ cá nhân. Tệp chứa dữ liệu học đã mã hóa. Giữ khóa riêng ở nơi an toàn; mất khóa sẽ không khôi phục được.").font(.caption)
            if showKey{TextField("Khóa khôi phục Base64",text:$key).textFieldStyle(.roundedBorder).textInputAutocapitalization(.never).autocorrectionDisabled()}
            else{SecureField("Khóa khôi phục Base64",text:$key).textFieldStyle(.roundedBorder)}
            Toggle("Hiển thị khóa",isOn:$showKey)
            Button("Tạo khóa ngẫu nhiên"){
                key=EverydayEncryption.makeKey();status="Hãy lưu khóa an toàn trước khi xuất."
            }.buttonStyle(.bordered)
            Button("Sao chép khóa (60 giây)"){
                UIPasteboard.general.setItems([[UTType.plainText.identifier:key]],options:[.localOnly:true,.expirationDate:Date().addingTimeInterval(60)])
            }.disabled(validKey==nil).buttonStyle(.bordered)
            Button("Xuất bản sao mã hóa"){
                guard let validKey,!KeyboardSettings.privateTypingMode else{status="Cần khóa hợp lệ và không ở chế độ riêng tư.";return}
                guard PersonalPhraseStore.canReadForBackup else{status="Không đọc được kho cụm từ. Kiểm tra App Group hoặc mở khóa thiết bị.";return}
                do {
                    let data=try JSONEncoder().encode(EverydayLearningArchive.capture())
                    let sealed=try EverydayEncryption.seal(data,using:validKey)
                    document=EverydayEncryptedFile(data:sealed);exporting=true
                }catch{status=error.localizedDescription}
            }.buttonStyle(.borderedProminent)
            Button("Nhập bản sao mã hóa"){importing=true}.buttonStyle(.bordered)
            Text("Nhập sẽ gộp theo tần suất lớn hơn, không xóa dữ liệu hiện tại; giữ các giới hạn dung lượng vốn có.").font(.caption).foregroundStyle(.secondary)
            Text(status).font(.caption).foregroundStyle(.orange)
        }.fileExporter(isPresented:$exporting,document:document,contentType:.data,defaultFilename:"ViePN-Learning.viepnbackup"){result in
            status=(try? result.get()) != nil ? "Đã xuất bản sao mã hóa." : "Chưa xuất được."
        }.fileImporter(isPresented:$importing,allowedContentTypes:[.data]){result in
            do {
                guard let validKey,!KeyboardSettings.privateTypingMode else{status="Cần khóa hợp lệ và không ở chế độ riêng tư.";return}
                let url=try result.get();let access=url.startAccessingSecurityScopedResource();defer{if access{url.stopAccessingSecurityScopedResource()}}
                guard let size=try? url.resourceValues(forKeys:[.fileSizeKey]).fileSize,size<=1_000_000 else{status="Tệp không hợp lệ.";return}
                let data=try EverydayEncryption.open(Data(contentsOf:url),using:validKey)
                let archive=try JSONDecoder().decode(EverydayLearningArchive.self,from:data)
                guard archive.version==1 else{status="Phiên bản không hỗ trợ.";return};confirmation=archive
            }catch{status="Không giải mã được. Kiểm tra khóa và tệp."}
        }.alert("Gộp dữ liệu học?",isPresented:Binding(get:{confirmation != nil},set:{if !$0{confirmation=nil}})){
            Button("Gộp"){if let archive=confirmation{status=archive.restore() ? "Đã gộp dữ liệu học." : "Chưa ghi được kho dữ liệu. Thử lại khi bàn phím đóng."};confirmation=nil}
            Button("Hủy",role:.cancel){confirmation=nil}
        }message:{Text("Dữ liệu hiện có không bị thay thế toàn bộ.")}
        .onDisappear{key="";confirmation=nil}
    }
    private var validKey:SymmetricKey? {
        EverydayEncryption.key(key)
    }
}
