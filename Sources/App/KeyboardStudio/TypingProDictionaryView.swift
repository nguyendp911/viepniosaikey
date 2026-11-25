import SwiftUI
import UniformTypeIdentifiers

struct TypingProDictionaryView:View {
    @State private var words=PersonalDictionary.words
    @State private var source=""
    @State private var status=""
    @State private var importing=false
    @State private var exporting=false
    @State private var document=ProThemeDocument()
    var body:some View{
        VStack(alignment:.leading,spacing:12){
            Text("Từ điển cá nhân").font(.title2.bold())
            Text("\(words.count)/500 từ · nhập TXT (mỗi dòng một từ), CSV (cột đầu), hoặc JSON mảng chuỗi. Gộp với từ hiện có, không ghi đè.").font(.caption).foregroundStyle(.secondary)
            TextEditor(text:$source).frame(minHeight:100)
            Button("Thêm từ đã nhập"){merge(TypingProText.dictionary(source,format:"txt"));source=""}.buttonStyle(.borderedProminent)
            HStack{
                Button("Nhập tệp"){importing=true}
                Button("Xuất JSON"){
                    if let data=try? JSONEncoder().encode(words){document=ProThemeDocument(data:data);exporting=true}
                }
            }.buttonStyle(.bordered)
            ForEach(words,id:\.self){word in
                HStack{
                    Text(word);Spacer()
                    Button(role:.destructive){words.removeAll{$0==word};PersonalDictionary.words=words}label:{Image(systemName:"trash")}
                }.padding(.vertical,4)
            }
            Text(status).font(.caption).foregroundStyle(.orange)
        }.fileImporter(isPresented:$importing,allowedContentTypes:[.plainText,.commaSeparatedText,.json]){result in
            do {
                let url=try result.get();let access=url.startAccessingSecurityScopedResource()
                defer{if access{url.stopAccessingSecurityScopedResource()}}
                guard let size=try? url.resourceValues(forKeys:[.fileSizeKey]).fileSize,size<=100_000 else{status="Tệp quá lớn.";return}
                let text=try String(contentsOf:url,encoding:.utf8)
                merge(TypingProText.dictionary(text,format:url.pathExtension.lowercased()))
            }catch{status=error.localizedDescription}
        }.fileExporter(isPresented:$exporting,document:document,contentType:.json,defaultFilename:"ViePN-Dictionary"){result in
            status=(try? result.get()) != nil ? "Đã xuất từ điển." : "Chưa xuất được."
        }
    }
    private func merge(_ incoming:[String]){
        guard !KeyboardSettings.privateTypingMode else{status="Tắt riêng tư để thay đổi từ điển.";return}
        let before=words.count
        PersonalDictionary.words=words+incoming;words=PersonalDictionary.words
        status="Đã thêm \(words.count-before) từ."
    }
}
