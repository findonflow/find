import FIND from 0x097bafa4e0b48eef

pub fun main(merchAccount: Address, name: String, addon:String, amount:UFix64) : PurchaseData {

    let address = FIND.lookupAddress(name) ?? panic("Name is not owned by anyone : ".concat(name))
    let finLeases : &FIND.LeaseCollection = getAuthAccount(address).borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath) ?? panic("Could not borrow reference to find lease collection")

    let lease = finLeases.borrow(name)

    let description = "Purchase addon ".concat(addon).concat(" for name :").concat(name).concat(" for Dapper Credit ").concat(amount.toString())
    let imageURL = "https://i.imgur.com/8W8NoO1.png"

    return PurchaseData(
            id: lease.uuid, 
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
