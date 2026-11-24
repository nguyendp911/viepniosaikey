import UIKit
import UniformTypeIdentifiers

/// Only explicitly shared text. No network, automatic send, or host-app access.
final class ShareViewController: UIViewController {
    private let editor = UITextView()
    private let status = UILabel()
    private let saveButton = UIButton(type: .system)
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let stack = UIStackView()
        stack.axis = .vertical; stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: view.keyboardLayoutGuide.topAnchor, constant: -12)
        ])
        let title = UILabel(); title.text = "ViePN · Nhập bản nháp"; title.font = .preferredFont(forTextStyle: .headline)
        status.text = "Kiểm tra văn bản trước khi lưu vào App Group."; status.numberOfLines = 0
        status.font = .preferredFont(forTextStyle: .footnote); status.textColor = .secondaryLabel
        editor.font = .preferredFont(forTextStyle: .body); editor.backgroundColor = .secondarySystemBackground
        editor.layer.cornerRadius = 12; editor.heightAnchor.constraint(equalToConstant: 180).isActive = true
        saveButton.setTitle("Lưu bản nháp", for: .normal); saveButton.isEnabled = false
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)
        let cancel = UIButton(type: .system); cancel.setTitle("Hủy", for: .normal)
        cancel.addTarget(self, action: #selector(close), for: .touchUpInside)
        [title,status,editor,saveButton,cancel].forEach { stack.addArrangedSubview($0) }
        let providers = (extensionContext?.inputItems as? [NSExtensionItem] ?? []).flatMap { $0.attachments ?? [] }
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) }) else {
            status.text = "Không có văn bản được chia sẻ."; return
        }
        provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] item, error in
            DispatchQueue.main.async {
                guard let self else { return }
                let value = (item as? String) ?? (item as? NSAttributedString)?.string ?? ""
                self.editor.text = String(value.prefix(3000))
                self.saveButton.isEnabled = error == nil && !value.isEmpty
                if !self.saveButton.isEnabled { self.status.text = "Không đọc được văn bản." }
            }
        }
    }
    @objc private func save() {
        let text = editor.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { status.text = "Bản nháp trống."; return }
        let lower = text.lowercased()
        guard !["otp", "mật khẩu", "password:", "api_key", "secret_key", "mã xác minh"].contains(where: { lower.contains($0) }),
              text.range(of: #"\b(?:\d[ -]?){12,19}\b"#, options: .regularExpression) == nil else {
            status.text = "Có thể chứa dữ liệu nhạy cảm. Hãy xóa chúng trước khi lưu."; return
        }
        guard ShareDraft.save(text) else { status.text = "Không lưu được. Kiểm tra App Group khi ký IPA."; return }
        extensionContext?.completeRequest(returningItems: nil)
    }
    @objc private func close() {
        extensionContext?.cancelRequest(withError: NSError(domain: "ViePNShare", code: 1, userInfo: [NSLocalizedDescriptionKey:"Đã hủy chia sẻ"]))
    }
}
