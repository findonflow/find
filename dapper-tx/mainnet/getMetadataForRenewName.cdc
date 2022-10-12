import DapperUtilityCoin from 0xead892083b3e2c6c
import FIND from 0x097bafa4e0b48eef

pub fun main(merchAccount: Address, name: String, amount: UFix64) : PurchaseData {

    let price = FIND.calculateCost(name)
    if amount != price {
        panic("Amount passed in does not match. Required price : ".concat(price.toString()))
    }
    let nameStatus=FIND.status(name)
    if nameStatus.status == FIND.LeaseStatus.FREE {
        panic("Name is not registered")
    }

    let description = "Renew name :".concat(name).concat(" for Dapper Credit ").concat(amount.toString())
    let imageURL = "https://i.imgur.com/8W8NoO1.png"

    return PurchaseData(
            // what should we put here?
            id: 0, 
            name: name, 
            amount: amount, 
            description: description, 
            imageURL: imageURL
            )
}

pub struct PurchaseData {
    pub let id: UInt64
    pub let name: String
    pub let amount: UFix64
    pub let description: String
    pub let imageURL: String

    init(id: UInt64, name: String, amount: UFix64, description: String, imageURL: String) {
        self.id = id
        self.name = name
        self.amount = amount
        self.description = description
        self.imageURL = imageURL
    }
}
