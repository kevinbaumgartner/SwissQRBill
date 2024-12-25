//
// QRBillLibrary
// A Swift package to generate Swiss QR bills
//

import UIKit
import CoreImage
import PDFKit

public class QRCodeGenerator {
    /// Generates a QR code image from a string
    /// - Parameters:
    ///   - string: The content to encode in the QR code
    ///   - size: The desired size of the QR code image
    /// - Returns: A `UIImage` representing the QR code
    public static func generateQRCode(from string: String, size: CGSize) -> UIImage? {
        guard let data = string.data(using: .utf8) else { return nil }
        
        // Create a QR code filter
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel") // Error correction level (L, M, Q, H)
        
        // Get the CIImage output
        guard let ciImage = filter.outputImage else { return nil }
        
        // Scale the image to the desired size
        let transform = CGAffineTransform(scaleX: size.width / ciImage.extent.size.width,
                                          y: size.height / ciImage.extent.size.height)
        let scaledCIImage = ciImage.transformed(by: transform)
        
        // Convert to UIImage
        let uiImage = UIImage(ciImage: scaledCIImage)
        return uiImage
    }
}

class QRBillGenerator {
    /// Generates the QR code image from a QR bill
    static func generateQRBillImage(from bill: QRBill, size: CGSize) -> UIImage? {
        let qrString = generateQRString(from: bill)
        return QRCodeGenerator.generateQRCode(from: qrString, size: size)
    }
    
    /// Generates the QR string for the Swiss QR Bill
    static func generateQRString(from bill: QRBill) -> String {
        let amountString = String(format: "%.2f", bill.amount)
        
        return """
    SPC
    0200
    1
    \(bill.account.value)
    K
    \(bill.creditor.name)
    \(bill.creditor.street)
    \(bill.creditor.zipCode) \(bill.creditor.city)
    
    
    \(bill.creditor.country)
    
    
    
    
    
    
    
    \(amountString)
    \(bill.currency)
    K
    \(bill.debtor.name)
    \(bill.debtor.street)
    \(bill.debtor.zipCode) \(bill.debtor.city)
    
    
    \(bill.debtor.country)
    NON
    
    \(bill.additionalInfo ?? "")
    EPD
    """
    }
    
    /// Generates a PDF file compliant with the Swiss QR Bill standards
    static func generateCompliantPDF(for bill: QRBill) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "QRBillLibrary",
            kCGPDFContextAuthor: "SwissQRBillLibrary"
        ]

        // Define page dimensions
        let pageWidth: CGFloat = 595.0 // A4 width in points
        let pageHeight: CGFloat = 842.0 // A4 height in points
        
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), pdfMetaData)
        UIGraphicsBeginPDFPage()



        // Define bottom section for QR Bill (105 mm height)
        let bottomSectionHeight: CGFloat = 297.0 // 105 mm in points
        let bottomSectionY: CGFloat = pageHeight - bottomSectionHeight
        let columnWidth = (pageWidth - 40) / 3.0 // Three equal columns with margins
        let margin: CGFloat = 20.0

        // Define left, center, and right column positions
        let leftColumnX: CGFloat = margin
        let centerColumnX: CGFloat = leftColumnX + columnWidth
        let rightColumnX: CGFloat = centerColumnX + columnWidth

        // Set Fonts
        let boldAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]

        let boldSmallAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 8),
            .foregroundColor: UIColor.black
        ]

        let smallTextAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8),
            .foregroundColor: UIColor.black
        ]

        // Draw line on top of all columns
        let context = UIGraphicsGetCurrentContext()
        context?.setLineWidth(1.0)
        context?.setStrokeColor(UIColor.black.cgColor)
        context?.move(to: CGPoint(x: 0, y: bottomSectionY))
        context?.addLine(to: CGPoint(x: pageWidth, y: bottomSectionY))
        context?.strokePath()

        // Draw line between first and second column
        context?.move(to: CGPoint(x: leftColumnX + columnWidth - margin, y: bottomSectionY))
        context?.addLine(to: CGPoint(x: leftColumnX + columnWidth - margin, y: bottomSectionY + bottomSectionHeight))
        context?.strokePath()

        // Left Column: Receipt
        let amountString = String(format: "%.2f", bill.amount)
        "Empfangsschein".draw(in: CGRect(x: leftColumnX, y: bottomSectionY + margin, width: columnWidth - margin, height: 20), withAttributes: boldAttributes)
        let receiptText = """
            \(bill.account.value)
            \(bill.creditor.name)
            \(bill.creditor.street)
            \(bill.creditor.zipCode) \(bill.creditor.city)
            """
        "Konto / Zahlbar an:".draw(in: CGRect(x: leftColumnX, y: bottomSectionY + margin + 25, width: columnWidth - margin, height: 15), withAttributes: boldSmallAttributes)
        receiptText.draw(in: CGRect(x: leftColumnX, y: bottomSectionY + margin + 40, width: columnWidth - margin, height: bottomSectionHeight - margin), withAttributes: smallTextAttributes)

        let amountY = bottomSectionY + (bottomSectionHeight - 200) / 2
        "Währung   Betrag".draw(in: CGRect(x: leftColumnX, y: amountY + 160, width: columnWidth - margin, height: 20), withAttributes: boldSmallAttributes)
        let amountTextColumn1 = "\(bill.currency) \(amountString)"
        amountTextColumn1.draw(in: CGRect(x: leftColumnX, y: amountY + 175, width: columnWidth - margin, height: 20), withAttributes: smallTextAttributes)
        
        // Right Column: Payment Part
        "Zahlteil".draw(in: CGRect(x: centerColumnX, y: bottomSectionY + margin, width: columnWidth - margin, height: 20), withAttributes: boldAttributes)

        // Center Column: QR Code and Amount
        guard let qrImage = generateQRBillImage(from: bill, size: CGSize(width: 150, height: 150)) else { return nil }
        let qrCodeX = centerColumnX
        let qrCodeY = bottomSectionY + (bottomSectionHeight - 200) / 2
        qrImage.draw(in: CGRect(x: qrCodeX, y: qrCodeY, width: 150, height: 150))

        "Währung   Betrag".draw(in: CGRect(x: centerColumnX, y: qrCodeY + 160, width: columnWidth - margin, height: 20), withAttributes: boldSmallAttributes)
        let amountText = "\(bill.currency) \(amountString)"
        amountText.draw(in: CGRect(x: centerColumnX, y: qrCodeY + 175, width: columnWidth - margin, height: 20), withAttributes: smallTextAttributes)

        let paymentText = """
            \(bill.account.value)
            \(bill.creditor.name)
            \(bill.creditor.street)
            \(bill.creditor.zipCode) \(bill.creditor.city)
            """
        "Konto / Zahlbar an:".draw(in: CGRect(x: rightColumnX, y: bottomSectionY + margin, width: columnWidth - margin, height: 15), withAttributes: boldSmallAttributes)
        paymentText.draw(in: CGRect(x: rightColumnX, y: bottomSectionY + margin + 15, width: columnWidth - margin, height: 60), withAttributes: smallTextAttributes)

        // Add bold titles
        "Zusätzliche Informationen:".draw(in: CGRect(x: rightColumnX, y: bottomSectionY + margin + 75, width: columnWidth - margin, height: 15), withAttributes: boldSmallAttributes)
        (bill.additionalInfo ?? "").draw(in: CGRect(x: rightColumnX, y: bottomSectionY + margin + 90, width: columnWidth - margin, height: 40), withAttributes: smallTextAttributes)

        "Zahlbar durch:".draw(in: CGRect(x: rightColumnX, y: bottomSectionY + margin + 120, width: columnWidth - margin, height: 15), withAttributes: boldSmallAttributes)
        let debtorText = """
            \(bill.debtor.name)
            \(bill.debtor.street)
            \(bill.debtor.zipCode) \(bill.debtor.city)
            """
        debtorText.draw(in: CGRect(x: rightColumnX, y: bottomSectionY + margin + 135, width: columnWidth - margin, height: 60), withAttributes: smallTextAttributes)

        // Close PDF Context
        UIGraphicsEndPDFContext()
        return pdfData as Data
    }
}
