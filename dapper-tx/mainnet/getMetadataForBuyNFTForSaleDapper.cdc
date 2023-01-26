import FindMarket from 0x097bafa4e0b48eef
import FindMarketSale from 0x097bafa4e0b48eef


pub fun main(address: Address, marketplace:Address, id: UInt64, amount: UFix64) : PurchaseData {

    let marketOption = FindMarket.getMarketOptionFromType(Type<@FindMarketSale.SaleItemCollection>())
    let item= FindMarket.assertOperationValid(tenant: marketplace, address: address, marketOption: marketOption, id: id)
    let display = item.getDisplay()
    let itemID = item.getItemID()
    let amount = item.getBalance()


    return PurchaseData(
        id: itemID,
        name: display.name,
        amount: amount,
        description: display.description,
        imageURL: display.thumbnail.uri()
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