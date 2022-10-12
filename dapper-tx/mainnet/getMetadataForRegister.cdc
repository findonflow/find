import FIND from 0x097bafa4e0b48eef

pub fun main(merchAccount: Address, name: String, amount: UFix64) : PurchaseData {

    let description = "Name :".concat(name).concat(" for Dapper Credit ").concat(amount.toString())
    let imageURL = "https://ik.imagekit.io/xyvsisxky/tr:ot-".concat(name).concat(",ots-55,otc-58B792,ox-N166,oy-N24,ott-b/https://i.imgur.com/8W8NoO1.png")

    return PurchaseData(
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
