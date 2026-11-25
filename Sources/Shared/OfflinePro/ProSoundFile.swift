import Foundation

enum ProSoundFile {
    static var url:URL? {
        #if os(iOS)
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier:KeyboardSettings.groupID)?.appendingPathComponent("offline4-key-sound.wav")
        #else
        nil
        #endif
    }
}
