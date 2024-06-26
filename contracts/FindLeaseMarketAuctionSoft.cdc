import FungibleToken from "./standard/FungibleToken.cdc"
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import Clock from "./Clock.cdc"
import FIND from "./FIND.cdc"
import FindMarket from "./FindMarket.cdc"
import FindLeaseMarket from "./FindLeaseMarket.cdc"

// An auction saleItem contract that escrows the FT, does _not_ escrow the NFT
pub contract FindLeaseMarketAuctionSoft {

	pub event EnglishAuction(tenant: String, id: UInt64, saleID: UInt64, seller: Address, sellerName:String?, amount: UFix64, auctionReservePrice: UFix64, status: String, vaultType:String, leaseInfo:FindLeaseMarket.LeaseInfo?, buyer:Address?, buyerName:String?, buyerAvatar:String?, endsAt: UFix64?, previousBuyer:Address?, previousBuyerName:String?)

	pub resource SaleItem : FindLeaseMarket.SaleItem {
		access(contract) var pointer: FindLeaseMarket.AuthLeasePointer
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
		access(contract) var saleItemExtraField: {String : AnyStruct}

		init(pointer: FindLeaseMarket.AuthLeasePointer, vaultType: Type, auctionStartPrice:UFix64, auctionReservePrice:UFix64, auctionValidUntil: UFix64?, saleItemExtraField: {String : AnyStruct}) {
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
		}

		//Here we do not get a vault back, it is sent in to the method itself
		pub fun acceptNonEscrowedBid() {
			pre{
				self.offerCallback != nil : "There is no bid offer to the item."
				self.offerCallback!.check() : "Bidder unlinked bid collection capability."
			}
			self.offerCallback!.borrow()!.accept(self.getLeaseName())
			self.pointer.move(to: self.offerCallback!.address)
		}

		pub fun getBalance() : UFix64 {
			if let cb= self.offerCallback {
				return cb.borrow()?.getBalance(self.getLeaseName()) ?? panic("Bidder unlinked bid collection capability. bidder address : ".concat(cb.address.toString()))
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

		pub fun getId() : UInt64{
			return self.pointer.getUUID()
		}

		pub fun getBuyerName() : String? {
			if let cb= self.offerCallback {
				return FIND.reverseLookup(cb.address)
			}
			return nil
		}

		pub fun toLeaseInfo() : FindLeaseMarket.LeaseInfo {
			return FindLeaseMarket.LeaseInfo(self.pointer)
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

		pub fun getListingTypeIdentifier() : String {
			return Type<@SaleItem>().identifier
		}

		pub fun getLeaseName() : String {
			return self.pointer.name
		}

		pub fun getItemType() : Type {
			return Type<@FIND.Lease>()
		}

		pub fun getAuction(): FindLeaseMarket.AuctionItem? {
			return FindLeaseMarket.AuctionItem(startPrice: self.auctionStartPrice,
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

	}

	pub resource interface SaleItemCollectionPublic {
		//fetch all the tokens in the collection
		pub fun getNameSales(): [String]
		pub fun containsNameSale(_ name: String): Bool
		access(contract) fun registerIncreasedBid(_ name: String, oldBalance: UFix64)

		//place a bid on a token
		access(contract) fun registerBid(name: String, callback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>, vaultType:Type)

		//only buyer can fulfill auctions since he needs to send funds for this type
		access(contract) fun fulfillAuction(name: String, vault: @FungibleToken.Vault)
	}

	pub resource SaleItemCollection: SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic  {
		//is this the best approach now or just put the NFT inside the saleItem?
		access(contract) var items: @{String: SaleItem}

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

		access(self) fun emitEvent(saleItem: &SaleItem, status: String,previousBuyer:Address?) {
			let owner=saleItem.getSeller()
			let ftType=saleItem.getFtType()
			let balance=saleItem.getBalance()
			let seller=saleItem.getSeller()
			let name=saleItem.getLeaseName()
			let buyer=saleItem.getBuyer()

			var leaseInfo:FindLeaseMarket.LeaseInfo?=nil
			if saleItem.checkPointer() {
				leaseInfo=saleItem.toLeaseInfo()
			}

			var previousBuyerName : String?=nil
			if let pb= previousBuyer {
				previousBuyerName = FIND.reverseLookup(pb)
			}

			if buyer != nil {
				let buyerName=FIND.reverseLookup(buyer!)
				let profile = FIND.lookup(buyer!.toString())
				emit EnglishAuction(tenant:self.getTenant().name, id: saleItem.getId(), saleID: saleItem.uuid, seller:seller, sellerName: FIND.reverseLookup(seller), amount: balance, auctionReservePrice: saleItem.auctionReservePrice,  status: status, vaultType:saleItem.vaultType.identifier, leaseInfo: leaseInfo,  buyer: buyer, buyerName: buyerName, buyerAvatar: profile?.getAvatar(), endsAt: saleItem.auctionEndsAt, previousBuyer:previousBuyer, previousBuyerName:previousBuyerName)
			} else {
				emit EnglishAuction(tenant:self.getTenant().name, id: saleItem.getId(), saleID: saleItem.uuid, seller:seller, sellerName: FIND.reverseLookup(seller), amount: balance, auctionReservePrice: saleItem.auctionReservePrice,  status: status, vaultType:saleItem.vaultType.identifier, leaseInfo: leaseInfo,  buyer: nil, buyerName: nil, buyerAvatar: nil, endsAt: saleItem.auctionEndsAt, previousBuyer:previousBuyer, previousBuyerName:previousBuyerName)
			}
		}

		pub fun getListingType() : Type {
			return Type<@SaleItem>()
		}

		access(self) fun addBid(name:String, newOffer: Capability<&MarketBidCollection{MarketBidCollectionPublic}>, oldBalance: UFix64) {
			let saleItem=self.borrow(name)

			let actionResult=self.getTenant().allowedAction(listingType: self.getListingType(), nftType: saleItem.getItemType(), ftType: saleItem.getFtType(), action: FindMarket.MarketAction(listing:false, name:"add bit in soft-auction"), seller: self.owner!.address ,buyer: newOffer.address)

			if !actionResult.allowed {
				panic(actionResult.message)
			}

			let timestamp=Clock.time()
			let newOfferBalance=newOffer.borrow()?.getBalance(name) ?? panic("The new offer bid capability is invalid.")

			let previousOffer = saleItem.offerCallback!


			var minBid=oldBalance + saleItem.auctionMinBidIncrement
			if newOffer.address != previousOffer.address {
				let previousBalance = previousOffer.borrow()?.getBalance(name) ?? panic("Previous bidder unlinked the bid ccollection capability. bidder address : ".concat(previousOffer.address.toString()))
				minBid = previousBalance + saleItem.auctionMinBidIncrement
			}

			if newOfferBalance < minBid {
				panic("bid ".concat(newOfferBalance.toString()).concat(" must be larger then previous bid+bidIncrement ").concat(minBid.toString()))
			}

			var previousBuyer:Address?=nil
			if newOffer.address != previousOffer.address {
				previousOffer.borrow()!.cancelBidFromSaleItem(name)
				previousBuyer=previousOffer.address
			}

			saleItem.setCallback(newOffer)

			let suggestedEndTime=timestamp+saleItem.auctionExtensionOnLateBid

			if suggestedEndTime > saleItem.auctionEndsAt! {
				saleItem.setAuctionEnds(suggestedEndTime)
			}
			self.emitEvent(saleItem: saleItem, status: "active_ongoing", previousBuyer:previousBuyer)

		}

		access(contract) fun registerIncreasedBid(_ name: String, oldBalance:UFix64) {
			pre {
				self.items.containsKey(name) : "Invalid lease name=".concat(name)
			}

			let saleItem=self.borrow(name)

			if !saleItem.hasAuctionStarted()  {
				panic("Auction is not started")
			}

			if saleItem.hasAuctionEnded() {
				panic("Auction has ended")
			}

			self.addBid(name: name, newOffer: saleItem.offerCallback!, oldBalance: oldBalance)

		}

		//This is a function that buyer will call (via his bid collection) to register the bicCallback with the seller
		access(contract) fun registerBid(name: String, callback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>, vaultType: Type) {

			let timestamp=Clock.time()

			let name = name

			let saleItem=self.borrow(name)
			if saleItem.hasAuctionStarted() {
				if saleItem.hasAuctionEnded() {
					panic("Auction has ended")
				}

				if let cb = saleItem.offerCallback {
					if cb.address == callback.address {
						panic("You already have the latest bid on this item, use the incraseBid transaction")
					}
				}

				self.addBid(name: name, newOffer: callback, oldBalance: 0.0)
				return
			}

			let actionResult=self.getTenant().allowedAction(listingType: self.getListingType(), nftType: saleItem.getItemType(), ftType: saleItem.getFtType(), action: FindMarket.MarketAction(listing:false, name:"bid item in soft-auction"), seller: self.owner!.address, buyer: callback.address)

			if !actionResult.allowed {
				panic(actionResult.message)
			}

			let balance=callback.borrow()?.getBalance(name) ?? panic("Bidder unlinked the bid collection capability. bidder address : ".concat(callback.address.toString()))

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

			self.emitEvent(saleItem: saleItem, status: "active_ongoing", previousBuyer:nil)
		}

		pub fun cancel(_ name: String) {
			pre {
				self.items.containsKey(name) : "Invalid lease name=".concat(name)
			}

			let saleItem=self.borrow(name)

			var status="cancel"
			if saleItem.checkPointer() {
				if saleItem.hasAuctionStarted() && saleItem.hasAuctionEnded() {
					if saleItem.hasAuctionMetReservePrice() {
						panic("Cannot cancel finished auction, fulfill it instead")
					}
					status="cancel_reserved_not_met"

				}
			} else {
				status="cancel_ghostlisting"
			}
			let actionResult=self.getTenant().allowedAction(listingType: self.getListingType(), nftType: saleItem.getItemType(), ftType: saleItem.getFtType(), action: FindMarket.MarketAction(listing:false, name:"delist item from soft-auction"), seller: nil, buyer: nil)

			if !actionResult.allowed {
				panic(actionResult.message)
			}

			self.emitEvent(saleItem: saleItem, status: status, previousBuyer:nil)

			if saleItem.offerCallback != nil && saleItem.offerCallback!.check() {
				saleItem.offerCallback!.borrow()!.cancelBidFromSaleItem(name)
			}

			destroy <- self.items.remove(key: name)
		}


		access(contract) fun fulfillAuction(name: String, vault: @FungibleToken.Vault) {
			pre {
				self.items.containsKey(name) : "Invalid lease name=".concat(name)
			}

			let saleItem = self.borrow(name)

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

			let actionResult=self.getTenant().allowedAction(listingType: self.getListingType(), nftType: saleItem.getItemType(), ftType: saleItem.getFtType(), action: FindMarket.MarketAction(listing:false, name:"buy item for soft-auction"), seller: self.owner!.address,buyer: saleItem.offerCallback!.address)

			if !actionResult.allowed {
				panic(actionResult.message)
			}

			let cuts= self.getTenant().getCuts(name: actionResult.name, listingType: self.getListingType(), nftType: saleItem.getItemType(), ftType: saleItem.getFtType())


			let leaseInfo=saleItem.toLeaseInfo()

			self.emitEvent(saleItem: saleItem, status: "sold", previousBuyer:nil)
			saleItem.acceptNonEscrowedBid()

			FindLeaseMarket.pay(tenant:self.getTenant().name, leaseName:name, saleItem: saleItem, vault: <- vault, leaseInfo:leaseInfo, cuts:cuts)

			destroy <- self.items.remove(key: name)

		}

		pub fun listForAuction(pointer: FindLeaseMarket.AuthLeasePointer, vaultType: Type, auctionStartPrice: UFix64, auctionReservePrice: UFix64, auctionDuration: UFix64, auctionExtensionOnLateBid: UFix64, minimumBidIncrement: UFix64, auctionValidUntil: UFix64?, saleItemExtraField: {String : AnyStruct}) {

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

			let saleItem <- create SaleItem(pointer: pointer, vaultType:vaultType, auctionStartPrice: auctionStartPrice, auctionReservePrice:auctionReservePrice, auctionValidUntil: auctionValidUntil, saleItemExtraField: saleItemExtraField)

			let actionResult=self.getTenant().allowedAction(listingType: self.getListingType(), nftType: saleItem.getItemType(), ftType: saleItem.getFtType(), action: FindMarket.MarketAction(listing:true, name:"list item for soft-auction"), seller: self.owner!.address, buyer: nil)

			if !actionResult.allowed {
				panic(actionResult.message)
			}

			assert(self.items[pointer.name] == nil , message: "Auction listing for this item is already created.")

			saleItem.setAuctionDuration(auctionDuration)
			saleItem.setExtentionOnLateBid(auctionExtensionOnLateBid)
			saleItem.setMinBidIncrement(minimumBidIncrement)
			self.items[pointer.name] <-! saleItem
			let saleItemRef = self.borrow(pointer.name)
			self.emitEvent(saleItem: saleItemRef, status: "active_listed", previousBuyer:nil)
		}

		pub fun getNameSales(): [String] {
			return self.items.keys
		}

		pub fun containsNameSale(_ name: String): Bool {
			return self.items.containsKey(name)
		}

		pub fun borrow(_ name: String): &SaleItem {
			pre{
				self.items.containsKey(name) : "This name sale does not exist.".concat(name)
			}
			return (&self.items[name] as &SaleItem?)!
		}

		pub fun borrowSaleItem(_ name: String) : &{FindLeaseMarket.SaleItem} {
			pre{
				self.items.containsKey(name) : "This name sale does not exist.".concat(name)
			}
			return (&self.items[name] as &SaleItem{FindLeaseMarket.SaleItem}?)!
		}

		destroy() {
			destroy self.items
		}
	}

	pub resource Bid : FindLeaseMarket.Bid {
		access(contract) let from: Capability<&SaleItemCollection{SaleItemCollectionPublic}>
		access(contract) let leaseName: String

		access(contract) let vaultType: Type
		access(contract) var bidAt: UFix64
		access(contract) var balance: UFix64
		access(contract) let bidExtraField: {String : AnyStruct}

		init(from: Capability<&SaleItemCollection{SaleItemCollectionPublic}>, leaseName: String, vaultType:Type,  balance:UFix64, bidExtraField: {String : AnyStruct}){
			self.vaultType= vaultType
			self.balance=balance
			self.leaseName=leaseName
			self.from=from
			self.bidAt=Clock.time()
			self.bidExtraField=bidExtraField
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

		pub fun getBidExtraField() : {String : AnyStruct} {
			return self.bidExtraField
		}
	}

	pub resource interface MarketBidCollectionPublic {
		pub fun getBalance(_ name: String) : UFix64
		pub fun containsNameBid(_ name: String): Bool
		access(contract) fun accept(_ name: String)
		access(contract) fun cancelBidFromSaleItem(_ name: String)
	}

	//A collection stored for bidders/buyers
	pub resource MarketBidCollection: MarketBidCollectionPublic, FindLeaseMarket.MarketBidCollectionPublic {

		access(contract) var bids : @{String: Bid}
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
		access(contract) fun accept(_ name: String) {
			pre {
				self.bids[name] != nil : "You need to have a bid here already"
			}

			let bid <- self.bids.remove(key: name) ?? panic("missing bid")
			destroy bid
		}

		pub fun getNameBids() : [String] {
			return self.bids.keys
		}

		pub fun containsNameBid(_ name: String) : Bool {
			return self.bids.containsKey(name)
		}

		pub fun getBidType() : Type {
			return Type<@Bid>()
		}

		pub fun bid(name: String, amount:UFix64, vaultType:Type, bidExtraField: {String : AnyStruct}) {
			pre {
				self.owner!.address != FIND.status(name).owner!  : "You cannot bid on your own resource"
				self.bids[name] == nil : "You already have an bid for this item, use increaseBid on that bid"
			}

			let from=getAccount(FIND.status(name).owner!).getCapability<&SaleItemCollection{SaleItemCollectionPublic}>(self.getTenant().getPublicPath(Type<@SaleItemCollection>()))

			let bid <- create Bid(from: from, leaseName:name, vaultType: vaultType, balance:amount, bidExtraField: bidExtraField)
			let saleItemCollection= from.borrow() ?? panic("Could not borrow sale item for lease name=".concat(name))

			let callbackCapability =self.owner!.getCapability<&MarketBidCollection{MarketBidCollectionPublic}>(self.getTenant().getPublicPath(Type<@MarketBidCollection>()))
			let oldToken <- self.bids[name] <- bid
			saleItemCollection.registerBid(name: name, callback: callbackCapability, vaultType: vaultType)
			destroy oldToken
		}

		pub fun fulfillAuction(name:String, vault: @FungibleToken.Vault) {
			pre {
				self.bids[name] != nil : "You need to have a bid here already"
			}
			let bid =self.borrowBid(name)
			let saleItem=bid.from.borrow()!
			saleItem.fulfillAuction(name:name, vault: <- vault)
		}

		//increase a bid, will not work if the auction has already started
		pub fun increaseBid(name: String, increaseBy: UFix64) {
			pre {
				self.bids[name] != nil : "You need to have a bid here already"
			}
			let bid =self.borrowBid(name)

			let oldBalance=bid.balance

			bid.setBidAt(Clock.time())
			bid.setBalance(bid.balance + increaseBy)

			if !bid.from.check(){
				panic("Seller unlinked the SaleItem collection capability. seller address : ".concat(bid.from.address.toString()))
			}
			bid.from.borrow()!.registerIncreasedBid(name, oldBalance: oldBalance)
		}

		//called from saleItem when things are cancelled
		//if the bid is canceled from seller then we move the vault tokens back into your vault
		access(contract) fun cancelBidFromSaleItem(_ name: String) {
			let bid <- self.bids.remove(key: name) ?? panic("missing bid")
			destroy bid
		}

		pub fun borrowBid(_ name: String): &Bid {
			pre{
				self.bids.containsKey(name) : "This name lease bid does not exist.".concat(name)
			}
			return (&self.bids[name] as &Bid?)!
		}

		pub fun borrowBidItem(_ name: String): &{FindLeaseMarket.Bid} {
			pre{
				self.bids.containsKey(name) : "This name lease bid does not exist.".concat(name)
			}
			return (&self.bids[name] as &Bid{FindLeaseMarket.Bid}?)!
		}

		pub fun getBalance(_ name: String) : UFix64 {
			pre {
				self.bids[name] != nil : "You need to have a bid here already"
			}
			let bid= self.borrowBid(name)
			return bid.balance
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

	pub fun getSaleItemCapability(marketplace:Address, user:Address) : Capability<&SaleItemCollection{SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>? {
		pre{
			FindMarket.getTenantCapability(marketplace) != nil : "Invalid tenant"
		}
		if let tenant=FindMarket.getTenantCapability(marketplace)!.borrow() {
			return getAccount(user).getCapability<&SaleItemCollection{SaleItemCollectionPublic, FindLeaseMarket.SaleItemCollectionPublic}>(tenant.getPublicPath(Type<@SaleItemCollection>()))
		}
		return nil
	}

	pub fun getBidCapability( marketplace:Address, user:Address) : Capability<&MarketBidCollection{MarketBidCollectionPublic, FindLeaseMarket.MarketBidCollectionPublic}>? {
		pre{
			FindMarket.getTenantCapability(marketplace) != nil : "Invalid tenant"
		}
		if let tenant=FindMarket.getTenantCapability(marketplace)!.borrow() {
			return getAccount(user).getCapability<&MarketBidCollection{MarketBidCollectionPublic, FindLeaseMarket.MarketBidCollectionPublic}>(tenant.getPublicPath(Type<@MarketBidCollection>()))
		}
		return nil
	}

	init() {
		FindLeaseMarket.addSaleItemType(Type<@SaleItem>())
		FindLeaseMarket.addSaleItemCollectionType(Type<@SaleItemCollection>())
		FindLeaseMarket.addMarketBidType(Type<@Bid>())
		FindLeaseMarket.addMarketBidCollectionType(Type<@MarketBidCollection>())
	}

}
