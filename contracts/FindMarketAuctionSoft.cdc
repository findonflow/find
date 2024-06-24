import "FungibleToken"
import "NonFungibleToken"
import "MetadataViews"
import "FindViews"
import "Clock"
import "FIND"
import "FindMarket"
import "Profile"

// An auction saleItem contract that escrows the FT, does _not_ escrow the NFT
access(all) contract FindMarketAuctionSoft {

    // A seller can list,delist and relist leases for auction
    access(all) entitlement Seller

    access(all) event EnglishAuction(tenant: String, id: UInt64, saleID: UInt64, seller: Address, sellerName:String?, amount: UFix64, auctionReservePrice: UFix64, status: String, vaultType:String, nft:FindMarket.NFTInfo?, buyer:Address?, buyerName:String?, buyerAvatar:String?, endsAt: UFix64?, previousBuyer:Address?, previousBuyerName:String?)

    access(all) resource SaleItem : FindMarket.SaleItem {
        access(contract) var pointer: FindViews.AuthNFTPointer
        access(contract) var vaultType: Type
        access(contract) var auctionStartPrice: UFix64
        access(contract) var auctionReservePrice: UFix64
        access(contract) var auctionDuration: UFix64
        access(contract) var auctionMinBidIncrement: UFix64
        access(contract) var auctionExtensionOnLateBid: UFix64
        access(contract) var auctionStartedAt: UFix64?
        access(contract) var auctionValidUntil: UFix64?
        access(contract) var auctionEndsAt: UFix64?
        access(contract) var offerCallback: Capability<&MarketBidCollection>?
        access(contract) var saleItemExtraField: {String : AnyStruct}
        access(contract) let totalRoyalties: UFix64

        init(pointer: FindViews.AuthNFTPointer, vaultType: Type, auctionStartPrice:UFix64, auctionReservePrice:UFix64, auctionValidUntil: UFix64?, saleItemExtraField: {String : AnyStruct}) {
            self.vaultType=vaultType
            self.pointer=pointer
            self.auctionStartPrice=auctionStartPrice
            self.auctionReservePrice=auctionReservePrice
            self.auctionDuration=86400.0
            self.auctionExtensionOnLateBid=300.0
            self.auctionMinBidIncrement=10.0
            self.offerCallback=nil
            self.auctionStartedAt=nil
            self.auctionValidUntil=auctionValidUntil
            self.auctionEndsAt=nil
            self.saleItemExtraField=saleItemExtraField
            self.totalRoyalties=self.pointer.getTotalRoyaltiesCut()
        }

        access(all) fun getId() : UInt64{
            return self.pointer.getUUID()
        }

        access(all) fun getPointer() : FindViews.AuthNFTPointer {
            return self.pointer
        }

        //Here we do not get a vault back, it is sent in to the method itself
        access(contract) fun acceptNonEscrowedBid() {
            if self.offerCallback == nil  {
                panic("There is no bid offer to the item.")
            }
            if !self.offerCallback!.check()  {
                panic("Bidder unlinked bid collection capability.")
            }
            self.offerCallback!.borrow()!.accept(<- self.pointer.withdraw())
        }

        access(all) fun getRoyalty() : MetadataViews.Royalties {
            return self.pointer.getRoyalty()
        }

        access(all) fun getBalance() : UFix64 {
            if let cb= self.offerCallback {
                return cb.borrow()?.getBalance(self.getId()) ?? panic("Bidder unlinked bid collection capability. bidder address : ".concat(cb.address.toString()))
            }
            return self.auctionStartPrice
        }

        access(all) fun getSeller() : Address {
            return self.pointer.owner()
        }

        access(all) fun getSellerName() : String? {
            let address = self.pointer.owner()
            return FIND.reverseLookup(address)
        }

        access(all) fun getBuyer() : Address? {
            if let cb= self.offerCallback {
                return cb.address
            }
            return nil
        }

        access(all) fun getBuyerName() : String? {
            if let cb= self.offerCallback {
                return FIND.reverseLookup(cb.address)
            }
            return nil
        }

        access(all) fun toNFTInfo(_ detail: Bool) : FindMarket.NFTInfo{
            return FindMarket.NFTInfo(self.pointer.getViewResolver(), id: self.pointer.id, detail:detail)
        }

        access(contract) fun setAuctionStarted(_ startedAt: UFix64) {
            self.auctionStartedAt=startedAt
        }

        access(contract) fun setAuctionEnds(_ endsAt: UFix64){
            self.auctionEndsAt=endsAt
        }

        access(all) fun hasAuctionStarted() : Bool {
            if let starts = self.auctionStartedAt {
                return starts <= Clock.time()
            }
            return false
        }

        access(all) fun hasAuctionEnded() : Bool {
            if let ends = self.auctionEndsAt {
                return ends < Clock.time()
            }
            panic("Not a live auction")
        }

        access(all) fun hasAuctionMetReservePrice() : Bool {

            let balance=self.getBalance()

            if self.auctionReservePrice== nil {
                return false
            }


            return balance >= self.auctionReservePrice
        }

        access(contract) fun setExtentionOnLateBid(_ time: UFix64) {
            self.auctionExtensionOnLateBid=time
        }

        access(contract) fun setAuctionDuration(_ duration: UFix64) {
            self.auctionDuration=duration
        }

        access(contract) fun setReservePrice(_ price: UFix64) {
            self.auctionReservePrice=price
        }

        access(contract) fun setMinBidIncrement(_ price: UFix64) {
            self.auctionMinBidIncrement=price
        }

        access(contract) fun setStartAuctionPrice(_ price: UFix64) {
            self.auctionStartPrice=price
        }

        access(contract) fun setCallback(_ callback: Capability<&MarketBidCollection>?) {
            self.offerCallback=callback
        }

        access(all) fun getSaleType(): String {
            if self.auctionStartedAt != nil {
                if self.hasAuctionEnded() {
                    if self.hasAuctionMetReservePrice() {
                        return "finished_completed"
                    }
                    return "finished_failed"
                }
                return "active_ongoing"
            }
            return "active_listed"
        }

        access(all) fun getListingType() : Type {
            return Type<@SaleItem>()
        }

        access(all) fun getListingTypeIdentifier() : String {
            return Type<@SaleItem>().identifier
        }

        access(all) fun getItemID() : UInt64 {
            return self.pointer.id
        }

        access(all) fun getItemType() : Type {
            return self.pointer.getItemType()
        }

        access(all) fun getAuction(): FindMarket.AuctionItem? {
            return FindMarket.AuctionItem(startPrice: self.auctionStartPrice,
            currentPrice: self.getBalance(),
            minimumBidIncrement: self.auctionMinBidIncrement ,
            reservePrice: self.auctionReservePrice,
            extentionOnLateBid: self.auctionExtensionOnLateBid ,
            auctionEndsAt: self.auctionEndsAt ,
            timestamp: Clock.time())
        }

        access(all) fun getFtType() : Type {
            return self.vaultType
        }

        access(Seller) fun setValidUntil(_ time: UFix64?) {
            self.auctionValidUntil=time
        }

        access(all) fun getValidUntil() : UFix64? {
            if self.hasAuctionStarted() {
                return self.auctionEndsAt
            }
            return self.auctionValidUntil
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
        access(all) fun containsId(_ id: UInt64): Bool
        access(contract) fun registerIncreasedBid(_ id: UInt64, oldBalance: UFix64)

        //place a bid on a token
        access(contract) fun registerBid(item: FindViews.ViewReadPointer, callback: Capability<&MarketBidCollection>, vaultType:Type)

        //only buyer can fulfill auctions since he needs to send funds for this type
        access(contract) fun fulfillAuction(id: UInt64, vault: @{FungibleToken.Vault})
    }

    access(all) resource SaleItemCollection: SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic  {
        //is this the best approach now or just put the NFT inside the saleItem?
        access(contract) var items: @{UInt64: SaleItem}

        access(contract) let tenantCapability: Capability<&FindMarket.Tenant>

        init (_ tenantCapability: Capability<&FindMarket.Tenant>) {
            self.items <- {}
            self.tenantCapability=tenantCapability
        }

        access(self) fun getTenant() : &FindMarket.Tenant {
            if !self.tenantCapability.check()  {
                panic("Tenant client is not linked anymore")
            }
            return self.tenantCapability.borrow()!
        }

        access(all) fun getListingType() : Type {
            return Type<@SaleItem>()
        }

        access(self) fun addBid(id:UInt64, newOffer: Capability<&MarketBidCollection>, oldBalance: UFix64) {
            let saleItem=self.borrowAuth(id)

            let ftType=saleItem.getFtType()
            let nftType=saleItem.getItemType()
            let buyer=newOffer.address

            let tenant = self.getTenant()
            let actionResult=tenant.allowedAction(listingType: Type<@FindMarketAuctionSoft.SaleItem>(), nftType: nftType , ftType: ftType, action: FindMarket.MarketAction(listing:false, name: "add bit in soft-auction"), seller: self.owner!.address ,buyer: buyer)

            if !actionResult.allowed {
                panic(actionResult.message)
            }

            let timestamp=Clock.time()
            let newOfferBalance=newOffer.borrow()?.getBalance(id) ?? panic("The new offer bid capability is invalid.")

            let previousOffer = saleItem.offerCallback!


            var minBid=oldBalance + saleItem.auctionMinBidIncrement
            if newOffer.address != previousOffer.address {
                let previousBalance = previousOffer.borrow()?.getBalance(id) ?? panic("Previous bidder unlinked the bid ccollection capability. bidder address : ".concat(previousOffer.address.toString()))
                minBid = previousBalance + saleItem.auctionMinBidIncrement
            }

            if newOfferBalance < minBid {
                panic("bid ".concat(newOfferBalance.toString()).concat(" must be larger then previous bid+bidIncrement ").concat(minBid.toString()))
            }

            var previousBuyer:Address?=nil
            if newOffer.address != previousOffer.address {
                previousOffer.borrow()!.cancelBidFromSaleItem(id)
                previousBuyer=previousOffer.address
            }

            saleItem.setCallback(newOffer)

            let suggestedEndTime=timestamp+saleItem.auctionExtensionOnLateBid

            if suggestedEndTime > saleItem.auctionEndsAt! {
                saleItem.setAuctionEnds(suggestedEndTime)
            }

            let status = "active_ongoing"
            let seller=self.owner!.address

            let nftInfo=saleItem.toNFTInfo(true)

            var previousBuyerName : String?=nil
            if let pb= previousBuyer {
                previousBuyerName = FIND.reverseLookup(pb)
            }

            let buyerName=FIND.reverseLookup(buyer)
            let profile = Profile.find(buyer)
            emit EnglishAuction(tenant:tenant.name, id: id, saleID: saleItem.uuid, seller:seller, sellerName: FIND.reverseLookup(seller), amount: newOfferBalance, auctionReservePrice: saleItem.auctionReservePrice,  status: status, vaultType:saleItem.vaultType.identifier, nft: nftInfo,  buyer: buyer, buyerName: buyerName, buyerAvatar: profile.getAvatar(), endsAt: saleItem.auctionEndsAt, previousBuyer:previousBuyer, previousBuyerName:previousBuyerName)

        }

        access(contract) fun registerIncreasedBid(_ id: UInt64, oldBalance:UFix64) {
            if !self.items.containsKey(id) {
                panic( "Invalid id=".concat(id.toString()))
            }

            let saleItem=self.borrow(id)

            if !saleItem.hasAuctionStarted()  {
                panic("Auction is not started")
            }

            if saleItem.hasAuctionEnded() {
                panic("Auction has ended")
            }

            self.addBid(id: id, newOffer: saleItem.offerCallback!, oldBalance: oldBalance)

        }

        //This is a function that buyer will call (via his bid collection) to register the bicCallback with the seller
        access(contract) fun registerBid(item: FindViews.ViewReadPointer, callback: Capability<&MarketBidCollection>, vaultType: Type) {

            let timestamp=Clock.time()

            let id = item.getUUID()

            let saleItem=self.borrowAuth(id)
            if saleItem.hasAuctionStarted() {
                if saleItem.hasAuctionEnded() {
                    panic("Auction has ended")
                }

                if let cb = saleItem.offerCallback {
                    if cb.address == callback.address {
                        panic("You already have the latest bid on this item, use the incraseBid transaction")
                    }
                }

                self.addBid(id: id, newOffer: callback, oldBalance: 0.0)
                return
            }

            let ftType=saleItem.getFtType()
            let nftType=saleItem.getItemType()

            let tenant = self.getTenant()
            let actionResult=tenant.allowedAction(listingType: Type<@FindMarketAuctionSoft.SaleItem>(), nftType: nftType, ftType: ftType, action: FindMarket.MarketAction(listing:false, name: "bid item in soft-auction"), seller: self.owner!.address, buyer: callback.address)

            if !actionResult.allowed {
                panic(actionResult.message)
            }

            let balance=callback.borrow()?.getBalance(id) ?? panic("Bidder unlinked the bid collection capability. bidder address : ".concat(callback.address.toString()))

            if saleItem.auctionStartPrice >  balance {
                panic("You need to bid more then the starting price of ".concat(saleItem.auctionStartPrice.toString()))
            }

            if let valid = saleItem.getValidUntil() {
                if valid < Clock.time() {
                    panic("This auction listing is already expired")
                }
            }

            saleItem.setCallback(callback)
            let duration=saleItem.auctionDuration
            let endsAt=timestamp + duration
            saleItem.setAuctionStarted(timestamp)
            saleItem.setAuctionEnds(endsAt)

            let status= "active_ongoing"

            let nftInfo=saleItem.toNFTInfo(true)

            let buyerName=FIND.reverseLookup(callback.address)
            let profile = Profile.find(callback.address)
            emit EnglishAuction(tenant:tenant.name, id: id, saleID: saleItem.uuid, seller:self.owner!.address, sellerName: FIND.reverseLookup(self.owner!.address), amount: balance, auctionReservePrice: saleItem.auctionReservePrice,  status: status, vaultType:saleItem.vaultType.identifier, nft: nftInfo,  buyer: callback.address, buyerName: buyerName, buyerAvatar: profile.getAvatar(), endsAt: saleItem.auctionEndsAt, previousBuyer:nil, previousBuyerName:nil)

        }

        access(Seller) fun cancel(_ id: UInt64) {

            if !self.items.containsKey(id) {
                panic("Invalid id=".concat(id.toString()))
            }

            let saleItem=self.borrowAuth(id)

            var status="cancel"
            if saleItem.checkPointer() {
                if !saleItem.validateRoyalties() {
                    // this has to be here otherwise people cannot delist
                    status="cancel_royalties_changed"
                } else if saleItem.hasAuctionStarted() && saleItem.hasAuctionEnded() {
                    if saleItem.hasAuctionMetReservePrice() {
                        panic("Cannot cancel finished auction, fulfill it instead")
                    }
                    status="cancel_reserved_not_met"

                }
            } else {
                status="cancel_ghostlisting"
            }
            let ftType=saleItem.getFtType()
            let tenant=self.getTenant()

            let balance=saleItem.getBalance()
            let seller=self.owner!.address
            let buyer=saleItem.getBuyer()

            var nftInfo:FindMarket.NFTInfo?=nil
            if saleItem.checkPointer() {
                nftInfo=saleItem.toNFTInfo(false)
            }

            if buyer != nil {
                let buyerName=FIND.reverseLookup(buyer!)
                let profile = Profile.find(buyer!)
                emit EnglishAuction(tenant:tenant.name, id: id, saleID: saleItem.uuid, seller:seller, sellerName: FIND.reverseLookup(seller), amount: balance, auctionReservePrice: saleItem.auctionReservePrice,  status: status, vaultType:ftType.identifier, nft: nftInfo,  buyer: buyer, buyerName: buyerName, buyerAvatar: profile.getAvatar(), endsAt: saleItem.auctionEndsAt, previousBuyer:nil, previousBuyerName:nil)
            } else {
                emit EnglishAuction(tenant:tenant.name, id: id, saleID: saleItem.uuid, seller:seller, sellerName: FIND.reverseLookup(seller), amount: balance, auctionReservePrice: saleItem.auctionReservePrice,  status: status, vaultType:ftType.identifier, nft: nftInfo,  buyer: nil, buyerName: nil, buyerAvatar: nil, endsAt: saleItem.auctionEndsAt, previousBuyer:nil, previousBuyerName:nil)
            }

            if saleItem.offerCallback != nil && saleItem.offerCallback!.check() {
                saleItem.offerCallback!.borrow()!.cancelBidFromSaleItem(id)
            }

            destroy <- self.items.remove(key: id)
        }

        access(Seller) fun relist(_ id: UInt64) {
            let saleItem = self.borrowAuth(id)
            let pointer= saleItem.getPointer()
            let vaultType= saleItem.vaultType
            let auctionStartPrice= saleItem.auctionStartPrice
            let auctionReservePrice= saleItem.auctionReservePrice
            let auctionDuration = saleItem.auctionDuration
            let auctionExtensionOnLateBid = saleItem.auctionExtensionOnLateBid
            let minimumBidIncrement = saleItem.auctionMinBidIncrement
            var auctionValidUntil= saleItem.auctionValidUntil
            if auctionValidUntil != nil && saleItem.auctionValidUntil! <= Clock.time() {
                auctionValidUntil = nil
            }
            let saleItemExtraField= saleItem.getSaleItemExtraField()

            self.cancel(id)
            self.listForAuction(pointer: pointer, vaultType: vaultType, auctionStartPrice: auctionStartPrice, auctionReservePrice: auctionReservePrice, auctionDuration: auctionDuration, auctionExtensionOnLateBid: auctionExtensionOnLateBid, minimumBidIncrement: minimumBidIncrement, auctionValidUntil: auctionValidUntil, saleItemExtraField: saleItemExtraField)

        }

        access(contract) fun fulfillAuction(id: UInt64, vault: @{FungibleToken.Vault}) {
            if !self.items.containsKey(id) {
                panic("Invalid id=".concat(id.toString()))
            }

            let saleItem = self.borrowAuth(id)

            if !saleItem.hasAuctionStarted() {
                panic("This auction is not live")
            }

            if !saleItem.hasAuctionEnded() {
                panic("Auction has not ended yet")
            }

            if vault.getType() != saleItem.vaultType {
                panic("The FT vault sent in to fulfill does not match the required type. Required Type : ".concat(saleItem.vaultType.identifier).concat(" . Sent-in vault type : ".concat(vault.getType().identifier)))
            }

            if vault.balance < saleItem.auctionReservePrice {
                panic("cannot fulfill auction reserve price was not met, cancel it without a vault ".concat(vault.balance.toString()).concat(" < ").concat(saleItem.auctionReservePrice.toString()))
            }

            let ftType=saleItem.getFtType()
            let nftType=saleItem.getItemType()
            let tenant = self.getTenant()
            let actionResult=tenant.allowedAction(listingType: Type<@FindMarketAuctionSoft.SaleItem>(), nftType: nftType, ftType: ftType, action: FindMarket.MarketAction(listing:false, name:"buy item for soft-auction"), seller: self.owner!.address,buyer: saleItem.offerCallback!.address)

            if !actionResult.allowed {
                panic(actionResult.message)
            }

            let cuts= tenant.getCuts(name: actionResult.name, listingType: Type<@FindMarketAuctionSoft.SaleItem>(), nftType: nftType, ftType: ftType)

            let nftInfo=saleItem.toNFTInfo(true)
            let royalty=saleItem.getRoyalty()

            let balance=saleItem.getBalance()
            let seller=self.owner!.address
            let buyer=saleItem.getBuyer() ?? panic("Buyer is not set.")

            let previousBuyer : Address?=nil
            var previousBuyerName : String?=nil

            let status="sold"
            let buyerName=FIND.reverseLookup(buyer)
            let sellerName=FIND.reverseLookup(seller)
            let profile = Profile.find(buyer)
            emit EnglishAuction(tenant:tenant.name, id: id, saleID: saleItem.uuid, seller:seller, sellerName: FIND.reverseLookup(seller), amount: balance, auctionReservePrice: saleItem.auctionReservePrice,  status: status, vaultType:saleItem.vaultType.identifier, nft: nftInfo,  buyer: buyer, buyerName: buyerName, buyerAvatar: profile.getAvatar(), endsAt: saleItem.auctionEndsAt, previousBuyer:previousBuyer, previousBuyerName:previousBuyerName)

            saleItem.acceptNonEscrowedBid()

            let resolved : {Address : String} = {}
            resolved[buyer] = buyerName ?? ""
            resolved[seller] = sellerName ?? ""
            resolved[FindMarketAuctionSoft.account.address] =  "find"
            // Have to make sure the tenant always have the valid find name
            resolved[FindMarket.tenantNameAddress[tenant.name]!] =  tenant.name


            FindMarket.pay(tenant:tenant.name, id:id, saleItem: saleItem, vault: <- vault, royalty:royalty, nftInfo:nftInfo, cuts:cuts, resolver: FIND.reverseLookupFN(), resolvedAddress: resolved)

            destroy <- self.items.remove(key: id)

        }


        access(Seller) fun listForAuction(pointer: FindViews.AuthNFTPointer, vaultType: Type, auctionStartPrice: UFix64, auctionReservePrice: UFix64, auctionDuration: UFix64, auctionExtensionOnLateBid: UFix64, minimumBidIncrement: UFix64, auctionValidUntil: UFix64?, saleItemExtraField: {String : AnyStruct}) {
            // ensure it is not a 0 dollar listing
            if auctionStartPrice <= 0.0 {
                panic("Auction start price should be greater than 0")
            }

            // ensure it is not a 0 dollar listing
            if auctionReservePrice < auctionStartPrice {
                panic("Auction reserve price should be greater than Auction start price")
            }

            // ensure validUntil is valid
            if auctionValidUntil != nil && auctionValidUntil! < Clock.time() {
                panic("Valid until is before current time")
            }

            // check soul bound
            if pointer.checkSoulBound() {
                panic("This item is soul bounded and cannot be traded")
            }

            let saleItem <- create SaleItem(pointer: pointer, vaultType:vaultType, auctionStartPrice: auctionStartPrice, auctionReservePrice:auctionReservePrice, auctionValidUntil: auctionValidUntil, saleItemExtraField: saleItemExtraField)

            let tenant = self.getTenant()

            // Check if it is onefootball. If so, listing has to be at least $0.65 (DUC)
            if tenant.name == "onefootball" {
                // ensure it is not a 0 dollar listing
                if auctionStartPrice <= 0.65 {
                    panic("Auction start price should be greater than 0.65")
                }
            }

            let actionResult=tenant.allowedAction(listingType: Type<@FindMarketAuctionSoft.SaleItem>(), nftType: pointer.getItemType(), ftType: vaultType, action: FindMarket.MarketAction(listing:true, name:"list item for soft-auction"), seller: self.owner!.address, buyer: nil)

            if !actionResult.allowed {
                panic(actionResult.message)
            }

            let id = pointer.getUUID()

            if self.items[id] != nil {
                panic("Auction listing for this item is already created.")
            }

            saleItem.setAuctionDuration(auctionDuration)
            saleItem.setExtentionOnLateBid(auctionExtensionOnLateBid)
            saleItem.setMinBidIncrement(minimumBidIncrement)
            self.items[id] <-! saleItem
            let saleItemRef = self.borrow(id)

            let nftInfo=saleItemRef.toNFTInfo(true)

            emit EnglishAuction(tenant:tenant.name, id: id, saleID: saleItemRef.uuid, seller:self.owner!.address, sellerName: FIND.reverseLookup(self.owner!.address), amount: auctionStartPrice, auctionReservePrice: saleItemRef.auctionReservePrice,  status: "active_listed", vaultType:vaultType.identifier, nft: nftInfo,  buyer: nil, buyerName: nil, buyerAvatar: nil, endsAt: saleItemRef.auctionEndsAt, previousBuyer:nil, previousBuyerName:nil)

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
            if !self.items.containsKey(id)  {
                panic( "This id does not exist.".concat(id.toString()))
            }
            return (&self.items[id])!
        }

        access(Seller) fun borrowAuth(_ id: UInt64): auth(Seller) &SaleItem {
            if !self.items.containsKey(id)  {
                panic( "This id does not exist.".concat(id.toString()))
            }
            return (&self.items[id])!
        }

        access(all) fun borrowSaleItem(_ id: UInt64) : &{FindMarket.SaleItem} {
            if !self.items.containsKey(id)  {
                panic( "This id does not exist.".concat(id.toString()))
            }
            return (&self.items[id])!
        }
    }

    access(all) resource Bid : FindMarket.Bid {
        access(contract) let from: Capability<&SaleItemCollection>
        access(contract) let nftCap: Capability<&{NonFungibleToken.Receiver}>
        access(contract) let itemUUID: UInt64

        access(contract) let vaultType: Type
        access(contract) var bidAt: UFix64
        access(contract) var balance: UFix64
        access(contract) let bidExtraField: {String : AnyStruct}

        init(from: Capability<&SaleItemCollection>, itemUUID: UInt64, nftCap: Capability<&{NonFungibleToken.Receiver}>, vaultType:Type,  balance:UFix64, bidExtraField: {String : AnyStruct}){
            self.vaultType= vaultType
            self.balance=balance
            self.itemUUID=itemUUID
            self.from=from
            self.bidAt=Clock.time()
            self.nftCap=nftCap
            self.bidExtraField=bidExtraField
        }

        access(contract) fun setBalance(_ balance:UFix64) {
            self.balance=balance
        }

        access(contract) fun setBidAt(_ time: UFix64) {
            self.bidAt=time
        }

        access(all) fun getBalance() : UFix64 {
            return self.balance
        }

        access(all) fun getSellerAddress() : Address {
            return self.from.address
        }

        access(all) fun getBidExtraField() : {String : AnyStruct} {
            return self.bidExtraField
        }
    }

    access(all) resource interface MarketBidCollectionPublic {
        access(all) fun getBalance(_ id: UInt64) : UFix64
        access(all) fun containsId(_ id: UInt64): Bool
        access(contract) fun accept(_ nft: @{NonFungibleToken.NFT})
        access(contract) fun cancelBidFromSaleItem(_ id: UInt64)
    }

    access(all) entitlement Buyer

    //A collection stored for bidders/buyers
    access(all) resource MarketBidCollection: MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic {

        access(contract) var bids : @{UInt64: Bid}
        access(contract) let receiver: Capability<&{FungibleToken.Receiver}>
        access(contract) let tenantCapability: Capability<&FindMarket.Tenant>

        //not sure we can store this here anymore. think it needs to be in every bid
        init(receiver: Capability<&{FungibleToken.Receiver}>, tenantCapability: Capability<&FindMarket.Tenant>) {
            self.bids <- {}
            self.receiver=receiver
            self.tenantCapability=tenantCapability
        }

        access(self) fun getTenant() : &FindMarket.Tenant {
            if !self.tenantCapability.check()  {
                panic("Tenant client is not linked anymore")
            }
            return self.tenantCapability.borrow()!
        }

        //called from lease when auction is ended
        access(contract) fun accept(_ nft: @{NonFungibleToken.NFT}) {
            if self.bids[nft.uuid] == nil  {
                panic("You need to have a bid here already")
            }
            let bid <- self.bids.remove(key: nft.uuid) ?? panic("missing bid")
            if !bid.nftCap.check() {
                panic("Bidder unlinked the nft receiver capability. bidder address : ".concat(bid.nftCap.address.toString()))
            }
            bid.nftCap.borrow()!.deposit(token: <- nft)
            destroy bid
        }

        access(all) fun getIds() : [UInt64] {
            return self.bids.keys
        }

        access(all) fun containsId(_ id: UInt64) : Bool {
            return self.bids.containsKey(id)
        }

        access(all) fun getBidType() : Type {
            return Type<@Bid>()
        }

        access(Buyer) fun bid(item: FindViews.ViewReadPointer, amount:UFix64, vaultType:Type, nftCap: Capability<&{NonFungibleToken.Receiver}>, bidExtraField: {String : AnyStruct}) {

            if self.owner!.address == item.owner() {
                panic("You cannot bid on your own resource")
            }

            let uuid=item.getUUID()

            if self.bids[uuid] != nil {
                panic("You already have an bid for this item, use increaseBid on that bid")
            }
            let tenant=self.getTenant()
            let from=getAccount(item.owner()).capabilities.get<&SaleItemCollection>(tenant.getPublicPath(Type<@SaleItemCollection>()))!

            let bid <- create Bid(from: from, itemUUID:uuid, nftCap: nftCap, vaultType: vaultType, balance:amount, bidExtraField: bidExtraField)
            let saleItemCollection= from.borrow() ?? panic("Could not borrow sale item for id=".concat(uuid.toString()))

            let callbackCapability =self.owner!.capabilities.get<&MarketBidCollection>(tenant.getPublicPath(Type<@MarketBidCollection>()))!
            let oldToken <- self.bids[uuid] <- bid
            saleItemCollection.registerBid(item: item, callback: callbackCapability, vaultType: vaultType)
            destroy oldToken
        }

        access(all) fun fulfillAuction(id:UInt64, vault: @{FungibleToken.Vault}) {

            if self.bids[id] == nil  {
                panic("You need to have a bid here already")
            }
            let bid =self.borrowBid(id)
            let saleItem=bid.from.borrow()!
            saleItem.fulfillAuction(id:id, vault: <- vault)
        }

        //increase a bid, will not work if the auction has already started
        access(Buyer) fun increaseBid(id: UInt64, increaseBy: UFix64) {
            if self.bids[id] == nil  {
                panic("You need to have a bid here already")
            }
            let bid =self.borrowBid(id)

            let oldBalance=bid.balance

            bid.setBidAt(Clock.time())
            bid.setBalance(bid.balance + increaseBy)

            if !bid.from.check(){
                panic("Seller unlinked the SaleItem collection capability. seller address : ".concat(bid.from.address.toString()))
            }
            bid.from.borrow()!.registerIncreasedBid(id, oldBalance: oldBalance)
        }

        //called from saleItem when things are cancelled
        //if the bid is canceled from seller then we move the vault tokens back into your vault
        access(contract) fun cancelBidFromSaleItem(_ id: UInt64) {
            let bid <- self.bids.remove(key: id) ?? panic("missing bid")
            destroy bid
        }

        access(all) fun borrowBid(_ id: UInt64): &Bid {
            if !self.bids.containsKey(id) {
                panic("This id does not exist.".concat(id.toString()))
            }
            return (&self.bids[id])!
        }

        access(all) fun borrowBidItem(_ id: UInt64): &{FindMarket.Bid} {
            if !self.bids.containsKey(id) {
                panic("This id does not exist.".concat(id.toString()))
            }
            return (&self.bids[id])!
        }

        access(all) fun getBalance(_ id: UInt64) : UFix64 {
            if self.bids[id] == nil  {
                panic("You need to have a bid here already")
            }
            let bid= self.borrowBid(id)
            return bid.balance
        }
    }

    //Create an empty lease collection that store your leases to a name
    access(all) fun createEmptySaleItemCollection(_ tenantCapability: Capability<&FindMarket.Tenant>) : @SaleItemCollection {
        return <- create SaleItemCollection(tenantCapability)
    }

    access(all) fun createEmptyMarketBidCollection(receiver: Capability<&{FungibleToken.Receiver}>, tenantCapability: Capability<&FindMarket.Tenant>) : @MarketBidCollection {
        return <- create MarketBidCollection(receiver: receiver, tenantCapability:tenantCapability)
    }

    access(all) fun getSaleItemCapability(marketplace:Address, user:Address) : Capability<&SaleItemCollection>? {
        if FindMarket.getTenantCapability(marketplace) == nil {
            panic("Invalid tenant")
        }
        if let tenant=FindMarket.getTenantCapability(marketplace)!.borrow() {
            return getAccount(user).capabilities.get<&SaleItemCollection>(tenant.getPublicPath(Type<@SaleItemCollection>()))
        }
        return nil
    }

    access(all) fun getBidCapability( marketplace:Address, user:Address) : Capability<&MarketBidCollection>? {
        if FindMarket.getTenantCapability(marketplace) == nil {
            panic("Invalid tenant")
        }
        if let tenant=FindMarket.getTenantCapability(marketplace)!.borrow() {
            return getAccount(user).capabilities.get<&MarketBidCollection>(tenant.getPublicPath(Type<@MarketBidCollection>()))
        }
        return nil
    }

    init() {
        FindMarket.addSaleItemType(Type<@SaleItem>())
        FindMarket.addSaleItemCollectionType(Type<@SaleItemCollection>())
        FindMarket.addMarketBidType(Type<@Bid>())
        FindMarket.addMarketBidCollectionType(Type<@MarketBidCollection>())
    }
}
