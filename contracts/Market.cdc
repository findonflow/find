import FungibleToken from "./standard/FungibleToken.cdc"
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import TypedMetadata from "../contracts/TypedMetadata.cdc"
import Profile from "./Profile.cdc"
import Clock from "./Clock.cdc"
import Debug from "./Debug.cdc"

/*

///Market

///A market contrat that allows a user to receive bids on his nfts, direct sell and english auction his nfts

The market has 2 collections
- MarketBidCollection: This contains all bids you have made, both bids on an auction and direct bids
- SaleItemCollection: This collection contains your saleItems and directOffers for your NFTs that others have made

*/
pub contract Market {

	pub let SaleItemCollectionStoragePath: StoragePath
	pub let SaleItemCollectionPublicPath: PublicPath

	pub let MarketBidCollectionStoragePath: StoragePath
	pub let MarketBidCollectionPublicPath: PublicPath

	pub event NFTEscrowed(id: UInt64)
	pub event RoyaltyPaid(id: UInt64, name:String, amount: UFix64, vaultType:String)

	//TODO: always add names as optionals and try to resolve. 
	/// Emitted when a name is sold to a new owner
	pub event Sold(id: UInt64, previousOwner: Address, newOwner: Address, amount: UFix64, vaultType:String)

	/// Emitted when a name is explicistly put up for sale
	pub event ForSale(id: UInt64, owner: Address, amount: UFix64, active: Bool, vaultType:String)
	pub event ForAuction(id: UInt64, owner: Address,  amount: UFix64, auctionReservePrice: UFix64, active: Bool, vaultType:String)

	/// Emitted if a bid occurs at a name that is too low or not for sale
	pub event DirectOfferBid(id: UInt64, bidder: Address, amount: UFix64, vaultType:String)

	/// Emitted if a blind bid is canceled
	pub event DirectOfferCanceled(id: UInt64, bidder: Address, vaultType:String)

	/// Emitted if a blind bid is rejected
	pub event DirectOfferRejected(id: UInt64, bidder: Address, amount: UFix64, vaultType:String)

	pub event AuctionCancelled(id: UInt64, bidder: Address, amount: UFix64, vaultType:String)

	/// Emitted when an auction starts. 
	pub event AuctionStarted(id: UInt64, bidder: Address, amount: UFix64, auctionEndAt: UFix64, vaultType:String)

	/// Emitted when there is a new bid in an auction
	pub event AuctionBid(id: UInt64, bidder: Address, amount: UFix64, auctionEndAt: UFix64, vaultType:String)


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

			self.type= item.pointer.getItemType()
			self.typeId=item.pointer.id
			self.id=item.pointer.getUUID()
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

	//TODO create SaleItemInformation struct that can be returned to gui
	pub resource SaleItem{

		access(contract) var escrow : @NonFungibleToken.NFT?
		access(contract) let vaultType: Type //The type of vault to use for this sale Item
		access(contract) var pointer: AnyStruct{TypedMetadata.Pointer}
		access(contract) var salePrice: UFix64?
		access(contract) var auctionStartPrice: UFix64?
		access(contract) var auctionReservePrice: UFix64?
		access(contract) var auctionDuration: UFix64
		access(contract) var auctionMinBidIncrement: UFix64
		access(contract) var auctionExtensionOnLateBid: UFix64
		access(contract) var offerCallback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>?

		//This most likely has to be a resource since we want to escrow when this starts
		access(contract) var auction: Auction?

		init(pointer: AnyStruct{TypedMetadata.Pointer}, vaultType: Type) {
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
			if self.pointer.getType() == Type<TypedMetadata.ViewReadPointer>() {
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
			let pointer= self.pointer as! TypedMetadata.AuthNFTPointer
			let nft <- self.escrow <- nil
			pointer.deposit(<- nft!)
		}

		pub fun sellNFT(_ cb : Capability<&MarketBidCollection{MarketBidCollectionPublic}>) : @FungibleToken.Vault {

			if self.auction != nil {
				let nft <- self.escrow <- nil
				return <- cb.borrow()!.accept(<- nft!)
			}

			let pointer= self.pointer as! TypedMetadata.AuthNFTPointer
			return <- cb.borrow()!.accept(<- pointer.withdraw())
		}

		//TODO: better error message if it is not there
		//TODO: is it correct to escrow it in here?
		pub fun setAuction(_ auction: Auction?) {

			if self.pointer.getType() != Type<TypedMetadata.AuthNFTPointer>() {
				panic("cannot start and auction since we do not have permission to withdraw nft")
			}

			let pointer= self.pointer as! TypedMetadata.AuthNFTPointer

			emit NFTEscrowed(id: pointer.id)
			let old <- self.escrow <- pointer.withdraw()
			//TODO: do something here
			destroy old
			self.auction=auction
		}

		pub fun setExtentionOnLateBid(_ time: UFix64) {
			self.auctionExtensionOnLateBid=time
		}

		pub fun setPointer(_ pointer: TypedMetadata.AuthNFTPointer) {
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

		//this id is the uuid of the item beeing auctioned
		access(contract) var id: UInt64
		access(contract) var endsAt: UFix64
		access(contract) var startedAt: UFix64
		access(contract) let extendOnLateBid: UFix64
		access(contract) let minimumBidIncrement: UFix64
		access(contract) var latestBidCallback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>

		init(endsAt: UFix64, startedAt: UFix64, extendOnLateBid: UFix64, latestBidCallback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>, minimumBidIncrement: UFix64, id: UInt64) {
			pre {
				extendOnLateBid != 0.0 : "Extends on late bid must be a non zero value"
			}
			self.id=id
			self.endsAt=endsAt
			self.startedAt=startedAt
			self.extendOnLateBid=extendOnLateBid
			self.minimumBidIncrement=minimumBidIncrement
			self.latestBidCallback=latestBidCallback
		}

		pub fun getAuctionBalance() : UFix64 {
			return self.latestBidCallback.borrow()!.getBalance(self.id)
		}


		pub fun addBid(callback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>, timestamp: UFix64) {
			let offer=callback.borrow()!
			offer.setBidType(id: self.id, type: "auction")

			let cb = self.latestBidCallback 
			if callback.address != cb.address {

				let offerBalance=offer.getBalance(self.id)
				let minBid=self.getAuctionBalance() + self.minimumBidIncrement

				if offerBalance < minBid {
					panic("bid ".concat(offerBalance.toString()).concat(" must be larger then previous bid+bidIncrement").concat(minBid.toString()))
				}
				cb.borrow()!.cancelBidFromLease(self.id)
			}
			self.latestBidCallback=callback

			let suggestedEndTime=timestamp+self.extendOnLateBid
			if suggestedEndTime > self.endsAt {
				self.endsAt=suggestedEndTime
			}
			emit AuctionBid(id: self.id, bidder: cb.address, amount: self.getAuctionBalance(), auctionEndAt: self.endsAt, vaultType:offer.getVaultType(self.id).identifier)

		}
	}

	pub resource interface SaleItemCollectionPublic {
		//fetch all the tokens in the collection
		pub fun getIds(): [UInt64]
		//fetch all names that are for sale

		pub fun getItemsForSale(): { UInt64:SaleItemInformation}

		pub fun getItemForSaleInformation(_ id:UInt64) : SaleItemInformation 

		access(contract)fun cancelBid(_ id: UInt64) 
		access(contract) fun registerIncreasedBid(_ id: UInt64) 

		//place a bid on a token
		access(contract) fun registerBid(item: TypedMetadata.ViewReadPointer, callback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>, vaultType:Type)

		//anybody should be able to fulfill an auction as long as it is done
		pub fun fulfillAuction(_ id: UInt64) 
	}

	pub resource SaleItemCollection: SaleItemCollectionPublic {
		//is this the best approach now or just put the NFT inside the saleItem?
		access(contract) var items: @{UInt64: SaleItem}

		//the cut the network will take, default 2.5%
		access(contract) let networkCut: UFix64

		//the wallet of the network to transfer royalty to
		access(contract) let networkWallet: Capability<&{FungibleToken.Receiver}>

		init (networkCut: UFix64, networkWallet: Capability<&{FungibleToken.Receiver}>) {
			self.items <- {}
			self.networkCut=networkCut
			self.networkWallet=networkWallet
		}

		pub fun getItemForSaleInformation(_ id:UInt64) : SaleItemInformation {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
			}
			return SaleItemInformation(self.borrow(id))

		}

		pub fun getItemsForSale(): { UInt64: SaleItemInformation} {
			let info: {UInt64:SaleItemInformation} ={}
			for id in self.getIds() {
				info[id]=SaleItemInformation(self.borrow(id))
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

			let callback=saleItem.offerCallback!
			let offer=callback.borrow()!

			let endsAt=timestamp + duration
			emit AuctionStarted(id: id, bidder: callback.address, amount: offer.getBalance(id), auctionEndAt: endsAt, vaultType: saleItem.vaultType.identifier)

			let auction=Auction(endsAt:endsAt, startedAt: timestamp, extendOnLateBid: extensionOnLateBid, latestBidCallback: callback, minimumBidIncrement: saleItem.auctionMinBidIncrement, id: id)
			saleItem.setCallback(nil)
			saleItem.setAuction(auction)

		}


		access(contract) fun cancelBid(_ id: UInt64) {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
				//TODO: handle pre that it should not be an auction
			}

			let saleItem=self.borrow(id)
			if let callback = saleItem.offerCallback {
				emit DirectOfferCanceled(id: id, bidder: callback.address, vaultType:saleItem.vaultType.identifier)
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
				auction.addBid(callback:auction.latestBidCallback, timestamp:timestamp)
				return
			}

			let balance=saleItem.offerCallback!.borrow()!.getBalance(id) 
			Debug.log("Offer is at ".concat(balance.toString()))
			if saleItem.salePrice == nil  && saleItem.auctionStartPrice == nil{
				emit DirectOfferBid(id: id, bidder: saleItem.offerCallback!.address, amount: balance, vaultType:saleItem.vaultType.identifier)
				return
			}


			if saleItem.salePrice != nil && balance >= saleItem.salePrice! {
				self.fulfill(id)
			} else if saleItem.auctionStartPrice != nil && balance >= saleItem.auctionStartPrice! {
				self.startAuction(id)
			} else {
				emit DirectOfferBid(id: id, bidder: saleItem.offerCallback!.address, amount: balance, vaultType:saleItem.vaultType.identifier)
			}
		}

		//This is a function that buyer will call (via his bid collection) to register the bicCallback with the seller
		access(contract) fun registerBid(item: TypedMetadata.ViewReadPointer, callback: Capability<&MarketBidCollection{MarketBidCollectionPublic}>, vaultType: Type) {

			let timestamp=Clock.time()

			let id = item.getUUID()

			if !self.items.containsKey(id) {
				let saleItem <- create SaleItem(pointer: item, vaultType:vaultType)
				self.items[id] <-! saleItem
			} 

			let saleItem=self.borrow(id)
			if let auction= saleItem.auction {
				if auction.endsAt < timestamp {
					panic("Auction has ended")
				}
				auction.addBid(callback:callback, timestamp:timestamp)
				return
			}


			//TODO: double check this vs FIND contract, we need to check price if higher or not here
			if let cb= saleItem.offerCallback {
				cb.borrow()!.cancelBidFromLease(id)
			}


			saleItem.setCallback(callback)

			let balance=callback.borrow()!.getBalance(id)

			Debug.log("Balance of bid is at ".concat(balance.toString()))
			if saleItem.salePrice == nil && saleItem.auctionStartPrice == nil {
				Debug.log("Sale price not set")
				emit DirectOfferBid(id: id, bidder: callback.address, amount: balance, vaultType: saleItem.vaultType.identifier)
				return
			}

			if saleItem.salePrice != nil && balance == saleItem.salePrice! {
				Debug.log("Direct sale!")
				self.fulfill(id)
			}	 else if saleItem.auctionStartPrice != nil && balance >= saleItem.auctionStartPrice! {
				self.startAuction(id)
			} else {
				emit DirectOfferBid(id: id, bidder: callback.address, amount: balance, vaultType:saleItem.vaultType.identifier)
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
				Debug.log("we have a blind bid so we cancel that")
				emit DirectOfferRejected(id: id, bidder: cb.address, amount: cb.borrow()!.getBalance(id), vaultType:saleItem.vaultType.identifier)
				cb.borrow()!.cancelBidFromLease(id)
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

				emit AuctionCancelled(id: id, bidder: auction.latestBidCallback.address, amount: balance, vaultType:saleItem.vaultType.identifier)
				emit ForAuction(id: id, owner:owner, amount: balance, auctionReservePrice: saleItem.auctionReservePrice!,  active: false, vaultType:saleItem.vaultType.identifier)

				saleItem.returnNFT()
				auction.latestBidCallback.borrow()!.cancelBidFromLease(id)
				destroy <- self.items.remove(key: id)
			}
		}

		/// fulfillAuction wraps the fulfill method and ensure that only a finished auction can be fulfilled by anybody
		pub fun fulfillAuction(_ id: UInt64) {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
				self.borrow(id).auction != nil : "Cannot fulfill sale that is not an auction=".concat(id.toString())
			}

			//TODO: add a check to see if we have reaced min bid price
			return self.fulfill(id)
		}

		//Here we will have a seperate model to fulfill a direct offer since we then need to add the auth pointer to it?

		pub fun fulfillDirectOffer(_ pointer: TypedMetadata.AuthNFTPointer) {
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

			self.fulfill(id)

		}

		pub fun fulfill(_ id: UInt64) {
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
				let soldFor=offer.getBalance(id)
				//move the token to the new profile
				emit Sold(id: id, previousOwner:owner, newOwner: cb.address, amount: soldFor, vaultType: ftType.identifier)
				emit ForSale(id: id, owner:owner, amount: soldFor, active: false, vaultType: ftType.identifier)

				let royaltyType=Type<AnyStruct{TypedMetadata.Royalty}>()
				var royalty: AnyStruct{TypedMetadata.Royalty}?=nil

				if saleItem.pointer.getViews().contains(royaltyType) {
					royalty = saleItem.pointer.resolveView(royaltyType) as! AnyStruct{TypedMetadata.Royalty}? 
				}

				let vault <- saleItem.sellNFT(cb)

				if royalty != nil {
					let royaltyVault <- vault.withdraw(amount: royalty!.calculateRoyalty(type: ftType, amount: soldFor)!)
					royalty!.distributeRoyalty(vault: <- royaltyVault)
				}
				if self.networkCut != 0.0 {
					let cutAmount= soldFor * self.networkCut
					emit RoyaltyPaid(id: id, name: "market", amount: cutAmount,  vaultType: ftType.identifier)
					self.networkWallet.borrow()!.deposit(from: <- vault.withdraw(amount: cutAmount))
				}

				//TODO: should we use the method that emits good event here?
				oldProfile.deposit(from: <- vault)
			} else if let auction = saleItem.auction {

				//TODO: fix royalty here.
				let soldFor=auction.getAuctionBalance()
				let oldProfile= getAccount(saleItem.pointer.owner()).getCapability<&{Profile.Public}>(Profile.publicPath).borrow()!

				emit Sold(id: id, previousOwner:owner, newOwner: auction.latestBidCallback.address, amount: soldFor, vaultType:ftType.identifier)
				emit ForAuction(id: id, owner:owner, amount: soldFor, auctionReservePrice: saleItem.auctionReservePrice!,  active: false, vaultType: ftType.identifier)

				let vault <- saleItem.sellNFT(auction.latestBidCallback)

				if self.networkCut != 0.0 {
					let cutAmount= soldFor * self.networkCut
					self.networkWallet.borrow()!.deposit(from: <- vault.withdraw(amount: cutAmount))
				}

				//TODO: should we use the method that emits good event here?
				oldProfile.deposit(from: <- vault)
			}
			destroy  saleItem

		}

		pub fun listForAuction(pointer: TypedMetadata.AuthNFTPointer, vaultType: Type, auctionStartPrice: UFix64, auctionReservePrice: UFix64, auctionDuration: UFix64, auctionExtensionOnLateBid: UFix64, minimumBidIncrement: UFix64) {

			let saleItem <- create SaleItem(pointer: pointer, vaultType:vaultType)

			saleItem.setStartAuctionPrice(auctionStartPrice)
			saleItem.setReservePrice(auctionReservePrice)
			saleItem.setAuctionDuration(auctionDuration)
			saleItem.setExtentionOnLateBid(auctionExtensionOnLateBid)
			saleItem.setMinBidIncrement(minimumBidIncrement)

			//TODO; need type and id of nft and uuid of saleItem
			emit ForAuction(id: pointer.getUUID(), owner:self.owner!.address, amount: saleItem.auctionStartPrice!, auctionReservePrice: saleItem.auctionReservePrice!,  active: true, vaultType:vaultType.identifier)

			self.items[pointer.getUUID()] <-! saleItem
		}

		pub fun listForSale(pointer: TypedMetadata.AuthNFTPointer, vaultType: Type, directSellPrice:UFix64) {

			let saleItem <- create SaleItem(pointer: pointer, vaultType:vaultType)
			saleItem.setSalePrice(directSellPrice)

			emit ForSale(id: pointer.getUUID(), owner:self.owner!.address, amount: saleItem.salePrice!, active: true, vaultType: vaultType.identifier)
			self.items[pointer.getUUID()] <-! saleItem

		}

		pub fun delist(_ id: UInt64) {
			pre {
				self.items.containsKey(id) : "Unknown item with id=".concat(id.toString())
			}

			let saleItem <- self.items.remove(key: id)!
			//TODO if this has bids cancel then
			emit ForSale(id: id, owner:self.owner!.address, amount: saleItem.salePrice!, active: false, vaultType: saleItem.vaultType.identifier)
			//this will transfer the NFT back
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

	//Create an empty lease collection that store your leases to a name
	pub fun createEmptySaleItemCollection(): @SaleItemCollection {
		let wallet=Market.account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
		return <- create SaleItemCollection(networkCut:0.025, networkWallet: wallet)
	}

	/*
	==========================================================================
	Bids are a collection/resource for storing the bids bidder made on leases
	==========================================================================
	*/

	/*

	From FIND		
	pub let name: String
	pub let type: String
	pub let amount: UFix64
	pub let timestamp: UFix64
	pub let lease: LeaseInformation?


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
		access(contract) fun cancelBidFromLease(_ id: UInt64)
		access(contract) fun setBidType(id: UInt64, type: String) 
	}

	//A collection stored for bidders/buyers
	pub resource MarketBidCollection: MarketBidCollectionPublic {

		access(contract) var bids : @{UInt64: Bid}
		access(contract) let receiver: Capability<&{FungibleToken.Receiver}>

		//not sure we can store this here anymore. think it needs to be in every bid
		init(receiver: Capability<&{FungibleToken.Receiver}>) {
			self.bids <- {}
			self.receiver=receiver
		}

		//called from lease when auction is ended
		access(contract) fun accept(_ nft: @NonFungibleToken.NFT) : @FungibleToken.Vault{

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
				bidInfo.append(BidInfo(id: bid.itemUUID, amount: bid.vault.balance, timestamp: bid.bidAt, type: bid.type, item:saleInfo))
			}
			return bidInfo
		}

		//the bid collection cannot be indexed on saleItem id since we have some bids that do not have saleItemId
		pub fun bid(item: TypedMetadata.ViewReadPointer, vault: @FungibleToken.Vault, nftCap: Capability<&{NonFungibleToken.Receiver}>) {
			pre {
				self.owner!.address != item.owner()  : "You cannot bid on your own resource"
				self.bids[item.getUUID()] == nil : "You already have an bid for this item, use increaseBid on that bid"
			}

			let uuid=item.getUUID()
			let from=getAccount(item.owner()).getCapability<&SaleItemCollection{SaleItemCollectionPublic}>(Market.SaleItemCollectionPublicPath)
			let vaultType=vault.getType()

			let bid <- create Bid(from: from, itemUUID:item.getUUID(), vault: <- vault, nftCap: nftCap)
			let saleItemCollection= from.borrow() ?? panic("Could not borrow sale item for id=".concat(uuid.toString()))
			let callbackCapability =self.owner!.getCapability<&MarketBidCollection{MarketBidCollectionPublic}>(Market.MarketBidCollectionPublicPath)
			let oldToken <- self.bids[uuid] <- bid
			//send info to leaseCollection
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
			self.cancelBidFromLease(id)
		}

		//called from lease when things are cancelled
		//if the bid is canceled from seller then we move the vault tokens back into your vault
		access(contract) fun cancelBidFromLease(_ id: UInt64) {
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

	pub fun createEmptyMarketBidCollection(receiver: Capability<&{FungibleToken.Receiver}>) : @MarketBidCollection {
		return <- create MarketBidCollection(receiver: receiver)
	}

	init() {

		self.SaleItemCollectionStoragePath=/storage/findMarketSaleItem
		self.SaleItemCollectionPublicPath=/public/findMarketSaleItem

		self.MarketBidCollectionStoragePath=/storage/findMarketBids
		self.MarketBidCollectionPublicPath=/public/findMarketBids
	}
}
