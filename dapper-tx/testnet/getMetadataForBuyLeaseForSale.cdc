import FindMarket from 0x35717efbbce11c74
import FIND from 0x35717efbbce11c74
import Profile from 0x35717efbbce11c74
import DapperUtilityCoin from 0x82ec283f88a62e65
import FindLeaseMarketSale from 0x35717efbbce11c74
import FindLeaseMarket from 0x35717efbbce11c74

pub fun main(sellerAccount: Address, leaseName: String, amount: UFix64) :PurchaseData{

    let address = FIND.resolve(leaseName) ?? panic("The address input is not a valid name nor address. Input : ".concat(leaseName))
    let leaseMarketplace = FindMarket.getFindTenantAddress()
    let leaseTenant = FindMarket.getTenant(leaseMarketplace)
    let storagePath = leaseTenant.getStoragePath(Type<@FindLeaseMarketSale.SaleItemCollection>())
    let saleItemRef = getAuthAccount(address).borrow<&FindLeaseMarketSale.SaleItemCollection>(from: storagePath) ?? panic("Cannot borrow reference to sale item")
    let saleItem = saleItemRef.borrow(leaseName)

    let description = "Name :".concat(leaseName).concat(" for Dapper Credit ").concat(amount.toString())
    let imageURL = "https://i.imgur.com/8W8NoO1.png"

    return PurchaseData(
            id: saleItem.getId(),
            name: leaseName,
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
