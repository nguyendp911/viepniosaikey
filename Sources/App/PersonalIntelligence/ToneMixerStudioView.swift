import SwiftUI

struct ToneMixerStudioView:View {
    @State private var mix=ToneMix()
    @State private var presets=PersonalIntelligenceSettings.presets
    @State private var name=""
    @State private var source=""
    @State private var result=""
    @State private var status=""
    @State private var busy=false
    @State private var work:Task<Void,Never>?
    var body:some View {
        VStack(alignment:.leading,spacing:13){
            Text("Tone Mixer").font(.title.bold())
            Text("Sáu mức cường độ độc lập, không cần cộng thành 100%. AI ưu tiên nghĩa gốc và sự tôn trọng.").font(.caption).foregroundStyle(.secondary)
            ForEach(ToneMix.names.indices,id:\.self){i in
                VStack(alignment:.leading,spacing:4){
                    HStack{Text(ToneMix.names[i]);Spacer();Text("\(mix.values[i])%").monospacedDigit().foregroundStyle(.cyan)}
                    Slider(value:Binding(get:{Double(mix.values[i])},set:{mix.values[i]=Int($0)}),in:0...100,step:5)
                }
            }
            Picker("Độ dài",selection:$mix.length){ForEach(["Ngắn","Vừa","Dài"],id:\.self){Text($0)}}.pickerStyle(.segmented)
            HStack{
                TextField("Tên preset",text:$name).textFieldStyle(.roundedBorder)
                Button("Lưu"){let clean=name.trimmingCharacters(in:.whitespacesAndNewlines);guard !clean.isEmpty,MessageSafety.warnings(in:clean).isEmpty else{return};presets.insert(.init(title:clean,mix:mix),at:0);PersonalIntelligenceSettings.presets=presets;presets=PersonalIntelligenceSettings.presets;name=""}.buttonStyle(.bordered)
            }
            ForEach(presets){preset in
                HStack{Button(preset.title){mix=preset.mix.normalized};Spacer();Button(role:.destructive){presets.removeAll{$0.id==preset.id};PersonalIntelligenceSettings.presets=presets}label:{Image(systemName:"trash")}}
            }
            TextEditor(text:$source).frame(minHeight:125)
            HStack{Button(busy ? "Đang xử lý…" : "Tạo tin nhắn"){run()}.buttonStyle(.borderedProminent).disabled(busy);if busy{Button("Hủy"){work?.cancel();busy=false}}}
            Text(status).font(.caption).foregroundStyle(.orange)
            if !result.isEmpty{TextEditor(text:$result).frame(minHeight:120);PersonalResultActions(text:result,status:$status)}
        }.onDisappear{work?.cancel()}
    }
    private func run(){
        guard KeyboardSettings.allowCloudAI,!source.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty,MessageSafety.warnings(in:source).isEmpty else{status="Cần AI online và văn bản không nhạy cảm.";return}
        let input=source;let instruction=mix.instruction;let provider=KeyboardSettings.provider
        busy=true;result="";status=""
        work=Task{@MainActor in
            defer{if !Task.isCancelled{busy=false}}
            do{let value=try await AIWritingService.studio(input,instruction:instruction,provider:provider);if !Task.isCancelled{result=value}}
            catch{if !Task.isCancelled{status=error.localizedDescription}}
        }
    }
}
