import FungibleToken from "./standard/FungibleToken.cdc"
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import FindViews from "./FindViews.cdc"
import Clock from "./Clock.cdc"
import FIND from "./FIND.cdc"
import FindMarket from "./FindMarket.cdc"

// An auction saleItem contract that escrows the FT, does _not_ escrow the NFT
pub contract FindMarketAuctionEscrow {

	pub event EnglishAuction(tenant: String, id: UInt64, seller: Address, sellerName:String?, amount: UFix64, auctionReservePrice: UFix64, status: String, vaultType:String, nft:FindMarket.NFTInfo, buyer:Address?, buyerName:String?, endsAt: UFix64?)

	pub resource SaleItem : FindMarket.SaleItem {
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
		access(contract) var offerCallback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>?
		access(contract) let totalRoyalties: UFix64 
		access(contract) let saleItemExtraField: {String : AnyStruct}

		init(pointer: FindViews.AuthNFTPointer, vaultType: Type, auctionStartPrice:UFix64, auctionReservePrice:UFix64, auctionDuration: UFix64, extentionOnLateBid:UFix64, minimumBidIncrement:UFix64, auctionValidUntil: UFix64?, saleItemExtraField: {String : AnyStruct}) {
			self.vaultType=vaultType
			self.pointer=pointer
			self.auctionStartPrice=auctionStartPrice
			self.auctionReservePrice=auctionReservePrice
			self.auctionDuration=auctionDuration
			self.auctionExtensionOnLateBid=extentionOnLateBid
			self.auctionMinBidIncrement=minimumBidIncrement
			self.offerCallback=nil
			self.auctionStartedAt=nil
			self.auctionEndsAt=nil
			self.auctionValidUntil=auctionValidUntil
			self.saleItemExtraField=saleItemExtraField

			var royalties : UFix64 = 0.0
			if self.pointer.getViews().contains(Type<MetadataViews.Royalties>()) {
				let v = self.pointer.resolveView(Type<MetadataViews.Royalties>())! as! MetadataViews.Royalties
				for royalty in v.getRoyalties() {
					royalties = royalties + royalty.cut
				}
			}
			if self.pointer.getViews().contains(Type<MetadataViews.Royalty>()) {
				let royalty= self.pointer.resolveView(Type<MetadataViews.Royalty>())! as! MetadataViews.Royalty
				royalties = royalties + royalty.cut
			}
			if self.pointer.getViews().contains(Type<[MetadataViews.Royalty]>()) {
				let r= self.pointer.resolveView(Type<[MetadataViews.Royalty]>())! as! [MetadataViews.Royalty]
				for royalty in r {
					royalties = royalties + royalty.cut
				}
			}
			self.totalRoyalties=royalties
		}

		pub fun getId() : UInt64{
			return self.pointer.getUUID()
		}

		pub fun acceptEscrowedBid() : @FungibleToken.Vault {
			let vault <- self.offerCallback!.borrow()!.accept(<- self.pointer.withdraw())
			return <- vault
		}

		pub fun getRoyalty() : MetadataViews.Royalties? {
			if self.pointer.getViews().contains(Type<MetadataViews.Royalties>()) {
				return self.pointer.resolveView(Type<MetadataViews.Royalties>())! as! MetadataViews.Royalties
			}
			if self.pointer.getViews().contains(Type<MetadataViews.Royalty>()) {
				let royalty= self.pointer.resolveView(Type<MetadataViews.Royalty>())! as! MetadataViews.Royalty
				return MetadataViews.Royalties([royalty])
			}
			if self.pointer.getViews().contains(Type<[MetadataViews.Royalty]>()) {
				let royalty= self.pointer.resolveView(Type<[MetadataViews.Royalty]>())! as! [MetadataViews.Royalty]
				return MetadataViews.Royalties(royalty)
			}

			return  nil
		}

		pub fun getBalance() : UFix64 {
			if let cb= self.offerCallback {
				return cb.borrow()!.getBalance(self.getId())
			}
			return self.auctionStartPrice
		}

		pub fun getSeller() : Address {
			return self.pointer.owner()
		}

		pub fun getSellerName() : String? {
			let address = self.pointer.owner()
			return FIND.reverseLookup(address)
		}

		pub fun getBuyer() : Address? {
			if let cb= self.offerCallback {
				return cb.address
			}
			return nil
		}

		pub fun getBuyerName() : String? {
			if let cb= self.offerCallback {
				return FIND.reverseLookup(cb.address)
			}
			return nil
		}

		pub fun toNFTInfo() : FindMarket.NFTInfo{
			return FindMarket.NFTInfo(self.pointer.getViewResolver(), id: self.pointer.id)
		}

		pub fun setAuctionStarted(_ startedAt: UFix64) {
			self.auctionStartedAt=startedAt
		}

		pub fun setAuctionEnds(_ endsAt: UFix64){
			self.auctionEndsAt=endsAt
		}

		pub fun hasAuctionStarted() : Bool {
			if let starts = self.auctionStartedAt {
				return starts <= Clock.time()
			}
			return false
		}

		pub fun hasAuctionEnded() : Bool {      
			if let ends = self.auctionEndsAt {
				return ends < Clock.time()
			}
			panic("Not a live auction")
		}

		pub fun hasAuctionMetReservePrice() : Bool {

			let balance=self.getBalance()

			if self.auctionReservePrice== nil {
				return false
			}

			return balance >= self.auctionReservePrice
		}

		pub fun setExtentionOnLateBid(_ time: UFix64) {
			self.auctionExtensionOnLateBid=time
		}

		pub fun setAuctionDuration(_ duration: UFix64) {
			self.auctionDuration=duration
		}

		pub fun setReservePrice(_ price: UFix64) {
			self.auctionReservePrice=price
		}

		pub fun setMinBidIncrement(_ price: UFix64) {
			self.auctionMinBidIncrement=price
		}

		pub fun setStartAuctionPrice(_ price: UFix64) {
			self.auctionStartPrice=price
		}

		pub fun setCallback(_ callback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>?) {
			self.offerCallback=callback
		}


		pub fun getSaleType(): String {
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

		pub fun getListingType() : Type {
			return Type<@SaleItem>()
		}

		pub fun getListingTypeIdentifier(): String {
			return Type<@SaleItem>().identifier
		}


		pub fun getItemID() : UInt64 {
			return self.pointer.id
		}

		pub fun getItemType() : Type {
			return self.pointer.getItemType()
		}

		pub fun getAuction(): FindMarket.AuctionItem? {
			return FindMarket.AuctionItem(startPrice: self.auctionStartPrice, 
			currentPrice: self.getBalance(),
			minimumBidIncrement: self.auctionMinBidIncrement ,
			reservePrice: self.auctionReservePrice, 
			extentionOnLateBid: self.auctionExtensionOnLateBid ,
			auctionEndsAt: self.auctionEndsAt , 
			timestamp: Clock.time())
		}

		pub fun getFtType() : Type {
			return self.vaultType
		}

		pub fun setValidUntil(_ time: UFix64?) {
			self.auctionValidUntil=time
		}

		pub fun getValidUntil() : UFix64? {
			if self.hasAuctionStarted() {
				return self.auctionEndsAt
			}
			return self.auctionValidUntil
		}

		pub fun checkPointer() : Bool {
			return self.pointer.valid()
		}

		pub fun getSaleItemExtraField() : {String : AnyStruct} {
			return self.saleItemExtraField
		}
		
		pub fun getTotalRoyalties() : UFix64 {
			return self.totalRoyalties
		}
	}


	pub resource interface SaleItemCollectionPublic {
		//fetch all the tokens in the collection
		pub fun getIds(): [UInt64]

		access(contract) fun registerIncreasedBid(_ id: UInt64, oldBalance:UFix64) 

		//place a bid on a token
		access(contract) fun registerBid(item: FindViews.ViewReadPointer, callback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>, vaultType:Type)

		//anybody should be able to fulfill an auction as long as it is done
		pub fun fulfillAuction(_ id: UInt64) 
	}

	pub resource SaleItemCollection: SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic {
		//is this the best approach now or just put the NFT inside the saleItem?
		access(contract) var items: @{UInt64: SaleItem}

		access(contract) let tenantCapability: Capability<&FindMarket.Tenant{FindMarket.TenantPublic}>

		init (_ tenantCapability: Capability<&FindMarket.Tenant{FindMarket.TenantPublic}>) {
			self.items <- {}
			self.tenantCapability=tenantCapability
		}


		access(self) fun getTenant() : &FindMarket.Tenant{FindMarket.TenantPublic} {
			pre{
				self.tenantCapability.check() : "Tenant client is not linked anymore"
			}
			return self.tenantCapability.borrow()!
		}

		access(self) fun emitEvent(saleItem: &SaleItem, status: String) {
			let owner=saleItem.getSeller()
			let ftType=saleItem.getFtType()
			let nftInfo=saleItem.toNFTInfo()
			let balance=saleItem.getBalance()
			let buyer=saleItem.getBuyer()
			let buyerName=saleItem.getBuyerName()
			let seller=saleItem.getSeller()
			let id=saleItem.getId()


			emit EnglishAuction(tenant:self.getTenant().name, id: id, seller:seller, sellerName: FIND.reverseLookup(seller), amount: balance, auctionReservePrice: saleItem.auctionReservePrice,  status: status, vaultType:saleItem.vaultType.identifier, nft: nftInfo,  buyer: buyer, buyerName: buyerName, endsAt: saleItem.auctionEndsAt)
		}

		pub fun getListingType() : Type {
			return Type<@SaleItem>()
		}

		access(self) fun addBid(id:UInt64, newOffer: Capability<&MarketBidCollection{MarketBidCollectionPublic}>, oldBalance:UFix64) {
			let saleItem=self.borrow(id)

			let actionResult=self.getTenant().allowedAction(listingType: Type<@FindMarketAuctionEscrow.SaleItem>(), nftType: saleItem.getItemType(), ftType: saleItem.getFtType(), action: FindMarket.MarketAction(listing:false, "add bid in auction"))

			if !actionResult.allowed {
				panic(actionResult.message)
			}

			let timestamp=Clock.time()
			let newOfferBalance=newOffer.borrow()!.getBalance(id)

			let previousOffer = saleItem.offerCallback!

			var minBid=oldBalance + saleItem.auctionMinBidIncrement
			if newOffer.address != previousOffer.address {
				minBid = previousOffer.borrow()!.getBalance(id) + saleItem.auctionMinBidIncrement
			}

			if newOfferBalance < minBid {
				panic("bid ".concat(newOfferBalance.toString()).concat(" must be larger then previous bid+bidIncrement ").concat(minBid.toString()))
			}

			if newOffer.address != previousOffer.address {
				previousOffer.borrow()!.cancelBidFromSaleItem(id)
			}

			saleItem.setCallback(newOffer)

			let suggestedEndTime=timestamp+saleItem.auctionExtensionOnLateBid

			if suggestedEndTime > saleItem.auctionEndsAt! {
				saleItem.setAuctionEnds(suggestedEndTime)
			}
			self.emitEvent(saleItem: saleItem, status: "active_ongoing")

		}

		access(contract) fun registerIncreasedBid(_ id: UInt64, oldBalance:UFix64) {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
			}

			let saleItem=self.borrow(id)

			if !saleItem.hasAuctionStarted() {
				panic("Auction is not started")
			}

			if saleItem.hasAuctionEnded() {
				panic("Auction has ended")
			}

			self.addBid(id: id, newOffer: saleItem.offerCallback!, oldBalance:oldBalance)
		}

		//This is a function that buyer will call (via his bid collection) to register the bicCallback with the seller
		access(contract) fun registerBid(item: FindViews.ViewReadPointer, callback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>, vaultType: Type) {

			let timestamp=Clock.time()

			let id = item.getUUID()

			let saleItem=self.borrow(id)

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

			let actionResult=self.getTenant().allowedAction(listingType: Type<@FindMarketAuctionEscrow.SaleItem>(), nftType: saleItem.getItemType(), ftType: saleItem.getFtType(), action: FindMarket.MarketAction(listing:false, "bid in auction"))

			if !actionResult.allowed {
				panic(actionResult.message)
			}

			let balance=callback.borrow()!.getBalance(id)

			if saleItem.auctionStartPrice >  balance {
				panic("You need to bid more then the starting price of ".concat(saleItem.auctionStartPrice.toString()))
			}

			if let valid = saleItem.getValidUntil() {
				assert( valid >= Clock.time(), message: "This auction listing is already expired")
			}

			saleItem.setCallback(callback)
			let duration=saleItem.auctionDuration
			let endsAt=timestamp + duration
			saleItem.setAuctionStarted(timestamp)
			saleItem.setAuctionEnds(endsAt)

			self.emitEvent(saleItem: saleItem, status: "active_ongoing")
		}

		pub fun cancel(_ id: UInt64) {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
			}

			let saleItem=self.borrow(id)

			var status = "cancel_listing"
			if saleItem.hasAuctionStarted() && saleItem.hasAuctionEnded() {
				if saleItem.hasAuctionMetReservePrice() {
					panic("Cannot cancel finished auction, fulfill it instead")
				}
				status="cancel_reserved_not_met"
			}

			let actionResult=self.getTenant().allowedAction(listingType: Type<@FindMarketAuctionEscrow.SaleItem>(), nftType: saleItem.getItemType(), ftType: saleItem.getFtType(), action: FindMarket.MarketAction(listing:false, "delist item for auction"))

			if !actionResult.allowed {
				panic(actionResult.message)
			}

			self.internalCancelAuction(saleItem: saleItem, status: status)

		}

		access(self) fun internalCancelAuction(saleItem: &SaleItem, status:String) {
			self.emitEvent(saleItem: saleItem, status: status)
			let id=saleItem.getId()
			if saleItem.offerCallback != nil && saleItem.offerCallback!.check() {
				saleItem.offerCallback!.borrow()!.cancelBidFromSaleItem(id)
			}
			destroy <- self.items.remove(key: id)
		}


		/// fulfillAuction wraps the fulfill method and ensure that only a finished auction can be fulfilled by anybody
		pub fun fulfillAuction(_ id: UInt64) {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
				self.borrow(id).auctionStartPrice != nil : "Cannot fulfill sale that is not an auction=".concat(id.toString())
			}

			let saleItem = self.borrow(id)

			if saleItem.hasAuctionStarted() {
				if !saleItem.hasAuctionEnded() {
					panic("Auction has not ended yet")
				}

				let actionResult=self.getTenant().allowedAction(listingType: Type<@FindMarketAuctionEscrow.SaleItem>(), nftType: saleItem.getItemType(), ftType: saleItem.getFtType(), action: FindMarket.MarketAction(listing:false, "fulfill auction"))

				if !actionResult.allowed {
					panic(actionResult.message)
				}

				let cuts= self.getTenant().getTeantCut(name: actionResult.name, listingType: Type<@FindMarketAuctionEscrow.SaleItem>(), nftType: saleItem.getItemType(), ftType: saleItem.getFtType())

				if !saleItem.hasAuctionMetReservePrice() {
					self.internalCancelAuction(saleItem: saleItem, status: "cancel_reserved_not_met")
					return
				}

				let nftInfo= saleItem.toNFTInfo()
				let royalty=saleItem.getRoyalty()

				self.emitEvent(saleItem: saleItem, status: "sold")

				let vault <- saleItem.acceptEscrowedBid()
				FindMarket.pay(tenant:self.getTenant().name, id:id, saleItem: saleItem, vault: <- vault, royalty:royalty, nftInfo:nftInfo, cuts:cuts, resolver: fun(address:Address): String? { return FIND.reverseLookup(address) })

				destroy <- self.items.remove(key: id)
				return 
			}
			panic("This auction is not live")

		} 

		pub fun listForAuction(pointer: FindViews.AuthNFTPointer, vaultType: Type, auctionStartPrice: UFix64, auctionReservePrice: UFix64, auctionDuration: UFix64, auctionExtensionOnLateBid: UFix64, minimumBidIncrement: UFix64, auctionValidUntil: UFix64?, saleItemExtraField: {String : AnyStruct}) {

			let saleItem <- create SaleItem(pointer: pointer, vaultType:vaultType, auctionStartPrice: auctionStartPrice, auctionReservePrice:auctionReservePrice, auctionDuration: auctionDuration, extentionOnLateBid: auctionExtensionOnLateBid, minimumBidIncrement:minimumBidIncrement, auctionValidUntil: auctionValidUntil, saleItemExtraField: saleItemExtraField)
			
			let actionResult=self.getTenant().allowedAction(listingType: Type<@FindMarketAuctionEscrow.SaleItem>(), nftType: saleItem.getItemType(), ftType: saleItem.getFtType(), action: FindMarket.MarketAction(listing:true, "list item for auction"))

			if !actionResult.allowed {
				panic(actionResult.message)
			}

			assert(self.items[pointer.getUUID()] == nil , message: "Auction listing for this item is already created.")

			self.items[pointer.getUUID()] <-! saleItem
			let saleItemRef = self.borrow(pointer.getUUID())
			self.emitEvent(saleItem: saleItemRef, status: "active_listed")

		}

		pub fun getIds(): [UInt64] {
			return self.items.keys
		}

		pub fun borrow(_ id: UInt64): &SaleItem {
			pre{
				self.items.containsKey(id) : "This id does not exist.".concat(id.toString())
			}
			return &self.items[id] as &SaleItem
		}

		pub fun borrowSaleItem(_ id: UInt64) : &{FindMarket.SaleItem} {
			pre{
				self.items.containsKey(id) : "This id does not exist.".concat(id.toString())
			}
			return &self.items[id] as &SaleItem{FindMarket.SaleItem}
		}

		destroy() {
			destroy self.items
		}
	}

	pub resource Bid : FindMarket.Bid {
		access(contract) let from: Capability<&SaleItemCollection{SaleItemCollectionPublic}>
		access(contract) let nftCap: Capability<&{NonFungibleToken.Receiver}>
		access(contract) let itemUUID: UInt64

		//this should reflect on what the above uuid is for
		access(contract) let vault: @FungibleToken.Vault
		access(contract) let vaultType: Type
		access(contract) var bidAt: UFix64
		access(contract) let bidExtraField: {String : AnyStruct}

		init(from: Capability<&SaleItemCollection{SaleItemCollectionPublic}>, itemUUID: UInt64, vault: @FungibleToken.Vault, nftCap: Capability<&{NonFungibleToken.Receiver}> , bidExtraField: {String : AnyStruct}) {
			self.vaultType= vault.getType()
			self.vault <- vault
			self.itemUUID=itemUUID
			self.from=from
			self.bidAt=Clock.time()
			self.nftCap=nftCap
			self.bidExtraField=bidExtraField
		}

		access(contract) fun setBidAt(_ time: UFix64) {
			self.bidAt=time
		}

		pub fun getBalance() : UFix64 {
			return self.vault.balance
		}

		pub fun getSellerAddress() : Address {
			return self.from.address
		}

		pub fun getBidExtraField() : {String : AnyStruct} {
			return self.bidExtraField 
		}

		destroy() {
			destroy self.vault
		}
	}

	pub resource interface MarketBidCollectionPublic {
		pub fun getBalance(_ id: UInt64) : UFix64
		access(contract) fun accept(_ nft: @NonFungibleToken.NFT) : @FungibleToken.Vault
		access(contract) fun cancelBidFromSaleItem(_ id: UInt64)
	}

	//A collection stored for bidders/buyers
	pub resource MarketBidCollection: MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic {

		access(contract) var bids : @{UInt64: Bid}
		access(contract) let receiver: Capability<&{FungibleToken.Receiver}>
		access(contract) let tenantCapability: Capability<&FindMarket.Tenant{FindMarket.TenantPublic}>

		//not sure we can store this here anymore. think it needs to be in every bid
		init(receiver: Capability<&{FungibleToken.Receiver}>, tenantCapability: Capability<&FindMarket.Tenant{FindMarket.TenantPublic}>) {
			self.bids <- {}
			self.receiver=receiver
			self.tenantCapability=tenantCapability
		}

		access(self) fun getTenant() : &FindMarket.Tenant{FindMarket.TenantPublic} {
			pre{
				self.tenantCapability.check() : "Tenant client is not linked anymore"
			}
			return self.tenantCapability.borrow()!
		}

		//called from lease when auction is ended
		access(contract) fun accept(_ nft: @NonFungibleToken.NFT) : @FungibleToken.Vault {
			let id= nft.id
			let bid <- self.bids.remove(key: nft.uuid) ?? panic("missing bid")
			let vaultRef = &bid.vault as &FungibleToken.Vault
			bid.nftCap.borrow()!.deposit(token: <- nft)
			let vault  <- vaultRef.withdraw(amount: vaultRef.balance)
			destroy bid
			return <- vault
		}

		pub fun getIds() : [UInt64] {
			return self.bids.keys
		}

		pub fun getBidType() : Type {
			return Type<@Bid>()
		}

		pub fun bid(item: FindViews.ViewReadPointer, vault: @FungibleToken.Vault, nftCap: Capability<&{NonFungibleToken.Receiver}>, bidExtraField: {String : AnyStruct}) {
			pre {
				self.owner!.address != item.owner()  : "You cannot bid on your own resource"
				self.bids[item.getUUID()] == nil : "You already have an bid for this item, use increaseBid on that bid"
			}

			let uuid=item.getUUID()

			let from=getAccount(item.owner()).getCapability<&SaleItemCollection{SaleItemCollectionPublic}>(self.getTenant().getPublicPath(Type<@SaleItemCollection>()))
			let vaultType=vault.getType()

			let bid <- create Bid(from: from, itemUUID:item.getUUID(), vault: <- vault, nftCap: nftCap, bidExtraField: bidExtraField)
			let saleItemCollection= from.borrow() ?? panic("Could not borrow sale item for id=".concat(uuid.toString()))

			let callbackCapability =self.owner!.getCapability<&MarketBidCollection{MarketBidCollectionPublic}>(self.getTenant().getPublicPath(Type<@MarketBidCollection>()))
			let oldToken <- self.bids[uuid] <- bid
			saleItemCollection.registerBid(item: item, callback: callbackCapability, vaultType: vaultType) 
			destroy oldToken
		}

		pub fun fulfillAuction(_ id:UInt64) {
			pre {
				self.bids[id] != nil : "You need to have a bid here already"
			}
			let bid =self.borrowBid(id)
			let saleItem=bid.from.borrow()!
			saleItem.fulfillAuction(id)
		}

		pub fun increaseBid(id: UInt64, vault: @FungibleToken.Vault) {
			pre {
				self.bids[id] != nil : "You need to have a bid here already"
			}
			let bid =self.borrowBid(id)

			let oldBalance=bid.vault.balance

			bid.setBidAt(Clock.time())
			bid.vault.deposit(from: <- vault)

			bid.from.borrow()!.registerIncreasedBid(id, oldBalance:oldBalance)
		}

		//called from saleItem when things are cancelled 
		//if the bid is canceled from seller then we move the vault tokens back into your vault
		access(contract) fun cancelBidFromSaleItem(_ id: UInt64) {
			let bid <- self.bids.remove(key: id) ?? panic("missing bid")
			let vaultRef = &bid.vault as &FungibleToken.Vault
			self.receiver.borrow()!.deposit(from: <- vaultRef.withdraw(amount: vaultRef.balance))
			destroy bid
		}

		pub fun borrowBid(_ id: UInt64): &Bid {
			pre{
				self.bids.containsKey(id) : "This id does not exist.".concat(id.toString())
			}
			return &self.bids[id] as &Bid
		}

		pub fun borrowBidItem(_ id: UInt64): &{FindMarket.Bid} {
			pre{
				self.bids.containsKey(id) : "This id does not exist.".concat(id.toString())
			}
			return &self.bids[id] as &Bid{FindMarket.Bid}
		}

		pub fun getBalance(_ id: UInt64) : UFix64 {
			let bid= self.borrowBid(id)
			return bid.vault.balance
		}

		destroy() {
			destroy self.bids
		}
	}

	//Create an empty lease collection that store your leases to a name
	pub fun createEmptySaleItemCollection(_ tenantCapability: Capability<&FindMarket.Tenant{FindMarket.TenantPublic}>): @SaleItemCollection {
		return <- create SaleItemCollection(tenantCapability)
	}

	pub fun createEmptyMarketBidCollection(receiver: Capability<&{FungibleToken.Receiver}>, tenantCapability: Capability<&FindMarket.Tenant{FindMarket.TenantPublic}>) : @MarketBidCollection {
		return <- create MarketBidCollection(receiver: receiver, tenantCapability:tenantCapability)
	}

	pub fun getSaleItemCapability(marketplace:Address, user:Address) : Capability<&SaleItemCollection{SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>? {
		pre{
			FindMarket.getTenantCapability(marketplace) != nil : "Invalid tenant"
		}
		if let tenant=FindMarket.getTenantCapability(marketplace)!.borrow() {
			return getAccount(user).getCapability<&SaleItemCollection{SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(tenant.getPublicPath(Type<@SaleItemCollection>()))
		}
		return nil
	}

	pub fun getBidCapability( marketplace:Address, user:Address) : Capability<&MarketBidCollection{MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>? {
		pre{
			FindMarket.getTenantCapability(marketplace) != nil : "Invalid tenant"
		}
		if let tenant=FindMarket.getTenantCapability(marketplace)!.borrow() {
			return getAccount(user).getCapability<&MarketBidCollection{MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(tenant.getPublicPath(Type<@MarketBidCollection>()))
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
