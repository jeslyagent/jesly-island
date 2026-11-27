import SwiftUI
import CoreGraphics

// MARK: - Head geometry (extracted from MochiOutfitDrawing.swift, Fase 2 sesión 5)
//
// MochiOutfitDrawing.swift held two things: the outfit drawing AND the shared
// head/eye geometry that BotEngine.drawEyes needs (`MochiH`, `mEyeFrames`).
// The outfit part is deleted with that file; this file keeps the geometry,
// copied verbatim (only the two outfit-only constants, `kEXP` and
// `kACC_PITCH`, were left behind — the 3D helpers that used them went with
// the outfit code). JESLY's cloud does not use this file; Mochi's body in
// the room, the pills and the weekly recap still do, until they are replaced.

// MARK: - Constants (mirror JS)

private let kVIEW_TILT: CGFloat = -0.30
private let kEYE_W: CGFloat = 0.25
private let kEYE_H: CGFloat = 0.27
private let kEYE_SP: CGFloat = 0.37
private let kEYE_P: CGFloat = -0.12

// MARK: - MochiH  (head geometry + physics)

struct MochiH {
    let R, rx, ry: CGFloat
    let yaw, pitch: CGFloat
    let view: CGFloat      // = VIEW_TILT (-0.30)
    let physDx, physDy: CGFloat
    let roll: CGFloat

    init(R: CGFloat, yaw: CGFloat = 0, pitch: CGFloat = 0,
         physDx: CGFloat = 0, physDy: CGFloat = 0, roll: CGFloat = 0) {
        self.R = R
        self.rx = R * 1.14
        self.ry = R * 0.88
        self.yaw = yaw
        self.pitch = pitch
        self.view = kVIEW_TILT
        self.physDx = physDx
        self.physDy = physDy
        self.roll = roll
    }
}

// MARK: - EyeFrame  (replaces mochiEyePositions)

struct EyeFrame {
    let sd: CGFloat   // -1 left, +1 right
    let x, y: CGFloat
    let fx, fy: CGFloat
    let visible: Bool
    let w, h: CGFloat
}

func mEyeFrames(_ H: MochiH) -> [EyeFrame] {
    var out: [EyeFrame] = []
    for sdD: Double in [-1.0, 1.0] {
        let sd = CGFloat(sdD)
        let eyeYaw   = sd * kEYE_SP + H.yaw
        let eyePitch = kEYE_P + H.pitch
        let cp = cos(eyePitch)
        let visible = cos(eyeYaw) * cp > 0.04
        out.append(EyeFrame(
            sd: sd,
            x:  sin(eyeYaw) * cp * H.rx,
            y: -sin(eyePitch) * H.ry,
            fx: max(0.18, cos(eyeYaw)),
            fy: max(0.18, cp),
            visible: visible,
            w: H.R * kEYE_W,
            h: H.R * kEYE_H
        ))
    }
    return out
}

/// Backward-compat shim (used by existing callers that haven't been updated yet).
func mochiEyePositions(yaw: CGFloat, pitch: CGFloat, rx: CGFloat, ry: CGFloat)
    -> [(ex: CGFloat, ey: CGFloat, fx: CGFloat, fy: CGFloat)] {
    let H = MochiH(R: rx / 1.14, yaw: yaw, pitch: pitch)
    return mEyeFrames(H).filter { $0.visible }.map { (ex: $0.x, ey: $0.y, fx: $0.fx, fy: $0.fy) }
}
