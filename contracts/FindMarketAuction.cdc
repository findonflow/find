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
This is a contract for Auctions where neither the NFT or the FT is escrowed. 

The only possible usecase for this is for use with DUC that does not allow escrow of FT
*/
pub contract FindMarketAuction {

	pub event ForAuction(tenant: String, id: UInt64, seller: Address, sellerName:String?, amount: UFix64, auctionReservePrice: UFix64, status: String, vaultType:String, nft:NFTInfo, buyer:Address?, buyerName:String?, endsAt: UFix64?)


	pub resource SaleItem{

		access(contract) let vaultType: Type //The type of vault to use for this sale Item
		access(contract) var pointer: AnyStruct{FindViews.Pointer}

		access(contract) var auctionStartPrice: UFix64?
		access(contract) var auctionReservePrice: UFix64?
		access(contract) var auctionDuration: UFix64
		access(contract) var auctionMinBidIncrement: UFix64
		access(contract) var auctionExtensionOnLateBid: UFix64
		access(contract) var auctionStartedAt: UFix64?
		access(contract) var auctionEndsAt: UFix64?

		//The callback to the latest offer
		access(contract) var offerCallback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>?

		init(pointer: AnyStruct{FindViews.Pointer}, vaultType: Type) {
			self.vaultType=vaultType
			self.pointer=pointer
			self.salePrice=nil
			self.auctionStartPrice=nil
			self.auctionReservePrice=nil
			self.auctionDuration=86400.0
			self.auctionExtensionOnLateBid=300.0
			self.auctionMinBidIncrement=10.0
			self.offerCallback=nil
			self.escrow <- nil
			self.directOfferAccepted=false
			self.saleItemType=""
			self.auctionStartedAt=nil
			self.auctionEndsAt=nil
		}

		pub fun getId() : UInt64{
			return self.pointer.getUUID()
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

		pub fun toNFTInfo() : NFTInfo{
			return NFTInfo(self.pointer.getViewResolver())
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

		pub fun getSaleItemBidderInfo() : SaleItemBidderInfo {
			if self.auctionEndsAt != nil {
				return SaleItemBidderInfo(
					bidder : self.getBuyer(),
					type:"ongoing_auction",
					amount:self.getBalance()
				)
			}

			return SaleItemBidderInfo(
				bidder: nil,
				type:"ondemand_auction", 
				amount:self.auctionStartPrice
			)
		}

		pub fun setExtentionOnLateBid(_ time: UFix64) {
			self.auctionExtensionOnLateBid=time
		}

		pub fun setAuctionDuration(_ duration: UFix64) {
			self.auctionDuration=duration
		}

		pub fun setReservePrice(_ price: UFix64?) {
			self.auctionReservePrice=price
		}

		pub fun setMinBidIncrement(_ price: UFix64) {
			self.auctionMinBidIncrement=price
		}

		pub fun setStartAuctionPrice(_ price: UFix64?) {
			self.auctionStartPrice=price
		}

		pub fun setCallback(_ callback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>?) {
			self.offerCallback=callback
		}
	}


	pub resource interface SaleItemCollectionPublic {
		//fetch all the tokens in the collection
		pub fun getIds(): [UInt64]
		//fetch all names that are for sale

		pub fun getItemsForSale(): [SaleItemInformation]

		pub fun getItemForSaleInformation(_ id:UInt64) : SaleItemInformation 

		access(contract)fun cancelBid(_ id: UInt64) 
		access(contract) fun registerIncreasedBid(_ id: UInt64) 

		//place a bid on a token
		access(contract) fun registerBid(item: FindViews.ViewReadPointer, callback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>, vaultType:Type)

		access(contract) fun fulfillNonEscrowedAuction(_ id: UInt64, vault: @FungibleToken.Vault) 
	}

	pub resource SaleItemCollection: SaleItemCollectionPublic {
		//is this the best approach now or just put the NFT inside the saleItem?
		access(contract) var items: @{UInt64: SaleItem}

		access(contract) let tenant: TenantInformation
		init (_ tenant: &Tenant) {
			self.items <- {}
			self.tenant=tenant.information
		}

		pub fun getItemForSaleInformation(_ id:UInt64) : SaleItemInformation {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
			}
			return SaleItemInformation(self.borrow(id))

		}

		pub fun getItemsForSale(): [SaleItemInformation] {
			let info: [SaleItemInformation] =[]
			for id in self.getIds() {
				info.append(SaleItemInformation(self.borrow(id)))
			}
			return info
		}

		//call this to start an auction for this lease
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

			let nftInfo= NFTInfo(saleItem.pointer.getViewResolver())
			let callback=saleItem.offerCallback!
			let offer=callback.borrow()!
			let buyer=callback.address
			let balance=offer.getBalance(id)
			let owner=self.owner!.address
			let endsAt=timestamp + duration

			emit ForAuction(tenant:self.tenant.name, id: id, seller:owner, sellerName: FIND.reverseLookup(owner), amount: balance, auctionReservePrice: saleItem.auctionReservePrice!,  status: "active", vaultType:saleItem.vaultType.identifier, nft: nftInfo,  buyer: buyer, buyerName: FIND.reverseLookup(buyer), endsAt: endsAt)
			saleItem.setAuctionStarted(timestamp)
			saleItem.setAuctionEnds(endsAt)
			saleItem.setSaleItemType("ondemand_auction")
		}


		access(self) fun addBid(id:UInt64, newOffer: Capability<&MarketBidCollection{MarketBidCollectionPublic}>) {
			let saleItem=self.borrow(id)

			if saleItem.saleItemType != "ondemand_auction" {
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

		access(contract) fun registerIncreasedBid(_ id: UInt64) {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
			}

			let saleItem=self.borrow(id)
			let timestamp=Clock.time()

			if saleItem.saleItemType == "ondemand_action" && saleItem.auctionEndsAt != nil {
				if saleItem.auctionEndsAt! < timestamp {
					panic("Auction has ended")
				}
				//TODO: is this right? get the same item and send it in again?
				self.addBid(id: id, newOffer: saleItem.offerCallback!)
				return
			}
			self.startAuction(id)
		}


		//This is a function that buyer will call (via his bid collection) to register the bicCallback with the seller
		access(contract) fun registerBid(item: FindViews.ViewReadPointer, callback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>, vaultType: Type) {

			let timestamp=Clock.time()

			let id = item.getUUID()

			let saleItem=self.borrow(id)
			if saleItem.saleItemType == "ondemand_action" && saleItem.auctionEndsAt != nil {
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

			let owner=saleItem.getSeller()
			let ftType=saleItem.vaultType
			let buyer=saleItem.getBuyer()! 

			self.startAuction(id)
		}

		//cancel will cancel and auction or reject a bid if no auction has started
		pub fun cancel(_ id: UInt64) {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
			}

			let saleItem=self.borrow(id)
			let owner=saleItem.getSeller()
				let balance=saleItem.getBalance()
				let price= saleItem.auctionReservePrice?.toString() ?? ""

				//ESCROW: We cannot do this when escrowed
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

		//This method is called from a bid to fulfill a non escrowed auction
		access(contract) fun fulfillNonEscrowedAuction(_ id: UInt64, vault: @FungibleToken.Vault) {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
				!self.tenant.escrowFT : "This tenant uses escrowed auctions"
			}

			let saleItem = self.borrow(id)
			if saleItem.auctionStartPrice == nil {
				panic("Not an auction")
			}

			if saleItem.isEscrowed() {
				panic("Call fulfill method to finish a escrowed auction as it already has the funds")
			}

			if !saleItem.hasAuctionEnded() {
				panic("Auction has not ended yet")
			}

			if vault.getType() != saleItem.vaultType {
				panic("The FT vault sent in to fulfill does not match the required type")
			}

			if vault.balance < saleItem.auctionReservePrice! {
				panic("cannot fulfill auction reserve price was not met, cancel it without a vault ".concat(vault.balance.toString()).concat(" < ").concat(saleItem.auctionReservePrice!.toString()))
			}

			let owner=saleItem.getSeller()
			let buyer=saleItem.getBuyer()!

			let nftInfo=saleItem.toNFTInfo()
			emit ForAuction(tenant:self.tenant.name, id: id, seller:owner, sellerName: FIND.reverseLookup(owner), amount: saleItem.getBalance(), auctionReservePrice: saleItem.auctionReservePrice!,  status:"finishedNonEscrow", vaultType: saleItem.vaultType.identifier, nft:nftInfo, buyer: buyer, buyerName:FIND.reverseLookup(buyer), endsAt: saleItem.auctionEndsAt)

			let royalty=saleItem.getRoyalty()
			saleItem.acceptNonEscrowedBid()

			self.pay(id:id, saleItem: saleItem, vault: <- vault, royalty:royalty, nftInfo:nftInfo)

			destroy <- self.items.remove(key: id)
		}





		pub fun listForAuction(pointer: FindViews.AuthNFTPointer, vaultType: Type, auctionStartPrice: UFix64, auctionReservePrice: UFix64, auctionDuration: UFix64, auctionExtensionOnLateBid: UFix64, minimumBidIncrement: UFix64) {

			let saleItem <- create SaleItem(pointer: pointer, vaultType:vaultType)

			saleItem.setStartAuctionPrice(auctionStartPrice)
			saleItem.setReservePrice(auctionReservePrice)
			saleItem.setAuctionDuration(auctionDuration)
			saleItem.setExtentionOnLateBid(auctionExtensionOnLateBid)
			saleItem.setMinBidIncrement(minimumBidIncrement)
			saleItem.setSaleItemType("ondemand_auction")

			emit ForAuction(tenant:self.tenant.name, id: pointer.getUUID(), seller:self.owner!.address, sellerName: FIND.reverseLookup(self.owner!.address), amount: saleItem.auctionStartPrice!, auctionReservePrice: saleItem.auctionReservePrice!,  status:"listed", vaultType:vaultType.identifier, nft: NFTInfo(pointer.getViewResolver()), buyer: nil, buyerName:nil, endsAt: nil)

			self.items[pointer.getUUID()] <-! saleItem
		}

		pub fun delist(_ id: UInt64) {
			pre {
				self.items.containsKey(id) : "Unknown item with id=".concat(id.toString())
			}

			let saleItem <- self.items.remove(key: id)!
			//TODO: verify that bids are removed here.
			let owner=self.owner!.address
			emit ForSale(tenant:self.tenant.name, id: id, seller:owner, sellerName:FIND.reverseLookup(owner), amount: saleItem.salePrice!, status: "cancelled", vaultType: saleItem.vaultType.identifier,nft: NFTInfo(saleItem.pointer.getViewResolver()), buyer:nil, buyerName:nil)
			destroy saleItem
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

	/*
	==========================================================================
	Bids are a collection/resource for storing the bids bidder made on leases
	==========================================================================
	*/


	//TODO: can not be escrowed
	pub resource Bid {
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
		access(contract) fun setBidAt(_ time: UFix64) {
			self.bidAt=time
		}

		destroy() {
			destroy self.vault
		}
	}

	pub resource interface MarketBidCollectionPublic {
		pub fun getBids() : [BidInfo]
		pub fun getBalance(_ id: UInt64) : UFix64
		pub fun getVaultType(_ id: UInt64) : Type
		access(contract) fun acceptNonEscrowed(_ nft: @NonFungibleToken.NFT)
		access(contract) fun cancelBidFromSaleItem(_ id: UInt64)
	}

	//A collection stored for bidders/buyers
	pub resource MarketBidCollection: MarketBidCollectionPublic {

		access(contract) var bids : @{UInt64: Bid}
		access(contract) let receiver: Capability<&{FungibleToken.Receiver}>
		access(contract) let tenant: TenantInformation

		//not sure we can store this here anymore. think it needs to be in every bid
		init(receiver: Capability<&{FungibleToken.Receiver}>, tenant: &Tenant) {
			self.bids <- {}
			self.receiver=receiver
			self.tenant=tenant.information
		}

		//called from lease when auction is ended
		access(contract) fun acceptNonEscrowed(_ nft: @NonFungibleToken.NFT) {
			let id= nft.id
			let bid <- self.bids.remove(key: nft.uuid) ?? panic("missing bid")
			bid.nftCap.borrow()!.deposit(token: <- nft)
			destroy bid
		}

		pub fun getVaultType(_ id:UInt64) : Type {
			return self.borrowBid(id).vaultType
		}

		pub fun getBids() : [BidInfo] {
			var bidInfo: [BidInfo] = []
			for id in self.bids.keys {
				let bid = self.borrowBid(id)

				let saleInfo=bid.from.borrow()!.getItemForSaleInformation(id)
				bidInfo.append(BidInfo(id: bid.itemUUID, amount: bid.balance, timestamp: bid.bidAt,item:saleInfo))
			}
			return bidInfo
		}


		pub fun bid(item: FindViews.ViewReadPointer, amount:UFix64, vaultType:Type, nftCap: Capability<&{NonFungibleToken.Receiver}>) {
			pre {
				self.owner!.address != item.owner()  : "You cannot bid on your own resource"
				self.bids[item.getUUID()] == nil : "You already have an bid for this item, use increaseBid on that bid"
				//TODO panic if tenant requires escrow for this combination
			}

			let uuid=item.getUUID()
			let from=getAccount(item.owner()).getCapability<&SaleItemCollection{SaleItemCollectionPublic}>(self.tenant.saleItemPublicPath)

			let bid <- create Bid(from: from, itemUUID:item.getUUID(), nftCap: nftCap, vaultType: vaultType, nonEscrowedBalance:amount)
			let saleItemCollection= from.borrow() ?? panic("Could not borrow sale item for id=".concat(uuid.toString()))
			let callbackCapability =self.owner!.getCapability<&MarketBidCollection{MarketBidCollectionPublic}>(self.tenant.bidPublicPath)
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
			saleItem.fulfillNonEscrowedAuction(id, vault: <- vault)
		}


		//increase a bid, will not work if the auction has already started
		pub fun increaseBid(id: UInt64, increaseBy: UFix64) {
			let bid =self.borrowBid(id)
			bid.setBidAt(Clock.time())
			bid.balance=bid.balance + increaseBy
			bid.from.borrow()!.registerIncreasedBid(id)
		}

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
			destroy bid
		}

		pub fun borrowBid(_ id: UInt64): &Bid {
			return &self.bids[id] as &Bid
		}

		pub fun isEscrowed(_ id:UInt64) : Bool {
			return self.borrowBid(id).nonEscrowedBalance != nil 
		}

		pub fun getBalance(_ id: UInt64) : UFix64 {
			let bid= self.borrowBid(id)
			return bid.balance
		}

		destroy() {
			destroy self.bids
		}
	}

	//Create an empty lease collection that store your leases to a name
	pub fun createEmptySaleItemCollection(_ tenant: &Tenant): @SaleItemCollection {
		let wallet=FindMarket.account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
		return <- create SaleItemCollection(tenant)
	}

	pub fun createEmptyMarketBidCollection(receiver: Capability<&{FungibleToken.Receiver}>, tenant: &Tenant) : @MarketBidCollection {
		return <- create MarketBidCollection(receiver: receiver, tenant:tenant)
	}

	pub fun getFindTenant() : &Tenant {
		return FindMarket.getTenant(FindMarket.account.address) ?? panic("Find market tenant not set up correctly")
	}

	pub fun getFindSaleItemCapability(_ user: Address) : Capability<&FindMarket.SaleItemCollection{FindMarket.SaleItemCollectionPublic}>? {
		return FindMarket.getSaleItemCapability(marketplace: FindMarket.account.address, user:user) 
	}

	pub fun getFindBidCapability(_ user: Address) :Capability<&FindMarket.MarketBidCollection{FindMarket.MarketBidCollectionPublic}>? {
		return FindMarket.getBidCapability(marketplace:FindMarket.account.address, user:user) 
	}

	pub fun getTenant(_ marketplace:Address) : &Tenant? {
		return getAccount(marketplace).getCapability<&{FindMarket.TenantPublic}>(FindMarket.TenantClientPublicPath).borrow()?.getTenant()
	}

	pub fun getSaleItemCapability(marketplace:Address, user:Address) : Capability<&FindMarket.SaleItemCollection{FindMarket.SaleItemCollectionPublic}>? {
		if let tenant=FindMarket.getTenant(marketplace) {
			return getAccount(user).getCapability<&FindMarket.SaleItemCollection{FindMarket.SaleItemCollectionPublic}>(tenant.information.saleItemPublicPath)
		}
		return nil
	}

	pub fun getBidCapability( marketplace:Address, user:Address) : Capability<&FindMarket.MarketBidCollection{FindMarket.MarketBidCollectionPublic}>? {
		if let tenant=FindMarket.getTenant(marketplace) {
			return getAccount(user).getCapability<&FindMarket.MarketBidCollection{FindMarket.MarketBidCollectionPublic}>(tenant.information.bidPublicPath)
		}
		return nil
	}

	init() {
		self.TenantClientPublicPath=/public/findMarketClient
		self.TenantClientStoragePath=/storage/findMarketClient

		self.TenantPrivatePath=/private/findMarketTenant
		self.TenantStoragePath=/storage/findMarketTenant

	}
}
