import FungibleToken from "./standard/FungibleToken.cdc"
import FUSD from "./standard/FUSD.cdc"
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import Profile from "./Profile.cdc"

/*

FNS

A naming service flow flow,

3 token tag cost 500 FUSD a year
4 token tag cost 100 FUSD a year
5 or more token tag cost 5 FUSD a year


This contract is pretty long, I have tried splitting it up into several files, but then there are issues

*/
pub contract FIN {



	//event that is emited when a tag is registered or renewed
	pub event Register(tag: String, owner: Address, expireAt: UFix64)

	//event that is emitted when a tag is moved
	pub event Moved(tag: String, previousOwner: Address, newOwner: Address, expireAt: UFix64)

	//event that is emitted when a tag is sold
	pub event Sold(tag: String, previousOwner: Address, newOwner: Address, expireAt: UFix64, amount: UFix64)

	pub event ForSale(tag: String, owner: Address, expireAt: UFix64, amount: UFix64, active: Bool)

	pub event BlindBid(tag: String, bidder: Address, amount: UFix64)
	pub event AuctionBid(tag: String, bidder: Address, amount: UFix64, auctionEndAt: UFix64)

	pub let BidPublicPath: PublicPath
	pub let BidPrivatePath: PrivatePath
	pub let BidStoragePath: StoragePath
	pub let NetworkStoragePath: StoragePath
	pub let NetworkPrivatePath: PrivatePath
	pub let AdministratorPrivatePath: PrivatePath
	pub let AdministratorStoragePath: StoragePath
	pub let AdminProxyPublicPath: PublicPath
	pub let AdminProxyStoragePath: StoragePath
	pub let LeaseStoragePath: StoragePath
	pub let LeasePublicPath: PublicPath

	access(contract) var fakeClock:UFix64?


	//For convenience the contract has a link to the given network so that you can call methods without having to borrow things.
	access(contract) var networkCap: Capability<&Network>?


	//These methods are basically just here for convenience
	pub fun calculateCost(_ tag:String) : UFix64 {
		pre {
			self.networkCap != nil : "Network is not set up"
		}
		return self.networkCap!.borrow()!.calculateCost(tag)
	}

	pub fun lookup(_ tag:String): &{Profile.Public}? {
		pre {
			self.networkCap != nil : "Network is not set up"
		}
		return self.networkCap!.borrow()!.lookup(tag)
	}

	pub fun deposit(to:String, from: @FungibleToken.Vault) {
		pre {
			self.networkCap != nil : "Network is not set up"
		}
		let profile=self.lookup(to) ?? panic("could not find tag")
		profile.deposit(from: <- from)
	}

	pub fun status(_ tag: String): LeaseStatus {
		pre {
			self.networkCap != nil : "Network is not set up"
		}
		return self.networkCap!.borrow()!.status(tag)
	}

	pub fun register(tag: String, vault: @FUSD.Vault, profile: Capability<&{Profile.Public}>, leases: Capability<&{LeaseCollectionPublic}>){
		pre {
			self.networkCap != nil : "Network is not set up"
			tag.length >= 3 : "A public minted FIN tag has to be minimum 3 letters long"
		}
		self.networkCap!.borrow()!.register(tag:tag, vault: <- vault, profile: profile, leases: leases)
	}


	/*

	LeaseToken is a resource you get back when you register a lease.
	You can use methods on it to renew the lease or to move to another profile
	*/
	pub resource LeaseToken {
		access(contract) let tag: String
		access(contract) let networkCap: Capability<&Network> //Does this have to be an interface?
		access(contract) var salePrice: UFix64?
		access(contract) var  callback: Capability<&{BidCollectionPublic}>?

		init(tag:String, networkCap: Capability<&Network>) {
			self.tag=tag
			self.networkCap= networkCap
			self.salePrice=0.0
			self.callback=nil
		}

		pub fun setSalePrice(_ price: UFix64?) {
			self.salePrice=price
		}

		pub fun setCallback(_ callback: Capability<&{BidCollectionPublic}>?) {
			self.callback=callback
		}

		pub fun extendLease(_ vault: @FUSD.Vault) {
			let network= self.networkCap.borrow()!
			network.renew(tag: self.tag, vault:<-  vault)
		}

		access(contract) fun move(profile: Capability<&{Profile.Public}>) {
			let network= self.networkCap.borrow()!
			network.move(tag: self.tag, profile: profile)
		}

		pub fun getLeaseExpireTime() : UFix64 {
			return self.networkCap.borrow()!.getLeaseExpireTime(self.tag)
		}

		pub fun getLeaseStatus() : LeaseStatus {
			return self.networkCap.borrow()!.getLeaseStatus(self.tag)
		}
	}

	/* An Auction for a lease */
	pub resource Auction {
		access(contract) var endsAt: UFix64
		access(contract) var startedAt: UFix64
		access(contract) let extendOnLateBid: UFix64
		access(contract) var  callback: Capability<&{BidCollectionPublic}>
		access(contract) let tag: String

		init(endsAt: UFix64, startedAt: UFix64, extendOnLateBid: UFix64, callback: Capability<&{BidCollectionPublic}>, tag: String) {
			self.endsAt=endsAt
			self.startedAt=startedAt
			self.extendOnLateBid=extendOnLateBid
			self.callback=callback
			self.tag=tag
		}

		pub fun getBalance() : UFix64 {
			return self.callback.borrow()!.getBalance(self.tag)
		}

		pub fun addBid(callback: Capability<&{BidCollectionPublic}>, timestamp: UFix64) {
			if callback.borrow()!.getBalance(self.tag) <= self.getBalance() {
				panic("bid must be larger then previous bid")
			}

			//we send the money back
			self.callback.borrow()!.cancel(self.tag)
			self.callback=callback
			let suggestedEndTime=timestamp+self.extendOnLateBid
			if suggestedEndTime > self.endsAt {
				//EMIT EVENT
				self.endsAt=suggestedEndTime
			}
		}
	}

	pub struct LeaseInformation {
		pub let tag: String
		pub let status: LeaseStatus
		pub let expireTime: UFix64
		pub let latestBid: UFix64?
		pub let auctionEnds: UFix64?
		pub let salePrice: UFix64?
		pub let latestBidBy: Address?

		init(tag: String, status:LeaseStatus, expireTime: UFix64, latestBid: UFix64?, auctionEnds: UFix64?, salePrice: UFix64?, latestBidBy: Address?) {

			self.tag=tag
			self.status=status
			self.expireTime=expireTime
			self.latestBid=latestBid
			self.latestBidBy=latestBidBy
			self.auctionEnds=auctionEnds
			self.salePrice=salePrice
		}

	}
	/*
	Since a single account can own more then one tag there is a collecition of them
	This collection has build in support for direct sale of a FIN leaseToken. The network owner till take 2.5% cut
	*/
	pub resource interface LeaseCollectionPublic {
		//fetch all the tokens in the collection
		pub fun getTokens(): [String]
		//fetch all tags that are for sale
		pub fun getLeaseInformation() : [LeaseInformation]
		pub fun getLease(_ tag: String) :LeaseInformation?

		//add a new lease token to the collection, can only be called in this contract
		access(contract) fun deposit(token: @FIN.LeaseToken)

	  access(contract)fun cancelBid(_ tag: String) 
		access(contract) fun increaseBid(_ tag: String) 

		//place a bid on a token
		access(contract) fun bid(tag: String, callback: Capability<&{BidCollectionPublic}>)
	}


	pub resource LeaseCollection: LeaseCollectionPublic {
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		access(contract) var tokens: @{String: FIN.LeaseToken}

		access(contract) var auctions: @{String: Auction}

		//the cut the network will take, default 2.5%
		access(contract) let networkCut: UFix64

		//the wallet of the network to transfer royalty to
		access(contract) let networkWallet: Capability<&{FungibleToken.Receiver}>

		init (networkCut: UFix64, networkWallet: Capability<&{FungibleToken.Receiver}>) {
			self.tokens <- {}
			self.auctions <- {}
			self.networkCut=networkCut
			self.networkWallet=networkWallet
		}

		pub fun getLease(_ tag: String) : LeaseInformation? {
			if !self.tokens.containsKey(tag) {
				return nil 
			}
			let token=self.borrow(tag)

			var latestBid: UFix64? = nil
			var auctionEnds: UFix64?= nil
			var latestBidBy: Address?=nil

			if self.auctions.containsKey(tag) {
				let auction = self.borrowAuction(tag)
				auctionEnds= auction.endsAt
				latestBid= auction.getBalance()
				latestBidBy= auction.callback.address
			} else {
				if let callback = token.callback {
					latestBid= callback.borrow()!.getBalance(tag)
					latestBidBy=callback.address
				}
			}

			return LeaseInformation(tag:  tag, status: token.getLeaseStatus(), expireTime: token.getLeaseExpireTime(), latestBid: latestBid, auctionEnds: auctionEnds, salePrice: token.salePrice, latestBidBy: latestBidBy)
		}

		pub fun getLeaseInformation() : [LeaseInformation]  {
			var info: [LeaseInformation]=[]
			for tag in self.tokens.keys {
				let lease=self.getLease(tag)
				if lease != nil {
					info.append(lease!)
				}
			}
			return info
		}

		//call this to start an auction for this lease
		pub fun startAuction(_ tag: String) {
			let timestamp=FIN.time()
			let duration=86400.0
			let lease = self.borrow(tag)
			if lease.callback == nil {
				panic("cannot start an auction on a tag without a bid, set salePrice")
			}
			let oldAuction <- self.auctions[tag] <- create Auction(endsAt: timestamp + duration, startedAt: timestamp, extendOnLateBid: 300.0, callback: lease.callback!, tag: tag)
			lease.setCallback(nil)
			//TODO: Emit event
			destroy oldAuction
		}


		access(contract) fun cancelBid(_ tag: String) {
			pre {
				self.tokens.containsKey(tag) : "Invalid tag=".concat(tag)
				!self.auctions.containsKey(tag) : "Cannot cancel a bid that is in an auction=".concat(tag)
			}

			let bid= self.borrow(tag)
			bid.setCallback(nil)
			//TODO: emit event
		}

		access(contract) fun increaseBid(_ tag: String) {
			pre {
				self.tokens.containsKey(tag) : "Invalid tag=".concat(tag)
				!self.auctions.containsKey(tag) : "Can only increase bid before auction=".concat(tag)
			}

			let lease = self.borrow(tag)

			if lease.salePrice == nil {
				return
			}

			if lease.salePrice!  <= lease.callback!.borrow()!.getBalance(tag) {
				self.startAuction(tag)
			}
		//TODO: emit event

		}

		access(contract) fun bid(tag: String, callback: Capability<&{BidCollectionPublic}>) {
			pre {
				self.tokens.containsKey(tag) : "Invalid tag=".concat(tag)
			}

			let timestamp=FIN.time()
			let lease = self.borrow(tag)
			if self.auctions.containsKey(tag) {
				let auction = self.borrowAuction(tag)
				if auction.endsAt < timestamp {
					panic("Auction has ended")
				}
				auction.addBid(callback:callback, timestamp:timestamp)
				return
			} 

			if let cb= lease.callback {
				cb.borrow()!.cancel(tag)
			}

			lease.setCallback(callback)

			if lease.salePrice == nil {
				return
			}

			if lease.salePrice!  <= callback.borrow()!.getBalance(tag) {
				self.startAuction(tag)
			}

		}

		pub fun fullfill(tag: String) {
			pre {
				self.tokens.containsKey(tag) : "Invalid tag=".concat(tag)
				self.auctions.containsKey(tag) : "Tag is not for auction tag=".concat(tag)
//				self.borrowAuction(tag).endsAt > FIN.time() : "Auction has not ended yet"
			}

			let oldProfile=FIN.lookup(tag)!

			let auction <- self.auctions.remove(key: tag)!

			let newProfile= getAccount(auction.callback.address).getCapability<&{Profile.Public}>(Profile.publicPath)

			let soldFor=auction.getBalance()
			//move the token to the new profile
			let tokenRef = self.borrow(tag)
			emit Sold(tag: tag, previousOwner:tokenRef.owner!.address, newOwner: newProfile.address, expireAt: tokenRef.getLeaseExpireTime(), amount: soldFor)
			tokenRef.move(profile: newProfile)

			let token <- self.tokens.remove(key: tag)!

			let vault <- auction.callback.borrow()!.fullfill(<- token)
			if self.networkCut != 0.0 {
				let cutAmount= soldFor * self.networkCut
				self.networkWallet.borrow()!.deposit(from: <- vault.withdraw(amount: cutAmount))
			}

			//why not use FIN to send money :P
			oldProfile.deposit(from: <- vault)

			destroy auction
			
		}

		pub fun listForSale(tag :String, amount: UFix64) {
			pre {
				self.tokens.containsKey(tag) : "Cannot list tag for sale that is not registered to you tag=".concat(tag)
			}

			let tokenRef = self.borrow(tag)
			emit ForSale(tag: tag, owner:self.owner!.address, expireAt: tokenRef.getLeaseExpireTime(), amount: amount, active: true)
			tokenRef.setSalePrice(amount)

		}

		pub fun delistSale(_ tag: String) {
			pre {
				self.tokens.containsKey(tag) : "Cannot list tag for sale that is not registered to you tag=".concat(tag)
			}

			let tokenRef = self.borrow(tag)
			emit ForSale(tag: tag, owner:self.owner!.address, expireAt: tokenRef.getLeaseExpireTime(), amount: tokenRef.salePrice!, active: false)
			tokenRef.setSalePrice(nil)
		}

		//note that when moving a tag
		pub fun move(tag: String, profile: Capability<&{Profile.Public}>, to: Capability<&{LeaseCollectionPublic}>) {
			let token <- self.tokens.remove(key:  tag) ?? panic("missing NFT")
			emit Moved(tag: tag, previousOwner:self.owner!.address, newOwner: profile.address, expireAt: token.getLeaseExpireTime())
			token.move(profile: profile)
			to.borrow()!.deposit(token: <- token)
		}

		//depoit a lease token into the lease collection, not available from the outside
		access(contract) fun deposit(token: @FIN.LeaseToken) {
			// add the new token to the dictionary which removes the old one
			let oldToken <- self.tokens[token.tag] <- token

			destroy oldToken
		}

		// getIDs returns an array of the IDs that are in the collection
		pub fun getTokens(): [String] {
			return self.tokens.keys
		}

		// borrowNFT gets a reference to an NFT in the collection
		// so that the caller can read its metadata and call its methods
		pub fun borrow(_ tag: String): &FIN.LeaseToken {
			return &self.tokens[tag] as &FIN.LeaseToken
		}

		pub fun borrowAuction(_ tag: String): &FIN.Auction {
			return &self.auctions[tag] as &FIN.Auction
		}

		destroy() {
			//should really deregister tokens in the Network?
			destroy self.tokens
			destroy self.auctions
		}
	}

	// public function that anyone can call to create a new empty collection
	pub fun createEmptyLeaseCollection(): @FIN.LeaseCollection {
		pre {
			self.networkCap != nil : "Network is not set up"
		}
		let network=self.networkCap!.borrow()!

		return <- create LeaseCollection(networkCut:network.secondaryCut, networkWallet: network.wallet)
	}

	pub struct NetworkLease {
		pub(set) var status: LeaseStatus
		pub(set) var time: UFix64
		pub(set) var profile: Capability<&{Profile.Public}>
		pub var address: Address
		pub var tag: String

		init(status:LeaseStatus, time:UFix64, profile: Capability<&{Profile.Public}>, tag: String) {
			self.status=status
			self.time=time
			self.profile=profile
			self.address= profile.address
			self.tag=tag
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

	pub resource Network  {

		access(contract) let wallet: Capability<&{FungibleToken.Receiver}>
		access(contract) var leasePeriod: UFix64
		access(contract) var lockPeriod: UFix64
		access(contract) var defaultPrice: UFix64
		access(contract) var secondaryCut: UFix64
		access(contract) var lengthPrices: {Int: UFix64}

		access(contract) let profiles: { String: NetworkLease}

		init(leasePeriod: UFix64, lockPeriod: UFix64, secondaryCut: UFix64, defaultPrice: UFix64, lengthPrices: {Int:UFix64}, wallet:Capability<&{FungibleToken.Receiver}>) {
			self.leasePeriod=leasePeriod
			self.lockPeriod=lockPeriod
			self.secondaryCut=secondaryCut
			self.defaultPrice=defaultPrice
			self.lengthPrices=lengthPrices
			self.profiles={}
			self.wallet=wallet
		}


		access(contract) fun renew(tag: String, vault: @FUSD.Vault) {
			if let lease= self.profiles[tag] {
				let status=self.status(tag)

				var newTime =0.0
				if status == LeaseStatus.TAKEN {
					newTime= lease.time + self.leasePeriod
				} else {
					let time=FIN.time()
					newTime = time + self.leasePeriod
				}

				let cost= self.calculateCost(tag)
				if vault.balance != cost {
					panic("Vault did not contain ".concat(cost.toString()).concat(" amount of FUSD"))
				}
				self.wallet.borrow()!.deposit(from: <- vault)


				let lease= NetworkLease(
					status: LeaseStatus.TAKEN,
					time:newTime,
					profile: lease.profile,
					tag: tag
				)

				emit Register(tag: tag, owner:lease.profile.address, expireAt: lease.time)
				self.profiles[tag] =  lease
				return
			}
			panic("Could not find profile with tag=".concat(tag))
		}

		access(contract) fun getLeaseExpireTime(_ tag: String) : UFix64{
			if let lease= self.profiles[tag] {
				return lease.time
			}
			panic("Could not find profile with tag=".concat(tag))
		}

		access(contract) fun getLeaseStatus(_ tag: String) : LeaseStatus{
			if let lease= self.profiles[tag] {
				return lease.status
			}
			panic("Could not find profile with tag=".concat(tag))
		}


		access(contract) fun move(tag: String, profile: Capability<&{Profile.Public}>) {
			if let lease= self.profiles[tag] {
				lease.profile=profile
				self.profiles[tag] = lease
				return
			}
			panic("Could not find profile with tag=".concat(tag))
		}

		pub fun register(tag: String, vault: @FUSD.Vault, profile: Capability<&{Profile.Public}>,  leases: Capability<&{LeaseCollectionPublic}>) {

			let status=self.status(tag)
			if status == LeaseStatus.TAKEN {
				panic("Tag already registered, if you want to renew lease use you LeaseToken")
			}

			let registrant= profile.address
			//if we have a locked profile that is not owned by the same identity then panic
			if status == LeaseStatus.LOCKED && self.profiles[tag]!.address != registrant {
				panic("Tag is locked")
			}

			let cost= self.calculateCost(tag)
			if vault.balance != cost {
				panic("Vault did not contain ".concat(cost.toString()).concat(" amount of FUSD"))
			}
			self.wallet.borrow()!.deposit(from: <- vault)

			let lease= NetworkLease(
				status: LeaseStatus.TAKEN,
				time:FIN.time() + self.leasePeriod,
				profile: profile,
				tag: tag
			)

			emit Register(tag: tag, owner:profile.address, expireAt: lease.time)
			self.profiles[tag] =  lease

			leases.borrow()!.deposit(token: <- create LeaseToken(tag: tag, networkCap: FIN.networkCap!))
		}


		pub fun status(_ tag: String): LeaseStatus {
			let currentTime=FIN.time()
			log("Check status at time=".concat(currentTime.toString()))
			if let  lease= self.profiles[tag] {
				let owner=lease.profile.borrow()!.owner!.address
				log("lease time is=".concat(lease.time.toString()))
				let diff= Int64(lease.time) - Int64(currentTime)
				log("time diff is=".concat(diff.toString()))
				log("lease status was=".concat(lease.status.rawValue.toString()))
				if currentTime <= lease.time {
					log("Still valid")
					return lease.status
				}

				if lease.status == LeaseStatus.LOCKED {
					self.profiles.remove(key: tag)
					log("was locked that is expired")
					return LeaseStatus.FREE
				}

				if lease.status == LeaseStatus.TAKEN {
					lease.status= LeaseStatus.LOCKED
					log("lock period is")
					log(self.lockPeriod)
					lease.time = currentTime + self.lockPeriod
					self.profiles[tag] = lease
					log("was taken is now locked")
					log(lease.time)
					log(lease.status)
				}
				return lease.status
			}
			log("FREE")
			return LeaseStatus.FREE
		}

		pub fun lookup(_ tag: String) : &{Profile.Public}? {
			let status=self.status(tag)
			if status != LeaseStatus.TAKEN {
				return nil
			}

			if let lease=self.profiles[tag] {
				return lease.profile.borrow()
			}
			return nil
		}

		pub fun calculateCost(_ tag: String) : UFix64 {
			let length= tag.length

			for i in self.lengthPrices.keys {
				if length==i {
					return self.lengthPrices[i]!
				}
			}
			return self.defaultPrice
		}

		pub fun setLengthPrices(_ lengthPrices: {Int: UFix64}) {
			self.lengthPrices=lengthPrices
		}

		pub fun setDefaultPrice(_ price: UFix64) {
			self.defaultPrice=price
		}

		pub fun setLeasePeriod(_ period: UFix64)  {
			self.leasePeriod=period
		}

		pub fun setLockPeriod(_ period: UFix64) {
			self.lockPeriod=period
		}

	}

	// Everything from here downwards is the admin capability receiver pattern
	//An Minter resource that can create a Network
	pub resource Administrator {

		pub fun createNetwork(
			leasePeriod: UFix64,
			lockPeriod: UFix64,
			secondaryCut: UFix64,
			defaultPrice: UFix64,
			lengthPrices: {Int:UFix64},
			wallet:Capability<&{FungibleToken.Receiver}>
		): @Network {
			return  <-  create Network(
				leasePeriod: leasePeriod,
				lockPeriod: lockPeriod,
				secondaryCut: secondaryCut,
				defaultPrice: defaultPrice,
				lengthPrices: lengthPrices,
				wallet: wallet
			)
		}

	}


	//Admin client to use for capability receiver pattern
	pub fun createAdminProxyClient() : @AdminProxy {
		return <- create AdminProxy()
	}

	//interface to use for capability receiver pattern
	pub resource interface AdminProxyClient {
		pub fun addCapability(_ cap: Capability<&Administrator>)
	}


	pub resource AdminProxy: AdminProxyClient {

		access(self) var capability: Capability<&Administrator>?

		init() {
			self.capability = nil
		}

		pub fun addCapability(_ cap: Capability<&Administrator>) {
			pre {
				cap.check() : "Invalid server capablity"
				self.capability == nil : "Server already set"
			}
			self.capability = cap
		}

		pub fun advanceClock(_ time: UFix64) {
			pre {
				self.capability != nil: "Cannot create FIN, capability is not set"
			}

			FIN.fakeClock=(FIN.fakeClock ?? 0.0) + time
			log("clock is now at=".concat(FIN.fakeClock?.toString() ?? "" ))
		}

		pub fun createNetwork( admin: AuthAccount, leasePeriod: UFix64, lockPeriod: UFix64, secondaryCut: UFix64, defaultPrice: UFix64, lengthPrices: {Int:UFix64}, wallet:Capability<&{FungibleToken.Receiver}>) {

			pre {
				self.capability != nil: "Cannot create FIN, capability is not set"
			}

			let network <- self.capability!.borrow()!.createNetwork(
				leasePeriod: leasePeriod,
				lockPeriod: lockPeriod,
				secondaryCut:secondaryCut,
				defaultPrice:defaultPrice,
				lengthPrices:lengthPrices,
				wallet: wallet
			)
			admin.save(<-network, to: FIN.NetworkStoragePath)
			admin.link<&Network>( FIN.NetworkPrivatePath, target: FIN.NetworkStoragePath)
			//For convenience in FIN we set the network in the contract itself. So there should really only be a single FIN. Not sure if this is really needed or apropriate.
			FIN.networkCap= admin.getCapability<&Network>(FIN.NetworkPrivatePath)
		}
	}



	pub struct BidInfo{
		pub let tag: String
		pub let amount: UFix64
		pub let timestamp: UFix64

		init(tag: String, amount: UFix64, timestamp: UFix64) {
			self.tag=tag
			self.amount=amount
			self.timestamp=timestamp
		}
	}

	pub resource Bid {
		access(contract) let from: Capability<&{FIN.LeaseCollectionPublic}>
		access(contract) let tag: String
		access(contract) let vault: @FUSD.Vault
		access(contract) var bidAt: UFix64

		init(from: Capability<&{FIN.LeaseCollectionPublic}>, tag: String, vault: @FUSD.Vault){
			self.vault <- vault
			self.tag=tag
			self.from=from
			self.bidAt=FIN.time()
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
		pub fun getBalance(_ tag: String) : UFix64
		access(contract) fun fullfill(_ token: @FIN.LeaseToken) : @FungibleToken.Vault
		access(contract) fun cancel(_ tag: String)
	}

	//A collection stored for bidders/buyers
	pub resource BidCollection: BidCollectionPublic {

		access(contract) var bids : @{String: Bid}
		access(contract) let receiver: Capability<&{FungibleToken.Receiver}>
		access(contract) let leases: Capability<&{FIN.LeaseCollectionPublic}>

		init(receiver: Capability<&{FungibleToken.Receiver}>, leases: Capability<&{FIN.LeaseCollectionPublic}>) {
			self.bids <- {}
			self.receiver=receiver
			self.leases=leases
		}

		//if purchase if fullfilled then we deposit money back into vault we get passed along and token into your own leases collection
		access(contract) fun fullfill(_ token: @FIN.LeaseToken) : @FungibleToken.Vault{

			let bid <- self.bids.remove(key: token.tag) ?? panic("missing bid")

			let vaultRef = &bid.vault as &FungibleToken.Vault

			token.setSalePrice(nil)
			token.setCallback(nil)
			self.leases.borrow()!.deposit(token: <- token)
			let vault  <- vaultRef.withdraw(amount: vaultRef.balance)
			destroy bid
			return <- vault
		}

		//if the bid is canceled from seller then we move the vault tokens back into your vault
		access(contract) fun cancel(_ tag: String) {
			let bid <- self.bids.remove(key: tag) ?? panic("missing bid")
			let vaultRef = &bid.vault as &FungibleToken.Vault
			self.receiver.borrow()!.deposit(from: <- vaultRef.withdraw(amount: vaultRef.balance))
			destroy bid
		}

		pub fun getBids() : [BidInfo] {
			var bidInfo: [BidInfo] = []
			for id in self.bids.keys {
				let bid = self.borrowBid(id)
				bidInfo.append(BidInfo(tag: bid.tag, amount: bid.vault.balance, timestamp: bid.bidAt))
			}
			return bidInfo
		}

		pub fun bid(tag: String, vault: @FUSD.Vault) {
			let seller= FIN.lookup(tag)!.owner!
			let from=seller.getCapability<&{FIN.LeaseCollectionPublic}>(FIN.LeasePublicPath)

			let bid <- create Bid(from: from, tag:tag, vault: <- vault)
		  let leaseCollection= from.borrow() ?? panic("Could not borrow lease bid from owner of tag=".concat(tag))
		  let callbackCapability =self.owner!.getCapability<&{BidCollectionPublic}>(FIN.BidPublicPath)
			let oldToken <- self.bids[bid.tag] <- bid
			//send info to leaseCollection
			destroy oldToken
			leaseCollection.bid(tag: tag, callback: callbackCapability) 
	  }

		//TODO; You have to be able to cancel a bid that is not in an auction

		pub fun increaseBid(tag: String, vault: @FungibleToken.Vault) {
			//TODO: Emit event here?
			let bid =self.borrowBid(tag)
			bid.setBidAt(FIN.time())
			bid.vault.deposit(from: <- vault)

			let seller= FIN.lookup(tag)!.owner!
			let from=seller.getCapability<&{FIN.LeaseCollectionPublic}>(FIN.LeasePublicPath)
			from.borrow()!.increaseBid(tag)
		}

		pub fun cancelBid(tag: String) {
			let seller= FIN.lookup(tag)!.owner!
			let from=seller.getCapability<&{FIN.LeaseCollectionPublic}>(FIN.LeasePublicPath)
			from.borrow()!.cancelBid(tag)
			self.cancelBid(tag: tag)
		}


		pub fun borrowBid(_ tag: String): &Bid {
			return &self.bids[tag] as &Bid
		}

		pub fun getBalance(_ tag: String) : UFix64 {
			let bid= self.borrowBid(tag)
			return bid.vault.balance
		}

		destroy() {
			destroy self.bids
		}
	}

	pub fun createEmptyBidCollection(receiver: Capability<&{FungibleToken.Receiver}>, leases: Capability<&{FIN.LeaseCollectionPublic}>) : @BidCollection {
		return <- create BidCollection(receiver: receiver,  leases: leases)
	}


	access(contract) fun time() : UFix64 {
		return self.fakeClock ?? getCurrentBlock().timestamp
	}

	init() {
		self.NetworkPrivatePath= /private/FIN
		self.NetworkStoragePath= /storage/FIN

		self.AdministratorStoragePath=/storage/finAdmin
		self.AdministratorPrivatePath=/private/finAdmin

		self.AdminProxyPublicPath= /public/finAdminProxy
		self.AdminProxyStoragePath=/storage/finAdminProxy

		self.LeasePublicPath=/public/finLeases
		self.LeaseStoragePath=/storage/finLeases

		self.BidPublicPath=/public/finbids
		self.BidPrivatePath=/private/finbids
		self.BidStoragePath=/storage/finBids


		self.account.save(<- create Administrator(), to: self.AdministratorStoragePath)
		self.account.link<&Administrator>(self.AdministratorPrivatePath, target: self.AdministratorStoragePath)
		self.networkCap = nil

		self.fakeClock=nil
	}
}
