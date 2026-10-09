#if os(macOS)
import AppKit
import Foundation

enum SoundPlayer {
    private static var playing: [NSSound] = []

    static func play(named name: String) {
        guard let url = locate(name) else {
            NSSound.beep()
            return
        }
        guard let sound = NSSound(contentsOf: url, byReference: true) else {
            NSSound.beep()
            return
        }
        playing.append(sound)
        sound.play()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            playing.removeAll { $0 == sound }
        }
    }

    static func locate(_ name: String) -> URL? {
        if let url = Bundle.main.url(forResource: name, withExtension: "wav") {
            return url
        }

        let executable = URL(fileURLWithPath: CommandLine.arguments[0])
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let candidates = [
            executable.deletingLastPathComponent().appendingPathComponent("\(name).wav"),
            executable.deletingLastPathComponent().appendingPathComponent("Resources/\(name).wav"),
            executable.deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("Resources/\(name).wav"),
            Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/\(name).wav"),
            cwd.appendingPathComponent("Resources/Sounds/\(name).wav"),
        ]
        return candidates.first { FileManager.default.fileExists(atPath: $0.path) }
    }
}
#endif
