import FungibleToken from "./standard/FungibleToken.cdc"
import FlowToken from "./standard/FlowToken.cdc"
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import Profile from "./Profile.cdc"
import Clock from "./Clock.cdc"
import Debug from "./Debug.cdc"
import FIND from "./FIND.cdc"

/*

The findMarket is a multi tenant multi capability market contract. 

When you list an item in FindMarket you alwasys list it at a tenant. Each tenant has its own collection and storage in a users account to avoid confusion. 

An item in FindMarket can be:
- listed for direct sale
- listed for on-demand auction: an auction that starts when the minimum bid has been reached

A buyer in FindMarket can add a DirectOffer to any compatible NFT a FindMarkt user owns.

Find will take a cut of every sale of the market that is coded into the tenant, this fee is negotiable. 
A tenant can also turn off auctions/directOffers if he does not want to.
A tenant can chose what NFTTypes to accept and what FTTypes to accept.
*/

//TODO: ensure we have the correct scripts to return the information we need in tests
//TODO: test all ! and convert to better error messages
//TODO: what to do if item implements display when added and does not anymore. does not implement display anymore?
//TODO: can a owner cancel an auction when it is running, if we do not escrow then he can
pub contract FindMarket {

	pub let TenantClientPublicPath: PublicPath
	pub let TenantClientStoragePath: StoragePath

	pub let TenantPrivatePath: PrivatePath
	pub let TenantStoragePath: StoragePath

	/*
	Events are very important in the FindMarket as we heavily use graffle to distribute events to clients vis signalR and to aggregate state in market based upon them. 
	We try to keep fields in events consistent and use the same names many places

	tenant: This is the name of the tenant for this market. Each individual instance of FindMarket has its own tenant that it is created for. The name of this tenant is present in every event
	id: this is the id of all resources in a .find market. This is the UUID of the NFT that the bid/saleItem is about.
	owner: TODO: rename to seller? this is and Address field of who currently owns an item before the event was emitted. 
	ownerName: the .find name for the owner if present. 
	amount: the amount of FT this item handles
	vaultType: The type of vault using the identifier of the vault
	buyer: the address of the buyer/bidder
	buyerName: the .find name of the buyer/bidder if any.  when the event was emitted
	auctionEnd: A timestamp of when an auction ends
	auctionReservePrice: the price an auction much reach to be fulfilled
	status: the status of the given item, this varies according to the event
	*/
	pub struct NFTInfo{
		pub let name:String
		pub let description:String
		pub let thumbnail:String
		pub let type: String
		//TODO: add more views here, like rarity

		init(_ item: &{MetadataViews.Resolver}){
			let display = item.resolveView(Type<MetadataViews.Display>())! as! MetadataViews.Display
			self.name=display.name
			self.description=display.description
			self.thumbnail=display.thumbnail.uri()
			self.type=item.getType().identifier
		}
	}

	pub event NFTEscrowed(tenant:String, id: UInt64, nft:NFTInfo)

	pub event RoyaltyPaid(tenant:String, id: UInt64, address:Address, findName:String?, name:String, amount: UFix64, vaultType:String, nft:NFTInfo)

	pub event ForSale(tenant: String, id: UInt64, seller: Address, sellerName: String?, amount: UFix64, status: String, vaultType:String, nft: NFTInfo, buyer:Address?, buyerName:String?)

	/// Status for auction is
	/// listed : the auction is listed but not started
	/// active: the auction is live and have bids
	/// cancelled: the auction was cancelled
	/// finished: the auction was finished
	pub event ForAuction(tenant: String, id: UInt64, seller: Address, sellerName:String?, amount: UFix64, auctionReservePrice: UFix64, status: String, vaultType:String, nft:NFTInfo, buyer:Address?, buyerName:String?, endsAt: UFix64?)

	pub event DirectOffer(tenant: String, id: UInt64, seller: Address, sellerName: String?, amount: UFix64, status: String, vaultType:String, nft: NFTInfo, buyer:Address?, buyerName:String?)

	//TODO: a tenant should say if they want escrowed or not!
	pub struct TenantInformation {

		//This is the name of the tenant, it will be in all the events and 
		pub let name: String

		//consider making an array of listingRules
		//TODO; add getters 
		//if this is not empty, only NFTs of that type can be sold at this tenant
		access(self) let validNFTTypes: [Type]

		//if this is not empty, only FTs of this type can be registered for sale/bid with on this tenant. No matter what the NFT support
		access(self) let ftTypes: [Type]

		//the paths to the bid collection for this tenant
		pub let bidPublicPath: PublicPath 
		pub let bidStoragePath: StoragePath 

		//the paths to the saleItem collection for this tenant
		pub let saleItemPublicPath: PublicPath 
		pub let saleItemStoragePath: StoragePath 

		pub let findCut: MetadataViews.Royalty?
		pub let tenantCut: MetadataViews.Royalty?

		pub let auctionsSupported:Bool
		pub let directOffersSupported:Bool

		pub let escrowFT:Bool

		init(name:String, validNFTTypes: [Type], ftTypes:[Type], findCut: MetadataViews.Royalty?, tenantCut: MetadataViews.Royalty?, bidPublicPath: PublicPath, bidStoragePath:StoragePath, saleItemPublicPath: PublicPath, saleItemStoragePath:StoragePath, auctions: Bool, directOffers:Bool) {
			self.name=name
			self.validNFTTypes=validNFTTypes
			self.ftTypes=ftTypes
			self.findCut=findCut
			self.tenantCut=tenantCut
			self.bidPublicPath=bidPublicPath
			self.bidStoragePath=bidStoragePath
			self.saleItemPublicPath=saleItemPublicPath
			self.saleItemStoragePath=saleItemStoragePath
			self.directOffersSupported=directOffers
			self.auctionsSupported=auctions

			//TODO:creat a field for this
			self.escrowFT=directOffers
		}
	}

	//this needs to be a resource so that nobody else can make it.
	pub resource Tenant {

		pub let information : TenantInformation

		init(_ tenant: TenantInformation) {
			self.information=tenant
		}
	}

	access(account) fun createTenant(_ tenant: TenantInformation) : @Tenant {
		return <- create Tenant(tenant)
	}

	// Tenant admin stuff
	//Admin client to use for capability receiver pattern
	pub fun createTenantClient() : @TenantClient {
		return <- create TenantClient()
	}

	//interface to use for capability receiver pattern
	pub resource interface TenantPublic  {
		pub fun getTenant() : &Tenant 
		pub fun addCapability(_ cap: Capability<&Tenant>)
	}

	//admin proxy with capability receiver 
	pub resource TenantClient: TenantPublic {

		access(self) var capability: Capability<&Tenant>?

		pub fun addCapability(_ cap: Capability<&Tenant>) {
			pre {
				cap.check() : "Invalid tenant"
				self.capability == nil : "Server already set"
			}
			self.capability = cap
		}

		init() {
			self.capability = nil
		}

		pub fun getTenant() : &Tenant {
			pre {
				self.capability != nil: "TenentClient is not present"
				self.capability!.check()  : "Tenant client is not linked anymore"
			}

			return self.capability!.borrow()!
		}
	}


	pub struct SaleItemBidderInfo {
		pub let amount: UFix64?
		pub let bidder: Address?
		pub let saleItemType:String

		init(bidder:Address?, type:String, amount:UFix64?) {
			self.bidder=bidder
			self.saleItemType=type
			self.amount=amount
		}
	}

	pub struct SaleItemInformation {

		pub let type:Type
		pub let typeId: UInt64
		pub let id:UInt64
		pub let owner: Address
		pub let amount: UFix64?
		pub let bidder: Address?
		pub let saleType:String
		pub let ftType: Type
		pub let ftTypeIdentifier: String
		pub let auctionReservePrice: UFix64?
		pub let extensionOnLateBid: UFix64?
		pub let listingValidUntil: UFix64?


		init(_ item: &SaleItem) {

			self.type= item.escrow?.getType() ?? item.pointer.getItemType()
			self.typeId=item.escrow?.id ?? item.pointer.id
			self.id= item.escrow?.uuid ?? item.pointer.getUUID()
			let bidderInfo=item.getSaleItemBidderInfo()
			self.amount=bidderInfo.amount
			self.bidder=bidderInfo.bidder
			self.saleType=bidderInfo.saleItemType
			self.owner=item.owner!.address
			self.auctionReservePrice=item.auctionReservePrice
			self.extensionOnLateBid=item.auctionExtensionOnLateBid
			self.ftType=item.vaultType
			self.ftTypeIdentifier=item.vaultType.identifier
			self.listingValidUntil=nil
		}
	}

	pub resource SaleItem{

		access(contract) var escrow : @NonFungibleToken.NFT?


		access(contract) var saleItemType: String

		access(contract) let vaultType: Type //The type of vault to use for this sale Item
		access(contract) var pointer: AnyStruct{FindViews.Pointer}

		//this field is set if this is a saleItem
		access(contract) var salePrice: UFix64?


		//these filds are set if it is an auction
		access(contract) var auctionStartPrice: UFix64?
		access(contract) var auctionReservePrice: UFix64?
		access(contract) var auctionDuration: UFix64
		access(contract) var auctionMinBidIncrement: UFix64
		access(contract) var auctionExtensionOnLateBid: UFix64
		access(contract) var auctionStartedAt: UFix64?
		access(contract) var auctionEndsAt: UFix64?


		//The callback to the latest offer
		access(contract) var offerCallback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>?

		access(contract) var directOfferAccepted:Bool

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

		pub fun acceptEscrowedBid() : @FungibleToken.Vault {
			let pointer= self.pointer as! FindViews.AuthNFTPointer
			let vault <- self.offerCallback!.borrow()!.accept(<- pointer.withdraw())
			return <- vault
		}

		//Here we do not get a vault back, it is sent in to the method itself
		pub fun acceptNonEscrowedBid() { 
			let pointer= self.pointer as! FindViews.AuthNFTPointer
			self.offerCallback!.borrow()!.acceptNonEscrowed(<- pointer.withdraw())
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

		pub fun isEscrowed(): Bool {
			if let cb= self.offerCallback {
				return cb.borrow()!.isEscrowed(self.getId())
			}
			return false
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

		access(contract) fun  setSaleItemType(_ sit: String) {
			self.saleItemType=sit
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

		pub fun acceptDirectOffer() {
			self.directOfferAccepted=true
		}

		pub fun getSaleItemBidderInfo() : SaleItemBidderInfo {
			if self.auctionEndsAt != nil {
				return SaleItemBidderInfo(
					bidder : self.getBuyer(),
					type:"ongoing_auction",
					amount:self.getBalance()
				)
			}
			if self.pointer.getType() == Type<FindViews.ViewReadPointer>() {
				return SaleItemBidderInfo(
					bidder: self.getBuyer(),
					type: "directoffer",
					amount: self.getBalance()
				)
			}


			if self.auctionStartPrice!= nil {
				return SaleItemBidderInfo(
					bidder: nil,
					type:"ondemand_auction", 
					amount:self.auctionStartPrice
				)
			} 

			return SaleItemBidderInfo(
				bidder: self.getBuyer(),
				type: "sale",
				amount: self.salePrice
			)

		}

		/*
		//ESCROW: this can be added back once we can escrow auctions again
		pub fun returnNFT() {
			if self.auction==nil {
				return
			}
			let pointer= self.pointer as! FindViews.AuthNFTPointer
			let nft <- self.escrow <- nil
			pointer.deposit(<- nft!)
		}

		pub fun getEscrow() :@NonFungibleToken.NFT {
			if self.auction != nil {
				let nft <- self.escrow <- nil
				return <- nft!
			}
			panic("Not an auction")
		}
		*/

		pub fun setExtentionOnLateBid(_ time: UFix64) {
			self.auctionExtensionOnLateBid=time
		}

		pub fun setPointer(_ pointer: FindViews.AuthNFTPointer) {
			self.pointer=pointer
		}

		pub fun setAuctionDuration(_ duration: UFix64) {
			self.auctionDuration=duration
		}

		pub fun setSalePrice(_ price: UFix64?) {
			self.salePrice=price
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

		destroy() {
			if self.escrow != nil {
				Debug.log("Destroyed escrow!!!")
			}
			destroy self.escrow
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

		access(contract) fun isAcceptedDirectOffer(_ id:UInt64) :Bool

		access(contract) fun fulfillDirectOfferNonEscrowed(id:UInt64, vault: @FungibleToken.Vault)

		//anybody should be able to fulfill an auction as long as it is done
		pub fun fulfillAuction(_ id: UInt64) 

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

		pub fun isAcceptedDirectOffer(_ id:UInt64) : Bool{
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
			}
			let saleItem = self.borrow(id)

			return saleItem.directOfferAccepted
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


		access(contract) fun cancelBid(_ id: UInt64) {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
			}

			let saleItem=self.borrow(id)

			if saleItem.saleItemType== "ondemand_auction" {
				panic("cannot cancel bid in auction")
			}

			let owner=saleItem.owner!.address
			let ftType=saleItem.vaultType
			let nftInfo=NFTInfo(saleItem.pointer.getViewResolver())
			let balance=saleItem.offerCallback!.borrow()!.getBalance(id) 

			if let callback = saleItem.offerCallback {
				let buyer=callback.address
				emit DirectOffer(tenant:self.tenant.name, id: id, seller:owner, sellerName: FIND.reverseLookup(owner), amount: balance, status:"cancelled", vaultType: ftType.identifier, nft:nftInfo, buyer: buyer, buyerName: FIND.reverseLookup(buyer))
			}

			saleItem.setCallback(nil)
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

		//TODO: here we know it is your bid
		//TODO: branch out earlier here in bids for sale/direct_offer/auction
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

			let owner=saleItem.owner!.address
			let ftType=saleItem.vaultType
			let nftInfo=NFTInfo(saleItem.pointer.getViewResolver())
			let buyer=saleItem.offerCallback!.address
			let balance=saleItem.offerCallback!.borrow()!.getBalance(id) 
			Debug.log("Offer is at ".concat(balance.toString()))

			if saleItem.salePrice == nil  && saleItem.auctionStartPrice == nil{
				emit DirectOffer(tenant:self.tenant.name, id: id, seller:owner, sellerName: FIND.reverseLookup(owner), amount: balance, status:"improved_offer", vaultType: ftType.identifier, nft:nftInfo, buyer: buyer, buyerName: FIND.reverseLookup(buyer))
				return
			}

			if saleItem.salePrice != nil && balance >= saleItem.salePrice! {
				self.fulfill(id)
			} else if saleItem.auctionStartPrice != nil && balance >= saleItem.auctionStartPrice! {
				self.startAuction(id)
			} else {
				panic("The price sent in for direct sale is not what it is offered for")
			}
		}


		//This is a function that buyer will call (via his bid collection) to register the bicCallback with the seller
		access(contract) fun registerBid(item: FindViews.ViewReadPointer, callback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>, vaultType: Type) {

			let timestamp=Clock.time()

			let id = item.getUUID()

			//If this is a DirectOffer we just add a new saleItem with that pointer
			//TODO: if this tenant does not support direct offer panic here
			if !self.items.containsKey(id) {
				let saleItem <- create SaleItem(pointer: item, vaultType:vaultType)
				saleItem.setSaleItemType("direct_offer")
				self.items[id] <-! saleItem
			} 

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

			Debug.log("Balance of bid is at ".concat(balance.toString())) 
			if saleItem.salePrice == nil && saleItem.auctionStartPrice == nil { 
				Debug.log("Sale price not set")
				emit DirectOffer(tenant:self.tenant.name, id: id, seller:owner, sellerName: FIND.reverseLookup(owner), amount: balance, status:"offered", vaultType: ftType.identifier, nft:saleItem.toNFTInfo(), buyer: buyer, buyerName: FIND.reverseLookup(buyer))
				return
			}

			if saleItem.salePrice != nil && balance == saleItem.salePrice! {
				Debug.log("Direct sale!")
				self.fulfill(id)
			}	 else if saleItem.auctionStartPrice != nil && balance >= saleItem.auctionStartPrice! {
				self.startAuction(id)
			} else {   
				panic("The price sent in for direct sale is not what it is offered for")
			}
		}

		//cancel will cancel and auction or reject a bid if no auction has started
		pub fun cancel(_ id: UInt64) {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
			}

			let saleItem=self.borrow(id)
			let owner=saleItem.getSeller()
			if saleItem.saleItemType == "ondemand_action" && saleItem.auctionEndsAt != nil {
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

			//TODO: assert that not non escrowe sale item
			if let cb= saleItem.offerCallback {
				Debug.log("we have a direct offer so we cancel that")

				let balance=saleItem.getBalance()
				let buyer=saleItem.getBuyer()!
				let ftType=saleItem.vaultType
				let nftInfo=saleItem.toNFTInfo()
				emit DirectOffer(tenant:self.tenant.name, id: id, seller:owner, sellerName: FIND.reverseLookup(owner), amount: balance, status:"rejected", vaultType: ftType.identifier, nft:nftInfo, buyer: buyer, buyerName: FIND.reverseLookup(buyer))
				cb.borrow()!.cancelBidFromSaleItem(id)
				saleItem.setCallback(nil)
				return 
			}
		}

		access(contract) fun fulfillDirectOfferNonEscrowed(id:UInt64, vault: @FungibleToken.Vault) {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
				!self.tenant.escrowFT : "This tenant uses escrowed auctions"
			}

			//TODO: assert that it has enough funds
			let saleItem = self.borrow(id)
			if !saleItem.directOfferAccepted {
				panic("cannot fulfill a direct offer that is not accepted yet")
			}

			if vault.getType() != saleItem.vaultType {
				panic("The FT vault sent in to fulfill does not match the required type")
			}

			let ftType=saleItem.vaultType
			let owner=saleItem.getSeller()
			let nftInfo=saleItem.toNFTInfo()
			let buyer= saleItem.getBuyer()!
			let soldFor=saleItem.getBalance()

			emit DirectOffer(tenant:self.tenant.name, id: id, seller:owner, sellerName: FIND.reverseLookup(owner), amount: soldFor, status:"accepted", vaultType: ftType.identifier, nft:nftInfo, buyer: buyer, buyerName: FIND.reverseLookup(buyer))

			let royalty=saleItem.getRoyalty()
			saleItem.acceptNonEscrowedBid()
			self.pay(id:id, saleItem: saleItem, vault: <- vault, royalty:royalty, nftInfo: nftInfo)

			destroy <- self.items.remove(key: id)
		}

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


		access(self) fun pay(id: UInt64, saleItem: &SaleItem, vault: @FungibleToken.Vault, royalty: MetadataViews.Royalties?, nftInfo:NFTInfo) {
			let tenant=self.tenant.name
			let buyer=saleItem.getBuyer()
			let seller=saleItem.getSeller()
			let oldProfile= getAccount(seller).getCapability<&{Profile.Public}>(Profile.publicPath).borrow()!
			let soldFor=vault.balance
			let ftType=vault.getType()

			if royalty != nil {
				for royaltyItem in royalty!.getRoyalties() {
					let description=royaltyItem.description 
					let cutAmount= soldFor * royaltyItem.cut
					emit RoyaltyPaid(tenant:self.tenant.name, id: id, address:royaltyItem.receiver.address, findName: FIND.reverseLookup(royaltyItem.receiver.address), name: description, amount: cutAmount,  vaultType: ftType.identifier, nft:nftInfo)
					royaltyItem.receiver.borrow()!.deposit(from: <- vault.withdraw(amount: cutAmount))
				}
			}

			if let findCut =self.tenant.findCut {
				let cutAmount= soldFor * self.tenant.findCut!.cut
				emit RoyaltyPaid(tenant: self.tenant.name, id: id, address:findCut.receiver.address, findName: FIND.reverseLookup(findCut.receiver.address), name: "find", amount: cutAmount,  vaultType: ftType.identifier, nft:nftInfo)
				findCut.receiver.borrow()!.deposit(from: <- vault.withdraw(amount: cutAmount))
			}

			if let tenantCut =self.tenant.tenantCut {
				let cutAmount= soldFor * self.tenant.findCut!.cut
				emit RoyaltyPaid(tenant: self.tenant.name, id: id, address:tenantCut.receiver.address, findName: FIND.reverseLookup(tenantCut.receiver.address), name: "marketplace", amount: cutAmount,  vaultType: ftType.identifier, nft:nftInfo)
				tenantCut.receiver.borrow()!.deposit(from: <- vault.withdraw(amount: cutAmount))
			}
			oldProfile.deposit(from: <- vault)
		}

		/// fulfillAuction wraps the fulfill method and ensure that only a finished auction can be fulfilled by anybody
		pub fun fulfillAuction(_ id: UInt64) {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
				self.borrow(id).auctionStartPrice != nil : "Cannot fulfill sale that is not an auction=".concat(id.toString())
				!self.borrow(id).isEscrowed() : "Cannot fulfill non escrowed auction without a vault"
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

			emit ForAuction(tenant:self.tenant.name, id: id, seller:owner, sellerName: FIND.reverseLookup(owner), amount: soldFor, auctionReservePrice: saleItem.auctionReservePrice!,  status:"finished", vaultType: ftType.identifier, nft:nftInfo, buyer: buyer, buyerName:FIND.reverseLookup(buyer), endsAt: Clock.time())

			//ESCROW: add this back once we can escrow item again
			//let nft <- saleItem.getEscrow()
			let vault <- saleItem.acceptEscrowedBid()
			self.pay(id:id, saleItem: saleItem, vault: <- vault, royalty:royalty, nftInfo:nftInfo)

			destroy <- self.items.remove(key: id)

		} 

		//This is called by the owner of the sale item collection
		//Here we will have a seperate model to fulfill a direct offer since we then need to add the auth pointer to it?
		pub fun acceptDirectOffer(_ pointer: FindViews.AuthNFTPointer) {
			pre {
				self.items.containsKey(pointer.getUUID()) : "Invalid id=".concat(pointer.getUUID().toString())
			}

			let id = pointer.getUUID()
			let saleItem = self.borrow(id)
			if saleItem.offerCallback==nil {
				panic("Not an offer here")
			}

		 if saleItem.isEscrowed() {
				panic("The funds for this direct offer are not escrowed so you need to accept it and the buyer must then fulfill")
			}

			if saleItem.auctionStartedAt != nil {
				panic("This item has an ongoing auction, you cannot fullfill this direct offer")
			}

			//Set the auth pointer in the saleItem so that it now can be fulfilled
			saleItem.setPointer(pointer)

			let ftType=saleItem.vaultType
			let owner=saleItem.getSeller()
			let nftInfo= saleItem.toNFTInfo()
			let royalty=saleItem.getRoyalty()
			let soldFor=saleItem.getBalance()
			let buyer=saleItem.getBuyer()!
			emit DirectOffer(tenant:self.tenant.name, id: id, seller:owner, sellerName: FIND.reverseLookup(owner), amount: soldFor, status:"finished", vaultType: ftType.identifier, nft:nftInfo, buyer: buyer, buyerName: FIND.reverseLookup(buyer))

			let vault <- saleItem.acceptEscrowedBid()
			self.pay(id:id, saleItem: saleItem, vault: <- vault, royalty:royalty, nftInfo:nftInfo)
			destroy <- self.items.remove(key: id)
		}

		//TODO test this
		pub fun acceptNonEscrowedDirectOffer(_ pointer: FindViews.AuthNFTPointer) {
			pre {
				self.items.containsKey(pointer.getUUID()) : "Invalid id=".concat(pointer.getUUID().toString())
			}

			let id = pointer.getUUID()
			let saleItemRef = self.borrow(id)

			if saleItemRef.isEscrowed() {
				panic("This direct offer can be directly accepted since the funds are already escrowed")
			}

			if saleItemRef.auctionStartedAt != nil {
				panic("This item has an ongoing auction, you cannot fullfill this direct offer")
			}

			//Set the auth pointer in the saleItem so that it now can be fulfilled
			saleItemRef.setPointer(pointer)
			saleItemRef.acceptDirectOffer()

			let owner=saleItemRef.getSeller()
			let soldFor=saleItemRef.getBalance()
			let ftType=saleItemRef.vaultType
			let nftInfo=saleItemRef.toNFTInfo()
			let buyer=saleItemRef.getBuyer()!

			emit DirectOffer(tenant:self.tenant.name, id: id, seller:owner, sellerName: FIND.reverseLookup(owner), amount: soldFor, status:"accepted", vaultType: ftType.identifier, nft:nftInfo, buyer: buyer, buyerName: FIND.reverseLookup(buyer))
		}


		//TODO: clean up this code
		pub fun fulfill(_ id: UInt64) {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
			}

			let saleItem=self.borrow(id)
			if saleItem.offerCallback==nil {
				panic("Not an offer here")
			}

			let ftType=saleItem.vaultType
			let owner=saleItem.getSeller()
			//ESCROW: we cannot continue like this when escrow since the pointer will be gone
			let nftInfo= saleItem.toNFTInfo()

			let royalty=saleItem.getRoyalty()
			let soldFor=saleItem.getBalance()
			let buyer=saleItem.getBuyer()!

			if saleItem.saleItemType=="sale" {
				emit ForSale(tenant:self.tenant.name, id: id, seller:owner, sellerName: FIND.reverseLookup(owner), amount: soldFor, status:"finished", vaultType: ftType.identifier, nft:nftInfo, buyer: buyer, buyerName: FIND.reverseLookup(buyer))
			} else {
				emit DirectOffer(tenant:self.tenant.name, id: id, seller:owner, sellerName: FIND.reverseLookup(owner), amount: soldFor, status:"finished", vaultType: ftType.identifier, nft:nftInfo, buyer: buyer, buyerName: FIND.reverseLookup(buyer))
			}

			let vault <- saleItem.acceptEscrowedBid()

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

		pub fun listForSale(pointer: FindViews.AuthNFTPointer, vaultType: Type, directSellPrice:UFix64) {

			let saleItem <- create SaleItem(pointer: pointer, vaultType:vaultType)
			saleItem.setSalePrice(directSellPrice)
			saleItem.setSaleItemType("sale")

			let owner=self.owner!.address
			emit ForSale(tenant: self.tenant.name, id: pointer.getUUID(), seller:owner, sellerName: FIND.reverseLookup(owner), amount: saleItem.salePrice!, status: "listed", vaultType: vaultType.identifier, nft:NFTInfo(pointer.getViewResolver()), buyer: nil, buyerName:nil)
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

	//Struct that is used to return information about bids
	pub struct BidInfo{
		pub let id: UInt64
		pub let amount: UFix64
		pub let timestamp: UFix64
		pub let item: SaleItemInformation

		init(id: UInt64, amount: UFix64, timestamp: UFix64, item:SaleItemInformation) {
			self.id=id
			self.amount=amount
			self.timestamp=timestamp
			self.item=item
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
		access(contract) var nonEscrowedBalance: UFix64?

		init(from: Capability<&SaleItemCollection{SaleItemCollectionPublic}>, itemUUID: UInt64, vault: @FungibleToken.Vault, nftCap: Capability<&{NonFungibleToken.Receiver}>, vaultType:Type,  nonEscrowedBalance:UFix64?){
			self.vaultType= vaultType
			self.vault <- vault
			self.nonEscrowedBalance=nonEscrowedBalance
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
		pub fun isEscrowed(_ id: UInt64) : Bool
		pub fun getVaultType(_ id: UInt64) : Type
		access(contract) fun accept(_ nft: @NonFungibleToken.NFT) : @FungibleToken.Vault
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

		pub fun getVaultType(_ id:UInt64) : Type {
			return self.borrowBid(id).vaultType
		}

		pub fun getBids() : [BidInfo] {
			var bidInfo: [BidInfo] = []
			for id in self.bids.keys {
				let bid = self.borrowBid(id)

				let saleInfo=bid.from.borrow()!.getItemForSaleInformation(id)
				bidInfo.append(BidInfo(id: bid.itemUUID, amount: bid.vault.balance, timestamp: bid.bidAt,item:saleInfo))
			}
			return bidInfo
		}


		pub fun softBid(item: FindViews.ViewReadPointer, amount:UFix64, vaultType:Type, nftCap: Capability<&{NonFungibleToken.Receiver}>) {
			pre {
				self.owner!.address != item.owner()  : "You cannot bid on your own resource"
				self.bids[item.getUUID()] == nil : "You already have an bid for this item, use increaseBid on that bid"
				//TODO panic if tenant requires escrow for this combination
			}

			let uuid=item.getUUID()
			let from=getAccount(item.owner()).getCapability<&SaleItemCollection{SaleItemCollectionPublic}>(self.tenant.saleItemPublicPath)

			let vault <- FlowToken.createEmptyVault()
			let bid <- create Bid(from: from, itemUUID:item.getUUID(), vault: <- vault, nftCap: nftCap, vaultType: vaultType, nonEscrowedBalance:amount)
			let saleItemCollection= from.borrow() ?? panic("Could not borrow sale item for id=".concat(uuid.toString()))
			let callbackCapability =self.owner!.getCapability<&MarketBidCollection{MarketBidCollectionPublic}>(self.tenant.bidPublicPath)
			let oldToken <- self.bids[uuid] <- bid
			saleItemCollection.registerBid(item: item, callback: callbackCapability, vaultType: vaultType) 
			destroy oldToken
		}

		pub fun bid(item: FindViews.ViewReadPointer, vault: @FungibleToken.Vault, nftCap: Capability<&{NonFungibleToken.Receiver}>) {
			pre {
				self.owner!.address != item.owner()  : "You cannot bid on your own resource"
				self.bids[item.getUUID()] == nil : "You already have an bid for this item, use increaseBid on that bid"
			}

			let uuid=item.getUUID()
			let from=getAccount(item.owner()).getCapability<&SaleItemCollection{SaleItemCollectionPublic}>(self.tenant.saleItemPublicPath)
			let vaultType=vault.getType()

			let bid <- create Bid(from: from, itemUUID:item.getUUID(), vault: <- vault, nftCap: nftCap, vaultType:vaultType, nonEscrowedBalance:nil)
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

		pub fun fulfillDirectOffer(id:UInt64, vault: @FungibleToken.Vault) {
			pre {
				self.bids[id] != nil : "You need to have a bid here already"
			}

			let bid =self.borrowBid(id)
			let saleItem=bid.from.borrow()!

			if !saleItem.isAcceptedDirectOffer(id) {
				panic("offer is not accepted yet")
			}

			saleItem.fulfillDirectOfferNonEscrowed(id:id, vault: <- vault)
		}

		//TODO: softIncreaseBid

		//increase a bid, will not work if the auction has already started
		pub fun increaseBid(id: UInt64, vault: @FungibleToken.Vault) {
			let bid =self.borrowBid(id)
			bid.setBidAt(Clock.time())
			bid.vault.deposit(from: <- vault)

			//TODO: need to send in the old balance here first or verify that this is allowed here....
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
			let vaultRef = &bid.vault as &FungibleToken.Vault
			if bid.nonEscrowedBalance==nil{
				self.receiver.borrow()!.deposit(from: <- vaultRef.withdraw(amount: vaultRef.balance))
			}
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
			return bid.nonEscrowedBalance ?? bid.vault.balance
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
