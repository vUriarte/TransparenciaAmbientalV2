import Foundation
import UIKit

final class CalloutViewFactory {
    func makeDetailView(for ann: FireAnnotation) -> UIView {
        let f = ann.focus

        func makeLabel(_ text: String, font: UIFont = .systemFont(ofSize: 13), color: UIColor = .label) -> UILabel {
            let l = UILabel()
            l.numberOfLines = 0
            l.font = font
            l.textColor = color
            l.text = text
            return l
        }

        var rows: [UIView] = []

        if let sat = f.satelite, !sat.isEmpty {
            rows.append(makeLabel("Satélite: \(sat)"))
        }

        if let frp = f.frp {
            let frpStr = String(format: "%.1f MW", frp)
            rows.append(makeLabel("FRP: \(frpStr)"))
        }

        if let dias = f.numeroDiasSemChuva {
            rows.append(makeLabel("Dias sem chuva: \(dias)"))
        }

        if let risco = f.riscoFogo, !risco.isEmpty {
            rows.append(makeLabel("Risco do fogo: \(risco)"))
        }

        if let bio = f.bioma, !bio.isEmpty {
            rows.append(makeLabel("Bioma: \(bio)"))
        }

        if let est = f.estado, !est.isEmpty {
            rows.append(makeLabel("Estado: \(est)"))
        }

        if let mun = f.municipio, !mun.isEmpty {
            rows.append(makeLabel("Município: \(mun)"))
        }

        if rows.isEmpty {
            rows.append(makeLabel("Sem informações adicionais", color: .secondaryLabel))
        }

        let stack = UIStackView(arrangedSubviews: rows)
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading

        let container = UIView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        let targetWidth: CGFloat = 240

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            container.widthAnchor.constraint(lessThanOrEqualToConstant: targetWidth)
        ])

        return container
    }
}
