import FungibleToken from "./standard/FungibleToken.cdc"
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import Profile from "./Profile.cdc"
import Clock from "./Clock.cdc"
import Debug from "./Debug.cdc"

/*

///Market

///A market contrat that allows a user to receive bids on his nfts, direct sell and english auction his nfts

The market has 2 collections
 - BidCollection: This contains all bids you have made, both bids on an auction and direct bids
 - SaleItemCollection: This collection contains your saleItems and directOffers for your NFTs that others have made

*/
pub contract Market {

	pub let SaleItemCollectionStoragePath: StoragePath
	pub let SaleItemCollectionPublicPath: PublicPath

	pub let BidCollectionStoragePath: StoragePath
	pub let BidCollectionPublicPath: PublicPath

	/// Emitted when a name is sold to a new owner
	pub event Sold(id: UInt64, previousOwner: Address, newOwner: Address, amount: UFix64)

	/// Emitted when a name is explicistly put up for sale
	pub event ForSale(id: UInt64, owner: Address, directSellPrice: UFix64, active: Bool)
	pub event ForAuction(id: UInt64, owner: Address,  auctionStartPrice: UFix64, auctionReservePrice: UFix64, active: Bool)

	/// Emitted if a bid occurs at a name that is too low or not for sale
	pub event DirectOfferBid(id: UInt64, bidder: Address, amount: UFix64)

	/// Emitted if a blind bid is canceled
	pub event DirectOfferCanceled(id: UInt64, bidder: Address)

	/// Emitted if a blind bid is rejected
	pub event DirectOfferRejected(id: UInt64, bidder: Address, amount: UFix64)

	pub event AuctionCancelled(id: UInt64, bidder: Address, amount: UFix64)

	/// Emitted when an auction starts. 
	pub event AuctionStarted(id: UInt64, bidder: Address, amount: UFix64, auctionEndAt: UFix64)

	/// Emitted when there is a new bid in an auction
	pub event AuctionBid(id: UInt64, bidder: Address, amount: UFix64, auctionEndAt: UFix64)


	//TODO create SaleItemInformation struct that can be returned to gui

	//can this be a struct?
	pub resource SaleItem{
		//TODO: until NFT standard me need metadata here I think so that we can display properly

		access(contract) let vaultType: Type //The type of vault to use for this sale Item
		access(contract) var nft: @NonFungibleToken.NFT? //this has to be optional since we have to send it somewhere
		access(contract) var salePrice: UFix64?
		access(contract) var auctionStartPrice: UFix64?
		access(contract) var auctionReservePrice: UFix64?
		access(contract) var auctionDuration: UFix64
		access(contract) var auctionMinBidIncrement: UFix64
		access(contract) var auctionExtensionOnLateBid: UFix64
		access(contract) var offerCallback: Capability<&BidCollection{BidCollectionPublic}>?
		access(contract) var auction: Auction?
		access(contract) var ownerCallback: Capability<&{NonFungibleToken.Receiver}>

		init(nft:@NonFungibleToken.NFT, vaultType: Type, ownerCallback: Capability<&{NonFungibleToken.Receiver}>) {
			self.ownerCallback=ownerCallback
			self.vaultType=vaultType
			self.nft <- nft
			self.salePrice=nil
			self.auctionStartPrice=nil
			self.auctionReservePrice=nil
			self.auctionDuration=86400.0
			self.auctionExtensionOnLateBid=300.0
			self.auctionMinBidIncrement=10.0
			self.offerCallback=nil
			self.auction=nil
		}

		pub fun sellNFT(_ cb : Capability<&BidCollection{BidCollectionPublic}>) : @FungibleToken.Vault {
			let token <- self.nft <- nil
			return <- cb.borrow()!.fulfill(<- token!)
		}

		pub fun setAuction(_ auction: Auction?) {
			self.auction=auction
		}

		pub fun setExtentionOnLateBid(_ time: UFix64) {
			self.auctionExtensionOnLateBid=time
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

		pub fun setCallback(_ callback: Capability<&BidCollection{BidCollectionPublic}>?) {
			self.offerCallback=callback
		}

		destroy () {


			if let token <- self.nft {
				self.ownerCallback.borrow()!.deposit(token: <- token)
			} else {
				//DEAD CODE
				destroy self.nft
			}
		}
	}


	pub struct Auction {

		//right now saleItem and bid share id, that is the id of the bid is the id of the saleItem, that does not hold anymore
		access(contract) var id: UInt64
		access(contract) var endsAt: UFix64
		access(contract) var startedAt: UFix64
		access(contract) let extendOnLateBid: UFix64
		access(contract) let minimumBidIncrement: UFix64
		access(contract) var latestBidCallback: Capability<&BidCollection{BidCollectionPublic}>

		//let auction=Auction(endsAt:endsAt, startedAt: timestamp, extendOnLateBid: extensionOnLateBid, latestBidCallback: callback, id: id)
		init(endsAt: UFix64, startedAt: UFix64, extendOnLateBid: UFix64, latestBidCallback: Capability<&BidCollection{BidCollectionPublic}>, minimumBidIncrement: UFix64, id: UInt64) {
			pre {
				extendOnLateBid != 0.0 : "Extends on late bid must be a non zero value"
			}
			self.id=id
			self.endsAt=self.endsAt
			self.startedAt=self.startedAt
			self.extendOnLateBid=extendOnLateBid
			self.minimumBidIncrement=minimumBidIncrement
			self.latestBidCallback=latestBidCallback
		}

		pub fun getBalance() : UFix64 {
			return self.latestBidCallback.borrow()!.getBalance(self.id)
		}

		pub fun addBid(callback: Capability<&BidCollection{BidCollectionPublic}>, timestamp: UFix64) {
			let offer=callback.borrow()!
			offer.setBidType(id: self.id, type: "auction")

			let cb = self.latestBidCallback 
			if callback.address != cb.address {

				let offerBalance=offer.getBalance(self.id)
				let minBid=self.getBalance() + self.minimumBidIncrement

				if offerBalance < minBid {
					panic("bid ".concat(offerBalance.toString()).concat(" must be larger then previous bid+bidIncrement").concat(minBid.toString()))
				}
				cb.borrow()!.cancel(self.id)
			}
			self.latestBidCallback=callback
			let suggestedEndTime=timestamp+self.extendOnLateBid
			if suggestedEndTime > self.endsAt {
				self.endsAt=suggestedEndTime
			}
			emit AuctionBid(id: self.id, bidder: cb.address, amount: self.getBalance(), auctionEndAt: self.endsAt)

		}
	}

	pub resource interface SaleItemCollectionPublic {
		//fetch all the tokens in the collection
		pub fun getIds(): [UInt64]
		//fetch all names that are for sale

		access(contract)fun cancelBid(_ id: UInt64) 
		//		access(contract) fun increaseBid(_ id: UInt64) 

		//place a bid on a token
		access(contract) fun bid(id: UInt64, callback: Capability<&BidCollection{BidCollectionPublic}>)

		//anybody should be able to fulfill an auction as long as it is done
		pub fun fulfillAuction(_ id: UInt64) 
	}

	pub resource DirectOffer {
		access(contract) let vaultType: Type //The type of vault to use for this sale Item
		access(contract) var nftId: UInt64
		access(contract) var nftCap: Capability<&{NonFungibleToken.CollectionPublic}>
		access(contract) var offerCallback: Capability<&BidCollection{BidCollectionPublic}>

		init(cb: Capability<&BidCollection{BidCollectionPublic}>, vaultType: Type, nftId:UInt64, nftCap: Capability<&{NonFungibleToken.CollectionPublic}>) {

			self.offerCallback=cb
			self.nftCap=nftCap
			self.nftId=nftId
			self.vaultType=vaultType
		}

		pub fun getBalance() : UFix64 {
			return self.offerCallback.borrow()!.getBalance(self.uuid)
		}

	}

	pub resource SaleItemCollection: SaleItemCollectionPublic {
		//is this the best approach now or just put the NFT inside the saleItem?
		access(contract) var items: @{UInt64: SaleItem}

		access(contract) var directOffers: @{UInt64: DirectOffer}
		//todo blind bids

		//the cut the network will take, default 2.5%
		access(contract) let networkCut: UFix64

		//the wallet of the network to transfer royalty to
		access(contract) let networkWallet: Capability<&{FungibleToken.Receiver}>

		init (networkCut: UFix64, networkWallet: Capability<&{FungibleToken.Receiver}>) {
			self.items <- {}
			self.directOffers <- {}
			self.networkCut=networkCut
			self.networkWallet=networkWallet
		}

		//call this to start an auction for this lease
		pub fun startAuction(_ id: UInt64) {
			//TODO: pre id
			let timestamp=Clock.time()
			let saleItem = self.borrow(id)
			let duration=saleItem.auctionDuration
			let extensionOnLateBid=saleItem.auctionExtensionOnLateBid
			if saleItem.offerCallback == nil {
				panic("cannot start an auction on a name without a bid, set salePrice")
			}

			let callback=saleItem.offerCallback!
			let offer=callback.borrow()!

			let endsAt=timestamp + duration
			emit AuctionStarted(id: id, bidder: callback.address, amount: offer.getBalance(id), auctionEndAt: endsAt)

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
				emit DirectOfferCanceled(id: id, bidder: callback.address)
			}

			saleItem.setCallback(nil)
		}

		/*
		access(contract) fun increaseBid(_ id: UInt64) {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
			}

			let saleItem=self.items[id]!
			let timestamp=Clock.time()

			if let auction= saleItem.auction {
				if auction.endsAt < timestamp {
					panic("Auction has ended")
				}
				auction.addBid(callback:auction.latestBidCallback, timestamp:timestamp)
				return
			}

			add this back when we add DirectOffers again
			let balance=saleItem.offerCallback!.borrow()!.getBalance(id) 
			Debug.log("Offer is at ".concat(balance.toString()))
			if saleItem.salePrice == nil  && saleItem.auctionStartPrice == nil{
				emit DirectOffer(id: id, bidder: saleItem.offerCallback!.address, amount: balance)
				return
			}


			if saleItem.salePrice != nil && balance >= saleItem.salePrice! {
				self.fulfill(id)
			} else if saleItem.auctionStartPrice != nil && balance >= saleItem.auctionStartPrice! {
				self.startAuction(id)
			} else {
				emit DirectOffer(id: id, bidder: saleItem.offerCallback!.address, amount: balance)
			}

		}
		*/

		access(contract) fun bid(id: UInt64, callback: Capability<&BidCollection{BidCollectionPublic}>) {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
			}

			let timestamp=Clock.time()
			let saleItem=self.borrow(id)

			if let auction= saleItem.auction {
				if auction.endsAt < timestamp {
					panic("Auction has ended")
				}
				auction.addBid(callback:callback, timestamp:timestamp)
				return
			}

			/*
			add back when we have DirectOffers
			if let cb= saleItem.offerCallback {
				cb.borrow()!.cancel(id)
			}
			*/

			saleItem.setCallback(callback)

			let balance=callback.borrow()!.getBalance(id)

			/*
			Debug.log("Balance of lease is at ".concat(balance.toString()))
			if saleItem.salePrice == nil && saleItem.auctionStartPrice == nil {
				Debug.log("Sale price not set")
				emit DirectOffer(id: id, bidder: callback.address, amount: balance)
				return
			}
			*/

			if saleItem.salePrice != nil && balance == saleItem.salePrice! {
				Debug.log("Direct sale!")
				self.fulfill(id)
			}	 else if saleItem.auctionStartPrice != nil && balance >= saleItem.auctionStartPrice! {
				self.startAuction(id)
			} 

			/*
			else {

				emit DirectOffer(id: id, bidder: callback.address, amount: balance)
			}
			*/

		}

		//cancel will cancel and auction or reject a bid if no auction has started
		pub fun cancel(_ id: UInt64) {
			pre {
				self.items.containsKey(id) : "Invalid name=".concat(id.toString())
			}

			let saleItem=self.borrow(id)
			//if we have a callback there is no auction and it is a blind bid
			if let cb= saleItem.offerCallback {
				Debug.log("we have a blind bid so we cancel that")
				emit DirectOfferRejected(id: id, bidder: cb.address, amount: cb.borrow()!.getBalance(id))
				cb.borrow()!.cancel(id)
				saleItem.setCallback(nil)
				return 
			}

			if let auction= saleItem.auction {
				let balance=auction.getBalance()

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

				emit AuctionCancelled(id: id, bidder: auction.latestBidCallback.address, amount: balance)
				auction.latestBidCallback.borrow()!.cancel(id)
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

		pub fun fulfill(_ id: UInt64) {
			pre {
				self.items.containsKey(id) : "Invalid id=".concat(id.toString())
				//todo more PRE checks
			}


			let saleItemRef = self.borrow(id)

			if let auction=saleItemRef.auction {
				if auction.endsAt > Clock.time() {
					panic("Auction has not ended yet")
				}

				let soldFor=auction.getBalance()
				let reservePrice=saleItemRef.auctionReservePrice ?? 0.0

				if reservePrice > soldFor {
					self.cancel(id)
					return
				}
			}

			let saleItem <- self.items.remove(key: id)!
			let owner=self.owner!.address

			if let cb= saleItem.offerCallback {
				let oldProfile= getAccount(owner).getCapability<&{Profile.Public}>(Profile.publicPath).borrow()!

				let offer= cb.borrow()!
				let soldFor=offer.getBalance(id)
				//move the token to the new profile
				emit Sold(id: id, previousOwner:offer.owner!.address, newOwner: cb.address, amount: soldFor)

				let vault <- saleItem.sellNFT(cb)
				if self.networkCut != 0.0 {
					let cutAmount= soldFor * self.networkCut
					self.networkWallet.borrow()!.deposit(from: <- vault.withdraw(amount: cutAmount))
				}

				oldProfile.deposit(from: <- vault)
			} else if let auction = saleItem.auction {

				let soldFor=auction.getBalance()
				let oldProfile= getAccount(saleItem.ownerCallback.address).getCapability<&{Profile.Public}>(Profile.publicPath).borrow()!

				emit Sold(id: id, previousOwner:owner, newOwner: auction.latestBidCallback.address, amount: soldFor)

				let vault <- saleItem.sellNFT(auction.latestBidCallback)
				if self.networkCut != 0.0 {
					let cutAmount= soldFor * self.networkCut
					//TODO: must  check type of fusd to return 
					//or just use the profile cap here for royalty?
					//no better to use NFT standard
					self.networkWallet.borrow()!.deposit(from: <- vault.withdraw(amount: cutAmount))
				}

				oldProfile.deposit(from: <- vault)
			}
			destroy  saleItem

			panic("Item is not for auction id=".concat(id.toString()))
			

		}

		//TODO: this needs to be different, need to add NFT here
		pub fun listForAuction(nft: @NonFungibleToken.NFT, callback: Capability<&{NonFungibleToken.Receiver}>, vaultType: Type, auctionStartPrice: UFix64, auctionReservePrice: UFix64, auctionDuration: UFix64, auctionExtensionOnLateBid: UFix64, minimumBidIncrement: UFix64) {

			let saleItem <- create SaleItem(nft: <- nft, vaultType:vaultType, ownerCallback: callback)

			saleItem.setStartAuctionPrice(auctionStartPrice)
			saleItem.setReservePrice(auctionReservePrice)
			saleItem.setAuctionDuration(auctionDuration)
			saleItem.setExtentionOnLateBid(auctionExtensionOnLateBid)
			saleItem.setMinBidIncrement(minimumBidIncrement)

			//TODO; need type and id of nft and uuid of saleItem
			emit ForAuction(id: saleItem.uuid, owner:self.owner!.address, auctionStartPrice: saleItem.auctionStartPrice!, auctionReservePrice: saleItem.auctionReservePrice!,  active: true)

			self.items[saleItem.uuid] <-! saleItem
		}

		pub fun listForSale(nft: @NonFungibleToken.NFT, callback: Capability<&{NonFungibleToken.Receiver}>, vaultType: Type, directSellPrice:UFix64) {

			let saleItem <- create SaleItem(nft: <- nft, vaultType:vaultType, ownerCallback: callback)
			saleItem.setSalePrice(directSellPrice)

			//TODO; need type and id of nft and uuid of saleItem
			emit ForSale(id: saleItem.uuid, owner:self.owner!.address, directSellPrice: saleItem.salePrice!, active: true)
			self.items[saleItem.uuid] <-! saleItem

		}


		pub fun delist(_ id: UInt64) {
			pre {
				self.items.containsKey(id) : "Unknown item with id=".concat(id.toString())
			}

			let saleItem <- self.items.remove(key: id)!
			//TODO if this has bids cancel then
			emit ForSale(id: id, owner:self.owner!.address, directSellPrice: saleItem.salePrice!, active: false)
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
			destroy self.directOffers
		}
	}

	//Create an empty lease collection that store your leases to a name
	pub fun createEmptySaleItemCollection(): @SaleItemCollection {
		//TODO:: add another ft
		//TODO: customize this
		//use royalty here

		let wallet = Market.account.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
		return <- create SaleItemCollection(networkCut:0.05, networkWallet: wallet)
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

		init(id: UInt64, amount: UFix64, timestamp: UFix64, type: String) {
			self.id=id
			self.amount=amount
			self.timestamp=timestamp
			self.type=type
		}
	}

	pub resource Bid {
		access(contract) let from: Capability<&SaleItemCollection{SaleItemCollectionPublic}>
		access(contract) let nftCap: Capability<&{NonFungibleToken.Receiver}>
		//This cannot be saleItemUUID anymore, as it is UUID of either saleItem or directOffer
		access(contract) let saleItemUUID: UInt64

		//this should reflect on what the above uuid is for
		access(contract) var type: String
		access(contract) let vault: @FungibleToken.Vault
		access(contract) var bidAt: UFix64

		init(from: Capability<&SaleItemCollection{SaleItemCollectionPublic}>, saleItemUUID: UInt64, vault: @FungibleToken.Vault, nftCap: Capability<&{NonFungibleToken.Receiver}>){
			self.vault <- vault
			self.saleItemUUID=saleItemUUID
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

	pub resource interface BidCollectionPublic {
		pub fun getBids() : [BidInfo]
		pub fun getBalance(_ id: UInt64) : UFix64
		access(contract) fun fulfill(_ token: @NonFungibleToken.NFT) : @FungibleToken.Vault
		access(contract) fun cancel(_ id: UInt64)
		access(contract) fun setBidType(id: UInt64, type: String) 
	}

	//A collection stored for bidders/buyers
	pub resource BidCollection: BidCollectionPublic {

		access(contract) var bids : @{UInt64: Bid}
		access(contract) let receiver: Capability<&{FungibleToken.Receiver}>

		//not sure we can store this here anymore. think it needs to be in every bid
		init(receiver: Capability<&{FungibleToken.Receiver}>) {
			self.bids <- {}
			self.receiver=receiver
		}

		//called from lease when auction is ended
		//if purchase if fulfilled then we deposit money back into vault we get passed along and token into your own leases collection
		access(contract) fun fulfill(_ token: @NonFungibleToken.NFT) : @FungibleToken.Vault{
			let bid <- self.bids.remove(key: token.uuid) ?? panic("missing bid")
			let vaultRef = &bid.vault as &FungibleToken.Vault
			bid.nftCap.borrow()!.deposit(token: <- token)
			let vault  <- vaultRef.withdraw(amount: vaultRef.balance)
			destroy bid
			return <- vault
		}


		pub fun getBids() : [BidInfo] {
			var bidInfo: [BidInfo] = []
			for id in self.bids.keys {
				let bid = self.borrowBid(id)
				bidInfo.append(BidInfo(id: bid.saleItemUUID, amount: bid.vault.balance, timestamp: bid.bidAt, type: bid.type))
			}
			return bidInfo
		}

		//this is offer on something that is not even listed
		pub fun directOffer() {

		}
		//* this is bid on saleItem */
		//the bid collection cannot be indexed on saleItem id since we have some bids that do not have saleItemId
		pub fun bid(id: UInt64, vault: @FungibleToken.Vault, nftCap: Capability<&{NonFungibleToken.Receiver}>) {
			let from=getAccount(self.owner!.address).getCapability<&SaleItemCollection{SaleItemCollectionPublic}>(Market.SaleItemCollectionPublicPath)

			let bid <- create Bid(from: from, saleItemUUID:id, vault: <- vault, nftCap: nftCap)
			let saleItemCollection= from.borrow() ?? panic("Could not borrow sale item for id=".concat(id.toString()))
			let callbackCapability =self.owner!.getCapability<&BidCollection{BidCollectionPublic}>(Market.BidCollectionPublicPath)
			let oldToken <- self.bids[id] <- bid
			//send info to leaseCollection
			destroy oldToken
			saleItemCollection.bid(id: id, callback: callbackCapability) 
		}

		/*
		//increase a bid, will not work if the auction has already started
		pub fun increaseBid(id: UInt64, vault: @FungibleToken.Vault) {
			let bid =self.borrowBid(id)
			bid.setBidAt(Clock.time())
			bid.vault.deposit(from: <- vault)

			bid.from.borrow()!.increaseBid(id)
		}
		*/

		/// The users cancel a bid himself
		pub fun cancelBid(_ id: UInt64) {
			let bid= self.borrowBid(id)
			bid.from.borrow()!.cancelBid(id)
			self.cancel(id)
		}

		//called from lease when things are cancelled
		//if the bid is canceled from seller then we move the vault tokens back into your vault
		access(contract) fun cancel(_ id: UInt64) {
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

	pub fun createEmptyBidCollection(receiver: Capability<&{FungibleToken.Receiver}>) : @BidCollection {
		return <- create BidCollection(receiver: receiver)
	}

	init() {

		self.SaleItemCollectionStoragePath=/storage/findMarketSaleItem
		self.SaleItemCollectionPublicPath=/public/findMarketSaleItem

		self.BidCollectionStoragePath=/storage/findMarketBids
		self.BidCollectionPublicPath=/public/findMarketBids
	}
}
