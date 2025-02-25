//
// QRBillLibrary
// A Swift package to generate Swiss QR bills
//

#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
import CoreImage
import PDFKit

#if os(macOS)
public typealias PlatformImage = NSImage
typealias PlatformFont = NSFont
typealias PlatformColor = NSColor
#else
public typealias PlatformImage = UIImage
typealias PlatformFont = UIFont
typealias PlatformColor = UIColor
#endif

class QRCodeGenerator {
    /// Generates a QR code image for iOS
    /// - Parameters:
    ///   - string: The content to encode in the QR code
    ///   - size: The desired size of the QR code image
    /// - Returns: A UIImage containing the QR code
    #if !os(macOS)
    static func generateQRCodeForIOS(from string: String, size: CGSize) -> UIImage? {
        guard let data = string.data(using: .utf8) else { return nil }
        
        // Create a QR code filter
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        
        // Get the CIImage output
        guard let ciImage = filter.outputImage else { return nil }
        
        // Scale the image to the desired size
        let transform = CGAffineTransform(scaleX: size.width / ciImage.extent.size.width,
                                        y: size.height / ciImage.extent.size.height)
        let scaledCIImage = ciImage.transformed(by: transform)
        
        return UIImage(ciImage: scaledCIImage)
    }
    #endif

    /// Generates a QR code image for macOS
    /// - Parameters:
    ///   - string: The content to encode in the QR code
    ///   - size: The desired size of the QR code image
    /// - Returns: An NSImage containing the QR code
    #if os(macOS)
    static func generateQRCodeForMacOS(from string: String, size: CGSize) -> NSImage? {
        guard let data = string.data(using: .utf8) else { return nil }
        
        // Create a QR code filter
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        
        // Get the CIImage output
        guard let ciImage = filter.outputImage else { return nil }
        
        // Scale the image to the desired size
        let transform = CGAffineTransform(scaleX: size.width / ciImage.extent.size.width,
                                        y: size.height / ciImage.extent.size.height)
        let scaledCIImage = ciImage.transformed(by: transform)
        
        // Convert to NSImage
        let rep = NSCIImageRep(ciImage: scaledCIImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        return nsImage
    }
    #endif

    /// Platform-agnostic wrapper that calls the appropriate platform-specific function
    static func generateQRCode(from string: String, size: CGSize) -> PlatformImage? {
        #if os(macOS)
        return generateQRCodeForMacOS(from: string, size: size)
        #else
        return generateQRCodeForIOS(from: string, size: size)
        #endif
    }
}

public class QRBillGenerator {
    /// Generates the QR code image from a QR bill
    public static func generateQRBillImage(from bill: QRBill, size: CGSize) -> PlatformImage? {
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
    public static func generateQRBillPDF(for bill: QRBill) -> Data? {
        let pdfMetaData = [
            kCGPDFContextCreator: "QRBillLibrary",
            kCGPDFContextAuthor: "SwissQRBillLibrary"
        ]

        // Define page dimensions
        let pageWidth: CGFloat = 595.0 // A4 width in points
        let pageHeight: CGFloat = 842.0 // A4 height in points
        
        let pdfData = NSMutableData()
        
        #if os(macOS)
        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        guard let context = CGContext(consumer: CGDataConsumer(data: pdfData)!,
                                    mediaBox: &mediaBox,
                                    pdfMetaData as CFDictionary) else { return nil }
        
        context.beginPDFPage(nil as CFDictionary?)
        #else
        UIGraphicsBeginPDFContextToData(pdfData, CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), pdfMetaData)
        UIGraphicsBeginPDFPage()
        let context = UIGraphicsGetCurrentContext()!
        #endif

        // Define bottom section for QR Bill (105 mm height)
        let bottomSectionHeight: CGFloat = 297.0 // 105 mm in points
        let bottomSectionY: CGFloat = pageHeight - bottomSectionHeight
        let columnWidth = (pageWidth - 40) / 3.0 // Three equal columns with margins
        let margin: CGFloat = 20.0

        // Define left, center, and right column positions
        let leftColumnX: CGFloat = margin
        let centerColumnX: CGFloat = leftColumnX + columnWidth
        let rightColumnX: CGFloat = centerColumnX + columnWidth

        #if os(macOS)
        let boldFont = PlatformFont.boldSystemFont(ofSize: 12)
        let boldSmallFont = PlatformFont.boldSystemFont(ofSize: 8)
        let smallFont = PlatformFont.systemFont(ofSize: 8)
        
        let boldAttributes: [NSAttributedString.Key: Any] = [
            .font: boldFont,
            .foregroundColor: PlatformColor.black
        ]

        let boldSmallAttributes: [NSAttributedString.Key: Any] = [
            .font: boldSmallFont,
            .foregroundColor: PlatformColor.black
        ]

        let smallTextAttributes: [NSAttributedString.Key: Any] = [
            .font: smallFont,
            .foregroundColor: PlatformColor.black
        ]
        #else
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
        #endif

        // Draw line on top of all columns
        context.setLineWidth(1.0)
        context.setStrokeColor(PlatformColor.black.cgColor)
        context.move(to: CGPoint(x: 0, y: bottomSectionY))
        context.addLine(to: CGPoint(x: pageWidth, y: bottomSectionY))
        context.strokePath()

        // Draw line between first and second column
        context.move(to: CGPoint(x: leftColumnX + columnWidth - margin, y: bottomSectionY))
        context.addLine(to: CGPoint(x: leftColumnX + columnWidth - margin, y: bottomSectionY + bottomSectionHeight))
        context.strokePath()

        // Left Column: Receipt
        let amountString = String(format: "%.2f", bill.amount)
        
        #if os(macOS)
        let flip = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: pageHeight)
        context.concatenate(flip)
        #endif
        
        // Draw text using NSAttributedString for both platforms
        ("Empfangsschein" as NSString).draw(in: CGRect(x: leftColumnX, y: bottomSectionY + margin, width: columnWidth - margin, height: 20), withAttributes: boldAttributes)
        let receiptText = """
            \(bill.account.value)
            \(bill.creditor.name)
            \(bill.creditor.street)
            \(bill.creditor.zipCode) \(bill.creditor.city)
            """
        ("Konto / Zahlbar an:" as NSString).draw(in: CGRect(x: leftColumnX, y: bottomSectionY + margin + 25, width: columnWidth - margin, height: 15), withAttributes: boldSmallAttributes)
        (receiptText as NSString).draw(in: CGRect(x: leftColumnX, y: bottomSectionY + margin + 40, width: columnWidth - margin, height: bottomSectionHeight - margin), withAttributes: smallTextAttributes)

        let amountY = bottomSectionY + (bottomSectionHeight - 200) / 2
        ("Währung   Betrag" as NSString).draw(in: CGRect(x: leftColumnX, y: amountY + 160, width: columnWidth - margin, height: 20), withAttributes: boldSmallAttributes)
        let amountTextColumn1 = "\(bill.currency) \(amountString)"
        (amountTextColumn1 as NSString).draw(in: CGRect(x: leftColumnX, y: amountY + 175, width: columnWidth - margin, height: 20), withAttributes: smallTextAttributes)
        
        // Right Column: Payment Part
        ("Zahlteil" as NSString).draw(in: CGRect(x: centerColumnX, y: bottomSectionY + margin, width: columnWidth - margin, height: 20), withAttributes: boldAttributes)

        // Center Column: QR Code and Amount
        guard let qrImage = generateQRBillImage(from: bill, size: CGSize(width: 150, height: 150)) else { return nil }
        let qrCodeX = centerColumnX
        let qrCodeY = bottomSectionY + (bottomSectionHeight - 200) / 2
        #if os(macOS)
        qrImage.draw(in: CGRect(x: qrCodeX, y: pageHeight - qrCodeY - 150, width: 150, height: 150), from: .zero, operation: .sourceOver, fraction: 1.0)
        #else
        qrImage.draw(in: CGRect(x: qrCodeX, y: qrCodeY, width: 150, height: 150))
        #endif

        ("Währung   Betrag" as NSString).draw(in: CGRect(x: centerColumnX, y: qrCodeY + 160, width: columnWidth - margin, height: 20), withAttributes: boldSmallAttributes)
        let amountText = "\(bill.currency) \(amountString)"
        (amountText as NSString).draw(in: CGRect(x: centerColumnX, y: qrCodeY + 175, width: columnWidth - margin, height: 20), withAttributes: smallTextAttributes)

        let paymentText = """
            \(bill.account.value)
            \(bill.creditor.name)
            \(bill.creditor.street)
            \(bill.creditor.zipCode) \(bill.creditor.city)
            """
        ("Konto / Zahlbar an:" as NSString).draw(in: CGRect(x: rightColumnX, y: bottomSectionY + margin, width: columnWidth - margin, height: 15), withAttributes: boldSmallAttributes)
        (paymentText as NSString).draw(in: CGRect(x: rightColumnX, y: bottomSectionY + margin + 15, width: columnWidth - margin, height: 60), withAttributes: smallTextAttributes)

        // Add bold titles
        ("Zusätzliche Informationen:" as NSString).draw(in: CGRect(x: rightColumnX, y: bottomSectionY + margin + 75, width: columnWidth - margin, height: 15), withAttributes: boldSmallAttributes)
        ((bill.additionalInfo ?? "") as NSString).draw(in: CGRect(x: rightColumnX, y: bottomSectionY + margin + 90, width: columnWidth - margin, height: 40), withAttributes: smallTextAttributes)

        ("Zahlbar durch:" as NSString).draw(in: CGRect(x: rightColumnX, y: bottomSectionY + margin + 120, width: columnWidth - margin, height: 15), withAttributes: boldSmallAttributes)
        let debtorText = """
            \(bill.debtor.name)
            \(bill.debtor.street)
            \(bill.debtor.zipCode) \(bill.debtor.city)
            """
        (debtorText as NSString).draw(in: CGRect(x: rightColumnX, y: bottomSectionY + margin + 135, width: columnWidth - margin, height: 60), withAttributes: smallTextAttributes)

        // Close PDF Context
        #if os(macOS)
        context.endPDFPage()
        context.closePDF()
        #else
        UIGraphicsEndPDFContext()
        #endif
        
        return pdfData as Data
    }
}
