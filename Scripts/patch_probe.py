import sys
p = "Sources/App/ContentView.swift"
s = open(p, "rb").read().decode("utf-8")
nl = "\r\n" if "\r\n" in s else "\n"
if "VIEPN_AUTOTAB" not in s:
    s = s.replace('@State private var selectedPage = "couple"',
                  '@State private var selectedPage = ProcessInfo.processInfo.environment["VIEPN_START_PAGE"] ?? "couple"', 1)
    block = nl.join([
        "        .preferredColorScheme(.dark)",
        "        .onAppear {",
        '            if let target = ProcessInfo.processInfo.environment["VIEPN_AUTOTAB"] {',
        "                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {",
        '                    HitchProbe.shared.start(label: target, duration: 8)',
        "                    withAnimation(.easeInOut(duration: 0.18)) { selectedPage = target }",
        "                }",
        "            }",
        "        }",
        ""])
    assert ("        .preferredColorScheme(.dark)" + nl) in s
    s = s.replace("        .preferredColorScheme(.dark)" + nl, block, 1)
open(p, "wb").write(s.encode("utf-8"))
print("patched")
