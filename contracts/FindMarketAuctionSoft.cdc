import FungibleToken from "./standard/FungibleToken.cdc"
import FlowToken from "./standard/FlowToken.cdc"
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import Profile from "./Profile.cdc"
import Clock from "./Clock.cdc"
import Debug from "./Debug.cdc"
import FIND from "./FIND.cdc"
import FindMarket from "./FindMarket.cdc"
import FindMarketTenant from "../contracts/FindMarketTenant.cdc"
import NFTRegistry from "../contracts/NFTRegistry.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"

// An auction saleItem contract that escrows the FT, does _not_ escrow the NFT
pub contract FindMarketAuctionSoft {

	pub event ForAuction(tenant: String, id: UInt64, seller: Address, sellerName:String?, amount: UFix64, auctionReservePrice: UFix64, status: String, vaultType:String, nft:FindMarket.NFTInfo, buyer:Address?, buyerName:String?, endsAt: UFix64?)

	pub resource SaleItem : FindMarket.SaleItem {
		access(contract) var pointer: FindViews.AuthNFTPointer

		access(contract) var vaultType: Type
		access(contract) var auctionStartPrice: UFix64
		access(contract) var auctionReservePrice: UFix64
		access(contract) var auctionDuration: UFix64
		access(contract) var auctionMinBidIncrement: UFix64
		access(contract) var auctionExtensionOnLateBid: UFix64
		access(contract) var auctionStartedAt: UFix64?
		access(contract) var auctionEndsAt: UFix64?
		access(contract) var offerCallback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>?

		init(pointer: FindViews.AuthNFTPointer, vaultType: Type, auctionStartPrice:UFix64, auctionReservePrice:UFix64) {
			self.vaultType=vaultType
			self.pointer=pointer
			self.auctionStartPrice=auctionStartPrice
			self.auctionReservePrice=auctionReservePrice
			self.auctionDuration=86400.0
			self.auctionExtensionOnLateBid=300.0
			self.auctionMinBidIncrement=10.0
			self.offerCallback=nil
			self.auctionStartedAt=nil
			self.auctionEndsAt=nil
		}

		//TODO: Should we rename this?
		pub fun getId() : UInt64{
			return self.pointer.getUUID()
		}

		//Here we do not get a vault back, it is sent in to the method itself
		pub fun acceptNonEscrowedBid() { 
			self.offerCallback!.borrow()!.accept(<- self.pointer.withdraw())
		}

		//BAM: copy this to the other options
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

			//BAM: if we explose Royalty just 1 return that as a Royalties? 
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

		//TODO: what should the type be here, how to diff on soft vs not?
		pub fun getSaleType(): String {
			if self.auctionStartedAt != nil {
				return "ongoing_auction"
			}
			return "ondemand_auction"
		}

		pub fun getListingType() : Type {
			return Type<@SaleItem>()
		}

		pub fun getListingTypeIdentifier() : String {
			return Type<@SaleItem>().identifier
		}

		pub fun getItemID() : UInt64 {
			return self.pointer.id
		}

		pub fun getItemType() : Type {
			return self.pointer.getItemType()
		}

		//BAM: remove these ones
		pub fun getItemCollectionAlias() : String {
			return NFTRegistry.getNFTInfoByTypeIdentifier(self.getItemType().identifier)!.alias
		}

		pub fun getAuction(): FindMarket.AuctionItem? {
			return FindMarket.AuctionItem(startPrice: self.auctionStartPrice, 
										  currentPrice: self.getBalance(),
										  minimumBidIncrement: self.auctionMinBidIncrement ,
										  reservePrice: self.auctionReservePrice, 
										  extentionOnLateBid: self.auctionExtensionOnLateBid ,
										  auctionEndsAt: self.auctionEndsAt ,
										  timestamp: getCurrentBlock().timestamp)
		}

		pub fun getFtType() : Type {
			return self.vaultType
		}

		pub fun getFtAlias() : String {
			return FTRegistry.getFTInfoByTypeIdentifier(self.getFtType().identifier)!.alias
		}

		pub fun getValidUntil() : UFix64? {
			return self.auctionEndsAt

		}

		pub fun checkPointer() : Bool {
			return self.pointer.valid()
		}
	}

	pub resource interface SaleItemCollectionPublic {
		//fetch all the tokens in the collection
		pub fun getIds(): [UInt64]

		access(contract) fun registerIncreasedBid(_ id: UInt64, oldBalance: UFix64) 

		//place a bid on a token
		access(contract) fun registerBid(item: FindViews.ViewReadPointer, callback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>, vaultType:Type)

		//only buyer can fulfill auctions since he needs to send funds for this type
		access(contract) fun fulfillAuction(id: UInt64, vault: @FungibleToken.Vault) 
	}

	pub resource SaleItemCollection: SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic  {
		//is this the best approach now or just put the NFT inside the saleItem?
		access(contract) var items: @{UInt64: SaleItem}

		access(contract) let tenantCapability: Capability<&FindMarketTenant.Tenant{FindMarketTenant.TenantPublic}>

		init (_ tenantCapability: Capability<&FindMarketTenant.Tenant{FindMarketTenant.TenantPublic}>) {
			self.items <- {}
			self.tenantCapability=tenantCapability
		}

		access(self) fun getTenant() : &FindMarketTenant.Tenant{FindMarketTenant.TenantPublic} {
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


			emit ForAuction(tenant:self.getTenant().name, id: id, seller:seller, sellerName: FIND.reverseLookup(seller), amount: balance, auctionReservePrice: saleItem.auctionReservePrice,  status: status, vaultType:saleItem.vaultType.identifier, nft: nftInfo,  buyer: buyer, buyerName: buyerName, endsAt: saleItem.auctionEndsAt)
		}

		pub fun getListingType() : Type {
			return Type<@SaleItem>()
		}

		access(self) fun addBid(id:UInt64, newOffer: Capability<&MarketBidCollection{MarketBidCollectionPublic}>, oldBalance: UFix64) {
			let saleItem=self.borrow(id)

			let actionResult=self.getTenant().allowedAction(listingType: Type<@FindMarketAuctionSoft.SaleItem>(), nftType: saleItem.getItemType(), ftType: saleItem.getFtType(), action: FindMarketTenant.MarketAction(listing:false, "add bit in soft-auction"))

			if !actionResult.allowed {
				panic(actionResult.message)
			}

			let timestamp=Clock.time()
			let newOfferBalance=newOffer.borrow()!.getBalance(id)

			let previousOffer = saleItem.offerCallback!

			let minBid=oldBalance + saleItem.auctionMinBidIncrement

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
			self.emitEvent(saleItem: saleItem, status: "active")

		}

		access(contract) fun registerIncreasedBid(_ id: UInt64, oldBalance:UFix64) {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
			}

			let saleItem=self.borrow(id)

			if saleItem.auctionEndsAt == nil {
				panic("Auction is not started")
			}


			let timestamp=Clock.time()
			if saleItem.auctionEndsAt! < timestamp {
				panic("Auction has ended")
			}

			self.addBid(id: id, newOffer: saleItem.offerCallback!, oldBalance: oldBalance)

		}

		//This is a function that buyer will call (via his bid collection) to register the bicCallback with the seller
		access(contract) fun registerBid(item: FindViews.ViewReadPointer, callback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>, vaultType: Type) {

			let timestamp=Clock.time()

			let id = item.getUUID()

			let saleItem=self.borrow(id)
			if saleItem.auctionEndsAt != nil {
				if saleItem.hasAuctionEnded() {
					panic("Auction has ended")
				}
				self.addBid(id: id, newOffer: callback, oldBalance: 0.0)
				return
			}

			let actionResult=self.getTenant().allowedAction(listingType: Type<@FindMarketAuctionSoft.SaleItem>(), nftType: saleItem.getItemType(), ftType: saleItem.getFtType(), action: FindMarketTenant.MarketAction(listing:false, "bid item in soft-auction"))

			if !actionResult.allowed {
				panic(actionResult.message)
			}

			let balance=callback.borrow()!.getBalance(id)

			if let cb= saleItem.offerCallback {
				if cb.address == callback.address {
					panic("You already have the latest bid on this item, use the incraseBid transaction")
				}

				let currentBalance=saleItem.getBalance()
				Debug.log("currentBalance=".concat(currentBalance.toString()).concat(" new bid is at=").concat(balance.toString()))
				if currentBalance >= balance {
					panic("There is already a higher bid on this item")
				}
				cb.borrow()!.cancelBidFromSaleItem(id)
			}
			saleItem.setCallback(callback)
			let duration=saleItem.auctionDuration
			let endsAt=timestamp + duration
			saleItem.setAuctionStarted(timestamp)
			saleItem.setAuctionEnds(endsAt)

			self.emitEvent(saleItem: saleItem, status: "active")
		}

		pub fun cancel(_ id: UInt64) {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
			}

			let saleItem=self.borrow(id)

			if saleItem.auctionEndsAt == nil {
				panic("auction is not ongoing")
			}

			var status="cancelled"
			if saleItem.hasAuctionEnded() && !saleItem.hasAuctionMetReservePrice() {
				status="failed"
			}

			let actionResult=self.getTenant().allowedAction(listingType: Type<@FindMarketAuctionSoft.SaleItem>(), nftType: saleItem.getItemType(), ftType: saleItem.getFtType(), action: FindMarketTenant.MarketAction(listing:false, "delist item from soft-auction"))

			if !actionResult.allowed {
				panic(actionResult.message)
			}

			self.emitEvent(saleItem: saleItem, status: status)
			saleItem.offerCallback!.borrow()!.cancelBidFromSaleItem(id)
			destroy <- self.items.remove(key: id)
		}


		access(contract) fun fulfillAuction(id: UInt64, vault: @FungibleToken.Vault) {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
			}

			let saleItem = self.borrow(id)

			if !saleItem.hasAuctionEnded() {
				panic("Auction has not ended yet")
			}

			if vault.getType() != saleItem.vaultType {
				panic("The FT vault sent in to fulfill does not match the required type")
			}

			if vault.balance < saleItem.auctionReservePrice {
				panic("cannot fulfill auction reserve price was not met, cancel it without a vault ".concat(vault.balance.toString()).concat(" < ").concat(saleItem.auctionReservePrice.toString()))
			}

			let actionResult=self.getTenant().allowedAction(listingType: Type<@FindMarketAuctionSoft.SaleItem>(), nftType: saleItem.getItemType(), ftType: saleItem.getFtType(), action: FindMarketTenant.MarketAction(listing:false, "buy item for soft-auction"))

			if !actionResult.allowed {
				panic(actionResult.message)
			}

			let cuts= self.getTenant().getTeantCut(name: actionResult.name, listingType: Type<@FindMarketAuctionSoft.SaleItem>(), nftType: saleItem.getItemType(), ftType: saleItem.getFtType())


			let nftInfo=saleItem.toNFTInfo()
			let royalty=saleItem.getRoyalty()

			self.emitEvent(saleItem: saleItem, status: "sold")
			saleItem.acceptNonEscrowedBid()

			FindMarket.pay(tenant:self.getTenant().name, id:id, saleItem: saleItem, vault: <- vault, royalty:royalty, nftInfo:nftInfo, cuts:cuts)

			destroy <- self.items.remove(key: id)
		}


		pub fun listForAuction(pointer: FindViews.AuthNFTPointer, vaultType: Type, auctionStartPrice: UFix64, auctionReservePrice: UFix64, auctionDuration: UFix64, auctionExtensionOnLateBid: UFix64, minimumBidIncrement: UFix64) {

			let saleItem <- create SaleItem(pointer: pointer, vaultType:vaultType, auctionStartPrice: auctionStartPrice, auctionReservePrice:auctionReservePrice)

			let actionResult=self.getTenant().allowedAction(listingType: Type<@FindMarketAuctionSoft.SaleItem>(), nftType: saleItem.getItemType(), ftType: saleItem.getFtType(), action: FindMarketTenant.MarketAction(listing:true, "list item for soft-auction"))

			if !actionResult.allowed {
				panic(actionResult.message)
			}

			assert(self.items[pointer.getUUID()] == nil , message: "Auction listing for this item is already created.")

			//TODO: inline these in contructor
			saleItem.setAuctionDuration(auctionDuration)
			saleItem.setExtentionOnLateBid(auctionExtensionOnLateBid)
			saleItem.setMinBidIncrement(minimumBidIncrement)
			self.items[pointer.getUUID()] <-! saleItem
			let saleItemRef = self.borrow(pointer.getUUID())
			self.emitEvent(saleItem: saleItemRef, status: "listed")
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

		access(contract) let vaultType: Type
		access(contract) var bidAt: UFix64
		access(contract) var balance: UFix64

		init(from: Capability<&SaleItemCollection{SaleItemCollectionPublic}>, itemUUID: UInt64, nftCap: Capability<&{NonFungibleToken.Receiver}>, vaultType:Type,  balance:UFix64){
			self.vaultType= vaultType
			self.balance=balance
			self.itemUUID=itemUUID
			self.from=from
			self.bidAt=Clock.time()
			self.nftCap=nftCap
		}

		access(contract) fun setBalance(_ balance:UFix64) {
			self.balance=balance
		}

		access(contract) fun setBidAt(_ time: UFix64) {
			self.bidAt=time
		}

		pub fun getBalance() : UFix64 {
			return self.balance
		}

		pub fun getSellerAddress() : Address {
			return self.from.address
		}
	}

	pub resource interface MarketBidCollectionPublic {
		pub fun getBalance(_ id: UInt64) : UFix64

		access(contract) fun accept(_ nft: @NonFungibleToken.NFT)
		access(contract) fun cancelBidFromSaleItem(_ id: UInt64)
	}

	//A collection stored for bidders/buyers
	pub resource MarketBidCollection: MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic {

		access(contract) var bids : @{UInt64: Bid}
		access(contract) let receiver: Capability<&{FungibleToken.Receiver}>
		access(contract) let tenantCapability: Capability<&FindMarketTenant.Tenant{FindMarketTenant.TenantPublic}>

		//not sure we can store this here anymore. think it needs to be in every bid
		init(receiver: Capability<&{FungibleToken.Receiver}>, tenantCapability: Capability<&FindMarketTenant.Tenant{FindMarketTenant.TenantPublic}>) {
			self.bids <- {}
			self.receiver=receiver
			self.tenantCapability=tenantCapability
		}

		access(self) fun getTenant() : &FindMarketTenant.Tenant{FindMarketTenant.TenantPublic} {
			pre{
				self.tenantCapability.check() : "Tenant client is not linked anymore"
			}
			return self.tenantCapability.borrow()!
		}

		//called from lease when auction is ended
		access(contract) fun accept(_ nft: @NonFungibleToken.NFT) {
			pre {
				self.bids[nft.uuid] != nil : "You need to have a bid here already"
			}

			let bid <- self.bids.remove(key: nft.uuid) ?? panic("missing bid")
			bid.nftCap.borrow()!.deposit(token: <- nft)
			destroy bid
		}

		pub fun getIds() : [UInt64] {
			return self.bids.keys
		}

		pub fun getBidType() : Type {
			return Type<@Bid>()
		}

		pub fun bid(item: FindViews.ViewReadPointer, amount:UFix64, vaultType:Type, nftCap: Capability<&{NonFungibleToken.Receiver}>) {
			pre {
				self.owner!.address != item.owner()  : "You cannot bid on your own resource"
				self.bids[item.getUUID()] == nil : "You already have an bid for this item, use increaseBid on that bid"
			}

			let uuid=item.getUUID()

			let from=getAccount(item.owner()).getCapability<&SaleItemCollection{SaleItemCollectionPublic}>(self.getTenant().getPublicPath(Type<@SaleItemCollection>()))

			let bid <- create Bid(from: from, itemUUID:item.getUUID(), nftCap: nftCap, vaultType: vaultType, balance:amount)
			let saleItemCollection= from.borrow() ?? panic("Could not borrow sale item for id=".concat(uuid.toString()))

			let callbackCapability =self.owner!.getCapability<&MarketBidCollection{MarketBidCollectionPublic}>(self.getTenant().getPublicPath(Type<@MarketBidCollection>()))
			let oldToken <- self.bids[uuid] <- bid
			saleItemCollection.registerBid(item: item, callback: callbackCapability, vaultType: vaultType) 
			destroy oldToken
		}

		pub fun fulfillAuction(id:UInt64, vault: @FungibleToken.Vault) {
			pre {
				self.bids[id] != nil : "You need to have a bid here already"
			}
			let bid =self.borrowBid(id)
			let saleItem=bid.from.borrow()!
			saleItem.fulfillAuction(id:id, vault: <- vault)
		}

		//increase a bid, will not work if the auction has already started
		pub fun increaseBid(id: UInt64, increaseBy: UFix64) {
			pre {
				self.bids[id] != nil : "You need to have a bid here already"
			}
			let bid =self.borrowBid(id)

			let oldBalance=bid.balance 

			bid.setBidAt(Clock.time())
			bid.setBalance(bid.balance + increaseBy)

			bid.from.borrow()!.registerIncreasedBid(id, oldBalance: oldBalance)
		}

		//called from saleItem when things are cancelled 
		//if the bid is canceled from seller then we move the vault tokens back into your vault
		access(contract) fun cancelBidFromSaleItem(_ id: UInt64) {
			let bid <- self.bids.remove(key: id) ?? panic("missing bid")
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
			pre {
				self.bids[id] != nil : "You need to have a bid here already"
			}
			let bid= self.borrowBid(id)
			return bid.balance
		}

		destroy() {
			destroy self.bids
		}
	}

	//Create an empty lease collection that store your leases to a name
	pub fun createEmptySaleItemCollection(_ tenantCapability: Capability<&FindMarketTenant.Tenant{FindMarketTenant.TenantPublic}>): @SaleItemCollection {
		let wallet=FindMarketAuctionSoft.account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
		return <- create SaleItemCollection(tenantCapability)
	}

	pub fun createEmptyMarketBidCollection(receiver: Capability<&{FungibleToken.Receiver}>, tenantCapability: Capability<&FindMarketTenant.Tenant{FindMarketTenant.TenantPublic}>) : @MarketBidCollection {
		return <- create MarketBidCollection(receiver: receiver, tenantCapability:tenantCapability)
	}

	pub fun getFindSaleItemCapability(_ user: Address) : Capability<&SaleItemCollection{SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>? {
		return FindMarketAuctionSoft.getSaleItemCapability(marketplace: FindMarketAuctionSoft.account.address, user:user) 
	}

	pub fun getFindBidCapability(_ user: Address) :Capability<&MarketBidCollection{MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>? {
		return FindMarketAuctionSoft.getBidCapability(marketplace:FindMarketAuctionSoft.account.address, user:user) 
	}

	pub fun getSaleItemCapability(marketplace:Address, user:Address) : Capability<&SaleItemCollection{SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>? {
		pre{
			FindMarketTenant.getTenantCapability(marketplace) != nil : "Invalid tenant"
		}
		if let tenant=FindMarketTenant.getTenantCapability(marketplace)!.borrow() {
			return getAccount(user).getCapability<&SaleItemCollection{SaleItemCollectionPublic, FindMarket.SaleItemCollectionPublic}>(tenant.getPublicPath(Type<@SaleItemCollection>()))
		}
		return nil
	}

	pub fun getBidCapability( marketplace:Address, user:Address) : Capability<&MarketBidCollection{MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>? {
		pre{
			FindMarketTenant.getTenantCapability(marketplace) != nil : "Invalid tenant"
		}
		if let tenant=FindMarketTenant.getTenantCapability(marketplace)!.borrow() {
			return getAccount(user).getCapability<&MarketBidCollection{MarketBidCollectionPublic, FindMarket.MarketBidCollectionPublic}>(tenant.getPublicPath(Type<@MarketBidCollection>()))
		}
		return nil
	}
}
