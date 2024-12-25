// QRBillLibraryTests
// Tests for the Swiss QR Bill Library

import Testing
import Foundation
import PDFKit
@testable import SwissQRBill

@Suite("QRBillLibraryTests")
class QRBillLibraryTests {

    // Shared QRBill instance for all tests
    var bill: QRBill

    init() {
        let creditor = Creditor(name: "Max Mustermann", street: "Musterstrasse 37", zipCode: "6000", city: "Luzern", country: "CH")
        let debtor = Debtor(name: "Alexandra Alexis", street: "Musterweg 1", zipCode: "8000", city: "Zürich", country: "CH")
        guard let iban = IBAN(value: "CH9300762011623852957") else { fatalError("Invalid IBAN") }
        bill = QRBill(
            account: iban,
            creditor: creditor,
            debtor: debtor,
            amount: 199.95,
            currency: "CHF",
            referenceType: .NON,
            reference: "123456789012345678901234567",
            additionalInfo: "Invoice 123"
        )
    }

    @Test("QRBill generates valid QR strings")
    func testQRBillGeneratesValidQRStrings() {
        let qrString = QRBillGenerator.generateQRString(from: bill)
        print("QRString: \(qrString)")
        assert(qrString.contains("SPC"))
        assert(qrString.contains("CH9300762011623852957"))
        assert(qrString.contains("199.95"))
        assert(qrString.contains("CHF"))
        assert(qrString.contains("NON"))
        assert(qrString.contains("EPD"))
        assert(!qrString.contains("IBAN"))
    }

    @Test("QRCodeGenerator generates and saves valid QR code images")
    func testQRCodeGeneratorGeneratesAndSavesQRCodeImages() {
        let qrString = QRBillGenerator.generateQRString(from: bill)
        let image = QRCodeGenerator.generateQRCode(from: qrString, size: CGSize(width: 300, height: 300))
        assert(image != nil)

        // Save QR code image to a specific repository path
        if let image = image {
            let repoPath = URL(fileURLWithPath: "/Users/kevinbaumgartner/Documents/Projekte/Libraries/SwissQRBill/Results/") // Replace with your actual repository path
            let qrImageFile = repoPath.appendingPathComponent("SwissQRBill.png")
            do {
                try image.pngData()?.write(to: qrImageFile)
                print("QR code image saved at: \(qrImageFile.path)")
            } catch {
                assertionFailure("Failed to save the QR code image file: \(error)")
            }
        }
    }

    @Test("Check PDF output and save to repository")
    func testPDFContentComplianceAndSave() {
        let pdfData = QRBillGenerator.generateQRBillPDF(for: bill)
        assert(pdfData != nil)

        // Save PDF to a specific repository path
        if let pdfData = pdfData {
            let repoPath = URL(fileURLWithPath: "/Users/kevinbaumgartner/Documents/Projekte/Libraries/SwissQRBill/Results/") // Replace with your actual repository path
            let pdfFile = repoPath.appendingPathComponent("SwissQRBill.pdf")
            do {
                try pdfData.write(to: pdfFile)
                print("PDF saved for compliance check at: \(pdfFile.path)")

                // Open and validate content structure
                let pdfDocument = PDFDocument(data: pdfData)
                assert(pdfDocument != nil, "Failed to open generated PDF for compliance check.")
                let page = pdfDocument?.page(at: 0)
                assert(page != nil, "Generated PDF does not contain a page.")

                // Ensure QR code is present and sections are properly defined (visual/manual validation)
            } catch {
                assertionFailure("Failed to save the compliance PDF file: \(error)")
            }
        }
    }

}
