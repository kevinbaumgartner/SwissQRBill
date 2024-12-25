//
//  QRBill.swift
//  SwissQRBill
//
//  Created by Kevin Baumgartner on 25.12.2024.
//

import Foundation

public struct QRBill {
    let account: IBAN
    let creditor: Creditor
    let debtor: Debtor
    let amount: Double
    let currency: String
    let referenceType: RefrenceType
    let reference: String?
    let additionalInfo: String?
    
    init(account: IBAN, creditor: Creditor, debtor: Debtor, amount: Double, currency: String, referenceType: RefrenceType, reference: String, additionalInfo: String?) {
        self.account = account
        self.creditor = creditor
        self.debtor = debtor
        self.amount = amount
        self.currency = currency
        self.referenceType = referenceType
        self.reference = reference
        self.additionalInfo = additionalInfo
    }
}

enum RefrenceType: String {
    case QRR = "QRR"
    case SCOR = "SCOR"
    case NON = "NON"
}

public struct IBAN {
    let value: String

    init?(value: String) {
        guard IBAN.isValid(value) else {
            return nil
        }
        self.value = value
    }

    static func isValid(_ iban: String) -> Bool {
        // Remove spaces and ensure uppercase
        let cleanIBAN = iban.replacingOccurrences(of: " ", with: "").uppercased()
        
        // Basic length check
        guard cleanIBAN.count >= 15 && cleanIBAN.count <= 34 else { return false }

        // Rearrange IBAN: move first 4 characters to the end
        let rearranged = cleanIBAN.dropFirst(4) + cleanIBAN.prefix(4)
        
        // Convert letters to numbers (A=10, B=11, ..., Z=35)
        let numericIBAN = rearranged.compactMap { char -> String? in
            if let digit = char.wholeNumberValue {
                return "\(digit)"
            } else if char.isLetter {
                return "\(Int(char.asciiValue! - 55))" // A=10, B=11, ..., Z=35
            }
            return nil
        }.joined()

        // Perform the modulo operation without BigInt
        let modulo = ibanModulo(numericIBAN)
        return modulo == 1
    }

    // Helper method to calculate modulo for very large numbers
    private static func ibanModulo(_ numericIBAN: String) -> Int {
        var remainder = 0
        for char in numericIBAN {
            if let digit = char.wholeNumberValue {
                remainder = (remainder * 10 + digit) % 97
            }
        }
        return remainder
    }
}
