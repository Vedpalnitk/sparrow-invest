import UIKit

final class PdfReportGenerator {

    // MARK: - Constants

    private static let pageWidth: CGFloat = 595.28
    private static let pageHeight: CGFloat = 841.89
    private static let margin: CGFloat = 40.0
    private static let contentWidth: CGFloat = 595.28 - 80.0

    private static let primaryColor = UIColor(red: 37/255, green: 99/255, blue: 235/255, alpha: 1.0)
    private static let secondaryColor = UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 1.0)
    private static let successColor = UIColor(red: 16/255, green: 185/255, blue: 129/255, alpha: 1.0)
    private static let errorColor = UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1.0)
    private static let textPrimary = UIColor(red: 30/255, green: 41/255, blue: 59/255, alpha: 1.0)
    private static let textSecondary = UIColor(red: 100/255, green: 116/255, blue: 139/255, alpha: 1.0)
    private static let headerRowColor = UIColor(red: 241/255, green: 245/255, blue: 249/255, alpha: 1.0)
    private static let alternateRowColor = UIColor(red: 248/255, green: 250/255, blue: 252/255, alpha: 1.0)

    // MARK: - Public

    static func generate(type: String, client: FAClientDetail) -> URL? {
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let fileName = type.lowercased().replacingOccurrences(of: " ", with: "_") + "_\(client.name.replacingOccurrences(of: " ", with: "_")).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try renderer.writePDF(to: url) { context in
                switch type {
                case "Portfolio Summary":
                    drawPortfolioSummary(context: context, client: client)
                case "Performance Report":
                    drawPerformanceReport(context: context, client: client)
                case "Tax Statement":
                    drawTaxStatement(context: context, client: client)
                case "Transaction Statement":
                    drawTransactionStatement(context: context, client: client)
                default:
                    drawPortfolioSummary(context: context, client: client)
                }
            }
            return url
        } catch {
            print("PDF generation error: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Report Types

    private static func drawPortfolioSummary(context: UIGraphicsPDFRendererContext, client: FAClientDetail) {
        context.beginPage()
        var yPos = drawHeader(context: context, title: "Portfolio Summary", client: client)

        // AUM Summary
        yPos = drawSectionTitle("Portfolio Overview", at: yPos, context: context)

        let summaryData: [(String, String)] = [
            ("Total AUM", formatCurrency(client.aum)),
            ("Overall Returns", String(format: "%+.2f%%", client.returns)),
            ("Total Holdings", "\(client.holdings.count)"),
            ("Active SIPs", "\(client.sips.filter { $0.status == "ACTIVE" }.count)")
        ]

        for (label, value) in summaryData {
            yPos = drawKeyValue(label: label, value: value, at: yPos, context: context)
        }

        yPos += 20

        // Holdings Table
        yPos = drawSectionTitle("Holdings", at: yPos, context: context)

        let holdingsHeaders = ["Fund Name", "Value", "Returns %"]
        let holdingsRows: [[String]] = client.holdings.map { holding in
            [
                String(holding.fundName.prefix(30)),
                formatCurrency(holding.currentValue),
                String(format: "%+.2f%%", holding.returnsPercentage)
            ]
        }

        yPos = drawTable(headers: holdingsHeaders, rows: holdingsRows, columnWidths: [0.5, 0.25, 0.25], at: yPos, context: context)

        // SIP Summary
        if !client.sips.isEmpty {
            yPos += 20
            if yPos > pageHeight - 150 {
                drawFooter(context: context)
                context.beginPage()
                yPos = margin + 20
            }

            yPos = drawSectionTitle("SIP Summary", at: yPos, context: context)

            let sipHeaders = ["Fund Name", "Amount", "Status"]
            let sipRows: [[String]] = client.sips.map { sip in
                [
                    String(sip.fundName.prefix(30)),
                    formatCurrency(sip.amount),
                    sip.status
                ]
            }

            yPos = drawTable(headers: sipHeaders, rows: sipRows, columnWidths: [0.5, 0.25, 0.25], at: yPos, context: context)
        }

        drawFooter(context: context)
    }

    private static func drawPerformanceReport(context: UIGraphicsPDFRendererContext, client: FAClientDetail) {
        context.beginPage()
        var yPos = drawHeader(context: context, title: "Performance Report", client: client)

        // Returns Summary
        yPos = drawSectionTitle("Returns Summary", at: yPos, context: context)

        let totalInvested = client.holdings.reduce(0.0) { $0 + $1.investedValue }
        let totalCurrent = client.holdings.reduce(0.0) { $0 + $1.currentValue }
        let totalReturns = totalCurrent - totalInvested

        let summaryData: [(String, String)] = [
            ("Total Invested", formatCurrency(totalInvested)),
            ("Current Value", formatCurrency(totalCurrent)),
            ("Total Returns", formatCurrency(totalReturns)),
            ("Overall Return %", String(format: "%+.2f%%", client.returns))
        ]

        for (label, value) in summaryData {
            yPos = drawKeyValue(label: label, value: value, at: yPos, context: context)
        }

        yPos += 20

        // Top Performers
        let sorted = client.holdings.sorted { $0.returnsPercentage > $1.returnsPercentage }
        let topPerformers = Array(sorted.prefix(5))

        if !topPerformers.isEmpty {
            yPos = drawSectionTitle("Top Performers", at: yPos, context: context)

            let headers = ["Fund Name", "Value", "Returns %"]
            let rows: [[String]] = topPerformers.map { h in
                [String(h.fundName.prefix(30)), formatCurrency(h.currentValue), String(format: "%+.2f%%", h.returnsPercentage)]
            }
            yPos = drawTable(headers: headers, rows: rows, columnWidths: [0.5, 0.25, 0.25], at: yPos, context: context)
        }

        // Bottom Performers
        let bottomPerformers = Array(sorted.suffix(min(5, sorted.count)).reversed())
        if !bottomPerformers.isEmpty && sorted.count > 5 {
            yPos += 20
            if yPos > pageHeight - 150 {
                drawFooter(context: context)
                context.beginPage()
                yPos = margin + 20
            }

            yPos = drawSectionTitle("Underperformers", at: yPos, context: context)

            let headers = ["Fund Name", "Value", "Returns %"]
            let rows: [[String]] = bottomPerformers.map { h in
                [String(h.fundName.prefix(30)), formatCurrency(h.currentValue), String(format: "%+.2f%%", h.returnsPercentage)]
            }
            yPos = drawTable(headers: headers, rows: rows, columnWidths: [0.5, 0.25, 0.25], at: yPos, context: context)
        }

        drawFooter(context: context)
    }

    private static func drawTaxStatement(context: UIGraphicsPDFRendererContext, client: FAClientDetail) {
        context.beginPage()
        var yPos = drawHeader(context: context, title: "Tax Statement", client: client)

        yPos = drawSectionTitle("Tax-Relevant Information", at: yPos, context: context)

        // Capital Gains Summary
        let totalGains = client.holdings.reduce(0.0) { $0 + $1.returns }
        let positiveGains = client.holdings.filter { $0.returns > 0 }.reduce(0.0) { $0 + $1.returns }
        let losses = client.holdings.filter { $0.returns < 0 }.reduce(0.0) { $0 + $1.returns }

        let summaryData: [(String, String)] = [
            ("Total Capital Gains", formatCurrency(totalGains)),
            ("Realized Gains", formatCurrency(positiveGains)),
            ("Realized Losses", formatCurrency(losses)),
            ("Net Taxable Amount", formatCurrency(max(0, totalGains)))
        ]

        for (label, value) in summaryData {
            yPos = drawKeyValue(label: label, value: value, at: yPos, context: context)
        }

        yPos += 20

        // Tax-relevant transactions
        let taxTransactions = client.recentTransactions.filter { tx in
            tx.type == "Sell" || tx.type == "Switch" || tx.status == "Completed"
        }

        if !taxTransactions.isEmpty {
            yPos = drawSectionTitle("Tax-Relevant Transactions", at: yPos, context: context)

            let headers = ["Fund", "Type", "Amount", "Date"]
            let rows: [[String]] = taxTransactions.map { tx in
                [String(tx.fundName.prefix(22)), tx.type, formatCurrency(tx.amount), tx.date]
            }
            yPos = drawTable(headers: headers, rows: rows, columnWidths: [0.35, 0.15, 0.25, 0.25], at: yPos, context: context)
        } else {
            yPos += 10
            let noDataAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: textSecondary
            ]
            let noDataStr = NSAttributedString(string: "No tax-relevant transactions found for the current period.", attributes: noDataAttrs)
            noDataStr.draw(at: CGPoint(x: margin, y: yPos))
        }

        drawFooter(context: context)
    }

    private static func drawTransactionStatement(context: UIGraphicsPDFRendererContext, client: FAClientDetail) {
        context.beginPage()
        var yPos = drawHeader(context: context, title: "Transaction Statement", client: client)

        yPos = drawSectionTitle("All Transactions", at: yPos, context: context)

        if client.recentTransactions.isEmpty {
            let noDataAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: textSecondary
            ]
            let noDataStr = NSAttributedString(string: "No transactions recorded.", attributes: noDataAttrs)
            noDataStr.draw(at: CGPoint(x: margin, y: yPos))
        } else {
            let headers = ["Fund", "Type", "Amount", "Status", "Date"]
            let rows: [[String]] = client.recentTransactions.map { tx in
                [String(tx.fundName.prefix(18)), tx.type, formatCurrency(tx.amount), tx.status, tx.date]
            }
            yPos = drawTable(headers: headers, rows: rows, columnWidths: [0.3, 0.12, 0.2, 0.18, 0.2], at: yPos, context: context)
        }

        // Transaction Summary
        yPos += 20
        if yPos < pageHeight - 150 {
            yPos = drawSectionTitle("Summary", at: yPos, context: context)

            let buyTotal = client.recentTransactions.filter { $0.type == "Buy" || $0.type == "SIP" }.reduce(0.0) { $0 + $1.amount }
            let sellTotal = client.recentTransactions.filter { $0.type == "Sell" }.reduce(0.0) { $0 + $1.amount }

            let summaryData: [(String, String)] = [
                ("Total Transactions", "\(client.recentTransactions.count)"),
                ("Total Purchases", formatCurrency(buyTotal)),
                ("Total Redemptions", formatCurrency(sellTotal)),
                ("Net Flow", formatCurrency(buyTotal - sellTotal))
            ]

            for (label, value) in summaryData {
                yPos = drawKeyValue(label: label, value: value, at: yPos, context: context)
            }
        }

        drawFooter(context: context)
    }

    // MARK: - Drawing Helpers

    @discardableResult
    private static func drawHeader(context: UIGraphicsPDFRendererContext, title: String, client: FAClientDetail) -> CGFloat {
        var yPos = margin

        // Brand title
        let brandAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: primaryColor
        ]
        let brandStr = NSAttributedString(string: "Sparrow Invest", attributes: brandAttrs)
        brandStr.draw(at: CGPoint(x: margin, y: yPos))
        yPos += 34

        // Report type subtitle
        let subtitleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .medium),
            .foregroundColor: textPrimary
        ]
        let subtitleStr = NSAttributedString(string: title, attributes: subtitleAttrs)
        subtitleStr.draw(at: CGPoint(x: margin, y: yPos))
        yPos += 26

        // Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy, hh:mm a"
        let dateString = "Generated: \(dateFormatter.string(from: Date()))"

        let dateAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: textSecondary
        ]
        let dateStr = NSAttributedString(string: dateString, attributes: dateAttrs)
        dateStr.draw(at: CGPoint(x: margin, y: yPos))
        yPos += 18

        // Divider line
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: yPos))
        path.addLine(to: CGPoint(x: pageWidth - margin, y: yPos))
        primaryColor.withAlphaComponent(0.3).setStroke()
        path.lineWidth = 1.0
        path.stroke()
        yPos += 12

        // Client info
        let clientNameAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 13),
            .foregroundColor: textPrimary
        ]
        let clientNameStr = NSAttributedString(string: "Client: \(client.name)", attributes: clientNameAttrs)
        clientNameStr.draw(at: CGPoint(x: margin, y: yPos))
        yPos += 18

        let emailAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: textSecondary
        ]
        let emailStr = NSAttributedString(string: "Email: \(client.email)", attributes: emailAttrs)
        emailStr.draw(at: CGPoint(x: margin, y: yPos))

        if let phone = client.phone, !phone.isEmpty {
            let phoneStr = NSAttributedString(string: "Phone: \(phone)", attributes: emailAttrs)
            phoneStr.draw(at: CGPoint(x: pageWidth / 2, y: yPos))
        }

        yPos += 24

        // Divider
        let divider = UIBezierPath()
        divider.move(to: CGPoint(x: margin, y: yPos))
        divider.addLine(to: CGPoint(x: pageWidth - margin, y: yPos))
        UIColor.lightGray.withAlphaComponent(0.4).setStroke()
        divider.lineWidth = 0.5
        divider.stroke()
        yPos += 16

        return yPos
    }

    @discardableResult
    private static func drawSectionTitle(_ title: String, at yPos: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: primaryColor
        ]
        let str = NSAttributedString(string: title, attributes: attrs)
        str.draw(at: CGPoint(x: margin, y: yPos))
        return yPos + 24
    }

    @discardableResult
    private static func drawKeyValue(label: String, value: String, at yPos: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: textSecondary
        ]
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 11),
            .foregroundColor: textPrimary
        ]

        let labelStr = NSAttributedString(string: label, attributes: labelAttrs)
        let valueStr = NSAttributedString(string: value, attributes: valueAttrs)

        labelStr.draw(at: CGPoint(x: margin, y: yPos))
        valueStr.draw(at: CGPoint(x: margin + 180, y: yPos))

        return yPos + 18
    }

    @discardableResult
    private static func drawTable(headers: [String], rows: [[String]], columnWidths: [CGFloat], at yPos: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        var currentY = yPos
        let rowHeight: CGFloat = 22.0

        // Header row background
        let headerRect = CGRect(x: margin, y: currentY, width: contentWidth, height: rowHeight)
        headerRowColor.setFill()
        UIBezierPath(roundedRect: headerRect, cornerRadius: 4).fill()

        // Header text
        var xPos = margin + 6
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 9),
            .foregroundColor: textPrimary
        ]

        for (index, header) in headers.enumerated() {
            let colWidth = contentWidth * columnWidths[index]
            let str = NSAttributedString(string: header.uppercased(), attributes: headerAttrs)
            str.draw(at: CGPoint(x: xPos, y: currentY + 5))
            xPos += colWidth
        }

        currentY += rowHeight

        // Data rows
        let cellAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: textPrimary
        ]

        for (rowIndex, row) in rows.enumerated() {
            // Check if we need a new page
            if currentY + rowHeight > pageHeight - 60 {
                drawFooter(context: context)
                context.beginPage()
                currentY = margin + 20
            }

            // Alternate row background
            if rowIndex % 2 == 1 {
                let rowRect = CGRect(x: margin, y: currentY, width: contentWidth, height: rowHeight)
                alternateRowColor.setFill()
                UIBezierPath(rect: rowRect).fill()
            }

            xPos = margin + 6
            for (colIndex, cell) in row.enumerated() {
                let colWidth = contentWidth * columnWidths[colIndex]
                let str = NSAttributedString(string: cell, attributes: cellAttrs)
                str.draw(at: CGPoint(x: xPos, y: currentY + 5))
                xPos += colWidth
            }

            currentY += rowHeight
        }

        return currentY
    }

    private static func drawFooter(context: UIGraphicsPDFRendererContext) {
        let footerY = pageHeight - 30

        // Footer line
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: footerY - 8))
        path.addLine(to: CGPoint(x: pageWidth - margin, y: footerY - 8))
        UIColor.lightGray.withAlphaComponent(0.3).setStroke()
        path.lineWidth = 0.5
        path.stroke()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm"
        let timestamp = dateFormatter.string(from: Date())

        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8),
            .foregroundColor: textSecondary
        ]

        let leftStr = NSAttributedString(string: "Generated by Sparrow Invest FA", attributes: footerAttrs)
        leftStr.draw(at: CGPoint(x: margin, y: footerY))

        let rightStr = NSAttributedString(string: timestamp, attributes: footerAttrs)
        let rightWidth = rightStr.size().width
        rightStr.draw(at: CGPoint(x: pageWidth - margin - rightWidth, y: footerY))
    }

    // MARK: - Formatting

    private static func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","
        formatter.locale = Locale(identifier: "en_IN")

        if value >= 10_000_000 {
            return "\u{20B9}\(String(format: "%.2f", value / 10_000_000)) Cr"
        } else if value >= 100_000 {
            return "\u{20B9}\(String(format: "%.2f", value / 100_000)) L"
        } else {
            let formatted = formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
            return "\u{20B9}\(formatted)"
        }
    }
}
