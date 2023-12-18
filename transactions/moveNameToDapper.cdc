import Profile from "../contracts/Profile.cdc"
import FIND from "../contracts/FIND.cdc"


transaction(name: String, receiver:String) {


	let receiverAddress:Address?
	let sender : &FIND.LeaseCollection

	prepare(acct: auth(BorrowValue) &Account) {
		self.sender= acct.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath) ?? panic("You do not have a profile set up, initialize the user first")
		self.receiverAddress=FIND.resolve(receiver)
	} 

	pre{
		self.receiverAddress != nil : "The input pass in is not a valid name or address. Input : ".concat(receiver)
	}

	execute {
		let receiver=getAccount(self.receiverAddress!)
		let receiverLease = receiver.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
		let receiverProfile = receiver.getCapability<&{Profile.Public}>(Profile.publicPath)

		if !receiverLease.check() || !receiverProfile.check() {
			panic("Not a valid FIND user")
		}

		self.sender.move(name:name, profile:receiverProfile, to: receiverLease)
	}
}
