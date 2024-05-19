import "FungibleToken"
import "NonFungibleToken"
import "MetadataViews"
import "FindViews"
import "Clock"
import "FIND"
import "Profile"
import "FindMarket"

/*

A Find Market for direct sales
*/
access(all) contract FindMarketSale {

    // A seller can list, delist and relist leases for sale
    access(all) entitlement Seller

    access(all) event Sale(tenant: String, id: UInt64, saleID: UInt64, seller: Address, sellerName: String?, amount: UFix64, status: String, vaultType:String, nft: FindMarket.NFTInfo?, buyer:Address?, buyerName:String?, buyerAvatar: String?, endsAt:UFix64?)

    //A sale item for a direct sale
    access(all) resource SaleItem : FindMarket.SaleItem{

        //this is set when bought so that pay will work
        access(self) var buyer: Address?

        access(contract) let vaultType: Type //The type of vault to use for this sale Item
        access(contract) var pointer: FindViews.AuthNFTPointer

        //this field is set if this is a saleItem
        access(contract) var salePrice: UFix64
        access(contract) var validUntil: UFix64?
        access(contract) let saleItemExtraField: {String : AnyStruct}

        access(contract) let totalRoyalties: UFix64
        init(pointer: FindViews.AuthNFTPointer, vaultType: Type, price:UFix64, validUntil: UFix64?, saleItemExtraField: {String : AnyStruct}) {
            self.vaultType=vaultType
            self.pointer=pointer
            self.salePrice=price
            self.buyer=nil
            self.validUntil=validUntil
            self.saleItemExtraField=saleItemExtraField
            var royalties : UFix64 = 0.0
            self.totalRoyalties=self.pointer.getTotalRoyaltiesCut()
        }

        access(all) fun getPointer() : FindViews.AuthNFTPointer {
            return self.pointer
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

        access(account) fun setBuyer(_ address:Address) {
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

        access(all) fun getId() : UInt64{
            return self.pointer.getUUID()
        }

        access(all) fun getItemID() : UInt64 {
            return self.pointer.id
        }

        access(all) fun getItemType() : Type {
            return self.pointer.getItemType()
        }

        access(all) fun getRoyalty() : MetadataViews.Royalties {
            return self.pointer.getRoyalty()
        }

        access(all) fun getSeller() : Address {
            return self.pointer.owner()
        }

        access(all) fun getSellerName() : String? {
            return FIND.reverseLookup(self.pointer.owner())
        }

        access(all) fun getBalance() : UFix64 {
            return self.salePrice
        }

        access(all) fun getAuction(): FindMarket.AuctionItem? {
            return nil
        }

        access(all) fun getFtType() : Type  {
            return self.vaultType
        }

        access(contract) fun setValidUntil(_ time: UFix64?) {
            self.validUntil=time
        }

        access(all) fun getValidUntil() : UFix64? {
            return self.validUntil
        }

        access(all) fun toNFTInfo(_ detail: Bool) : FindMarket.NFTInfo{
            return FindMarket.NFTInfo(self.pointer.getViewResolver(), id: self.pointer.id, detail:detail)
        }

        access(all) fun checkPointer() : Bool {
            return self.pointer.valid()
        }

        access(all) fun checkSoulBound() : Bool {
            return self.pointer.checkSoulBound()
        }

        access(all) fun getSaleItemExtraField() : {String : AnyStruct} {
            return self.saleItemExtraField
        }

        access(all) fun getTotalRoyalties() : UFix64 {
            return self.totalRoyalties
        }

        access(all) fun validateRoyalties() : Bool {
            return self.totalRoyalties == self.pointer.getTotalRoyaltiesCut()
        }

        access(all) fun getDisplay() : MetadataViews.Display {
            return self.pointer.getDisplay()
        }

        access(all) fun getNFTCollectionData() : MetadataViews.NFTCollectionData {
            return self.pointer.getNFTCollectionData()
        }
    }

    access(all) resource interface SaleItemCollectionPublic {
        //fetch all the tokens in the collection
        access(all) fun getIds(): [UInt64]
        access(all) fun borrowSaleItem(_ id: UInt64) : &{FindMarket.SaleItem}?
        access(all) fun containsId(_ id: UInt64): Bool
        access(all) fun buy(id: UInt64, vault: @{FungibleToken.Vault}, nftCap: Capability<&{NonFungibleToken.Receiver}>)
    }

    access(all) resource SaleItemCollection: SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic {
        //is this the best approach now or just put the NFT inside the saleItem?
        access(contract) var items: @{UInt64: SaleItem}

        //Not sure if this should be the interface or the impl
        access(contract) let tenantCapability: Capability<&FindMarket.Tenant>

        init (_ tenantCapability: Capability<&FindMarket.Tenant>) {
            self.items <- {}
            self.tenantCapability=tenantCapability
        }

        access(self) fun getTenant() : &FindMarket.Tenant {
            if !self.tenantCapability.check() {
                panic("Tenant client is not linked anymore")
            }
            return self.tenantCapability.borrow()!
        }

        access(all) fun getListingType() : Type {
            return Type<@SaleItem>()
        }

        access(all) fun buy(id: UInt64, vault: @{FungibleToken.Vault}, nftCap: Capability<&{NonFungibleToken.Receiver}>) {
            if !self.items.containsKey(id) {
                panic("Invalid id=".concat(id.toString()))
            }

            if self.owner!.address == nftCap.address {
                panic("You cannot buy your own listing")
            }

            let saleItem=self.borrow(id)

            if saleItem.salePrice != vault.balance {
                panic("Incorrect balance sent in vault. Expected ".concat(saleItem.salePrice.toString()).concat(" got ").concat(vault.balance.toString()))
            }

            if saleItem.validUntil != nil && saleItem.validUntil! < Clock.time() {
                panic("This sale item listing is already expired")
            }

            if saleItem.vaultType != vault.getType() {
                panic("This item can be bought using ".concat(saleItem.vaultType.identifier).concat(" you have sent in ").concat(vault.getType().identifier))
            }
            let tenant=self.getTenant()
            let ftType=saleItem.vaultType
            let nftType=saleItem.getItemType()

            //TOOD: method on saleItems that returns a cacheKey listingType-nftType-ftType
            let actionResult=tenant.allowedAction(listingType: Type<@FindMarketSale.SaleItem>(), nftType: nftType, ftType: ftType, action: FindMarket.MarketAction(listing:false, name: "buy item for sale"), seller: self.owner!.address, buyer: nftCap.address)

            if !actionResult.allowed {
                panic(actionResult.message)
            }

            let cuts= tenant.getCuts(name: actionResult.name, listingType: Type<@FindMarketSale.SaleItem>(), nftType: nftType, ftType: ftType)

            let nftInfo= saleItem.toNFTInfo(true)
            saleItem.setBuyer(nftCap.address)
            let buyer=nftCap.address
            let buyerName=FIND.reverseLookup(buyer)
            let sellerName=FIND.reverseLookup(self.owner!.address)

            emit Sale(tenant:tenant.name, id: id, saleID: saleItem.uuid, seller:self.owner!.address, sellerName: FIND.reverseLookup(self.owner!.address), amount: saleItem.getBalance(), status:"sold", vaultType: ftType.identifier, nft:nftInfo, buyer: buyer, buyerName: buyerName, buyerAvatar: Profile.find(nftCap.address).getAvatar() ,endsAt:saleItem.validUntil)
            let resolved : {Address : String} = {}

            resolved[buyer] = buyerName ?? ""
            resolved[self.owner!.address] = sellerName ?? ""
            resolved[FindMarketSale.account.address] = "find"
            // Have to make sure the tenant always have the valid find name
            resolved[FindMarket.tenantNameAddress[tenant.name]!] = tenant.name

            FindMarket.pay(tenant:tenant.name, id:id, saleItem: saleItem, vault: <- vault, royalty:saleItem.getRoyalty(), nftInfo:nftInfo, cuts:cuts, resolver: fun(address:Address): String? { return FIND.reverseLookup(address) }, resolvedAddress: resolved)


            if !nftCap.check() {
                let cp =getAccount(nftCap.address).capabilities.borrow<&{NonFungibleToken.Collection}>(saleItem.getNFTCollectionData().publicPath)
                if cp == nil {
                    panic("The nft receiver capability passed in is invalid.")
                } else {
                    cp!.deposit(token: <- saleItem.pointer.withdraw())
                }
            } else {
                nftCap.borrow()!.deposit(token: <- saleItem.pointer.withdraw())
            }

            destroy <- self.items.remove(key: id)
        }

        access(Seller) fun listForSale(pointer: FindViews.AuthNFTPointer, vaultType: Type, directSellPrice:UFix64, validUntil: UFix64?, extraField: {String:AnyStruct}) {


            // ensure it is not a 0 dollar listing
            if directSellPrice <= 0.0 {
                panic("Listing price should be greater than 0")
            }

            if validUntil != nil && validUntil! < Clock.time() {
                panic("Valid until is before current time")
            }

            // check soul bound
            if pointer.checkSoulBound() {
                panic("This item is soul bounded and cannot be traded")
            }

            // What happends if we relist
            let saleItem <- create SaleItem(pointer: pointer, vaultType:vaultType, price: directSellPrice, validUntil: validUntil, saleItemExtraField:extraField)

            let tenant=self.getTenant()

            // Check if it is onefootball. If so, listing has to be at least $0.65 (DUC)
            if tenant.name == "onefootball" {
                // ensure it is not a 0 dollar listing
                if directSellPrice <= 0.65 {
                    panic("Listing price should be greater than 0.65")
                }
            }

            let nftType=saleItem.getItemType()
            let ftType=saleItem.getFtType()

            let actionResult=tenant.allowedAction(listingType: Type<@FindMarketSale.SaleItem>(), nftType: nftType, ftType: ftType, action: FindMarket.MarketAction(listing:true, name: "list item for sale"), seller: self.owner!.address, buyer: nil)

            if !actionResult.allowed {
                panic(actionResult.message)
                // let message = "vault : ".concat(vaultType.identifier).concat(" . NFT Type : ".concat(saleItem.getItemType().identifier))
                // panic(message)
            }

            let owner=self.owner!.address
            emit Sale(tenant: tenant.name, id: pointer.getUUID(), saleID: saleItem.uuid, seller:owner, sellerName: FIND.reverseLookup(owner), amount: saleItem.salePrice, status: "active_listed", vaultType: vaultType.identifier, nft:saleItem.toNFTInfo(true), buyer: nil, buyerName:nil, buyerAvatar:nil, endsAt:saleItem.validUntil)
            let old <- self.items[pointer.getUUID()] <- saleItem
            destroy old

        }

        access(Seller) fun delist(_ id: UInt64) {
            if !self.items.containsKey(id) {
                panic("Unknown item with id=".concat(id.toString()))
            }

            let saleItem <- self.items.remove(key: id)!

            let tenant=self.getTenant()

            var status = "cancel"
            var nftInfo:FindMarket.NFTInfo?=nil
            if saleItem.checkPointer() {
                nftInfo=saleItem.toNFTInfo(false)
            }

            let owner=self.owner!.address
            emit Sale(tenant:tenant.name, id: id, saleID: saleItem.uuid, seller:owner, sellerName:FIND.reverseLookup(owner), amount: saleItem.salePrice, status: status, vaultType: saleItem.vaultType.identifier,nft: nftInfo, buyer:nil, buyerName:nil, buyerAvatar:nil, endsAt:saleItem.validUntil)
            destroy saleItem
        }

        access(Seller) fun relist(_ id: UInt64) {
            let saleItem = self.borrow(id)

            let pointer = saleItem.getPointer()
            let vaultType= saleItem.vaultType
            let directSellPrice=saleItem.salePrice
            var validUntil= saleItem.validUntil
            if validUntil != nil && saleItem.validUntil! <= Clock.time() {
                validUntil = nil
            }
            let extraField= saleItem.getSaleItemExtraField()

            self.delist(id)
            self.listForSale(pointer: pointer, vaultType: vaultType, directSellPrice:directSellPrice, validUntil: validUntil, extraField: extraField)
        }

        access(all) fun getIds(): [UInt64] {
            return self.items.keys
        }

        access(all) fun getRoyaltyChangedIds(): [UInt64] {
            let ids : [UInt64] = []
            for id in self.getIds() {
                let item = self.borrow(id)
                if !item.validateRoyalties() {
                    ids.append(id)
                }
            }
            return ids
        }

        access(all) fun containsId(_ id: UInt64): Bool {
            return self.items.containsKey(id)
        }

        access(all) fun borrow(_ id: UInt64): &SaleItem {
            return (&self.items[id])!
        }

        access(all) fun borrowSaleItem(_ id: UInt64) : &{FindMarket.SaleItem}? {
            if !self.items.containsKey(id) {
                panic("This id does not exist : ".concat(id.toString()))
            }
            return &self.items[id]
        }
    }

    //Create an empty lease collection that store your leases to a name
    access(all) fun createEmptySaleItemCollection(_ tenantCapability: Capability<&FindMarket.Tenant>) : @SaleItemCollection {
        return <- create SaleItemCollection(tenantCapability)
    }

    access(all) fun getSaleItemCapability(marketplace:Address, user:Address) : Capability<&{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>? {
        if let  tenantCap=FindMarket.getTenantCapability(marketplace) {
            let tenant=tenantCap.borrow() ?? panic("Invalid tenant")
            return getAccount(user).capabilities.get<&{FindMarketSale.SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(tenant.getPublicPath(Type<@SaleItemCollection>()))
        }
        return nil
    }


    init() {
        FindMarket.addSaleItemType(Type<@SaleItem>())
        FindMarket.addSaleItemCollectionType(Type<@SaleItemCollection>())
    }
}
