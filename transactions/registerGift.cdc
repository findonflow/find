import "FUSD"
import "Profile"
import "FIND"

transaction(name: String, amount: UFix64, recipient: String) {

	let price : UFix64 
	let vaultRef : &FUSD.Vault? 
	let receiverLease : Capability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>
	let receiverProfile : Capability<&{Profile.Public}>
	let leases : auth(FIND.LeaseOwner) &FIND.LeaseCollection?

	prepare(acct: auth(BorrowValue) &Account) {

		let resolveAddress = FIND.resolve(recipient)
		if resolveAddress == nil {panic("The input pass in is not a valid name or address. Input : ".concat(recipient))}
		let address = resolveAddress!

		self.price=FIND.calculateCost(name)
		log("The cost for registering this name is ".concat(self.price.toString()))

		self.vaultRef = acct.borrow<&FUSD.Vault>(from: /storage/fusdVault)

		self.leases=acct.borrow<auth(FIND.LeaseOwner) &FIND.LeaseCollection>(from: FIND.LeaseStoragePath)

		let receiver = getAccount(address)
		self.receiverLease = receiver.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
		self.receiverProfile = receiver.getCapability<&{Profile.Public}>(Profile.publicPath)

	}

	pre{
		self.price == amount : "Calculated cost : ".concat(self.price.toString()).concat(" does not match expected cost").concat(amount.toString())
		self.vaultRef != nil : "Cannot borrow reference to fusd Vault!"
		self.receiverLease.check() : "Lease capability is invalid"
		self.receiverProfile.check() : "Profile capability is invalid"
		self.leases != nil : "Cannot borrow refernce to find lease collection"
	}

	execute{
		let payVault <- self.vaultRef!.withdraw(amount: self.price) as! @FUSD.Vault
		self.leases!.register(name: name, vault: <- payVault)
		self.leases!.move(name: name, profile: self.receiverProfile, to: self.receiverLease)
	}
}
