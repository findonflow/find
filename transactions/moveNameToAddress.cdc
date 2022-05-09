import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import Profile from "../contracts/Profile.cdc"
import FIND from "../contracts/FIND.cdc"


transaction(name: String, receiverAddress:Address) {


	let receiverAddress:Address
	let sender : &FIND.LeaseCollection

	prepare(acct: AuthAccount) {
		self.sender= acct.borrow<&FIND.LeaseCollection>(from:FIND.LeaseStoragePath)!
		self.receiverAddress=receiverAddress
	} 

	execute {
		let receiver=getAccount(self.receiverAddress)
		let receiverLease = receiver.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
		let receiverProfile = receiver.getCapability<&{Profile.Public}>(Profile.publicPath)

		if !receiverLease.check() || !receiverProfile.check() {
			panic("Not a valid FIND user")
		}

		self.sender.move(name:name, profile:receiverProfile, to: receiverLease)
	}
}
