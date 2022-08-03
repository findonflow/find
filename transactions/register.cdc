import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import Profile from "../contracts/Profile.cdc"
import FIND from "../contracts/FIND.cdc"

transaction(name: String, amount: UFix64) {

	let vaultRef : &FUSD.Vault?
	let leases : &FIND.LeaseCollection?
	let price : UFix64

	prepare(account: AuthAccount) {

		let fusdReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
		if !fusdReceiver.check() {
			let fusd <- FUSD.createEmptyVault()
			account.save(<- fusd, to: /storage/fusdVault)
			account.link<&FUSD.Vault{FungibleToken.Receiver}>( /public/fusdReceiver, target: /storage/fusdVault)
			account.link<&FUSD.Vault{FungibleToken.Balance}>( /public/fusdBalance, target: /storage/fusdVault)
		}

		let leaseCollection = account.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
		if !leaseCollection.check() {
			account.save(<- FIND.createEmptyLeaseCollection(), to: FIND.LeaseStoragePath)
			account.link<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>( FIND.LeasePublicPath, target: FIND.LeaseStoragePath)
		}

		let bidCollection = account.getCapability<&FIND.BidCollection{FIND.BidCollectionPublic}>(FIND.BidPublicPath)
		if !bidCollection.check() {
			account.save(<- FIND.createEmptyBidCollection(receiver: fusdReceiver, leases: leaseCollection), to: FIND.BidStoragePath)
			account.link<&FIND.BidCollection{FIND.BidCollectionPublic}>( FIND.BidPublicPath, target: FIND.BidStoragePath)
		}

		var created=false
		var updated=false
		let profileCap = account.getCapability<&{Profile.Public}>(Profile.publicPath)
		if !profileCap.check() {
			let profile <-Profile.createUser(name:name, createdAt: "find")
			account.save(<-profile, to: Profile.storagePath)
			account.link<&Profile.User{Profile.Public}>(Profile.publicPath, target: Profile.storagePath)
			account.link<&{FungibleToken.Receiver}>(Profile.publicReceiverPath, target: Profile.storagePath)
			created=true
		}

		let profile=account.borrow<&Profile.User>(from: Profile.storagePath)!

		if !profile.hasWallet("Flow") {
			let flowWallet=Profile.Wallet( name:"Flow", receiver:account.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver), balance:account.getCapability<&{FungibleToken.Balance}>(/public/flowTokenBalance), accept: Type<@FlowToken.Vault>(), tags: ["flow"])
	
			profile.addWallet(flowWallet)
			updated=true
		}
		if !profile.hasWallet("FUSD") {
			profile.addWallet(Profile.Wallet( name:"FUSD", receiver:fusdReceiver, balance:account.getCapability<&{FungibleToken.Balance}>(/public/fusdBalance), accept: Type<@FUSD.Vault>(), tags: ["fusd", "stablecoin"]))
			updated=true
		}

		//If find name not set and we have a profile set it.
		if profile.getFindName() == "" {
			profile.setFindName(name)
			// If name is set, it will emit Updated Event, there is no need to emit another update event below. 
			updated=false
		}

		if created {
			profile.emitCreatedEvent()
		} else if updated {
			profile.emitUpdatedEvent()
		}

		self.price=FIND.calculateCost(name)
		log("The cost for registering this name is ".concat(self.price.toString()))
		self.vaultRef = account.borrow<&FUSD.Vault>(from: /storage/fusdVault)
		self.leases=account.borrow<&FIND.LeaseCollection>(from: FIND.LeaseStoragePath)
	}

	pre{
		self.vaultRef != nil : "Could not borrow reference to the fusdVault!"
		self.leases != nil : "Could not borrow reference to find lease collection"
		self.price == amount : "Calculated cost : ".concat(self.price.toString()).concat(" does not match expected cost : ").concat(amount.toString())
	}

	execute{
		let payVault <- self.vaultRef!.withdraw(amount: self.price) as! @FUSD.Vault
		self.leases!.register(name: name, vault: <- payVault)
	}
}
