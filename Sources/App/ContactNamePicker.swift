import SwiftUI
import Contacts
import ContactsUI

/// User explicitly chooses one contact. The app never receives the entire
/// address book, and no background contact permission is necessary.
struct ContactNamePicker: UIViewControllerRepresentable {
    let onChoose: (String) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onChoose: onChoose, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController,
                                context: Context) {}

    final class Coordinator: NSObject, CNContactPickerDelegate {
        let onChoose: (String) -> Void
        let onCancel: () -> Void

        init(onChoose: @escaping (String) -> Void,
             onCancel: @escaping () -> Void) {
            self.onChoose = onChoose
            self.onCancel = onCancel
        }

        func contactPicker(_ picker: CNContactPickerViewController,
                           didSelect contact: CNContact) {
            let name = CNContactFormatter.string(from: contact, style: .fullName)
                ?? ([contact.givenName, contact.familyName]
                    .filter { !$0.isEmpty }.joined(separator: " "))
            onChoose(name)
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            onCancel()
        }
    }
}
