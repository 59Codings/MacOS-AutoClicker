
import SwiftUI
import Combine

struct ContentView: View {
    @Bindable var settings: AppSettings
    var hotkeyManager: HotkeyManager
    var clickEngine: ClickEngine
    
    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()
    
    let intFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 8) {
            
            GroupBox(label: Text("Activation").font(.system(size: 11))) {
                VStack(alignment: .leading, spacing: 5) {
                    HotkeySelectorView(settings: settings, hotkeyManager: hotkeyManager)
                    
                    HStack {
                        Text("Activation Mode:")
                            .font(.system(size: 11))
                        
                        Button(action: { settings.activationMode = .hold }) {
                            HStack {
                                Image(systemName: settings.activationMode == .hold ? "largecircle.fill.circle" : "circle")
                                Text("hold")
                                    .font(.system(size: 11))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: { settings.activationMode = .toggle }) {
                            HStack {
                                Image(systemName: settings.activationMode == .toggle ? "largecircle.fill.circle" : "circle")
                                Text("toggle")
                                    .font(.system(size: 11))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(5)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            GroupBox(label: Text("Clicks").font(.system(size: 11))) {
                MouseGraphicView(settings: settings)
                    .padding(5)
                    .frame(maxWidth: .infinity)
            }
            
            HStack(alignment: .top, spacing: 8) {
                GroupBox(label: Text("Click rate").font(.system(size: 11))) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            TextField("", value: $settings.cps, formatter: numberFormatter)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 70)
                            
                            Stepper("", value: $settings.cps, step: 10)
                                .labelsHidden()
                            
                            Text("Clicks per second")
                                .font(.system(size: 11))
                        }
                        
                        HStack {
                            Toggle("unlimited", isOn: $settings.isUnlimited)
                                .font(.system(size: 11))
                            Toggle("random", isOn: $settings.isRandomCPS)
                                .font(.system(size: 11))
                        }
                        
                        HStack {
                            Text("Click duty cycle")
                                .font(.system(size: 11))
                            TextField("", value: $settings.clickDutyCycle, formatter: numberFormatter)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 60)
                            Stepper("", value: $settings.clickDutyCycle, in: 1...100, step: 5)
                                .labelsHidden()
                            Text("%")
                                .font(.system(size: 11))
                        }
                    }
                    .padding(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                GroupBox(label: Text("Click limit").font(.system(size: 11))) {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Enable Click Limit", isOn: $settings.isClickLimitEnabled)
                            .font(.system(size: 11))
                        
                        HStack {
                            Text("Maximum")
                                .font(.system(size: 11))
                                .foregroundColor(settings.isClickLimitEnabled ? .primary : .gray)
                            
                            TextField("", value: $settings.clickLimit, formatter: intFormatter)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 60)
                                .disabled(!settings.isClickLimitEnabled)
                            
                            Stepper("", value: $settings.clickLimit, step: 100)
                                .labelsHidden()
                                .disabled(!settings.isClickLimitEnabled)
                            
                            Text("Clicks")
                                .font(.system(size: 11))
                                .foregroundColor(settings.isClickLimitEnabled ? .primary : .gray)
                        }
                        
                        Spacer()
                    }
                    .padding(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            GroupBox(label: Text("Misc").font(.system(size: 11))) {
                HStack(alignment: .top, spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) {
                        Toggle("Autostart with macOS", isOn: Binding(
                            get: { settings.isStartWithMacOS },
                            set: { val in
                                settings.isStartWithMacOS = val
                                StartupManager.updateStartupStatus(isEnabled: val)
                            }
                        ))
                        .font(.system(size: 11))
                    }
                    
                    VStack(alignment: .trailing, spacing: 5) {
                        Picker("", selection: $settings.language) {
                            ForEach(LanguageManager.availableLanguages, id: \.id) { lang in
                                Text(lang.name).tag(lang.id)
                                    .font(.system(size: 11))
                            }
                        }
                        .labelsHidden()
                        .frame(width: 120)
                        
                        Button("Reset Settings") {
                            settings.resetToDefaults()
                        }
                        .font(.system(size: 11))
                        .frame(width: 120)
                    }
                }
                .padding(5)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            HStack {
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 100, height: 20)
                    
                    if settings.isRunning {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 100, height: 20)
                            .animation(.default, value: settings.isRunning)
                    } else {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 20, height: 20)
                            .animation(.default, value: settings.isRunning)
                    }
                }
                
                Spacer()
                
                Link("© 59Codings", destination: URL(string: "https://github.com/59Codings")!)
                    .font(.system(size: 11))
                    .foregroundColor(.blue)
                
                Spacer()
                
                Button("OK") {
                    NSApplication.shared.windows.first?.miniaturize(nil)
                }
                .frame(width: 60)
                
                Button("Exit") {
                    NSApplication.shared.terminate(nil)
                }
                .frame(width: 60)
            }
            .padding(.top, 5)
            
            if !settings.isAccessibilityGranted {
                Button(action: { 
                    AccessibilityManager.requestAccess()
                    settings.isAccessibilityGranted = AccessibilityManager.isTrusted
                }) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Accessibility Permissions Missing - Click to Fix")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .padding(8)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(4)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 5)
            }
            
            Text("v1.0 | Trust: \(settings.isAccessibilityGranted ? "YES" : "NO")")
                .font(.system(size: 8))
                .foregroundColor(.gray)
        }
        .padding(10)
        .frame(width: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .onReceive(Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()) { _ in
            let status = AccessibilityManager.refreshTrustStatus()
            if settings.isAccessibilityGranted != status {
                settings.isAccessibilityGranted = status
                if status {
                    hotkeyManager.refreshMonitors()
                }
            }
        }
    }
    

}
