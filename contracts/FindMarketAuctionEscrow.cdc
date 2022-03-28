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

/*

An auction contract where the FT is escrowed but the NFT is a pointer. 
It is not possible to have an escrowed NFT auction until the standard has progressed more
*/
pub contract FindMarketAuctionEscrow {

	pub event ForAuction(tenant: String, id: UInt64, seller: Address, sellerName:String?, amount: UFix64, auctionReservePrice: UFix64, status: String, vaultType:String, nft:FindMarket.NFTInfo, buyer:Address?, buyerName:String?, endsAt: UFix64?)


	pub resource SaleItem : FindMarket.SaleItem {
		access(contract) var pointer: AnyStruct{FindViews.Pointer}

		access(contract) var vaultType: Type
		access(contract) var auctionStartPrice: UFix64
		access(contract) var auctionReservePrice: UFix64
		access(contract) var auctionDuration: UFix64
		access(contract) var auctionMinBidIncrement: UFix64
		access(contract) var auctionExtensionOnLateBid: UFix64
		access(contract) var auctionStartedAt: UFix64?
		access(contract) var auctionEndsAt: UFix64?
		access(contract) var offerCallback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>?

		init(pointer: AnyStruct{FindViews.Pointer}, vaultType: Type, auctionStartPrice:UFix64, auctionReservePrice:UFix64) {
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

		pub fun getId() : UInt64{
			return self.pointer.getUUID()
		}

		pub fun acceptEscrowedBid() : @FungibleToken.Vault {
			let pointer= self.pointer as! FindViews.AuthNFTPointer
			let vault <- self.offerCallback!.borrow()!.accept(<- pointer.withdraw())
			return <- vault
		}

		pub fun getRoyalty() : MetadataViews.Royalties? {
			if self.pointer.getViews().contains(Type<MetadataViews.Royalties>()) {
				return self.pointer.resolveView(Type<MetadataViews.Royalties>())! as! MetadataViews.Royalties
			}

			return  nil
		}

		pub fun getBalance() : UFix64 {
			if let cb= self.offerCallback {
				return cb.borrow()!.getBalance(self.getId())
			}
			return 0.0
		}

		pub fun getSeller() : Address {
			return self.pointer.owner()
		}

		pub fun getBuyer() : Address? {
			if let cb= self.offerCallback {
				return cb.address
			}
			return nil
		}

		pub fun toNFTInfo() : FindMarket.NFTInfo{
			return FindMarket.NFTInfo(self.pointer.getViewResolver())
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

			return balance >= self.auctionReservePrice!
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
				return "ongoing_auction"
			}
			return "ondemand_auction"
		}


		pub fun getItemID() : UInt64 {
			return self.pointer.id
		}

		pub fun getItemType() : Type {
			return self.pointer.getItemType()
		}

		pub fun getAuction(): AnyStruct{FindMarket.AuctionItem}? {
			return AuctionItem(reservePrice: self.auctionReservePrice, extentionOnLateBid: self.auctionExtensionOnLateBid)
		}

		pub fun getFtType() : Type {
			return self.vaultType
		}

		pub fun getValidUntil() : UFix64? {
			return self.auctionEndsAt

		}
	}

	pub struct AuctionItem : FindMarket.AuctionItem{

		pub let reservePrice: UFix64
		pub let extentionOnLateBid:UFix64 

		init(reservePrice:UFix64, extentionOnLateBid: UFix64) {
			self.reservePrice=reservePrice
			self.extentionOnLateBid=extentionOnLateBid
		}
		pub fun getReservePrice(): UFix64  {
			return self.reservePrice
		}
		pub fun getExtentionOnLateBid(): UFix64 {
			return self.extentionOnLateBid
		}
	}


	pub resource interface SaleItemCollectionPublic {
		//fetch all the tokens in the collection
		pub fun getIds(): [UInt64]
		//fetch all names that are for sale

		pub fun getItemsForSale(): [FindMarket.SaleItemInformation]

		pub fun getItemForSaleInformation(_ id:UInt64) : FindMarket.SaleItemInformation 

		access(contract)fun cancelBid(_ id: UInt64) 
		access(contract) fun registerIncreasedBid(_ id: UInt64) 

		//place a bid on a token
		access(contract) fun registerBid(item: FindViews.ViewReadPointer, callback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>, vaultType:Type)

		//anybody should be able to fulfill an auction as long as it is done
		pub fun fulfillAuction(_ id: UInt64) 
	}

	pub resource SaleItemCollection: SaleItemCollectionPublic {
		//is this the best approach now or just put the NFT inside the saleItem?
		access(contract) var items: @{UInt64: SaleItem}

		access(contract) let tenant: FindMarket.TenantInformation
		init (_ tenant: &FindMarket.Tenant) {
			self.items <- {}
			self.tenant=tenant.information
		}

		pub fun getItemForSaleInformation(_ id:UInt64) : FindMarket.SaleItemInformation {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
			}
			return FindMarket.SaleItemInformation(self.borrow(id))

		}

		pub fun getItemsForSale(): [FindMarket.SaleItemInformation] {
			let info: [FindMarket.SaleItemInformation] =[]
			for id in self.getIds() {
				info.append(FindMarket.SaleItemInformation(self.borrow(id)))
			}
			return info
		}

		pub fun startAuction(_ id: UInt64) {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
			}
			let timestamp=Clock.time()
			let saleItem = self.borrow(id)
			let duration=saleItem.auctionDuration
			let extensionOnLateBid=saleItem.auctionExtensionOnLateBid
			if saleItem.offerCallback == nil {
				panic("No bid registered for item, cannot start auction without a bid")
			}

			let nftInfo= saleItem.toNFTInfo()
			let callback=saleItem.offerCallback!
			let offer=callback.borrow()!
			let buyer=callback.address
			let balance=offer.getBalance(id)
			let owner=self.owner!.address
			let endsAt=timestamp + duration

			emit ForAuction(tenant:self.tenant.name, id: id, seller:owner, sellerName: FIND.reverseLookup(owner), amount: balance, auctionReservePrice: saleItem.auctionReservePrice,  status: "active", vaultType:saleItem.vaultType.identifier, nft: nftInfo,  buyer: buyer, buyerName: FIND.reverseLookup(buyer), endsAt: endsAt)
			saleItem.setAuctionStarted(timestamp)
			saleItem.setAuctionEnds(endsAt)
		}

		access(self) fun addBid(id:UInt64, newOffer: Capability<&MarketBidCollection{MarketBidCollectionPublic}>) {
			let saleItem=self.borrow(id)

			if saleItem.auctionStartedAt == nil {
				panic("cannot add bid to an sale item that is not an ongoing auction")
			}
			let timestamp=Clock.time()

			let newOfferBalance=newOffer.borrow()!.getBalance(id)

			let previousOffer = saleItem.offerCallback!
			let previousBalance=previousOffer.borrow()!.getBalance(id) 

			if newOffer.address != previousOffer.address {
				let minBid=previousBalance + saleItem.auctionMinBidIncrement

				if newOfferBalance < minBid {
					panic("bid ".concat(newOfferBalance.toString()).concat(" must be larger then previous bid+bidIncrement").concat(minBid.toString()))
				}
				previousOffer.borrow()!.cancelBidFromSaleItem(id)
			}
			saleItem.setCallback(newOffer)

			let suggestedEndTime=timestamp+saleItem.auctionExtensionOnLateBid

			if suggestedEndTime > saleItem.auctionEndsAt! {
				saleItem.setAuctionEnds(suggestedEndTime)
			}

			let seller=saleItem.getSeller()
			let buyer=saleItem.getBuyer()!
			let nftInfo=saleItem.toNFTInfo()

			emit ForAuction(tenant:self.tenant.name, id: id, seller:seller, sellerName: FIND.reverseLookup(seller), amount: newOfferBalance, auctionReservePrice: saleItem.auctionReservePrice!,  status: "active", vaultType:saleItem.vaultType.identifier, nft: nftInfo,  buyer: buyer, buyerName: FIND.reverseLookup(buyer), endsAt: saleItem.auctionEndsAt)

		}

		//TODO: here we know it is your bid
		//TODO: branch out earlier here in bids for sale/direct_offer/auction
		access(contract) fun registerIncreasedBid(_ id: UInt64) {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
			}

			let saleItem=self.borrow(id)
			
			let timestamp=Clock.time()

			if saleItem.auctionEndsAt != nil {
				if saleItem.auctionEndsAt! < timestamp {
					panic("Auction has ended")
				}
				//TODO: is this right? get the same item and send it in again?
				self.addBid(id: id, newOffer: saleItem.offerCallback!)
				return
			}

			//TODO: this has to be wrong?
		//	self.startAuction(id)
		}


		//This is a function that buyer will call (via his bid collection) to register the bicCallback with the seller
		access(contract) fun registerBid(item: FindViews.ViewReadPointer, callback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>, vaultType: Type) {

			//TODO: check that bid is there
			let timestamp=Clock.time()

			let id = item.getUUID()

			let saleItem=self.borrow(id)
			if saleItem.auctionEndsAt != nil {
				//TODO: if this tenantn does not support auctions panic here
				if saleItem.hasAuctionEnded() {
					panic("Auction has ended")
				}
				self.addBid(id: id, newOffer: callback)
				return
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
			self.startAuction(id)
		}

		//cancel will cancel and auction or reject a bid if no auction has started
		pub fun cancel(_ id: UInt64) {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
			}
			//TODO: what to do here if auction s  active?
			let saleItem=self.borrow(id)
			let owner=saleItem.getSeller()
			if saleItem.auctionEndsAt != nil {
				let balance=saleItem.getBalance()
				let price= saleItem.auctionReservePrice.toString()

				let nftInfo=saleItem.toNFTInfo()
				//the auction has ended
				Debug.log("Latest bid is ".concat(balance.toString()).concat(" reserve price is ").concat(price))
				if saleItem.hasAuctionEnded() && saleItem.hasAuctionMetReservePrice() {
					panic("Cannot cancel finished auction, fulfill it instead")
				}

				emit ForAuction(tenant:self.tenant.name, id: id, seller:owner, sellerName: FIND.reverseLookup(owner), amount: balance, auctionReservePrice: saleItem.auctionReservePrice!,  status: "cancelled", vaultType:saleItem.vaultType.identifier, nft: nftInfo,  buyer: saleItem.getBuyer(), buyerName: FIND.reverseLookup(saleItem.getBuyer()!), endsAt: Clock.time())

				//ESCROW: this can be added back again once we can escrow NFTS again
				//saleItem.returnNFT()
				saleItem.offerCallback!.borrow()!.cancelBidFromSaleItem(id)
				destroy <- self.items.remove(key: id)
			}
		}

		
		/// fulfillAuction wraps the fulfill method and ensure that only a finished auction can be fulfilled by anybody
		pub fun fulfillAuction(_ id: UInt64) {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
				self.borrow(id).auctionStartPrice != nil : "Cannot fulfill sale that is not an auction=".concat(id.toString())
			}

			let saleItem = self.borrow(id)
			if !saleItem.hasAuctionEnded() {
				panic("Auction has not ended yet")
			}

			if !saleItem.hasAuctionMetReservePrice() {
				self.cancel(id)
				return
			}

			let ftType=saleItem.vaultType
			let owner=saleItem.getSeller()
			let nftInfo= saleItem.toNFTInfo()
			let royalty=saleItem.getRoyalty()
			let buyer=saleItem.getBuyer()!
			let pointer= saleItem.pointer as! FindViews.AuthNFTPointer
			let soldFor=saleItem.getBalance()

			emit ForAuction(tenant:self.tenant.name, id: id, seller:owner, sellerName: FIND.reverseLookup(owner), amount: soldFor, auctionReservePrice: saleItem.auctionReservePrice!,  status:"sold", vaultType: ftType.identifier, nft:nftInfo, buyer: buyer, buyerName:FIND.reverseLookup(buyer), endsAt: Clock.time())

			//ESCROW: add this back once we can escrow item again
			//let nft <- saleItem.getEscrow()
			let vault <- saleItem.acceptEscrowedBid()
			FindMarket.pay(tenant:self.tenant, id:id, saleItem: saleItem, vault: <- vault, royalty:royalty, nftInfo:nftInfo)

			destroy <- self.items.remove(key: id)

		} 




		pub fun listForAuction(pointer: FindViews.AuthNFTPointer, vaultType: Type, auctionStartPrice: UFix64, auctionReservePrice: UFix64, auctionDuration: UFix64, auctionExtensionOnLateBid: UFix64, minimumBidIncrement: UFix64) {

			let saleItem <- create SaleItem(pointer: pointer, vaultType:vaultType, auctionStartPrice: auctionStartPrice, auctionReservePrice:auctionReservePrice)

			saleItem.setAuctionDuration(auctionDuration)
			saleItem.setExtentionOnLateBid(auctionExtensionOnLateBid)
			saleItem.setMinBidIncrement(minimumBidIncrement)

			emit ForAuction(tenant:self.tenant.name, id: pointer.getUUID(), seller:self.owner!.address, sellerName: FIND.reverseLookup(self.owner!.address), amount: saleItem.auctionStartPrice, auctionReservePrice: saleItem.auctionReservePrice!,  status:"listed", vaultType:vaultType.identifier, nft: saleItem.toNFTInfo(), buyer: nil, buyerName:nil, endsAt: nil)

			self.items[pointer.getUUID()] <-! saleItem
		}

		pub fun getIds(): [UInt64] {
			return self.items.keys
		}

		pub fun borrow(_ id: UInt64): &SaleItem {
			return &self.items[id] as &SaleItem
		}

		destroy() {
			destroy self.items
		}
	}

	//TODO: can not be escrowed
	pub resource Bid {
		access(contract) let from: Capability<&SaleItemCollection{SaleItemCollectionPublic}>
		access(contract) let nftCap: Capability<&{NonFungibleToken.Receiver}>
		access(contract) let itemUUID: UInt64

		//this should reflect on what the above uuid is for
		access(contract) let vault: @FungibleToken.Vault
		access(contract) let vaultType: Type
		access(contract) var bidAt: UFix64

		init(from: Capability<&SaleItemCollection{SaleItemCollectionPublic}>, itemUUID: UInt64, vault: @FungibleToken.Vault, nftCap: Capability<&{NonFungibleToken.Receiver}>) {
			self.vaultType= vault.getType()
			self.vault <- vault
			self.itemUUID=itemUUID
			self.from=from
			self.bidAt=Clock.time()
			self.nftCap=nftCap
		}
		access(contract) fun setBidAt(_ time: UFix64) {
			self.bidAt=time
		}

		destroy() {
			destroy self.vault
		}
	}

	pub resource interface MarketBidCollectionPublic {
		pub fun getBids() : [FindMarket.BidInfo]
		pub fun getBalance(_ id: UInt64) : UFix64
		access(contract) fun accept(_ nft: @NonFungibleToken.NFT) : @FungibleToken.Vault
		access(contract) fun cancelBidFromSaleItem(_ id: UInt64)
	}

	//A collection stored for bidders/buyers
	pub resource MarketBidCollection: MarketBidCollectionPublic {

		access(contract) var bids : @{UInt64: Bid}
		access(contract) let receiver: Capability<&{FungibleToken.Receiver}>
		access(contract) let tenant: FindMarket.TenantInformation

		//not sure we can store this here anymore. think it needs to be in every bid
		init(receiver: Capability<&{FungibleToken.Receiver}>, tenant: &FindMarket.Tenant) {
			self.bids <- {}
			self.receiver=receiver
			self.tenant=tenant.information
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

		pub fun getBids() : [FindMarket.BidInfo] {
			var bidInfo: [FindMarket.BidInfo] = []
			for id in self.bids.keys {
				let bid = self.borrowBid(id)

				let saleInfo=bid.from.borrow()!.getItemForSaleInformation(id)
				bidInfo.append(FindMarket.BidInfo(id: bid.itemUUID, amount: bid.vault.balance, timestamp: bid.bidAt,item:saleInfo))
			}
			return bidInfo
		}

		pub fun bid(item: FindViews.ViewReadPointer, vault: @FungibleToken.Vault, nftCap: Capability<&{NonFungibleToken.Receiver}>) {
			pre {
				self.owner!.address != item.owner()  : "You cannot bid on your own resource"
				self.bids[item.getUUID()] == nil : "You already have an bid for this item, use increaseBid on that bid"
			}

			let uuid=item.getUUID()
			let from=getAccount(item.owner()).getCapability<&SaleItemCollection{SaleItemCollectionPublic}>(self.tenant.saleItemPublicPath)
			let vaultType=vault.getType()

			let bid <- create Bid(from: from, itemUUID:item.getUUID(), vault: <- vault, nftCap: nftCap)
			let saleItemCollection= from.borrow() ?? panic("Could not borrow sale item for id=".concat(uuid.toString()))
			let callbackCapability =self.owner!.getCapability<&MarketBidCollection{MarketBidCollectionPublic}>(self.tenant.bidPublicPath)
			let oldToken <- self.bids[uuid] <- bid
			saleItemCollection.registerBid(item: item, callback: callbackCapability, vaultType: vaultType) 
			destroy oldToken
		}

		pub fun fulfillAuction(id:UInt64) {
			pre {
				self.bids[id] != nil : "You need to have a bid here already"
			}
			let bid =self.borrowBid(id)
			let saleItem=bid.from.borrow()!
			saleItem.fulfillAuction(id)
		}

		//increase a bid, will not work if the auction has already started
		pub fun increaseBid(id: UInt64, vault: @FungibleToken.Vault) {
			let bid =self.borrowBid(id)
			bid.setBidAt(Clock.time())
			bid.vault.deposit(from: <- vault)

			//TODO: need to send in the old balance here first or verify that this is allowed here....
			bid.from.borrow()!.registerIncreasedBid(id)
		}

		//TODO: check out the semantics here
		/// The users cancel a bid himself
		pub fun cancelBid(_ id: UInt64) {
			let bid= self.borrowBid(id)
			bid.from.borrow()!.cancelBid(id)
			self.cancelBidFromSaleItem(id)
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
			return &self.bids[id] as &Bid
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
	pub fun createEmptySaleItemCollection(_ tenant: &FindMarket.Tenant): @SaleItemCollection {
		let wallet=FindMarketAuctionEscrow.account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
		return <- create SaleItemCollection(tenant)
	}

	pub fun createEmptyMarketBidCollection(receiver: Capability<&{FungibleToken.Receiver}>, tenant: &FindMarket.Tenant) : @MarketBidCollection {
		return <- create MarketBidCollection(receiver: receiver, tenant:tenant)
	}

	pub fun getFindSaleItemCapability(_ user: Address) : Capability<&SaleItemCollection{SaleItemCollectionPublic}>? {
		return FindMarketAuctionEscrow.getSaleItemCapability(marketplace: FindMarketAuctionEscrow.account.address, user:user) 
	}

	pub fun getFindBidCapability(_ user: Address) :Capability<&MarketBidCollection{MarketBidCollectionPublic}>? {
		return FindMarketAuctionEscrow.getBidCapability(marketplace:FindMarketAuctionEscrow.account.address, user:user) 
	}

	pub fun getSaleItemCapability(marketplace:Address, user:Address) : Capability<&SaleItemCollection{SaleItemCollectionPublic}>? {
		if let tenant=FindMarket.getTenant(marketplace) {
			return getAccount(user).getCapability<&SaleItemCollection{SaleItemCollectionPublic}>(tenant.getPublicPath(Type<@SaleItemCollection>())!)
		}
		return nil
	}

	pub fun getBidCapability( marketplace:Address, user:Address) : Capability<&MarketBidCollection{MarketBidCollectionPublic}>? {
		if let tenant=FindMarket.getTenant(marketplace) {
			return getAccount(user).getCapability<&MarketBidCollection{MarketBidCollectionPublic}>(tenant.getPublicPath(Type<@MarketBidCollection>())!)
		}
		return nil
	}
}
