//
//  DeliveryToastView.swift
//  Dictdotclick
//
//  Phase 6 — the brief message shown after a dictation lands.
//
//  Only needed when something did not go to plan. A successful paste needs no
//  announcement: the words appearing where the user was typing is the
//  feedback. A toast on every success would be noise over their real work.
//
//  A failure does need one, and specifically needs to say what to do next —
//  "press ⌘V" — because the alternative is a user who talked for a minute and
//  believes the app lost it.
//

import SwiftUI

struct DeliveryToastView: View {
    let message: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 15))
                .foregroundStyle(.tint)

            Text(message)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .frame(maxWidth: 380, alignment: .leading)
        .glassEffect(.regular, in: .capsule)
        .fixedSize()
    }
}

#Preview {
    DeliveryToastView(
        message: "Copied — press ⌘V to paste.",
        systemImage: "doc.on.clipboard"
    )
    .padding(40)
}
