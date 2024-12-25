//
//  ContactInfo.swift
//  SwissQRBill
//
//  Created by Kevin Baumgartner on 25.12.2024.
//


protocol ContactInfo {
    var name: String { get }
    var street: String { get }
    var zipCode: String { get }
    var city: String { get }
    var country: String { get }
}

public struct Creditor: ContactInfo  {
    var name: String
    var street: String
    var zipCode: String
    var city: String
    var country: String
}

public struct Debtor: ContactInfo {
    var name: String
    var street: String
    var zipCode: String
    var city: String
    var country: String
}