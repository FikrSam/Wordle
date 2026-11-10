//
//  LogoShape.swift
//  Wordle
//
//  Created by Fikir on 11/9/26.
//

import SwiftUI

/// Vector shape matching the custom Wordle / Wordly "W" logo provided:
/// <svg width="44" height="36" viewBox="0 0 44 36" ...>
struct WordleLogoShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let sx = rect.width / 44.0
        let sy = rect.height / 36.0

        path.move(to: CGPoint(x: 14.5002 * sx, y: 36.0000 * sy))
        path.addCurve(to: CGPoint(x: 9.7246 * sx, y: 34.5103 * sy), control1: CGPoint(x: 12.4772 * sx, y: 36.0000 * sy), control2: CGPoint(x: 10.8853 * sx, y: 35.5035 * sy))
        path.addCurve(to: CGPoint(x: 6.9387 * sx, y: 30.4386 * sy), control1: CGPoint(x: 8.5638 * sx, y: 33.5172 * sy), control2: CGPoint(x: 7.6352 * sx, y: 32.1600 * sy))
        path.addCurve(to: CGPoint(x: 5.0484 * sx, y: 24.4800 * sy), control1: CGPoint(x: 6.2755 * sx, y: 28.6841 * sy), control2: CGPoint(x: 5.6453 * sx, y: 26.6979 * sy))
        path.addLine(to: CGPoint(x: 0.2229 * sx, y: 6.6041 * sy))
        path.addCurve(to: CGPoint(x: 0.4717 * sx, y: 2.7310 * sy), control1: CGPoint(x: -0.1419 * sx, y: 5.2138 * sy), control2: CGPoint(x: -0.0590 * sx, y: 3.9228 * sy))
        path.addCurve(to: CGPoint(x: 3.6057 * sx, y: 0.2979 * sy), control1: CGPoint(x: 1.0023 * sx, y: 1.5062 * sy), control2: CGPoint(x: 2.0470 * sx, y: 0.6952 * sy))
        path.addCurve(to: CGPoint(x: 7.4859 * sx, y: 0.5959 * sy), control1: CGPoint(x: 5.0649 * sx, y: -0.0993 * sy), control2: CGPoint(x: 6.3584 * sx, y: 0.0000 * sy))
        path.addCurve(to: CGPoint(x: 9.7743 * sx, y: 3.7241 * sy), control1: CGPoint(x: 8.6135 * sx, y: 1.1917 * sy), control2: CGPoint(x: 9.3763 * sx, y: 2.2345 * sy))
        path.addLine(to: CGPoint(x: 14.2515 * sx, y: 20.0607 * sy))
        path.addCurve(to: CGPoint(x: 15.4952 * sx, y: 23.1890 * sy), control1: CGPoint(x: 14.6495 * sx, y: 21.4841 * sy), control2: CGPoint(x: 15.0640 * sx, y: 22.5269 * sy))
        path.addCurve(to: CGPoint(x: 17.6840 * sx, y: 23.8345 * sy), control1: CGPoint(x: 15.9595 * sx, y: 23.8510 * sy), control2: CGPoint(x: 16.6891 * sx, y: 24.0662 * sy))
        path.addCurve(to: CGPoint(x: 19.1764 * sx, y: 22.2952 * sy), control1: CGPoint(x: 18.6126 * sx, y: 23.6028 * sy), control2: CGPoint(x: 19.1101 * sx, y: 23.0897 * sy))
        path.addCurve(to: CGPoint(x: 18.6790 * sx, y: 18.9186 * sy), control1: CGPoint(x: 19.2427 * sx, y: 21.5007 * sy), control2: CGPoint(x: 19.0769 * sx, y: 20.3752 * sy))
        path.addLine(to: CGPoint(x: 15.4952 * sx, y: 6.8524 * sy))
        path.addCurve(to: CGPoint(x: 15.6444 * sx, y: 2.5821 * sy), control1: CGPoint(x: 15.0640 * sx, y: 5.1972 * sy), control2: CGPoint(x: 15.1138 * sx, y: 3.7738 * sy))
        path.addCurve(to: CGPoint(x: 18.9277 * sx, y: 0.1986 * sy), control1: CGPoint(x: 16.2082 * sx, y: 1.3572 * sy), control2: CGPoint(x: 17.3026 * sx, y: 0.5628 * sy))
        path.addCurve(to: CGPoint(x: 22.9074 * sx, y: 0.8441 * sy), control1: CGPoint(x: 20.5859 * sx, y: -0.1986 * sy), control2: CGPoint(x: 21.9125 * sx, y: 0.0166 * sy))
        path.addCurve(to: CGPoint(x: 24.9968 * sx, y: 4.2207 * sy), control1: CGPoint(x: 23.9355 * sx, y: 1.6386 * sy), control2: CGPoint(x: 24.6320 * sx, y: 2.7641 * sy))
        path.addLine(to: CGPoint(x: 29.0263 * sx, y: 20.0607 * sy))
        path.addCurve(to: CGPoint(x: 30.4192 * sx, y: 23.3379 * sy), control1: CGPoint(x: 29.4574 * sx, y: 21.6828 * sy), control2: CGPoint(x: 29.9217 * sx, y: 22.7752 * sy))
        path.addCurve(to: CGPoint(x: 32.4588 * sx, y: 23.8345 * sy), control1: CGPoint(x: 30.9498 * sx, y: 23.9007 * sy), control2: CGPoint(x: 31.6297 * sx, y: 24.0662 * sy))
        path.addCurve(to: CGPoint(x: 33.8019 * sx, y: 22.2952 * sy), control1: CGPoint(x: 33.3874 * sx, y: 23.5697 * sy), control2: CGPoint(x: 33.8351 * sx, y: 23.0566 * sy))
        path.addCurve(to: CGPoint(x: 33.4537 * sx, y: 18.8690 * sy), control1: CGPoint(x: 33.7688 * sx, y: 21.5007 * sy), control2: CGPoint(x: 33.6527 * sx, y: 20.3586 * sy))
        path.addCurve(to: CGPoint(x: 32.6578 * sx, y: 13.1586 * sy), control1: CGPoint(x: 33.1552 * sx, y: 16.5517 * sy), control2: CGPoint(x: 32.8899 * sx, y: 14.6483 * sy))
        path.addCurve(to: CGPoint(x: 32.1603 * sx, y: 9.4345 * sy), control1: CGPoint(x: 32.4588 * sx, y: 11.6690 * sy), control2: CGPoint(x: 32.2930 * sx, y: 10.4276 * sy))
        path.addCurve(to: CGPoint(x: 32.0111 * sx, y: 6.7034 * sy), control1: CGPoint(x: 32.0608 * sx, y: 8.4414 * sy), control2: CGPoint(x: 32.0111 * sx, y: 7.5310 * sy))
        path.addCurve(to: CGPoint(x: 33.6527 * sx, y: 1.9862 * sy), control1: CGPoint(x: 32.0111 * sx, y: 4.8497 * sy), control2: CGPoint(x: 32.5583 * sx, y: 3.2772 * sy))
        path.addCurve(to: CGPoint(x: 38.1299 * sx, y: 0.0000 * sy), control1: CGPoint(x: 34.7471 * sx, y: 0.6621 * sy), control2: CGPoint(x: 36.2395 * sx, y: 0.0000 * sy))
        path.addCurve(to: CGPoint(x: 42.5076 * sx, y: 1.7876 * sy), control1: CGPoint(x: 40.0534 * sx, y: 0.0000 * sy), control2: CGPoint(x: 41.5127 * sx, y: 0.5959 * sy))
        path.addCurve(to: CGPoint(x: 44.0000 * sx, y: 6.6041 * sy), control1: CGPoint(x: 43.5025 * sx, y: 2.9462 * sy), control2: CGPoint(x: 44.0000 * sx, y: 4.5517 * sy))
        path.addCurve(to: CGPoint(x: 43.4030 * sx, y: 10.7752 * sy), control1: CGPoint(x: 44.0000 * sx, y: 7.9283 * sy), control2: CGPoint(x: 43.8010 * sx, y: 9.3186 * sy))
        path.addCurve(to: CGPoint(x: 42.3086 * sx, y: 14.8966 * sy), control1: CGPoint(x: 43.0382 * sx, y: 12.2317 * sy), control2: CGPoint(x: 42.6734 * sx, y: 13.6055 * sy))
        path.addLine(to: CGPoint(x: 39.5228 * sx, y: 24.4800 * sy))
        path.addCurve(to: CGPoint(x: 37.6324 * sx, y: 30.3890 * sy), control1: CGPoint(x: 38.8927 * sx, y: 26.6648 * sy), control2: CGPoint(x: 38.2626 * sx, y: 28.6345 * sy))
        path.addCurve(to: CGPoint(x: 35.1948 * sx, y: 34.5103 * sy), control1: CGPoint(x: 37.0355 * sx, y: 32.1103 * sy), control2: CGPoint(x: 36.2229 * sx, y: 33.4841 * sy))
        path.addCurve(to: CGPoint(x: 30.8171 * sx, y: 36.0000 * sy), control1: CGPoint(x: 34.1667 * sx, y: 35.5035 * sy), control2: CGPoint(x: 32.7075 * sx, y: 36.0000 * sy))
        path.addCurve(to: CGPoint(x: 25.4445 * sx, y: 33.8648 * sy), control1: CGPoint(x: 28.5288 * sx, y: 36.0000 * sy), control2: CGPoint(x: 26.7379 * sx, y: 35.2883 * sy))
        path.addCurve(to: CGPoint(x: 22.4597 * sx, y: 26.8634 * sy), control1: CGPoint(x: 24.1511 * sx, y: 32.4414 * sy), control2: CGPoint(x: 23.1562 * sx, y: 30.1076 * sy))
        path.addLine(to: CGPoint(x: 22.1115 * sx, y: 26.8634 * sy))
        path.addCurve(to: CGPoint(x: 19.4749 * sx, y: 33.8648 * sy), control1: CGPoint(x: 21.4482 * sx, y: 30.1076 * sy), control2: CGPoint(x: 20.5693 * sx, y: 32.4414 * sy))
        path.addCurve(to: CGPoint(x: 14.5002 * sx, y: 36.0000 * sy), control1: CGPoint(x: 18.3805 * sx, y: 35.2883 * sy), control2: CGPoint(x: 16.7222 * sx, y: 36.0000 * sy))
        path.closeSubpath()

        return path
    }
}

/// Tactile Brand Logo Badge used in header, hero, and icon previews
struct BrandLogoBadge: View {
    var size: CGFloat = 40
    var iconColor: Color = .white
    var backgroundColor: Color = Color(red: 0.31, green: 0.27, blue: 0.90)

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(backgroundColor)
                .frame(width: size, height: size)

            WordleLogoShape()
                .fill(iconColor)
                .frame(width: size * 0.55, height: size * 0.45)
        }
    }
}
