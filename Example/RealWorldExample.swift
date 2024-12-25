// ExampleUsage.swift
// Real-world example for using the SwissQRBill Library

import Foundation
import PDFKit
import SwissQRBill

class RealWorldExample {

    static func generateAndSaveQRBill() {
        // Define creditor and debtor information
        let creditor = Creditor(name: "Max Mustermann", street: "Musterstrasse 37", zipCode: "6000", city: "Luzern", country: "CH")
        let debtor = Debtor(name: "Alexandra Alexis", street: "Musterweg 1", zipCode: "8000", city: "Zürich", country: "CH")

        // Define IBAN
        guard let iban = IBAN(value: "CH9300762011623852957") else {
            print("Invalid IBAN")
            return
        }

        // Create QRBill instance
        let bill = QRBill(
            account: iban,
            creditor: creditor,
            debtor: debtor,
            amount: 199.95,
            currency: "CHF",
            referenceType: .NON,
            reference: "123456789012345678901234567",
            additionalInfo: "Invoice 123"
        )

        // Generate QR Code image
        let qrString = QRBillGenerator.generateQRString(from: bill)
        if let qrImage = QRCodeGenerator.generateQRCode(from: qrString, size: CGSize(width: 300, height: 300)) {
            saveQRCodeImage(qrImage)
        } else {
            print("Failed to generate QR Code image.")
        }

        // Generate compliant PDF
        if let pdfData = QRBillGenerator.generateCompliantPDF(for: bill) {
            savePDF(pdfData)
        } else {
            print("Failed to generate compliant PDF.")
        }
    }

    private static func saveQRCodeImage(_ image: UIImage) {
        let repoPath = URL(fileURLWithPath: "./GeneratedFiles") // Adjust to your desired path
        let qrImageFile = repoPath.appendingPathComponent("QRBillQRCode.png")

        do {
            // Ensure directory exists
            try FileManager.default.createDirectory(at: repoPath, withIntermediateDirectories: true, attributes: nil)
            // Save QR Code image
            try image.pngData()?.write(to: qrImageFile)
            print("QR Code image saved at: \(qrImageFile.path)")
        } catch {
            print("Failed to save QR Code image: \(error)")
        }
    }

    private static func savePDF(_ pdfData: Data) {
        let repoPath = URL(fileURLWithPath: "./GeneratedFiles") // Adjust to your desired path
        let pdfFile = repoPath.appendingPathComponent("QRBillComplianceCheck.pdf")

        do {
            // Ensure directory exists
            try FileManager.default.createDirectory(at: repoPath, withIntermediateDirectories: true, attributes: nil)
            // Save PDF
            try pdfData.write(to: pdfFile)
            print("PDF saved at: \(pdfFile.path)")
        } catch {
            print("Failed to save PDF: \(error)")
        }
    }
}

// Execute the real-world example
RealWorldExample.generateAndSaveQRBill()
