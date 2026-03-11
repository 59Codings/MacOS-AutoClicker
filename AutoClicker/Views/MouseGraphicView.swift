
import SwiftUI

struct MouseGraphicView: View {
    @Bindable var settings: AppSettings
    
    var body: some View {
        VStack(spacing: 5) {
            Button(action: { settings.mouseButton = .middle }) {
                HStack(spacing: 4) {
                    Image(systemName: settings.mouseButton == .middle ? "largecircle.fill.circle" : "circle")
                    Text("Middle Button")
                        .font(.system(size: 11))
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.bottom, 2)
            
            HStack(spacing: 8) {
                Button(action: { settings.mouseButton = .left }) {
                    HStack(spacing: 4) {
                        Image(systemName: settings.mouseButton == .left ? "largecircle.fill.circle" : "circle")
                        Text("Left Button")
                            .font(.system(size: 11))
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                ZStack {
                    Capsule()
                        .fill(Color.white)
                        .frame(width: 80, height: 120)
                        .overlay(Capsule().stroke(Color.gray, lineWidth: 1))
                        .shadow(radius: 2)
                    
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: 40))
                                path.addCurve(to: CGPoint(x: 40, y: 0), control1: CGPoint(x: 0, y: 10), control2: CGPoint(x: 10, y: 0))
                                path.addLine(to: CGPoint(x: 40, y: 40))
                                path.addLine(to: CGPoint(x: 0, y: 40))
                            }
                            .fill(settings.mouseButton == .left ? Color.red.opacity(0.5) : Color.clear)
                            .frame(width: 40, height: 40)
                            
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: 40))
                                path.addLine(to: CGPoint(x: 0, y: 0))
                                path.addCurve(to: CGPoint(x: 40, y: 40), control1: CGPoint(x: 30, y: 0), control2: CGPoint(x: 40, y: 10))
                                path.addLine(to: CGPoint(x: 0, y: 40))
                            }
                            .fill(settings.mouseButton == .right ? Color.red.opacity(0.5) : Color.clear)
                            .frame(width: 40, height: 40)
                        }
                        
                        Capsule()
                            .fill(settings.mouseButton == .middle ? Color.red.opacity(0.7) : Color.gray)
                            .frame(width: 8, height: 20)
                            .offset(y: -50)
                        
                        Spacer()
                    }
                    .frame(width: 80, height: 120)
                    .clipShape(Capsule())
                }
                
                Button(action: { settings.mouseButton = .right }) {
                    HStack(spacing: 4) {
                        Image(systemName: settings.mouseButton == .right ? "largecircle.fill.circle" : "circle")
                        Text("Right Button")
                            .font(.system(size: 11))
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}
