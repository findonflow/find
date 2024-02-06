import "FungibleToken"
import "FindViews"
import "Clock"
import "FIND"
import "FindLeaseMarket"
import "FindMarket"
import "Debug"

/*

A Find Market for direct sales
*/
//TODO: entitlements
access(all) contract FindLeaseMarketSale {

    access(all) entitlement Seller

    access(all) event Sale(tenant: String, id: UInt64, saleID: UInt64, seller: Address, sellerName: String?, amount: UFix64, status: String, vaultType:String, leaseInfo: FindLeaseMarket.LeaseInfo?, buyer:Address?, buyerName:String?, buyerAvatar: String?, endsAt:UFix64?)

    //A sale item for a direct sale
    access(all) resource SaleItem : FindLeaseMarket.SaleItem{

        //this is set when bought so that pay will work
        access(self) var buyer: Address?

        access(contract) let vaultType: Type //The type of vault to use for this sale Item
        access(contract) var pointer: FindLeaseMarket.AuthLeasePointer

        //this field is set if this is a saleItem
        access(contract) var salePrice: UFix64
        access(contract) var validUntil: UFix64?
        access(contract) let saleItemExtraField: {String : AnyStruct}

        init(pointer: FindLeaseMarket.AuthLeasePointer, vaultType: Type, price:UFix64, validUntil: UFix64?, saleItemExtraField: {String : AnyStruct}) {
            self.vaultType=vaultType
            self.pointer=pointer
            self.salePrice=price
            self.buyer=nil
            self.validUntil=validUntil
            self.saleItemExtraField=saleItemExtraField
        }

        access(all) fun getSaleType() : String {
            return "active_listed"
        }

        access(all) fun getListingType() : Type {
            return Type<@SaleItem>()
        }

        access(all) fun getListingTypeIdentifier(): String {
            return Type<@SaleItem>().identifier
        }

        access(all) fun setBuyer(_ address:Address) {
            self.buyer=address
        }

        access(all) fun getBuyer(): Address? {
            return self.buyer
        }

        access(all) fun getBuyerName() : String? {
            if let address = self.buyer {
                return FIND.reverseLookup(address)
            }
            return nil
        }

        access(all) fun getLeaseName() : String {
            return self.pointer.name
        }

        access(all) fun getItemType() : Type {
            return Type<@FIND.Lease>()
        }

        access(all) fun getId() : UInt64 {
            return self.pointer.getUUID()
        }

        access(all) fun getSeller() : Address {
            return self.pointer.owner()
        }

        access(all) fun getSellerName() : String? {
            let address = self.pointer.owner()
            return FIND.reverseLookup(address)
        }

        access(all) fun getBalance() : UFix64 {
            return self.salePrice
        }

        access(all) fun getAuction(): FindLeaseMarket.AuctionItem? {
            return nil
        }

        access(all) fun getFtType() : Type  {
            return self.vaultType
        }

        access(all) fun setValidUntil(_ time: UFix64?) {
            self.validUntil=time
        }

        access(all) fun getValidUntil() : UFix64? {
            return self.validUntil
        }

        access(all) fun toLeaseInfo() : FindLeaseMarket.LeaseInfo {
            return FindLeaseMarket.LeaseInfo(self.pointer)
        }

        access(all) fun checkPointer() : Bool {
            return self.pointer.valid()
        }

        access(all) fun getSaleItemExtraField() : {String : AnyStruct} {
            return self.saleItemExtraField
        }

    }

    access(all) resource interface SaleItemCollectionPublic {
        //fetch all the tokens in the collection
        access(all) fun getNameSales(): [String]
        access(all) fun containsNameSale(_ name: String): Bool
        access(all) fun borrowSaleItem(_ name: String) : &{FindLeaseMarket.SaleItem}
        access(all) fun buy(name: String, vault: @{FungibleToken.Vault}, to: Address)
    }

    access(all) resource SaleItemCollection: SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic {
        //is this the best approach now or just put the NFT inside the saleItem?
        access(contract) var items: @{String: SaleItem}

        access(contract) let tenantCapability: Capability<&{FindMarket.TenantPublic}>

        init (_ tenantCapability: Capability<&{FindMarket.TenantPublic}>) {
            self.items <- {}
            self.tenantCapability=tenantCapability
        }

        access(self) fun getTenant() : &{FindMarket.TenantPublic} {
            pre{
                self.tenantCapability.check() : "Tenant client is not linked anymore"
            }
            return self.tenantCapability.borrow()!
        }

        access(all) fun getListingType() : Type {
            return Type<@SaleItem>()
        }

        access(all) fun buy(name: String, vault: @{FungibleToken.Vault}, to: Address)  {
            pre {
                self.items.containsKey(name) : "Invalid name=".concat(name)
                self.owner!.address != to : "You cannot buy your own listing"
            }

            let saleItem=self.borrow(name)

            if saleItem.salePrice != vault.balance {
                panic("Incorrect balance sent in vault. Expected ".concat(saleItem.salePrice.toString()).concat(" got ").concat(vault.balance.toString()))
            }

            if saleItem.validUntil != nil && saleItem.validUntil! < Clock.time() {
                panic("This sale item listing is already expired")
            }

            if saleItem.vaultType != vault.getType() {
                panic("This item can be baught using ".concat(saleItem.vaultType.identifier).concat(" you have sent in ").concat(vault.getType().identifier))
            }

            let actionResult=self.getTenant().allowedAction(listingType: Type<@FindLeaseMarketSale.SaleItem>(), nftType: saleItem.getItemType(), ftType: saleItem.getFtType(), action: FindMarket.MarketAction(listing:false, name:"buy lease for sale"), seller: self.owner!.address, buyer: to)

            if !actionResult.allowed {
                panic(actionResult.message)
            }

            let cuts= self.getTenant().getCuts(name: actionResult.name, listingType: Type<@FindLeaseMarketSale.SaleItem>(), nftType: saleItem.getItemType(), ftType: saleItem.getFtType())

            let ftType=saleItem.vaultType
            let owner=saleItem.getSeller()
            let leaseInfo= saleItem.toLeaseInfo()

            let soldFor=saleItem.getBalance()
            saleItem.setBuyer(to)
            let buyer=to
            let buyerName=FIND.reverseLookup(buyer)
            let profile = FIND.lookup(buyer.toString())

            saleItem.pointer.move(to: to)

            FindLeaseMarket.pay(tenant:self.getTenant().name, leaseName:name, saleItem: saleItem, vault: <- vault, leaseInfo:leaseInfo, cuts:cuts)

            emit Sale(tenant:self.getTenant().name, id: saleItem.getId(), saleID: saleItem.uuid, seller:owner, sellerName: FIND.reverseLookup(owner), amount: soldFor, status:"sold", vaultType: ftType.identifier, leaseInfo:leaseInfo, buyer: buyer, buyerName: buyerName, buyerAvatar: profile?.getAvatar() ,endsAt:saleItem.validUntil)

            destroy <- self.items.remove(key: name)
        }

        access(Seller) fun listForSale(pointer: FindLeaseMarket.AuthLeasePointer, vaultType: Type, directSellPrice:UFix64, validUntil: UFix64?, extraField: {String:AnyStruct}) {
            Debug.log("foo")

            // ensure it is not a 0 dollar listing
            if directSellPrice <= 0.0 {
                panic("Listing price should be greater than 0")
            }

            if validUntil != nil && validUntil! < Clock.time() {
                panic("Valid until is before current time")
            }

            // What happends if we relist
            let saleItem <- create SaleItem(pointer: pointer, vaultType:vaultType, price: directSellPrice, validUntil: validUntil, saleItemExtraField:extraField)

            let actionResult=self.getTenant().allowedAction(listingType: Type<@FindLeaseMarketSale.SaleItem>(), nftType: saleItem.getItemType(), ftType: saleItem.getFtType(), action: FindMarket.MarketAction(listing:true, name:"list lease for sale"), seller: self.owner!.address, buyer: nil)

            if !actionResult.allowed {
                panic(actionResult.message)
            }

            let owner=self.owner!.address
            emit Sale(tenant: self.getTenant().name, id: saleItem.getId(), saleID: saleItem.uuid, seller:owner, sellerName: FIND.reverseLookup(owner), amount: saleItem.salePrice, status: "active_listed", vaultType: vaultType.identifier, leaseInfo:saleItem.toLeaseInfo(), buyer: nil, buyerName:nil, buyerAvatar:nil, endsAt:saleItem.validUntil)
            let old <- self.items[pointer.name] <- saleItem
            destroy old

        }

        access(Seller) fun delist(_ name: String) {
            pre {
                self.items.containsKey(name) : "Unknown name lease=".concat(name)
            }

            let saleItem <- self.items.remove(key: name)!

            if saleItem.checkPointer() {
                let actionResult=self.getTenant().allowedAction(listingType: Type<@FindLeaseMarketSale.SaleItem>(), nftType: saleItem.getItemType(), ftType: saleItem.getFtType(), action: FindMarket.MarketAction(listing:false, name:"delist lease for sale"), seller: nil, buyer: nil)

                if !actionResult.allowed {
                    panic(actionResult.message)
                }
                let owner=self.owner!.address
                emit Sale(tenant:self.getTenant().name, id: saleItem.getId(), saleID: saleItem.uuid, seller:owner, sellerName:FIND.reverseLookup(owner), amount: saleItem.salePrice, status: "cancel", vaultType: saleItem.vaultType.identifier,leaseInfo: saleItem.toLeaseInfo(), buyer:nil, buyerName:nil, buyerAvatar:nil, endsAt:saleItem.validUntil)
                destroy saleItem
                return
            }

            let owner=self.owner!.address
            if !saleItem.checkPointer() {
                emit Sale(tenant:self.getTenant().name, id: saleItem.getId(), saleID: saleItem.uuid, seller:owner, sellerName:FIND.reverseLookup(owner), amount: saleItem.salePrice, status: "cancel", vaultType: saleItem.vaultType.identifier,leaseInfo: nil, buyer:nil, buyerName:nil, buyerAvatar:nil, endsAt:saleItem.validUntil)
            } else {
                emit Sale(tenant:self.getTenant().name, id: saleItem.getId(), saleID: saleItem.uuid, seller:owner, sellerName:FIND.reverseLookup(owner), amount: saleItem.salePrice, status: "cancel", vaultType: saleItem.vaultType.identifier,leaseInfo: saleItem.toLeaseInfo(), buyer:nil, buyerName:nil, buyerAvatar:nil, endsAt:saleItem.validUntil)
            }
            destroy saleItem
        }

        access(all) fun getNameSales(): [String] {
            return self.items.keys
        }

        access(all) fun containsNameSale(_ name: String): Bool {
            return self.items.containsKey(name)
        }

        access(all) fun borrow(_ name: String): &SaleItem {
            return (&self.items[name])!
        }

        access(all) fun borrowSaleItem(_ name: String) : &{FindLeaseMarket.SaleItem} {
            pre{
                self.items.containsKey(name) : "This name sale does not exist : ".concat(name)
            }
            return (&self.items[name])!
        }

    }

    //Create an empty lease collection that store your leases to a name
    access(all) fun createEmptySaleItemCollection(_ tenantCapability: Capability<&{FindMarket.TenantPublic}>) : @SaleItemCollection {
        return <- create SaleItemCollection(tenantCapability)
    }

    access(all) fun getSaleItemCapability(marketplace:Address, user:Address) : Capability<&{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>? {
        if FindMarket.getTenantCapability(marketplace) == nil {
            panic("Invalid tenant")
        }
        if let tenant=FindMarket.getTenantCapability(marketplace)!.borrow() {
            return getAccount(user).capabilities.get<&{FindLeaseMarketSale.SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(tenant.getPublicPath(Type<@SaleItemCollection>()))!
        }
        return nil
    }


    init() {
        FindLeaseMarket.addSaleItemType(Type<@SaleItem>())
        FindLeaseMarket.addSaleItemCollectionType(Type<@SaleItemCollection>())
    }
}
