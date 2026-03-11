
import SwiftUI

struct HotkeySelectorView: View {
    @Bindable var settings: AppSettings
    var hotkeyManager: HotkeyManager
    
    @State private var isListening = false
    
    var body: some View {
        HStack {
            Text("Activation Key:")
                .font(.system(size: 11))
            
            TextField("", text: .constant(isListening ? "Press key..." : settings.hotkey.displayString))
                .disabled(true)
                .frame(width: 100)
                .multilineTextAlignment(.center)
            
            Button("Select...") {
                isListening = true
                hotkeyManager.listenForNextHotkey { newHotkey in
                    DispatchQueue.main.async {
                        settings.hotkey = newHotkey
                        isListening = false
                    }
                }
            }
            .disabled(isListening)
        }
    }
}
