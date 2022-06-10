import MetadataViews from "./standard/MetadataViews.cdc"
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import FungibleToken from "./standard/FungibleToken.cdc"
import FUSD from "./standard/FUSD.cdc"
import Profile from "./Profile.cdc"
import Debug from "./Debug.cdc"
import Clock from "./Clock.cdc"
// import Dandy from "./Dandy.cdc"
import Sender from "./Sender.cdc"
/*

///FIND

///Flow Integrated Name Directory - A naming service on flow,

/// Lease a name in the network for as little as 5 FUSD a year, (4 characters cost 100, 3 cost 500)

Taxonomy:

- name: a textual description minimum 3 chars long that can be leased in FIND 
- profile: A Versus profile that represents a person, a name registed in FIND points to a profile
- lease: a resource representing registering a name for a period of 1 year
- leaseCollection: Collection of the leases an account holds
- leaseStatus: FREE|TAKEN|LOCKED, a LOCKED lease can be reopend by the owner. A lease will be locked for 90 days before it is freed
*/
pub contract FIND {


	//Old events not in use anymore we cannot remove
  	pub event Sold()
	pub event SoldAuction()
  	pub event DirectOfferRejected()
	pub event DirectOfferCanceled()
	pub event AuctionStarted()
	pub event AuctionCanceled()
	pub event AuctionBid()
	pub event AuctionCanceledReservePrice()
	pub event ForSale()
	pub event ForAuction()


	//event when FT is sent
	pub event FungibleTokenSent(from:Address, fromName:String?, name:String, toAddress:Address, message:String, tag:String, amount: UFix64, ftType:Type)

	/// An event to singla that there is a name in the network
	pub event Name(name: String)

	pub event AddonActivated(name: String, addon:String)

	///  Emitted when a name is registred in FIND
	pub event Register(name: String, owner: Address, validUntil: UFix64, lockedUntil: UFix64)

	/// Emitted when a name is moved to a new owner
	pub event Moved(name: String, previousOwner: Address, newOwner: Address, validUntil: UFix64, lockedUntil: UFix64)

	/// Emitted when a name is explicistly put up for sale
	pub event Sale(name: String, uuid:UInt64, seller: Address, sellerName: String?, amount: UFix64, status: String, vaultType:String, buyer:Address?, buyerName:String?, validUntil: UFix64, lockedUntil: UFix64)

	/// Emitted when an name is put up for on-demand auction
	pub event EnglishAuction(name: String, uuid:UInt64, seller: Address, sellerName:String?, amount: UFix64, auctionReservePrice: UFix64, status: String, vaultType:String, buyer:Address?, buyerName:String?, endsAt: UFix64?, validUntil: UFix64, lockedUntil: UFix64)

	/// Emitted if a bid occurs at a name that is too low or not for sale
	pub event DirectOffer(name: String, uuid:UInt64, seller: Address, sellerName: String?, amount: UFix64, status: String, vaultType:String, buyer:Address?, buyerName:String?, validUntil: UFix64, lockedUntil: UFix64)

	pub event CastForge(name: String, uuid: UInt64, forgeType: String, action: String)

	//store bids made by a bidder to somebody elses leases
	pub let BidPublicPath: PublicPath
	pub let BidStoragePath: StoragePath

	//store the network itself
	pub let NetworkStoragePath: StoragePath
	pub let NetworkPrivatePath: PrivatePath

	//store the leases you own
	pub let LeaseStoragePath: StoragePath
	pub let LeasePublicPath: PublicPath

	//forge 
	access(contract) let forgeCasterCapabilities : {String : Capability<&{Forge}>}

	pub fun getLeases() : [NetworkLease] {
		if let network = self.account.borrow<&Network>(from: FIND.NetworkStoragePath) {
			return network.profiles.values
		}
		panic("Network is not set up")
	}
	
	//These methods are basically just here for convenience

	/// Calculate the cost of an name
	/// @param _ the name to calculate the cost for
	pub fun calculateCost(_ name:String) : UFix64 {
		pre {
			FIND.validateFindName(name) : "A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters"
		}


		if let network = self.account.borrow<&Network>(from: FIND.NetworkStoragePath) {
			return network.calculateCost(name)
		}
		panic("Network is not set up")
	}

	pub fun resolve(_ input:String) : Address? {
		if FIND.validateFindName(input) {
			return FIND.lookupAddress(input)
		}

		var address=input
		if input.utf8[1] == 120 {
			address = input.slice(from: 2, upTo: input.length)
		}
		var r:UInt64 = 0 
		var bytes = address.decodeHex()

		while bytes.length>0{
			r = r  + (UInt64(bytes.removeFirst()) << UInt64(bytes.length * 8 ))
		}

		return Address(r)
	}

	/// Lookup the address registered for a name
	pub fun lookupAddress(_ name:String): Address? {
		pre {
			FIND.validateFindName(name) : "A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters"
		}

		if let network = self.account.borrow<&Network>(from: FIND.NetworkStoragePath) {
			return network.lookup(name)?.owner?.address
		}
		panic("Network is not set up")
	}

	/// Lookup the profile registered for a name
	pub fun lookup(_ input:String): &{Profile.Public}? {

		if FIND.validateFindName(input) {
			if let network = self.account.borrow<&Network>(from: FIND.NetworkStoragePath) {
				return network.lookup(input)
			}
		}

		var address=input
		if input.utf8[1] == 120 {
			address = input.slice(from: 2, upTo: input.length)
		}
		var r:UInt64 = 0 
		var bytes = address.decodeHex()

		while bytes.length>0{
			r = r  + (UInt64(bytes.removeFirst()) << UInt64(bytes.length * 8 ))
		}

		let account = getAccount(Address(r))
		let cap = account.getCapability<&{Profile.Public}>(Profile.publicPath)
		if cap.check() {
			return cap.borrow()!
		}

		panic("Network is not set up")
	}


	pub fun reverseLookupFN() : ((Address) : String?) {
		return fun(address:Address): String? { 
			return FIND.reverseLookup(address) 
		}
	}

	/// lookup if an address has a .find name, if it does pick either the default one or the first registered
	pub fun reverseLookup(_ address:Address): String? {
		let account=getAccount(address)
		let leaseCap = account.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)

		if !leaseCap.check() {
			return nil
		}

		let profileFindName= Profile.find(address).getFindName()
		let leases = leaseCap.borrow()!.getLeaseInformation() 
		var time : UFix64?= nil
		var name :String?= nil
		for lease in leases {

			//filter out all leases that are FREE or LOCKED since they are not actice
			if lease.status != "TAKEN" {
				continue
			}

			//if we have not set a 
			if profileFindName == "" {
				if time == nil || lease.validUntil < time! {
					time=lease.validUntil
					name=lease.name
				}
			}

			if profileFindName == lease.name {
				return lease.name
			}
		}
		return name
	}

	/// Deposit FT to name
	/// @param to: The name to send money too
	/// @param message: The message to send
	/// @param tag: The tag to add to the event 
	/// @param vault: The vault to send too
	/// @param from: The sender that sent the funds
	pub fun depositWithTagAndMessage(to:String, message:String, tag: String, vault: @FungibleToken.Vault, from: &Sender.Token) {
		pre {
			FIND.validateFindName(to) : "A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters"
		}

		if let network = self.account.borrow<&Network>(from: FIND.NetworkStoragePath) {
			let profile=network.lookup(to) ?? panic("could not find name")
			let fromAddress= from.owner!.address
			emit FungibleTokenSent(from: fromAddress, fromName: FIND.reverseLookup(fromAddress), name: to, toAddress: profile.getAddress(), message:message, tag:tag, amount:vault.balance, ftType:vault.getType()) 
			profile.deposit(from: <- vault)
			return 
		}
		panic("Network is not set up")
	}

	/// Deposit FT to name
	/// @param to: The name to send money too
	/// @param from: The vault to send too
	pub fun deposit(to:String, from: @FungibleToken.Vault) {
		pre {
			FIND.validateFindName(to) : "A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters"
		}

		if let network = self.account.borrow<&Network>(from: FIND.NetworkStoragePath) {
			let profile=network.lookup(to) ?? panic("could not find name")
			profile.deposit(from: <- from)
			return 
		}
		panic("Network is not set up")
	}

	/// Return the status for a given name
	/// @return The Name status of a name
	pub fun status(_ name: String): NameStatus {
		pre {
			FIND.validateFindName(name) : "A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters"
		}

		if let network = self.account.borrow<&Network>(from: FIND.NetworkStoragePath) {
			return network.readStatus(name)
		}
		panic("Network is not set up")
	}


	/// Struct holding information about a lease. Contains both the internal status the owner of the lease and if the state is persisted or not. 
	pub struct NameStatus{
		pub let status: LeaseStatus
		pub let owner: Address?

		init(status:LeaseStatus, owner:Address?) {
			self.status=status
			self.owner=owner
		}
	}

	// PlatformMinter is a compulsory element for minters 
	pub struct MinterPlatform {
		pub let platform: Capability<&{FungibleToken.Receiver}>
		pub let platformPercentCut: UFix64
		pub let name: String
		pub let description: String 
		pub let externalURL: String 
		pub let squareImage: String 
		pub let bannerImage: String 

		init(name: String, platform:Capability<&{FungibleToken.Receiver}>, platformPercentCut: UFix64, description: String, externalURL: String, squareImage: String, bannerImage: String) {
			self.platform=platform
			self.platformPercentCut=platformPercentCut
			self.name=name
			self.description=description 
			self.externalURL=externalURL 
			self.squareImage=squareImage 
			self.bannerImage=bannerImage
		}
	}

	// ForgeMinter Interface 
	pub resource interface ForgeMinter {
		pub fun mint(minterPlatform: MinterPlatform, data: AnyStruct) : @NonFungibleToken.NFT 
	}

	pub resource interface Forge {
		access(account) fun createForge() : @{ForgeMinter}
	}

	/*
	=============================================================
	Lease is a collection/resource for storing the token leases 
	Also have a seperate Auction for tracking auctioning of leases
	=============================================================
	*/

	/*

	Lease is a resource you get back when you register a lease.
	You can use methods on it to renew the lease or to move to another profile
	*/
	pub resource Lease {
		access(contract) let name: String
		access(contract) let networkCap: Capability<&Network> 
		access(contract) var salePrice: UFix64?
		access(contract) var auctionStartPrice: UFix64?
		access(contract) var auctionReservePrice: UFix64?
		access(contract) var auctionDuration: UFix64
		access(contract) var auctionMinBidIncrement: UFix64
		access(contract) var auctionExtensionOnLateBid: UFix64
		access(contract) var offerCallback: Capability<&BidCollection{BidCollectionPublic}>?
		access(contract) var addons: {String: Bool}
		access(contract) var forges: @{String : {ForgeMinter}}

		init(name:String, networkCap: Capability<&Network>) {
			self.name=name
			self.networkCap= networkCap
			self.salePrice=nil
			self.auctionStartPrice=nil
			self.auctionReservePrice=nil
			self.auctionDuration=86400.0
			self.auctionExtensionOnLateBid=300.0
			self.auctionMinBidIncrement=10.0
			self.offerCallback=nil
			self.addons={}
			self.forges<-{}
		}

		destroy() {
			destroy self.forges
		}

		access(contract) fun addForge(_ forge: @{ForgeMinter}) {
			pre{
				!self.forges.containsKey(forge.getType().identifier) : "This forge minter already exist :".concat(forge.getType().identifier)
			}
			let key = forge.getType().identifier
			self.forges[key] <-! forge
			emit CastForge(name: self.name, uuid: self.uuid, forgeType: key, action: "addForge")
		}

		access(contract) fun removeForge(_ forge: String) {
			pre{
				self.forges.containsKey(forge) : "This forge minter does not exist :".concat(forge)
			}
			destroy self.forges.remove(key: forge)!
			emit CastForge(name: self.name, uuid: self.uuid, forgeType: forge, action: "removeForge")
		}

		access(contract) fun borrowForge(_ forge: String) : &{ForgeMinter}? {
			return &self.forges[forge] as &{ForgeMinter}?
		}

		pub fun getForges() : [String] {
			return self.forges.keys
		}

		pub fun containsForge(_ forge: String) : Bool {
			return self.forges.containsKey(forge)
		}

		pub fun addAddon(_ addon:String) {
			self.addons[addon]=true
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

		pub fun extendLease(_ vault: @FUSD.Vault) {
			let network= self.networkCap.borrow()!
			network.renew(name: self.name, vault:<-  vault)
		}

		access(contract) fun move(profile: Capability<&{Profile.Public}>) {
			let network= self.networkCap.borrow()!
			network.move(name: self.name, profile: profile)
		}

		pub fun getLeaseExpireTime() : UFix64 {
			return self.networkCap.borrow()!.getLeaseExpireTime(self.name)
		}

		pub fun getLeaseLockedUntil() : UFix64 {
			return self.networkCap.borrow()!.getLeaseLockedUntil(self.name)
		}

		pub fun getProfile():&{Profile.Public}? {
			return self.networkCap.borrow()!.profile(self.name)
		}

		pub fun getLeaseStatus() : LeaseStatus {
			return FIND.status(self.name).status
		}
	}

	/* An Auction for a lease */
	pub resource Auction {
		access(contract) var endsAt: UFix64
		access(contract) var startedAt: UFix64
		access(contract) let extendOnLateBid: UFix64
		access(contract) var latestBidCallback: Capability<&BidCollection{BidCollectionPublic}>
		access(contract) let name: String

		init(endsAt: UFix64, startedAt: UFix64, extendOnLateBid: UFix64, latestBidCallback: Capability<&BidCollection{BidCollectionPublic}>, name: String) {
			pre {
				startedAt < endsAt : "Cannot start before it will end"
				extendOnLateBid != 0.0 : "Extends on late bid must be a non zero value"
			}
			self.endsAt=endsAt
			self.startedAt=startedAt
			self.extendOnLateBid=extendOnLateBid
			self.latestBidCallback=latestBidCallback
			self.name=name
		}

		pub fun getBalance() : UFix64 {
			return self.latestBidCallback.borrow()!.getBalance(self.name)
		}

		pub fun addBid(callback: Capability<&BidCollection{BidCollectionPublic}>, timestamp: UFix64, lease: &Lease) {
			let offer=callback.borrow()!
			offer.setBidType(name: self.name, type: "auction")

			if callback.address != self.latestBidCallback.address {
				if offer.getBalance(self.name) <= self.getBalance() {
					panic("bid must be larger then previous bid")
				}
				//we send the money back
				self.latestBidCallback.borrow()!.cancel(self.name)
			}
			self.latestBidCallback=callback
			let suggestedEndTime=timestamp+self.extendOnLateBid
			if suggestedEndTime > self.endsAt {
				self.endsAt=suggestedEndTime
			}

			let bidder= callback.address
			let profile=getAccount(bidder).getCapability<&{Profile.Public}>(Profile.publicPath).borrow()
			if profile == nil {
				panic("Create a profile before you make a bid")
			}
			let bidderName= profile!.getName()
			let owner=lease.owner!.address
			let ownerName=lease.getProfile()!.getName()

			emit EnglishAuction(name: self.name, uuid: lease.uuid, seller: owner, sellerName:ownerName, amount: offer.getBalance(self.name), auctionReservePrice: lease.auctionReservePrice!, status: "active_ongoing", vaultType:Type<@FUSD.Vault>().identifier, buyer:bidder, buyerName:bidderName, endsAt: self.endsAt ,validUntil: lease.getLeaseExpireTime(), lockedUntil: lease.getLeaseLockedUntil())
		}
	}

	//struct to expose information about leases
	pub struct LeaseInformation {
		pub let name: String
		pub let address: Address
		pub let cost: UFix64
		pub let status: String
		pub let validUntil: UFix64
		pub let lockedUntil: UFix64
		pub let latestBid: UFix64?
		pub let auctionEnds: UFix64?
		pub let salePrice: UFix64?
		pub let latestBidBy: Address?
		pub let currentTime: UFix64
		pub let auctionStartPrice: UFix64?
		pub let auctionReservePrice: UFix64?
		pub let extensionOnLateBid: UFix64?
		pub let addons: [String]

		init(name: String, status:LeaseStatus, validUntil: UFix64, lockedUntil:UFix64, latestBid: UFix64?, auctionEnds: UFix64?, salePrice: UFix64?, latestBidBy: Address?, auctionStartPrice: UFix64?, auctionReservePrice: UFix64?, extensionOnLateBid:UFix64?, address:Address, addons: [String]){

			self.name=name
			var s="TAKEN"	
			if status == LeaseStatus.FREE {
				s="FREE"
			} else if status == LeaseStatus.LOCKED {
				s="LOCKED"
			}
			self.status=s
			self.validUntil=validUntil
			self.lockedUntil=lockedUntil
			self.latestBid=latestBid
			self.latestBidBy=latestBidBy
			self.auctionEnds=auctionEnds
			self.salePrice=salePrice
			self.currentTime=Clock.time()
			self.auctionStartPrice=auctionStartPrice
			self.auctionReservePrice=auctionReservePrice
			self.extensionOnLateBid=extensionOnLateBid
			self.address=address
			self.cost=FIND.calculateCost(name)
			self.addons=addons

		}

	}
	/*
	Since a single account can own more then one name there is a collecition of them
	This collection has build in support for direct sale of a FIND leaseToken. The network owner till take 2.5% cut
	*/
	pub resource interface LeaseCollectionPublic {
		//fetch all the tokens in the collection
		pub fun getLeases(): [String]
		//fetch all names that are for sale
		pub fun getLeaseInformation() : [LeaseInformation]
		pub fun getLease(_ name: String) :LeaseInformation?

		//add a new lease token to the collection, can only be called in this contract
		access(contract) fun deposit(token: @FIND.Lease)

		access(contract)fun cancelUserBid(_ name: String) 
		access(contract) fun increaseBid(_ name: String, balance: UFix64) 

		//place a bid on a token
		access(contract) fun registerBid(name: String, callback: Capability<&BidCollection{BidCollectionPublic}>)

		//anybody should be able to fulfill an auction as long as it is done
		pub fun fulfillAuction(_ name: String) 
		pub fun buyAddon(name:String, addon: String, vault: @FUSD.Vault) 

	}


	pub resource LeaseCollection: LeaseCollectionPublic {
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(contract) var leases: @{String: FIND.Lease}

		access(contract) var auctions: @{String: Auction}

		//the cut the network will take, default 2.5%
		access(contract) let networkCut: UFix64

		//the wallet of the network to transfer royalty to
		access(contract) let networkWallet: Capability<&{FungibleToken.Receiver}>

		init (networkCut: UFix64, networkWallet: Capability<&{FungibleToken.Receiver}>) {
			self.leases <- {}
			self.auctions <- {}
			self.networkCut=networkCut
			self.networkWallet=networkWallet
		}

		access(contract) fun createPlatform(name: String, description: String, externalURL: String, squareImage: String, bannerImage: String) : FIND.MinterPlatform{
			let receiverCap=FIND.account.getCapability<&{FungibleToken.Receiver}>(Profile.publicReceiverPath)
			return FIND.MinterPlatform(name:name, receiverCap:receiverCap, platformPercentCut: 0.025, description: description, externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage)
		}

		// pub fun mintDandy(minter: String, nftName: String, description: String, thumbnail: MetadataViews.Media, schemas: [AnyStruct], externalUrlPrefix: String?, collectionDescription: String, collectionExternalURL: String, collectionSquareImage: String, collectionBannerImage: String) : @Dandy.NFT {

		// 	let lease = self.borrow(minter)
		// 	if !lease.addons.containsKey("forge") {
		// 		panic("You do not have the forge addon, buy it first")
		// 	}

		// 	return <- Dandy.mintNFT(name:nftName, description:description, thumbnail: thumbnail, platform: self.createPlatform(name: minter, description: collectionDescription, externalURL: collectionExternalURL, squareImage: collectionSquareImage, bannerImage: collectionBannerImage), schemas: schemas, externalUrlPrefix:externalUrlPrefix)
		// }

		pub fun mintWithForge(minter: String, forge: String, name: String, description: String, externalURL: String, squareImage: String, bannerImage: String, mintData: AnyStruct) : @NonFungibleToken.NFT {
			pre {
				self.leases.containsKey(name) : "Invalid name=".concat(name)
			}

			let lease = self.borrow(name)
			assert(lease.containsForge(forge) , message: "This name is not equipped with specified forge. Name: ".concat(forge))
			let forge = lease.borrowForge(forge)!

			let minterPlatform = self.createPlatform(name: name, description: description, externalURL: externalURL, squareImage: squareImage, bannerImage: bannerImage)
			return <- forge.mint(minterPlatform: minterPlatform, data: mintData)
		}

		// add forge to the collection of forge under find name
		pub fun addForge(name: String, forgeType: String) {
			pre {
				self.leases.containsKey(name) : "Invalid name=".concat(name)
				FIND.forgeCasterCapabilities.containsKey(forgeType) : "Invalid forge type=".concat(forgeType)
			}

			let lease = self.borrow(name)

			let forgeCap = FIND.forgeCasterCapabilities[forgeType]! 
			let forgeRef = forgeCap.borrow() ?? panic("Forge capability is not set up properly.")
			let forge <- forgeRef.createForge()

			lease.addForge(<- forge)
		}

		pub fun buyAddon(name:String, addon:String, vault: @FUSD.Vault)  {
			pre {
				self.leases.containsKey(name) : "Invalid name=".concat(name)
			}

			let lease = self.borrow(name)

			if lease.addons.containsKey(addon) {
				panic("You already have this addon")
			}

			if addon=="forge" && vault.balance != 50.0 {
				panic("Expect 50 FUSD for forge addon")
			}

			lease.addAddon(addon)

			//put something in your storage
			emit AddonActivated(name: name, addon: addon)
			self.networkWallet.borrow()!.deposit(from: <- vault)
		}

		pub fun getLease(_ name: String) : LeaseInformation? {
			if !self.leases.containsKey(name) {
				return nil 
			}
			let token=self.borrow(name)

			var latestBid: UFix64? = nil
			var auctionEnds: UFix64?= nil
			var latestBidBy: Address?=nil

			if self.auctions.containsKey(name) {
				let auction = self.borrowAuction(name)
				auctionEnds= auction.endsAt
				latestBid= auction.getBalance()
				latestBidBy= auction.latestBidCallback.address
			} else {
				if let callback = token.offerCallback {
					latestBid= callback.borrow()!.getBalance(name)
					latestBidBy=callback.address
				}
			}

			return LeaseInformation(name:  name, status: token.getLeaseStatus(), validUntil: token.getLeaseExpireTime(), lockedUntil: token.getLeaseLockedUntil(), latestBid: latestBid, auctionEnds: auctionEnds, salePrice: token.salePrice, latestBidBy: latestBidBy, auctionStartPrice: token.auctionStartPrice, auctionReservePrice: token.auctionReservePrice, extensionOnLateBid: token.auctionExtensionOnLateBid, address: token.owner!.address, addons: token.addons.keys)
		}

		pub fun getLeaseInformation() : [LeaseInformation]  {
			var info: [LeaseInformation]=[]
			for name in self.leases.keys {
				if !FIND.validateFindName(name) {
					continue
				}
				let lease=self.getLease(name)
				if lease != nil && lease!.status != "FREE" {
					info.append(lease!)
				}
			}
			return info
		}

		//call this to start an auction for this lease
		pub fun startAuction(_ name: String) {
			let timestamp=Clock.time()
			let lease = self.borrow(name)
			let duration=lease.auctionDuration
			let extensionOnLateBid=lease.auctionExtensionOnLateBid
			if lease.offerCallback == nil {
				panic("cannot start an auction on a name without a bid, set salePrice")
			}

			let callback=lease.offerCallback!
			let offer=callback.borrow()!
			offer.setBidType(name: name, type: "auction")



			let bidder= callback.address
			let bidderName= getAccount(bidder).getCapability<&{Profile.Public}>(Profile.publicPath).borrow()!.getName()
			let owner=lease.owner!.address
			let ownerName=lease.getProfile()!.getName()

			let endsAt=timestamp + duration
			emit EnglishAuction(name: name, uuid:lease.uuid, seller: owner, sellerName:FIND.reverseLookup(owner), amount: offer.getBalance(name), auctionReservePrice: lease.auctionReservePrice!, status: "active_ongoing", vaultType:Type<@FUSD.Vault>().identifier, buyer:bidder, buyerName:bidderName, endsAt: endsAt, validUntil: lease.getLeaseExpireTime(), lockedUntil: lease.getLeaseLockedUntil())

			let oldAuction <- self.auctions[name] <- create Auction(endsAt:endsAt, startedAt: timestamp, extendOnLateBid: extensionOnLateBid, latestBidCallback: callback, name: name)
			lease.setCallback(nil)

			if lease.offerCallback == nil {
				Debug.log("offer callback is empty")
			}else {
				Debug.log("offer callback is NOT empty")
			}

			destroy oldAuction
		}

		access(contract) fun cancelUserBid(_ name: String) {
			pre {
				self.leases.containsKey(name) : "Invalid name=".concat(name)
				!self.auctions.containsKey(name) : "Cannot cancel a bid that is in an auction=".concat(name)
			}

			let lease= self.borrow(name)

			if let callback = lease.offerCallback {

				let bidder= callback.address
				let bidderName= getAccount(bidder).getCapability<&{Profile.Public}>(Profile.publicPath).borrow()!.getName()
				let owner=lease.owner!.address
				let ownerName=lease.getProfile()!.getName()
				var amount : UFix64 = 0.0
				if callback.check() {
					amount = callback.borrow()!.getBalance(name)
				}
				emit DirectOffer(name: name, uuid: lease.uuid, seller: owner, sellerName: ownerName, amount: amount, status: "cancel_rejected", vaultType:Type<@FUSD.Vault>().identifier, buyer:bidder, buyerName:bidderName, validUntil: lease.getLeaseExpireTime(), lockedUntil: lease.getLeaseLockedUntil())
			}

			lease.setCallback(nil)
		}

		access(contract) fun increaseBid(_ name: String, balance: UFix64) {
			pre {
				self.leases.containsKey(name) : "Invalid name=".concat(name)
			}

			let lease = self.borrow(name)
			let timestamp=Clock.time()

			assert(balance >= lease.auctionMinBidIncrement, message: "Increment should be greater than ".concat(lease.auctionMinBidIncrement.toString()))

			if self.auctions.containsKey(name) {
				let auction = self.borrowAuction(name)
				if auction.endsAt < timestamp {
					panic("Auction has ended")
				}
				auction.addBid(callback:auction.latestBidCallback, timestamp:timestamp, lease: lease)
				return
			}


			let bidder= lease.offerCallback!.address
			let bidderName= getAccount(bidder).getCapability<&{Profile.Public}>(Profile.publicPath).borrow()?.getName()
			let owner=lease.owner!.address
			let ownerName=lease.getProfile()!.getName()

			let balance=lease.offerCallback!.borrow()!.getBalance(name) 
			Debug.log("Offer is at ".concat(balance.toString()))
			if lease.salePrice == nil  && lease.auctionStartPrice == nil{

				emit DirectOffer(name: name, uuid: lease.uuid, seller: owner, sellerName: ownerName, amount: balance, status: "active_offered", vaultType:Type<@FUSD.Vault>().identifier, buyer:bidder, buyerName:bidderName, validUntil: lease.getLeaseExpireTime(), lockedUntil: lease.getLeaseLockedUntil())
				return
			}


			if lease.salePrice != nil && lease.salePrice != nil && balance >= lease.salePrice! {
				self.fulfill(name)
			} else if lease.auctionStartPrice != nil && balance >= lease.auctionStartPrice! {
				self.startAuction(name)
			} else {
				emit DirectOffer(name: name, uuid: lease.uuid, seller: owner, sellerName: ownerName, amount: balance, status: "active_offered", vaultType:Type<@FUSD.Vault>().identifier, buyer:bidder, buyerName:bidderName, validUntil: lease.getLeaseExpireTime(), lockedUntil: lease.getLeaseLockedUntil())
			}

		}

		access(contract) fun registerBid(name: String, callback: Capability<&BidCollection{BidCollectionPublic}>) {
			pre {
				self.leases.containsKey(name) : "Invalid name=".concat(name)
			}

			let timestamp=Clock.time()
			let lease = self.borrow(name)

			if self.auctions.containsKey(name) {
				let auction = self.borrowAuction(name)

				if auction.latestBidCallback.address == callback.address {
					panic("You already have the latest bid on this item, use the incraseBid transaction")
				}
				if auction.endsAt < timestamp {
					panic("Auction has ended")
				}
				auction.addBid(callback:callback, timestamp:timestamp, lease: lease)
				return
			} 

			let balance=callback.borrow()!.getBalance(name)
			if let cb= lease.offerCallback {
				if cb.address == callback.address {
					panic("You already have the latest bid on this item, use the incraseBid transaction")
				}
				let currentBalance=cb.borrow()!.getBalance(name)

				Debug.log("currentBalance=".concat(currentBalance.toString()).concat(" new bid is at=").concat(balance.toString()))
				if currentBalance >= balance {
					panic("There is already a higher bid on this lease")
				}

				cb.borrow()!.cancel(name)
			}

			lease.setCallback(callback)



			let bidder= callback.address
			let profile=getAccount(bidder).getCapability<&{Profile.Public}>(Profile.publicPath).borrow()
			if profile == nil {
				panic("Create a profile before you make a bid")
			}
			let bidderName= profile!.getName()
			let owner=lease.owner!.address
			let ownerName=lease.getProfile()!.getName()


			Debug.log("Balance of lease is at ".concat(balance.toString()))
			if lease.salePrice == nil && lease.auctionStartPrice == nil {
				Debug.log("Sale price not set")
				emit DirectOffer(name: name, uuid:lease.uuid, seller: owner, sellerName: ownerName, amount: balance, status: "offered", vaultType:Type<@FUSD.Vault>().identifier, buyer:bidder, buyerName:bidderName, validUntil: lease.getLeaseExpireTime(), lockedUntil: lease.getLeaseLockedUntil())
				return
			}

			if lease.salePrice != nil && balance >= lease.salePrice! {
				Debug.log("Direct sale!")
				self.fulfill(name)
			}	 else if lease.auctionStartPrice != nil && balance >= lease.auctionStartPrice! {
				self.startAuction(name)
			} else {
				emit DirectOffer(name: name, uuid: lease.uuid, seller: owner, sellerName: ownerName, amount: balance, status: "offered", vaultType:Type<@FUSD.Vault>().identifier, buyer:bidder, buyerName:bidderName, validUntil: lease.getLeaseExpireTime(), lockedUntil: lease.getLeaseLockedUntil())
			}

		}

		//cancel will cancel and auction or reject a bid if no auction has started
		pub fun cancel(_ name: String) {
			pre {
				self.leases.containsKey(name) : "Invalid name=".concat(name)
			}

			let lease = self.borrow(name)
			//if we have a callback there is no auction and it is a blind bid
			if let cb= lease.offerCallback {

				let bidder= cb.address
				let bidderName= getAccount(bidder).getCapability<&{Profile.Public}>(Profile.publicPath).borrow()!.getName()
				let owner=lease.owner!.address
				let ownerName=lease.getProfile()!.getName()
				Debug.log("we have a blind bid so we cancel that")
				emit DirectOffer(name: name, uuid:lease.uuid, seller: owner, sellerName: ownerName, amount: cb.borrow()!.getBalance(name), status: "rejected", vaultType:Type<@FUSD.Vault>().identifier, buyer:bidder, buyerName:bidderName, validUntil: lease.getLeaseExpireTime(), lockedUntil: lease.getLeaseLockedUntil())
				
				cb.borrow()!.cancel(name)
				lease.setCallback(nil)
			}

			if self.auctions.containsKey(name) {

				let auction=self.borrowAuction(name)
				let balance=auction.getBalance()

				let auctionEnded= auction.endsAt <= Clock.time()
				var hasMetReservePrice= false
				if lease.auctionReservePrice != nil && lease.auctionReservePrice! <= balance {
					hasMetReservePrice=true
				}
				let price= lease.auctionReservePrice?.toString() ?? ""
				//the auction has ended
				Debug.log("Latest bid is ".concat(balance.toString()).concat(" reserve price is ").concat(price))
				if auctionEnded && hasMetReservePrice {
					//&& lease.auctionReservePrice != nil && lease.auctionReservePrice! < balance {
					panic("Cannot cancel finished auction, fulfill it instead")
				}

				let bidder= auction.latestBidCallback.address
				let bidderName= getAccount(bidder).getCapability<&{Profile.Public}>(Profile.publicPath).borrow()!.getName()
				let owner=lease.owner!.address
				let ownerName=lease.getProfile()!.getName()


				let leaseInfo = self.getLease(name)!
				
				if auctionEnded {
					emit EnglishAuction(name: name, uuid:lease.uuid, seller: owner, sellerName:ownerName, amount: balance, auctionReservePrice: lease.auctionReservePrice!, status: "cancel_reserved_not_met", vaultType:Type<@FUSD.Vault>().identifier, buyer:bidder, buyerName:bidderName, endsAt: auction.endsAt, validUntil: lease.getLeaseExpireTime(), lockedUntil: lease.getLeaseLockedUntil())
				} else {
					emit EnglishAuction(name: name, uuid:lease.uuid, seller: owner, sellerName:ownerName, amount: balance, auctionReservePrice: lease.auctionReservePrice!, status: "cancel_listing", vaultType:Type<@FUSD.Vault>().identifier, buyer:bidder, buyerName:bidderName, endsAt: auction.endsAt, validUntil: lease.getLeaseExpireTime(), lockedUntil: lease.getLeaseLockedUntil())
				}
				auction.latestBidCallback.borrow()!.cancel(name)
				destroy <- self.auctions.remove(key: name)!
			}
		}

		/// fulfillAuction wraps the fulfill method and ensure that only a finished auction can be fulfilled by anybody
		pub fun fulfillAuction(_ name: String) {
			pre {
				self.leases.containsKey(name) : "Invalid name=".concat(name)
				self.auctions.containsKey(name) : "Cannot fulfill sale that is not an auction=".concat(name)
			}

			return self.fulfill(name)
		}

		pub fun fulfill(_ name: String) {
			pre {
				self.leases.containsKey(name) : "Invalid name=".concat(name)
			}

			let lease = self.borrow(name)
			if lease.getLeaseStatus() == LeaseStatus.FREE {
				panic("cannot fulfill sale name is now free")
			}

			let oldProfile=lease.getProfile()!
			
			if let cb= lease.offerCallback {
				let offer= cb.borrow()!
				let newProfile= getAccount(cb.address).getCapability<&{Profile.Public}>(Profile.publicPath)
				let soldFor=offer.getBalance(name)
				emit Sale(name: name, uuid: lease.uuid, seller: lease.owner!.address, sellerName: FIND.reverseLookup(lease.owner!.address), amount: soldFor, status: "sold", vaultType:Type<@FUSD.Vault>().identifier, buyer:newProfile.address, buyerName:FIND.reverseLookup(newProfile.address), validUntil: lease.getLeaseExpireTime(), lockedUntil: lease.getLeaseLockedUntil())
				//move the token to the new profile
				lease.move(profile: newProfile)

				let token <- self.leases.remove(key: name)!
				let vault <- offer.fulfillLease(<- token)
				if self.networkCut != 0.0 {
					let cutAmount= soldFor * self.networkCut
					self.networkWallet.borrow()!.deposit(from: <- vault.withdraw(amount: cutAmount))
				}

				//why not use Profile to send money :P
				oldProfile.deposit(from: <- vault)
				return
			}

			if !self.auctions.containsKey(name) {
				panic("Name is not for auction name=".concat(name))
			}

			if self.borrowAuction(name).endsAt > Clock.time() {
				panic("Auction has not ended yet")
			}


			let auctionRef=self.borrowAuction(name)
			let soldFor=auctionRef.getBalance()
			let reservePrice=lease.auctionReservePrice ?? 0.0

			if reservePrice > soldFor {
				self.cancel(name)
				return
			}
			let newProfile= getAccount(auctionRef.latestBidCallback.address).getCapability<&{Profile.Public}>(Profile.publicPath)
			emit EnglishAuction(name: name, uuid:lease.uuid, seller: lease.owner!.address, sellerName:FIND.reverseLookup(lease.owner!.address), amount: soldFor, auctionReservePrice: lease.auctionReservePrice!, status: "sold", vaultType:Type<@FUSD.Vault>().identifier, buyer:newProfile.address, buyerName:FIND.reverseLookup(newProfile.address), endsAt: self.borrowAuction(name).endsAt, validUntil: lease.getLeaseExpireTime(), lockedUntil: lease.getLeaseLockedUntil())


			let auction <- self.auctions.remove(key: name)!

			//move the token to the new profile
			lease.move(profile: newProfile)

			let token <- self.leases.remove(key: name)!

			let vault <- auction.latestBidCallback.borrow()!.fulfillLease(<- token)
			if self.networkCut != 0.0 {
				let cutAmount= soldFor * self.networkCut
				self.networkWallet.borrow()!.deposit(from: <- vault.withdraw(amount: cutAmount))
			}

			//why not use FIND to send money :P
			oldProfile.deposit(from: <- vault)

			destroy auction

		}

		pub fun listForAuction(name :String, auctionStartPrice: UFix64, auctionReservePrice: UFix64, auctionDuration: UFix64, auctionExtensionOnLateBid: UFix64) {
			pre {
				self.leases.containsKey(name) : "Cannot list name for sale that is not registered to you name=".concat(name)
			}

			let tokenRef = self.borrow(name)

			//if we have a callback there is no auction and it is a blind bid
			if let cb= tokenRef.offerCallback {
				let bidder= cb.address
				let bidderName= getAccount(bidder).getCapability<&{Profile.Public}>(Profile.publicPath).borrow()!.getName()
				let owner=tokenRef.owner!.address
				let ownerName=tokenRef.getProfile()!.getName()
				Debug.log("we have a blind bid so we cancel that")
				emit DirectOffer(name: name, uuid:tokenRef.uuid, seller: owner, sellerName: ownerName, amount: cb.borrow()!.getBalance(name), status: "rejected", vaultType:Type<@FUSD.Vault>().identifier, buyer:bidder, buyerName:bidderName, validUntil: tokenRef.getLeaseExpireTime(), lockedUntil: tokenRef.getLeaseLockedUntil())
				cb.borrow()!.cancel(name)
				tokenRef.setCallback(nil)
			}

			tokenRef.setStartAuctionPrice(auctionStartPrice)
			tokenRef.setReservePrice(auctionReservePrice)
			tokenRef.setAuctionDuration(auctionDuration)
			tokenRef.setExtentionOnLateBid(auctionExtensionOnLateBid)
			emit EnglishAuction(name: name, uuid: tokenRef.uuid, seller: self.owner!.address, sellerName:FIND.reverseLookup(self.owner!.address), amount: tokenRef.auctionStartPrice!, auctionReservePrice: tokenRef.auctionReservePrice!, status: "active_listed", vaultType:Type<@FUSD.Vault>().identifier, buyer:nil, buyerName:nil, endsAt: nil, validUntil: tokenRef.getLeaseExpireTime(), lockedUntil: tokenRef.getLeaseLockedUntil())
		}

		pub fun listForSale(name :String, directSellPrice:UFix64) {
			pre {
				self.leases.containsKey(name) : "Cannot list name for sale that is not registered to you name=".concat(name)
			}

			let tokenRef = self.borrow(name)
			tokenRef.setSalePrice(directSellPrice)
			emit Sale(name: name, uuid: tokenRef.uuid, seller: self.owner!.address, sellerName: FIND.reverseLookup(self.owner!.address), amount: tokenRef.salePrice!, status: "active_listed", vaultType:Type<@FUSD.Vault>().identifier, buyer:nil, buyerName:nil, validUntil: tokenRef.getLeaseExpireTime(), lockedUntil: tokenRef.getLeaseLockedUntil())
		}


		pub fun delistAuction(_ name: String) {
			pre {
				self.leases.containsKey(name) : "Cannot delist name for sale that is not registered to you name=".concat(name)
			}

			let tokenRef = self.borrow(name)

			emit EnglishAuction(name: name, uuid:tokenRef.uuid, seller: self.owner!.address, sellerName:FIND.reverseLookup(self.owner!.address), amount: tokenRef.auctionStartPrice!, auctionReservePrice: tokenRef.auctionReservePrice!, status: "cancel_listing", vaultType:Type<@FUSD.Vault>().identifier, buyer:nil, buyerName:nil, endsAt: nil, validUntil: tokenRef.getLeaseExpireTime(), lockedUntil: tokenRef.getLeaseLockedUntil())
			
			tokenRef.setStartAuctionPrice(nil)
			tokenRef.setReservePrice(nil)
		}


		pub fun delistSale(_ name: String) {
			pre {
				self.leases.containsKey(name) : "Cannot list name for sale that is not registered to you name=".concat(name)
			}

			let tokenRef = self.borrow(name)
			emit Sale(name: name, uuid:tokenRef.uuid, seller: self.owner!.address, sellerName: FIND.reverseLookup(self.owner!.address), amount: tokenRef.salePrice!, status: "cancel", vaultType:Type<@FUSD.Vault>().identifier, buyer:nil, buyerName:nil, validUntil: tokenRef.getLeaseExpireTime(), lockedUntil: tokenRef.getLeaseLockedUntil())
			tokenRef.setSalePrice(nil)
		}

		//note that when moving a name
		pub fun move(name: String, profile: Capability<&{Profile.Public}>, to: Capability<&LeaseCollection{LeaseCollectionPublic}>) {
			let token <- self.leases.remove(key:  name) ?? panic("missing NFT")
			emit Moved(name: name, previousOwner:self.owner!.address, newOwner: profile.address, validUntil: token.getLeaseExpireTime(), lockedUntil: token.getLeaseLockedUntil())
			token.move(profile: profile)
			to.borrow()!.deposit(token: <- token)
		}

		//depoit a lease token into the lease collection, not available from the outside
		access(contract) fun deposit(token: @FIND.Lease) {
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.leases[token.name] <- token

			destroy oldToken
		}

		// getIDs returns an array of the IDs that are in the collection
		pub fun getLeases(): [String] {
			return self.leases.keys
		}

		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		pub fun borrow(_ name: String): &FIND.Lease {
			return (&self.leases[name] as &FIND.Lease?)!
		}

		//borrow the auction
		pub fun borrowAuction(_ name: String): &FIND.Auction {
			return (&self.auctions[name] as &FIND.Auction?)!
		}


		//This has to be here since you can only get this from a auth account and thus we ensure that you cannot use wrong paths
		pub fun register(name: String, vault: @FUSD.Vault){
			let profileCap = self.owner!.getCapability<&{Profile.Public}>(Profile.publicPath)
			let leases= self.owner!.getCapability<&LeaseCollection{LeaseCollectionPublic}>(FIND.LeasePublicPath)

			let network=FIND.account.borrow<&Network>(from: FIND.NetworkStoragePath)!

			if !network.publicEnabled {
				panic("Public registration is not enabled yet")
			}

			network.register(name:name, vault: <- vault, profile: profileCap, leases: leases)
		}

		destroy() {
			destroy self.leases
			destroy self.auctions
		}
	}

	//Create an empty lease collection that store your leases to a name
	pub fun createEmptyLeaseCollection(): @FIND.LeaseCollection {
		if let network = self.account.borrow<&Network>(from: FIND.NetworkStoragePath) {
			return <- create LeaseCollection(networkCut:network.secondaryCut, networkWallet: network.wallet)
		}
		panic("Network is not set up")
	}



	/*
	Core network things
	//===================================================================================================================
	*/
	//a struct that represents a lease of a name in the network. 
	pub struct NetworkLease {
		pub let registeredTime: UFix64
		pub var validUntil: UFix64
		pub var lockedUntil: UFix64
		pub(set) var profile: Capability<&{Profile.Public}>
		pub var address: Address
		pub var name: String

		init( validUntil:UFix64, lockedUntil:UFix64, profile: Capability<&{Profile.Public}>, name: String) {
			self.validUntil=validUntil
			self.lockedUntil=lockedUntil
			self.registeredTime=Clock.time()
			self.profile=profile
			self.address= profile.address
			self.name=name
		}

		pub fun setValidUntil(_ unit: UFix64) {
			self.validUntil=unit
		}

		pub fun setLockedUntil(_ unit: UFix64) {
			self.lockedUntil=unit
		}

		pub fun status() : LeaseStatus {
			let time=Clock.time()

			if time >= self.lockedUntil {
				return LeaseStatus.FREE
			}

			if time >= self.validUntil {
				return LeaseStatus.LOCKED
			}
			return 	LeaseStatus.TAKEN
		}
	}


	/*
	FREE, does not exist in profiles dictionary
	TAKEN, registered with a time that is currentTime + leasePeriod
	LOCKED, after TAKEN.time you will get a new  status and the new time will be

	*/

	pub enum LeaseStatus: UInt8 {
		pub case FREE
		pub case TAKEN
		pub case LOCKED
	}

	/*
	The main network resource that holds the state of the names in the network
	*/
	pub resource Network  {
		access(contract) var wallet: Capability<&{FungibleToken.Receiver}>
		access(contract) let leasePeriod: UFix64
		access(contract) let lockPeriod: UFix64
		access(contract) var defaultPrice: UFix64
		access(contract) let secondaryCut: UFix64
		access(contract) var pricesChangedAt: UFix64 
		access(contract) var lengthPrices: {Int: UFix64}
		access(contract) var addonPrices: {String: UFix64}

		access(contract) var publicEnabled: Bool

		//map from name to lease for that name
		access(contract) let profiles: { String: NetworkLease}

		init(leasePeriod: UFix64, lockPeriod: UFix64, secondaryCut: UFix64, defaultPrice: UFix64, lengthPrices: {Int:UFix64}, wallet:Capability<&{FungibleToken.Receiver}>, publicEnabled:Bool) {
			self.leasePeriod=leasePeriod
			self.addonPrices = { "artifact" : 50.0 }
			self.lockPeriod=lockPeriod
			self.secondaryCut=secondaryCut
			self.defaultPrice=defaultPrice
			self.lengthPrices=lengthPrices
			self.profiles={}
			self.wallet=wallet
			self.pricesChangedAt= Clock.time()
			self.publicEnabled=publicEnabled
		}


		pub fun setAddonPrice(name:String, price:UFix64) {
			self.addonPrices[name]=price
		}

		pub fun setPrice(default: UFix64, additionalPrices: {Int: UFix64}) {
			self.defaultPrice=default
			self.lengthPrices=additionalPrices
		}


		//this method is only called from a lease, and only the owner has that capability
		access(contract) fun renew(name: String, vault: @FUSD.Vault) {
			if let lease= self.profiles[name] {

				var newTime=0.0
				if lease.status() == LeaseStatus.TAKEN {
					//the name is taken but not expired so we extend the total period of the lease
					lease.setValidUntil(lease.validUntil + self.leasePeriod)
				} else {
					lease.setValidUntil(Clock.time() + self.leasePeriod)
				}
				lease.setLockedUntil(lease.validUntil+ self.lockPeriod)

				let cost= self.calculateCost(name)
				if vault.balance != cost {
					panic("Vault did not contain ".concat(cost.toString()).concat(" amount of FUSD"))
				}
				self.wallet.borrow()!.deposit(from: <- vault)

				emit Register(name: name, owner:lease.profile.address, validUntil: lease.validUntil, lockedUntil: lease.lockedUntil)
				self.profiles[name] =  lease
				return
			}
			panic("Could not find profile with name=".concat(name))
		}


		access(contract) fun getLeaseExpireTime(_ name: String) : UFix64{
			if let lease= self.profiles[name] {
				return lease.validUntil
			}
			panic("Could not find profile with name=".concat(name))
		}

		access(contract) fun getLeaseLockedUntil(_ name: String) : UFix64{
			if let lease= self.profiles[name] {
				return lease.lockedUntil
			}
			panic("Could not find profile with name=".concat(name))
		}

		//moving leases are done from the lease collection
		access(contract) fun move(name: String, profile: Capability<&{Profile.Public}>) {
			if let lease= self.profiles[name] {
				lease.profile=profile
				self.profiles[name] = lease
				return
			}
			panic("Could not find profile with name=".concat(name))
		}

		//everybody can call register, normally done through the convenience method in the contract
		pub fun register(name: String, vault: @FUSD.Vault, profile: Capability<&{Profile.Public}>,  leases: Capability<&LeaseCollection{LeaseCollectionPublic}>) {
			pre {
				name.length >= 3 : "A FIND name has to be minimum 3 letters long"
			}

			let nameStatus=self.readStatus(name)
			if nameStatus.status == LeaseStatus.TAKEN {
				panic("Name already registered")
			}

			//if we have a locked profile that is not owned by the same identity then panic
			if nameStatus.status == LeaseStatus.LOCKED {
				panic("Name is locked")
			}

			let cost= self.calculateCost(name)
			if vault.balance != cost {
				panic("Vault did not contain ".concat(cost.toString()).concat(" amount of FUSD"))
			}
			self.wallet.borrow()!.deposit(from: <- vault)

			self.internal_register(name: name, profile: profile, leases: leases)
		}

		access(account) fun internal_register(name: String, profile: Capability<&{Profile.Public}>,  leases: Capability<&LeaseCollection{LeaseCollectionPublic}>) {
			pre {
				name.length >= 3 : "A FIND name has to be minimum 3 letters long"
			}

			let nameStatus=self.readStatus(name)
			if nameStatus.status == LeaseStatus.TAKEN {
				panic("Name already registered")
			}

			//if we have a locked profile that is not owned by the same identity then panic
			if nameStatus.status == LeaseStatus.LOCKED {
				panic("Name is locked")
			}

			let lease= NetworkLease(
				validUntil:Clock.time() + self.leasePeriod,
				lockedUntil: Clock.time() + self.leasePeriod+ self.lockPeriod,
				profile: profile,
				name: name
			)

			emit Register(name: name, owner:profile.address, validUntil: lease.validUntil, lockedUntil: lease.lockedUntil)
			emit Name(name: name)
			self.profiles[name] =  lease

			leases.borrow()!.deposit(token: <- create Lease(name: name, networkCap: FIND.account.getCapability<&Network>(FIND.NetworkPrivatePath)))

		}

		pub fun readStatus(_ name: String): NameStatus {
			let currentTime=Clock.time()
			if let lease= self.profiles[name] {
				if !lease.profile.check() {
					return NameStatus(status: LeaseStatus.TAKEN, owner: nil)
				}
				let owner=lease.profile.borrow()!.owner!.address
				return NameStatus(status: lease.status(), owner: owner)
			}
			return NameStatus(status:LeaseStatus.FREE, owner: nil)
		}

		access(account) fun profile(_ name: String) : &{Profile.Public}? {
			let nameStatus=self.readStatus(name)
			if nameStatus.status == LeaseStatus.FREE {
				return nil
			}

			if let lease=self.profiles[name] {
				return lease.profile.borrow()
			}
			return nil
		}


		//lookup a name that is not locked
		pub fun lookup(_ name: String) : &{Profile.Public}? {
			let nameStatus=self.readStatus(name)
			if nameStatus.status != LeaseStatus.TAKEN {
				return nil
			}

			if let lease=self.profiles[name] {
				return lease.profile.borrow()
			}
			return nil
		}

		pub fun calculateCost(_ name: String) : UFix64 {
			if self.lengthPrices[name.length] != nil {
				return self.lengthPrices[name.length]!
			} else {
				return self.defaultPrice
			}
		}

		pub fun setWallet(_ wallet: Capability<&{FungibleToken.Receiver}>) {
			self.wallet=wallet
		}

		pub fun setPublicEnabled(_ enabled: Bool) {
			self.publicEnabled=enabled
		}
	}



	/*
	==========================================================================
	Bids are a collection/resource for storing the bids bidder made on leases
	==========================================================================
	*/

	//Struct that is used to return information about bids
	pub struct BidInfo{
		pub let name: String
		pub let type: String
		pub let amount: UFix64
		pub let timestamp: UFix64
		pub let lease: LeaseInformation?

		init(name: String, amount: UFix64, timestamp: UFix64, type: String, lease: LeaseInformation?) {
			self.name=name
			self.amount=amount
			self.timestamp=timestamp
			self.type=type
			self.lease=lease
		}
	}


	pub resource Bid {
		access(contract) let from: Capability<&LeaseCollection{LeaseCollectionPublic}>
		access(contract) let name: String
		access(contract) var type: String
		access(contract) let vault: @FUSD.Vault
		access(contract) var bidAt: UFix64

		init(from: Capability<&LeaseCollection{LeaseCollectionPublic}>, name: String, vault: @FUSD.Vault){
			self.vault <- vault
			self.name=name
			self.from=from
			self.type="blind"
			self.bidAt=Clock.time()
		}

		access(contract) fun setType(_ type: String) {
			self.type=type
		}
		access(contract) fun setBidAt(_ time: UFix64) {
			self.bidAt=time
		}

		destroy() {
			//This is kinda bad. find FUSD vault of owner and deploy to that?
			destroy self.vault
		}
	}

	pub resource interface BidCollectionPublic {
		pub fun getBids() : [BidInfo]
		pub fun getBalance(_ name: String) : UFix64
		access(contract) fun fulfillLease(_ token: @FIND.Lease) : @FungibleToken.Vault
		access(contract) fun cancel(_ name: String)
		access(contract) fun setBidType(name: String, type: String) 
	}

	//A collection stored for bidders/buyers
	pub resource BidCollection: BidCollectionPublic {

		access(contract) var bids : @{String: Bid}
		access(contract) let receiver: Capability<&{FungibleToken.Receiver}>
		access(contract) let leases: Capability<&LeaseCollection{LeaseCollectionPublic}>

		init(receiver: Capability<&{FungibleToken.Receiver}>, leases: Capability<&LeaseCollection{LeaseCollectionPublic}>) {
			self.bids <- {}
			self.receiver=receiver
			self.leases=leases
		}

		//called from lease when auction is ended
		//if purchase if fulfilled then we deposit money back into vault we get passed along and token into your own leases collection
		access(contract) fun fulfillLease(_ token: @FIND.Lease) : @FungibleToken.Vault{

			let bid <- self.bids.remove(key: token.name) ?? panic("missing bid")

			let vaultRef = &bid.vault as &FungibleToken.Vault

			token.setSalePrice(nil)
			token.setCallback(nil)
			token.setReservePrice(nil)
			token.setStartAuctionPrice(nil)
			self.leases.borrow()!.deposit(token: <- token)
			let vault  <- vaultRef.withdraw(amount: vaultRef.balance)
			destroy bid
			return <- vault
		}

		//called from lease when things are canceled
		//if the bid is canceled from seller then we move the vault tokens back into your vault
		access(contract) fun cancel(_ name: String) {
			let bid <- self.bids.remove(key: name) ?? panic("missing bid")
			let vaultRef = &bid.vault as &FungibleToken.Vault
			self.receiver.borrow()!.deposit(from: <- vaultRef.withdraw(amount: vaultRef.balance))
			destroy bid
		}

		pub fun getBids() : [BidInfo] {
			var bidInfo: [BidInfo] = []
			for id in self.bids.keys {
				let bid = self.borrowBid(id)
				let leaseCollection= bid.from.borrow() ?? panic("Could not borrow lease bid from owner of name=".concat(bid.name))
				bidInfo.append(BidInfo(name: bid.name, amount: bid.vault.balance, timestamp: bid.bidAt, type: bid.type, lease: leaseCollection.getLease(bid.name)))
			}
			return bidInfo
		}

		//make a bid on a name
		pub fun bid(name: String, vault: @FUSD.Vault) {
			let nameStatus=FIND.status(name)
			if nameStatus.status ==  LeaseStatus.FREE {
				panic("cannot bid on name that is free")
			}

			if self.owner!.address == nameStatus.owner {
				panic("cannot bid on your own name")
			}

			let from=getAccount(nameStatus.owner!).getCapability<&LeaseCollection{LeaseCollectionPublic}>(FIND.LeasePublicPath)

			let bid <- create Bid(from: from, name:name, vault: <- vault)
			let leaseCollection= from.borrow() ?? panic("Could not borrow lease bid from owner of name=".concat(name))


			let callbackCapability =self.owner!.getCapability<&BidCollection{BidCollectionPublic}>(FIND.BidPublicPath)
			let oldToken <- self.bids[bid.name] <- bid
			//send info to leaseCollection
			destroy oldToken
			leaseCollection.registerBid(name: name, callback: callbackCapability) 
		}


		//increase a bid, will not work if the auction has already started
		pub fun increaseBid(name: String, vault: @FungibleToken.Vault) {
			let nameStatus=FIND.status(name)
			if nameStatus.status ==  LeaseStatus.FREE {
				panic("cannot increaseBid on name that is free")
			}
			let seller=getAccount(nameStatus.owner!).getCapability<&LeaseCollection{LeaseCollectionPublic}>(FIND.LeasePublicPath)

			let balance = vault.balance
			let bid =self.borrowBid(name)
			bid.setBidAt(Clock.time())
			bid.vault.deposit(from: <- vault)

			let from=getAccount(nameStatus.owner!).getCapability<&LeaseCollection{LeaseCollectionPublic}>(FIND.LeasePublicPath)
			from.borrow()!.increaseBid(name, balance: balance)
		}

		//cancel a bid, will panic if called after auction has started
		pub fun cancelBid(_ name: String) {

			let nameStatus=FIND.status(name)
			if nameStatus.status == LeaseStatus.FREE {
				self.cancel(name)
				return
			}
			let from=getAccount(nameStatus.owner!).getCapability<&LeaseCollection{LeaseCollectionPublic}>(FIND.LeasePublicPath)
			from.borrow()!.cancelUserBid(name)
			self.cancel(name)
		}

		pub fun borrowBid(_ name: String): &Bid {
			return (&self.bids[name] as &Bid?)!
		}

		access(contract) fun setBidType(name: String, type: String) {
			let bid= self.borrowBid(name)
			bid.setType(type)
		}

		pub fun getBalance(_ name: String) : UFix64 {
			let bid= self.borrowBid(name)
			return bid.vault.balance
		}

		destroy() {
			destroy self.bids
		}
	}

	pub fun createEmptyBidCollection(receiver: Capability<&{FungibleToken.Receiver}>, leases: Capability<&LeaseCollection{LeaseCollectionPublic}>) : @BidCollection {
		return <- create BidCollection(receiver: receiver,  leases: leases)
	}

	pub fun validateFindName(_ value: String) : Bool {
		if value.length < 3 || value.length > 16 {
			return false
		}
		if !FIND.validateAlphanumericLowerDash(value) {
			return false
		}

		if value.length==16 && FIND.validateHex(value) {
			return false
		}

		return true
	}

	pub fun validateAlphanumericLowerDash(_ value:String) : Bool {
		let lowerA: UInt8=97
		let lowerZ: UInt8=122

		let dash:UInt8=45
		let number0:UInt8=48
		let number9:UInt8=57

		let bytes=value.utf8
		for byte in bytes {
			if byte >= lowerA && byte <= lowerZ {
				continue
			}
			if byte >= number0 && byte <= number9  {
				continue
			}

			if byte == dash {
				continue
			}
			return false

		}
		return true

	}

	pub fun validateHex(_ value:String) : Bool {
		let lowerA: UInt8=97
		let lowerF: UInt8=102

		let number0:UInt8=48
		let number9:UInt8=57

		let bytes=value.utf8
		for byte in bytes {
			if byte >= lowerA && byte <= lowerF {
				continue
			}
			if byte >= number0 && byte <= number9  {
				continue
			}
			return false

		}
		return true

	}

	pub fun getForgeCasters() : [String] {
		return self.forgeCasterCapabilities.keys
	}

	access(account) fun addForgeCreatorCapabilities(type: String, cap: Capability<&{Forge}>) {
		pre{
			!self.forgeCasterCapabilities.containsKey(type) : "This forge is already registered."
			cap.check() : "Capability is not set properly."
		}

		self.forgeCasterCapabilities[type] = cap
	}

	access(account) fun removeForgeCreatorCapabilities(type: String) {
		pre{
			self.forgeCasterCapabilities.containsKey(type) : "This forge is not registered."
		}

		self.forgeCasterCapabilities.remove(key: type)!
	}

	init() {
		self.NetworkPrivatePath= /private/FIND
		self.NetworkStoragePath= /storage/FIND

		self.LeasePublicPath=/public/findLeases
		self.LeaseStoragePath=/storage/findLeases

		self.BidPublicPath=/public/findBids
		self.BidStoragePath=/storage/findBids

		self.forgeCasterCapabilities={}

		let wallet=self.account.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)

		// these values are hardcoded here for a reason. Then plan is to throw away the key and not have setters for them so that people can trust the contract to be the same
		let network <-  create Network(
			leasePeriod: 31536000.0, //365 days
			lockPeriod: 7776000.0, //90 days
			secondaryCut: 0.05,
			defaultPrice: 5.0,
			lengthPrices: {3: 500.0, 4:100.0},
			wallet: wallet,
			publicEnabled: false
		)
		self.account.save(<-network, to: FIND.NetworkStoragePath)
		self.account.link<&Network>( FIND.NetworkPrivatePath, target: FIND.NetworkStoragePath)

	}
}
