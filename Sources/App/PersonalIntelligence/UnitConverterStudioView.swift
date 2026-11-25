import SwiftUI

struct UnitConverterStudioView:View {
    @State private var group="Chiều dài"
    @State private var from="m"
    @State private var to="cm"
    @State private var value="1"
    @State private var rate=""
    @State private var currencyFrom="USD"
    @State private var currencyTo="VND"
    @State private var status=""
    private var units:[PersonalUnits.Unit]{PersonalUnits.groups[group] ?? []}
    private var output:String{
        guard let number=Double(value.replacingOccurrences(of:",",with:".")) else{return ""}
        let result=group=="Tiền tệ" ? Double(rate.replacingOccurrences(of:",",with:".")).flatMap{PersonalUnits.currency(number,rate:$0)} : PersonalUnits.convert(number,group:group,from:from,to:to)
        return result.map{String(format:"%.10g",$0)} ?? ""
    }
    var body:some View {
        VStack(alignment:.leading,spacing:12){
            Text("Unit Converter").font(.title.bold())
            Picker("Nhóm",selection:$group){ForEach(PersonalUnits.groups.keys.sorted()+["Tiền tệ"],id:\.self){Text($0)}}
                .onChange(of:group){_ in from=units.first?.id ?? "";to=units.dropFirst().first?.id ?? from}
            TextField("Giá trị",text:$value).textFieldStyle(.roundedBorder).keyboardType(.numbersAndPunctuation)
            if group=="Tiền tệ"{
                Text("Tỷ giá do bạn nhập, không phải tỷ giá trực tuyến.").font(.caption).foregroundStyle(.secondary)
                TextField("Đồng nguồn",text:$currencyFrom).textFieldStyle(.roundedBorder)
                TextField("Đồng đích",text:$currencyTo).textFieldStyle(.roundedBorder)
                TextField("1 đơn vị nguồn = bao nhiêu đơn vị đích",text:$rate).textFieldStyle(.roundedBorder).keyboardType(.numbersAndPunctuation)
            }else{
                Picker("Từ",selection:$from){ForEach(units){Text($0.name).tag($0.id)}}
                Picker("Sang",selection:$to){ForEach(units){Text($0.name).tag($0.id)}}
                Button("Đảo chiều"){let old=from;from=to;to=old}.buttonStyle(.bordered)
            }
            Text(output.isEmpty ? "Nhập dữ liệu hợp lệ" : output+" "+(group=="Tiền tệ" ? currencyTo : units.first{$0.id==to}?.name ?? "")).font(.largeTitle.bold()).foregroundStyle(.cyan).textSelection(.enabled)
            if !output.isEmpty{PersonalResultActions(text:output,status:$status)}
            Text(status).font(.caption)
        }
    }
}
