import FungibleToken from "./standard/FungibleToken.cdc"
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import Profile from "./Profile.cdc"
import Clock from "./Clock.cdc"
import Debug from "./Debug.cdc"
import Dandy from "./Dandy.cdc"
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

//TODO: add validUntil to saleItem. optional UFix64. 
//TODO: ensure we have the correct scripts to return the information we need in tests
//TODO: test all ! and convert to better error messages
//TODO: what to do if item implements display when added and does not anymore. does not implement display anymore?
//TODO: can a owner cancel an auction when it is running, if we do not escrow then he can
//TODO: consider _not_ escrowing
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
		active: if an item was active or not
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

	pub event RoyaltyPaid(tenant:String, id: UInt64, name:String, amount: UFix64, vaultType:String, nft:NFTInfo)

	//TODO: Need more fields in here about what is in the event, so what is for sale, like display information aso
	pub event ForSale(tenant: String, id: UInt64, seller: Address, sellerName: String?, amount: UFix64, active: Bool, vaultType:String, nft: NFTInfo, buyer:Address?, buyerName:String?)

	pub event ForAuction(tenant: String, id: UInt64, seller: Address, sellerName:String?, amount: UFix64, auctionReservePrice: UFix64, active: Bool, vaultType:String, nft:NFTInfo, buyer:Address?, buyerName:String?, currentBid: UFix64?)

	pub event DirectOffer(tenant: String, id: UInt64, seller: Address, sellerName: String?, amount: UFix64, active: Bool, vaultType:String, nft: NFTInfo, buyer:Address?, buyerName:String?)

	//TODO: need one Event DirectOffer
	/// Emitted if a bid occurs at a name that is too low or not for sale
	pub event DirectOfferBid(tenant:String, id: UInt64, bidder: Address, amount: UFix64, vaultType:String)

	pub event DirectOfferCanceled(tenant:String, id: UInt64, bidder: Address, vaultType:String)

	pub event DirectOfferRejected(tenant:String, id: UInt64, bidder: Address, amount: UFix64, vaultType:String)

	//TODO: a tenant should say if they want escrowed or not!
	pub struct TenantInformation {

		//This is the name of the tenant, it will be in all the events and 
		pub let name: String

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
		}
	}

	pub resource SaleItem{


		//TODO: leve this field here for now but do not use it until default impl is handled
		access(contract) var escrow : @NonFungibleToken.NFT?

		//TODO:if direct offer and tenant is not escrow need to be able to say that it is accepted
		//TODO:if auction and tenant is not escrow only buyer can fulfill

		access(contract) let vaultType: Type //The type of vault to use for this sale Item
		access(contract) var pointer: AnyStruct{FindViews.Pointer}
		access(contract) var salePrice: UFix64?
		access(contract) var auctionStartPrice: UFix64?
		access(contract) var auctionReservePrice: UFix64?
		access(contract) var auctionDuration: UFix64
		access(contract) var auctionMinBidIncrement: UFix64
		access(contract) var auctionExtensionOnLateBid: UFix64
		access(contract) var offerCallback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>?

		//This most likely has to be a resource since we want to escrow when this starts
		access(contract) var auction: Auction?

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
			self.auction=nil
			self.escrow <- nil
		}


		pub fun getSaleItemBidderInfo() : SaleItemBidderInfo {
			if self.auction != nil {

				return SaleItemBidderInfo(
					bidder :self.auction!.latestBidCallback.address,
					type:"ongoing_auction",
					amount:self.auction!.getAuctionBalance()
				)
			}
			if self.pointer.getType() == Type<FindViews.ViewReadPointer>() {
				return SaleItemBidderInfo(
					bidder:self.offerCallback?.address,
					type: "directoffer",
					amount: self.offerCallback!.borrow()!.getBalance(self.pointer.getUUID())
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
				bidder: self.offerCallback?.address,
				type: "sale",
				amount: self.salePrice
			)

		}
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

		pub fun setAuction(auction: Auction, tenant: String) {

			if self.pointer.getType() != Type<FindViews.AuthNFTPointer>() {
				panic("cannot start an auction since we do not have permission to withdraw nft")
			}

			let pointer= self.pointer as! FindViews.AuthNFTPointer
			emit NFTEscrowed(tenant: tenant, id: pointer.id, nft:auction.nftInfo)
			let old <- self.escrow <- pointer.withdraw()
			destroy old
			self.auction=auction
		}

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


	pub struct Auction {

		//This should be taken out from the NFT but that is hard right now so we just put it here
		access(contract) let nftInfo: NFTInfo

		//this id is the uuid of the item beeing auctioned
		access(contract) var id: UInt64
		access(contract) var endsAt: UFix64
		access(contract) var startedAt: UFix64
		access(contract) let extendOnLateBid: UFix64
		access(contract) let minimumBidIncrement: UFix64
		access(contract) var latestBidCallback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>

		init(endsAt: UFix64, startedAt: UFix64, extendOnLateBid: UFix64, latestBidCallback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>, minimumBidIncrement: UFix64, id: UInt64, nftInfo: NFTInfo) {
			pre {
				extendOnLateBid != 0.0 : "Extends on late bid must be a non zero value"
			}
			self.id=id
			self.endsAt=endsAt
			self.startedAt=startedAt
			self.extendOnLateBid=extendOnLateBid
			self.minimumBidIncrement=minimumBidIncrement
			self.latestBidCallback=latestBidCallback
			self.nftInfo=nftInfo
		}

		pub fun getAuctionBalance() : UFix64 {
			return self.latestBidCallback.borrow()!.getBalance(self.id)
		}


		pub fun addBid(callback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>, timestamp: UFix64, tenantName: String, saleItem: &SaleItem) {
			let offer=callback.borrow()!
			offer.setBidType(id: self.id, type: "auction")

			let cb = self.latestBidCallback 
			let offerBalance=offer.getBalance(self.id)
			if callback.address != cb.address {
				let minBid=self.getAuctionBalance() + self.minimumBidIncrement

				if offerBalance < minBid {
					panic("bid ".concat(offerBalance.toString()).concat(" must be larger then previous bid+bidIncrement").concat(minBid.toString()))
				}
				cb.borrow()!.cancelBidFromSaleItem(self.id)
			}
			self.latestBidCallback=callback

			let suggestedEndTime=timestamp+self.extendOnLateBid
			if suggestedEndTime > self.endsAt {
				self.endsAt=suggestedEndTime
			}

			let seller=saleItem.owner!.address
			let buyer=cb.address
			let nftInfo=NFTInfo(saleItem.pointer.getViewResolver())

			emit ForAuction(tenant:tenantName, id: self.id, seller:seller, sellerName: FIND.reverseLookup(seller), amount: offerBalance, auctionReservePrice: saleItem.auctionReservePrice!,  active: false, vaultType:saleItem.vaultType.identifier, nft: nftInfo,  buyer: buyer, buyerName: FIND.reverseLookup(buyer), currentBid: offerBalance)

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

		//anybody should be able to fulfill an auction as long as it is done
		pub fun fulfillAuction(_ id: UInt64) 
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

			emit ForAuction(tenant:self.tenant.name, id: id, seller:owner, sellerName: FIND.reverseLookup(owner), amount: balance, auctionReservePrice: saleItem.auctionReservePrice!,  active: false, vaultType:saleItem.vaultType.identifier, nft: nftInfo,  buyer: buyer, buyerName: FIND.reverseLookup(buyer), currentBid: balance)

			let auction=Auction(endsAt:endsAt, startedAt: timestamp, extendOnLateBid: extensionOnLateBid, latestBidCallback: callback, minimumBidIncrement: saleItem.auctionMinBidIncrement, id: id, nftInfo:nftInfo)
			saleItem.setCallback(nil)
			saleItem.setAuction(auction:auction, tenant: self.tenant.name)

		}


		access(contract) fun cancelBid(_ id: UInt64) {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
			}

			let saleItem=self.borrow(id)

			if saleItem.auction != nil {
				panic("cannot cancel bid in auction")
			}

			if let callback = saleItem.offerCallback {
				emit DirectOfferCanceled(tenant: self.tenant.name, id: id, bidder: callback.address, vaultType:saleItem.vaultType.identifier)
			}

			saleItem.setCallback(nil)
		}

		access(contract) fun registerIncreasedBid(_ id: UInt64) {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
			}

			let saleItem=self.borrow(id)
			let timestamp=Clock.time()

			if let auction= saleItem.auction {
				if auction.endsAt < timestamp {
					panic("Auction has ended")
				}
				auction.addBid(callback:auction.latestBidCallback, timestamp:timestamp, tenantName:self.tenant.name, saleItem: saleItem)
				return
			}

			let balance=saleItem.offerCallback!.borrow()!.getBalance(id) 
			Debug.log("Offer is at ".concat(balance.toString()))
			if saleItem.salePrice == nil  && saleItem.auctionStartPrice == nil{
				emit DirectOfferBid(tenant:self.tenant.name, id: id, bidder: saleItem.offerCallback!.address, amount: balance, vaultType:saleItem.vaultType.identifier)
				return
			}


			if saleItem.salePrice != nil && balance >= saleItem.salePrice! {
				self.fulfill(id, type: "sale")
			} else if saleItem.auctionStartPrice != nil && balance >= saleItem.auctionStartPrice! {
				self.startAuction(id)
			} else {
				emit DirectOfferBid(tenant:self.tenant.name, id: id, bidder: saleItem.offerCallback!.address, amount: balance, vaultType:saleItem.vaultType.identifier)
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
				self.items[id] <-! saleItem
			} 

			let saleItem=self.borrow(id)
			if let auction= saleItem.auction {
				//TODO: if this tenantn does not support auctions panic here
				if auction.endsAt < timestamp {
					panic("Auction has ended")
				}
				//TODO:refactor!
				auction.addBid(callback:callback, timestamp:timestamp, tenantName:self.tenant.name, saleItem:saleItem)
				return
			}

			let balance=callback.borrow()!.getBalance(id)

			if let cb= saleItem.offerCallback {
				if cb.address == callback.address {
					panic("You already have the latest bid on this item, use the incraseBid transaction")
				}

				let currentBalance=cb.borrow()!.getBalance(id)
				Debug.log("currentBalance=".concat(currentBalance.toString()).concat(" new bid is at=").concat(balance.toString()))
				if currentBalance >= balance {
					panic("There is already a higher bid on this item")
				}
				cb.borrow()!.cancelBidFromSaleItem(id)
			}

			saleItem.setCallback(callback)


			Debug.log("Balance of bid is at ".concat(balance.toString()))
			if saleItem.salePrice == nil && saleItem.auctionStartPrice == nil {
				Debug.log("Sale price not set")
				emit DirectOfferBid(tenant:self.tenant.name, id: id, bidder: callback.address, amount: balance, vaultType: saleItem.vaultType.identifier)
				return
			}

			if saleItem.salePrice != nil && balance == saleItem.salePrice! {
				Debug.log("Direct sale!")
				self.fulfill(id, type: "sale")
			}	 else if saleItem.auctionStartPrice != nil && balance >= saleItem.auctionStartPrice! {
				self.startAuction(id)
			} else {
				emit DirectOfferBid(tenant:self.tenant.name, id: id, bidder: callback.address, amount: balance, vaultType:saleItem.vaultType.identifier)
			}

		}

		//cancel will cancel and auction or reject a bid if no auction has started
		pub fun cancel(_ id: UInt64) {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
			}

			let saleItem=self.borrow(id)
			let owner=self.owner!.address
			//if we have a callback there is no auction and it is a blind bid
			if let cb= saleItem.offerCallback {
				Debug.log("we have a direct offer so we cancel that")
				emit DirectOfferRejected(tenant:self.tenant.name, id: id, bidder: cb.address, amount: cb.borrow()!.getBalance(id), vaultType:saleItem.vaultType.identifier)
				cb.borrow()!.cancelBidFromSaleItem(id)
				saleItem.setCallback(nil)
				return 
			}

			if let auction= saleItem.auction {
				let balance=auction.getAuctionBalance()

				let auctionEnded= auction.endsAt <= Clock.time()
				var hasMetReservePrice= false
				if saleItem.auctionReservePrice != nil && saleItem.auctionReservePrice! <= balance {
					hasMetReservePrice=true
				}
				let price= saleItem.auctionReservePrice?.toString() ?? ""
				//the auction has ended
				Debug.log("Latest bid is ".concat(balance.toString()).concat(" reserve price is ").concat(price))
				if auctionEnded && hasMetReservePrice {
					panic("Cannot cancel finished auction, fulfill it instead")
				}

				let buyer=auction.latestBidCallback.address

				emit ForAuction(tenant:self.tenant.name, id: id, seller:owner, sellerName: FIND.reverseLookup(owner), amount: balance, auctionReservePrice: saleItem.auctionReservePrice!,  active: false, vaultType:saleItem.vaultType.identifier, nft: auction.nftInfo,  buyer: buyer, buyerName: FIND.reverseLookup(buyer), currentBid: balance)

				saleItem.returnNFT()
				auction.latestBidCallback.borrow()!.cancelBidFromSaleItem(id)
				destroy <- self.items.remove(key: id)
			}
		}

		/// fulfillAuction wraps the fulfill method and ensure that only a finished auction can be fulfilled by anybody
		pub fun fulfillAuction(_ id: UInt64) {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
				self.borrow(id).auction != nil : "Cannot fulfill sale that is not an auction=".concat(id.toString())
			}

			return self.fulfill(id, type:"Auction")
		}

		//Here we will have a seperate model to fulfill a direct offer since we then need to add the auth pointer to it?

		pub fun fulfillDirectOffer(_ pointer: FindViews.AuthNFTPointer) {
			pre {
				self.items.containsKey(pointer.getUUID()) : "Invalid id=".concat(pointer.getUUID().toString())
			}

			let id = pointer.getUUID()
			let saleItemRef = self.borrow(id)

			if let auction=saleItemRef.auction {
				panic("This item has an ongoing auction, you cannot fullfill this direct offer")
			}

			//Set the auth pointer in the saleItem so that it now can be fulfilled
			saleItemRef.setPointer(pointer)

			//need to singla that this is direct offer somehow
			self.fulfill(id, type: "direct")

		}

		pub fun fulfill(_ id: UInt64, type:String) {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
			}


			let saleItemRef = self.borrow(id)

			if let auction=saleItemRef.auction {
				if auction.endsAt > Clock.time() {
					panic("Auction has not ended yet")
				}

				let soldFor=auction.getAuctionBalance()
				let reservePrice=saleItemRef.auctionReservePrice ?? 0.0

				if reservePrice > soldFor {
					self.cancel(id)
					return
				}
			}

			let saleItem <- self.items.remove(key: id)!
			let ftType=saleItem.vaultType
			let owner=self.owner!.address

			if let cb= saleItem.offerCallback {
				let oldProfile= getAccount(owner).getCapability<&{Profile.Public}>(Profile.publicPath).borrow()!

				let offer= cb.borrow()!
				let buyer= cb.address
				let soldFor=offer.getBalance(id)
				//move the token to the new profile

				let nftInfo= NFTInfo(saleItem.pointer.getViewResolver())

				//TODO: emit an different event if type=="direct"
				if type !="direct" {
					emit ForSale(tenant:self.tenant.name, id: id, seller:owner, sellerName: FIND.reverseLookup(owner), amount: soldFor, active: false, vaultType: ftType.identifier, nft:nftInfo, buyer: buyer, buyerName: FIND.reverseLookup(buyer))
				} else {
					emit DirectOffer(tenant:self.tenant.name, id: id, seller:owner, sellerName: FIND.reverseLookup(owner), amount: soldFor, active: false, vaultType: ftType.identifier, nft:nftInfo, buyer: buyer, buyerName: FIND.reverseLookup(buyer))
				}

				let royaltyType=Type<MetadataViews.Royalties>()
				var royalty: MetadataViews.Royalties?=nil

				if saleItem.pointer.getViews().contains(royaltyType) {
					royalty = saleItem.pointer.resolveView(royaltyType)! as! MetadataViews.Royalties
				}

				let pointer= saleItem.pointer as! FindViews.AuthNFTPointer
 		    let vault <- cb.borrow()!.accept(<- pointer.withdraw())


				if royalty != nil {
					for royaltyItem in royalty!.getRoyalties() {
						let description=royaltyItem.description 
						let cutAmount= soldFor * royaltyItem.cut
						emit RoyaltyPaid(tenant:self.tenant.name, id: id, name: description, amount: cutAmount,  vaultType: ftType.identifier, nft:nftInfo)
						royaltyItem.receiver.borrow()!.deposit(from: <- vault.withdraw(amount: cutAmount))
					}
				}

				if let findCut =self.tenant.findCut {
					let cutAmount= soldFor * self.tenant.findCut!.cut
					emit RoyaltyPaid(tenant: self.tenant.name, id: id, name: "find", amount: cutAmount,  vaultType: ftType.identifier, nft:nftInfo)
					findCut.receiver.borrow()!.deposit(from: <- vault.withdraw(amount: cutAmount))
				}

				if let tenantCut =self.tenant.tenantCut {
					let cutAmount= soldFor * self.tenant.findCut!.cut
					emit RoyaltyPaid(tenant: self.tenant.name, id: id, name: "tenant", amount: cutAmount,  vaultType: ftType.identifier, nft:nftInfo)
					tenantCut.receiver.borrow()!.deposit(from: <- vault.withdraw(amount: cutAmount))
				}

				//TODO: should we use the method that emits good event here?
				oldProfile.deposit(from: <- vault)
			} else if let auction = saleItem.auction {

				let soldFor=auction.getAuctionBalance()
				let oldProfile= getAccount(saleItem.pointer.owner()).getCapability<&{Profile.Public}>(Profile.publicPath).borrow()!

				let buyer=auction.latestBidCallback.address
				emit ForAuction(tenant:self.tenant.name, id: id, seller:owner, sellerName: FIND.reverseLookup(owner), amount: soldFor, auctionReservePrice: saleItem.auctionReservePrice!,  active: false, vaultType: ftType.identifier, nft:auction.nftInfo, buyer: buyer, buyerName:FIND.reverseLookup(buyer), currentBid: soldFor)

				let nft <- saleItem.getEscrow()
				let vault <- auction.latestBidCallback.borrow()!.accept(<- nft)

				//let collectionRef = &self.collections[bucket] as! &TopShot.Collection
				/*
				//TODO: handle royalty from the escrowed item
				let royaltyType=Type<MetadataViews.Royalties>()
				var royalty: MetadataViews.Royalties?=nil

				if saleItem.pointer.getViews().contains(royaltyType) {
					royalty = saleItem.pointer.resolveView(royaltyType)! as! MetadataViews.Royalties
				}

				if royalty != nil {
					for royaltyItem in royalty!.getRoyalties() {
						let description=royaltyItem.description 
						let cutAmount= soldFor * royaltyItem.cut
						emit RoyaltyPaid(id: id, name: description, amount: cutAmount,  vaultType: ftType.identifier)
						royaltyItem.receiver.borrow()!.deposit(from: <- vault.withdraw(amount: cutAmount))
					}
				}

				if let findCut =self.tenant.findCut {
					let cutAmount= soldFor * self.tenant.findCut!.cut
					emit RoyaltyPaid(id: id, name: "find", amount: cutAmount,  vaultType: ftType.identifier)
					findCut.receiver.borrow()!.deposit(from: <- vault.withdraw(amount: cutAmount))
				}

				if let tenantCut =self.tenant.tenantCut {
					let cutAmount= soldFor * self.tenant.findCut!.cut
					emit RoyaltyPaid(id: id, name: "tenant", amount: cutAmount,  vaultType: ftType.identifier)
					tenantCut.receiver.borrow()!.deposit(from: <- vault.withdraw(amount: cutAmount))
				}
				*/

				//TODO: should we use the method that emits good event here?
				oldProfile.deposit(from: <- vault)
			}
			//TODO: if dandy mark royalty as paid!
			destroy  saleItem
		}

		pub fun listForAuction(pointer: FindViews.AuthNFTPointer, vaultType: Type, auctionStartPrice: UFix64, auctionReservePrice: UFix64, auctionDuration: UFix64, auctionExtensionOnLateBid: UFix64, minimumBidIncrement: UFix64) {

			let saleItem <- create SaleItem(pointer: pointer, vaultType:vaultType)

			saleItem.setStartAuctionPrice(auctionStartPrice)
			saleItem.setReservePrice(auctionReservePrice)
			saleItem.setAuctionDuration(auctionDuration)
			saleItem.setExtentionOnLateBid(auctionExtensionOnLateBid)
			saleItem.setMinBidIncrement(minimumBidIncrement)

			emit ForAuction(tenant:self.tenant.name, id: pointer.getUUID(), seller:self.owner!.address, sellerName: FIND.reverseLookup(self.owner!.address), amount: saleItem.auctionStartPrice!, auctionReservePrice: saleItem.auctionReservePrice!,  active: true, vaultType:vaultType.identifier, nft: NFTInfo(pointer.getViewResolver()), buyer: nil, buyerName:nil, currentBid: nil)

			self.items[pointer.getUUID()] <-! saleItem
		}

		pub fun listForSale(pointer: FindViews.AuthNFTPointer, vaultType: Type, directSellPrice:UFix64) {

			let saleItem <- create SaleItem(pointer: pointer, vaultType:vaultType)
			saleItem.setSalePrice(directSellPrice)

			let owner=self.owner!.address
			emit ForSale(tenant: self.tenant.name, id: pointer.getUUID(), seller:owner, sellerName: FIND.reverseLookup(owner), amount: saleItem.salePrice!, active: true, vaultType: vaultType.identifier, nft:NFTInfo(pointer.getViewResolver()), buyer: nil, buyerName:nil)
			self.items[pointer.getUUID()] <-! saleItem

		}

		pub fun delist(_ id: UInt64) {
			pre {
				self.items.containsKey(id) : "Unknown item with id=".concat(id.toString())
			}

			let saleItem <- self.items.remove(key: id)!
			//TODO: verify that bids are removed here.
			let owner=self.owner!.address
			emit ForSale(tenant:self.tenant.name, id: id, seller:owner, sellerName:FIND.reverseLookup(owner), amount: saleItem.salePrice!, active: false, vaultType: saleItem.vaultType.identifier,nft: NFTInfo(saleItem.pointer.getViewResolver()), buyer:nil, buyerName:nil)
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
		pub let type: String
		pub let amount: UFix64
		pub let timestamp: UFix64
		pub let item: SaleItemInformation

		init(id: UInt64, amount: UFix64, timestamp: UFix64, type: String, item:SaleItemInformation) {
			self.id=id
			self.amount=amount
			self.timestamp=timestamp
			self.type=type
			self.item=item
		}
	}

	//TODO: can not be escrowed
	pub resource Bid {
		access(contract) let from: Capability<&SaleItemCollection{SaleItemCollectionPublic}>
		access(contract) let nftCap: Capability<&{NonFungibleToken.Receiver}>
		access(contract) let itemUUID: UInt64

		//this should reflect on what the above uuid is for
		access(contract) var type: String
		access(contract) let vault: @FungibleToken.Vault
		access(contract) let vaultType: Type
		access(contract) var bidAt: UFix64

		init(from: Capability<&SaleItemCollection{SaleItemCollectionPublic}>, itemUUID: UInt64, vault: @FungibleToken.Vault, nftCap: Capability<&{NonFungibleToken.Receiver}>){
			self.vaultType= vault.getType()
			self.vault <- vault
			self.itemUUID=itemUUID
			self.from=from
			self.type="directOffer"
			self.bidAt=Clock.time()
			self.nftCap=nftCap
		}


		access(contract) fun setType(_ type: String) {
			self.type=type
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
		access(contract) fun accept(_ nft: @NonFungibleToken.NFT) : @FungibleToken.Vault
		access(contract) fun cancelBidFromSaleItem(_ id: UInt64)
		access(contract) fun setBidType(id: UInt64, type: String) 
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
		access(contract) fun accept(_ nft: @NonFungibleToken.NFT) : @FungibleToken.Vault {
			let isDandy = nft.getType() == Type<@Dandy.NFT>() 
			let id= nft.id
			let bid <- self.bids.remove(key: nft.uuid) ?? panic("missing bid")
			let vaultRef = &bid.vault as &FungibleToken.Vault
			bid.nftCap.borrow()!.deposit(token: <- nft)

			// TODO: is this a good idea? I do not think so anymore. 
			/*
			if isDandy {
				let address=bid.nftCap.address
				getAccount(address).getCapability<&{Dandy.CollectionPublic}>(Dandy.CollectionPublicPath).borrow()!.setPrimaryCutPaid(id)
			}
			*/
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
				bidInfo.append(BidInfo(id: bid.itemUUID, amount: bid.vault.balance, timestamp: bid.bidAt, type: bid.type, item:saleInfo))
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

		//increase a bid, will not work if the auction has already started
		pub fun increaseBid(id: UInt64, vault: @FungibleToken.Vault) {
			let bid =self.borrowBid(id)
			bid.setBidAt(Clock.time())
			bid.vault.deposit(from: <- vault)

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
			self.receiver.borrow()!.deposit(from: <- vaultRef.withdraw(amount: vaultRef.balance))
			destroy bid
		}

		pub fun borrowBid(_ id: UInt64): &Bid {
			return &self.bids[id] as &Bid
		}

		access(contract) fun setBidType(id: UInt64, type: String) {
			let bid= self.borrowBid(id)
			bid.setType(type)
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
