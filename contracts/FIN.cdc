import FungibleToken from "./standard/FungibleToken.cdc"
import FUSD from "./standard/FUSD.cdc"
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import Profile from "./Profile.cdc"

pub contract FIN {

	pub let NetworkStoragePath: StoragePath
	pub let NetworkPrivatePath: PrivatePath
	pub let AdministratorPrivatePath: PrivatePath
	pub let AdministratorStoragePath: StoragePath
	pub let AdminClientPublicPath: PublicPath
	pub let AdminClientStoragePath: StoragePath
	pub let LeaseStoragePath: StoragePath
	pub let LeasePublicPath: PublicPath

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

	pub fun register(tag: String, vault: @FUSD.Vault, profile: Capability<&{Profile.Public}>) : @LeaseToken{
		pre {
			self.networkCap != nil : "Network is not set up"
			tag.length >= 3 : "A public minted FIN tag has to be minimum 3 letters long"
		}
		return <- self.networkCap!.borrow()!.register(tag:tag, vault: <- vault, profile: profile)
	}

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


	pub fun createAdminClient() : @Admin {
		return <- create Admin()
	}

	pub resource interface AdminClient {
		pub fun addCapability(_ cap: Capability<&Administrator>)
	}

	pub resource Admin: AdminClient {

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
			FIN.networkCap= admin.getCapability<&Network>(FIN.NetworkPrivatePath)
		}
	}



	pub resource LeaseToken {
		pub let tag: String
		pub let networkCap: Capability<&Network> //Does this have to be an interface?

		init(tag:String, networkCap: Capability<&Network>) {
			self.tag=tag
			self.networkCap= networkCap
		}

		pub fun extendLease(_ vault: @FUSD.Vault) {
			let network= self.networkCap.borrow()!
			network.renew(tag: self.tag, vault:<-  vault) 
		}

		pub fun move(profile: Capability<&{Profile.Public}>) {
			let network= self.networkCap.borrow()!
			network.move(tag: self.tag, profile: profile)
		}

		pub fun getLeaseExpireTime() : UFix64 {
			return self.networkCap.borrow()!.getLeaseExpireTime(self.tag)

		}
	}


	pub resource interface LeaseCollectionPublic {
		pub fun getTokens(): [String] 
		pub fun getForSale() : [LeaseForSale]
		pub fun deposit(token: @FIN.LeaseToken)
		pub fun buy(tag: String, vault: @FUSD.Vault, leases: Capability<&{LeaseCollectionPublic}>) 
	}

	pub struct LeaseForSale{
		pub let tag: String
		pub let amount: UFix64
		pub let expireAt: UFix64

		init(tag: String, amount:UFix64, expireAt:UFix64) {
			self.tag=tag
			self.amount=amount
			self.expireAt=expireAt
		}
	}

	pub resource LeaseCollection: LeaseCollectionPublic {
		// dictionary of NFT conforming tokens
		// NFT is a resource type with an `UInt64` ID field
		pub var tokens: @{String: FIN.LeaseToken}
		pub var forSale: {String: UFix64}
		pub let networkCut: UFix64
		pub let networkWallet: Capability<&{FungibleToken.Receiver}>

		init (networkCut: UFix64, networkWallet: Capability<&{FungibleToken.Receiver}>) {
			self.tokens <- {}
			self.forSale = {}
			self.networkCut=networkCut
			self.networkWallet=networkWallet
		}

		pub fun getForSale() : [LeaseForSale]  {

			var forSales: [LeaseForSale]=[]
			for tag in self.forSale.keys {
				let time=self.borrow(tag).getLeaseExpireTime()
				let item=LeaseForSale(tag:  tag, amount: self.forSale[tag]!, expireAt: time)
				forSales.append(item)
			}
			return forSales
		}

		pub fun buy(tag: String, vault: @FUSD.Vault, leases: Capability<&{LeaseCollectionPublic}>)  {
			pre {
				self.tokens.containsKey(tag) : "Invalid tag=".concat(tag)
				self.forSale.containsKey(tag) : "Invalid tag=".concat(tag)
				self.forSale[tag]! == vault.balance : "Invalid amount of fusd sent in want=".concat(self.forSale[tag]!.toString()).concat(" got ").concat(vault.balance.toString())
			}

			let newProfile= getAccount(leases.address).getCapability<&{Profile.Public}>(Profile.publicPath)

			//move the token to the new profile
			let tokenRef = self.borrow(tag)
			tokenRef.move(profile: newProfile)

			if self.networkCut != 0.0 {
				let cutAmount= self.forSale[tag]! * self.networkCut
				self.networkWallet.borrow()!.deposit(from: <- vault.withdraw(amount: cutAmount))
			}

			//why not use FIN to send money :P
			FIN.lookup(tag)!.deposit(from: <- vault)
			//remove the resource
			let token <- self.tokens.remove(key: tag)! 
			self.forSale.remove(key: tag)

			//put it in the collection
			leases.borrow()!.deposit(token: <- token)

		}

		pub fun listForSale(tag :String, amount: UFix64) {
			pre {
				self.tokens.containsKey(tag) : "Cannot list tag for sale that is not registered to you tag=".concat(tag)
			}
			self.forSale[tag] = amount

		}

		pub fun delistSale(_ tag: String) {
			pre {
				self.tokens.containsKey(tag) : "Cannot list tag for sale that is not registered to you tag=".concat(tag)
			}
			self.forSale.remove(key: tag)
		}

		// withdraw removes an NFT from the collection and moves it to the caller
		pub fun withdraw(_ tag: String): @FIN.LeaseToken {
			let token <- self.tokens.remove(key:  tag) ?? panic("missing NFT")
			return <-token
		}

		// deposit takes a NFT and adds it to the collections dictionary
		// and adds the ID to the id array
		pub fun deposit(token: @FIN.LeaseToken) {
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

		destroy() {
			destroy self.tokens
		}
	}

	// public function that anyone can call to create a new empty collection
	pub fun createEmptyCollection(): @FIN.LeaseCollection {
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
					let block=getCurrentBlock()
					newTime = block.timestamp + self.leasePeriod
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


		access(contract) fun move(tag: String, profile: Capability<&{Profile.Public}>) {
			if let lease= self.profiles[tag] {
				lease.profile=profile
				self.profiles[tag] =  lease
				return
			}
			panic("Could not find profile with tag=".concat(tag))
		}

		pub fun register(tag: String, vault: @FUSD.Vault, profile: Capability<&{Profile.Public}>) : @LeaseToken{

			let status=self.status(tag)
			if status == LeaseStatus.TAKEN {
				panic("Tag already registered")
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

			let block=getCurrentBlock()

			let lease= NetworkLease(
				status: LeaseStatus.TAKEN,
				time:block.timestamp + self.leasePeriod,
				profile: profile,
				tag: tag
			)

			self.profiles[tag] =  lease
			return <- create LeaseToken(tag: tag, networkCap: FIN.networkCap!)
		}

		pub fun status(_ tag: String): LeaseStatus {
			let currentTime=getCurrentBlock().timestamp
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

		/*
		Do we want to be able to set the parameters?
		*/
		pub fun calculateCost(_ tag: String) : UFix64 {
			let length= tag.length

			for i in self.lengthPrices.keys {
				if length==i {
					return self.lengthPrices[i]!
				}
			}
			return self.defaultPrice
		}

		pub fun setLeasePeriod(_ period: UFix64)  {
			self.leasePeriod=period
		}

		pub fun setLockPeriod(_ period: UFix64) {
			self.lockPeriod=period
		}

	}

	init() {
		self.NetworkPrivatePath= /private/FIN
		self.NetworkStoragePath= /storage/FIN
		self.AdministratorStoragePath=/storage/finAdmin
		self.AdministratorPrivatePath=/private/finAdmin
		self.AdminClientPublicPath= /public/finAdminClient
		self.AdminClientStoragePath=/storage/finAdminClient
		self.LeasePublicPath=/public/finLeases
		self.LeaseStoragePath=/storage/finLeases
		self.account.save(<- create Administrator(), to: self.AdministratorStoragePath)
		self.account.link<&Administrator>(self.AdministratorPrivatePath, target: self.AdministratorStoragePath) 
		self.networkCap = nil
	}
}
