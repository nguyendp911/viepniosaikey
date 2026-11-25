import SwiftUI

struct TypingProEntryView: View {
    @State private var open=false
    var body: some View {
        Button{open=true}label:{
            HStack(spacing:12){
                Image(systemName:"keyboard.badge.ellipsis").font(.system(size:26,weight:.medium)).foregroundStyle(.cyan)
                    .frame(width:46,height:46).background(.cyan.opacity(0.10),in:RoundedRectangle(cornerRadius:12))
                VStack(alignment:.leading,spacing:5){
                    Text("Typing Premium 6.0").font(.system(size:15,weight:.bold)).foregroundStyle(.white)
                    Text("Bộ gõ · Tự học · Hiệu chỉnh").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName:"chevron.right").font(.caption).foregroundStyle(.secondary)
            }.padding(15).background(Color(red:0.10,green:0.14,blue:0.20),in:RoundedRectangle(cornerRadius:16))
                .overlay{RoundedRectangle(cornerRadius:16).strokeBorder(.cyan.opacity(0.2))}
        }.buttonStyle(.plain).accessibilityIdentifier("typingPro6.open")
            .sheet(isPresented:$open){
                NavigationStack{
                    ScrollView{TypingProStudioView().padding(16)}
                        .navigationTitle("Typing Pro 6.0").navigationBarTitleDisplayMode(.inline)
                        .toolbar{ToolbarItem(placement:.cancellationAction){Button("Đóng"){open=false}.accessibilityIdentifier("typingPro6.close")}}
                }.preferredColorScheme(.dark)
            }
    }
}
