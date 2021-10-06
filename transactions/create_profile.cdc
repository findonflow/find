import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"


//really not sure on how to input links here.
transaction(name: String, description: String, avatar: String, tags:[String], allowStoringFollowers: Bool, linkTitle: [String], linkType: [String], linkUrl: [String]) {
	prepare(acct: AuthAccount) {

		let profile <-Profile.createUser(name:name, description: description, allowStoringFollowers:allowStoringFollowers, tags:tags)

		//Add exising FUSD or create a new one and add it
		let fusdReceiver = acct.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
		if !fusdReceiver.check() {
			let fusd <- FUSD.createEmptyVault()
			acct.save(<- fusd, to: /storage/fusdVault)
			acct.link<&FUSD.Vault{FungibleToken.Receiver}>( /public/fusdReceiver, target: /storage/fusdVault)
			acct.link<&FUSD.Vault{FungibleToken.Balance}>( /public/fusdBalance, target: /storage/fusdVault)

			let fusdWallet=Profile.Wallet(
				name:"FUSD", 
				receiver:acct.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver),
				balance:acct.getCapability<&{FungibleToken.Balance}>(/public/fusdBalance),
				accept: Type<@FUSD.Vault>(),
				names: ["fusd", "stablecoin"]
			)

			profile.addWallet(fusdWallet)

		}

		let leaseCollection = acct.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
		if !leaseCollection.check() {
			acct.save(<- FIND.createEmptyLeaseCollection(), to: FIND.LeaseStoragePath)
			acct.link<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>( FIND.LeasePublicPath, target: FIND.LeaseStoragePath)
		}
		profile.addCollection(Profile.ResourceCollection("FINDLeases",leaseCollection, Type<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(), ["find", "leases"]))

		let bidCollection = acct.getCapability<&FIND.BidCollection{FIND.BidCollectionPublic}>(FIND.BidPublicPath)
		if !bidCollection.check() {
			acct.save(<- FIND.createEmptyBidCollection(receiver: fusdReceiver, leases: leaseCollection), to: FIND.BidStoragePath)
			acct.link<&FIND.BidCollection{FIND.BidCollectionPublic}>( FIND.BidPublicPath, target: FIND.BidStoragePath)
		}
		profile.addCollection(Profile.ResourceCollection( "FINDBids", bidCollection, Type<&FIND.BidCollection{FIND.BidCollectionPublic}>(), ["find", "bids"]))

		profile.setAvatar(avatar)

		if linkTitle.length != linkType.length && linkType.length != linkUrl.length {
			panic("need same length of link names, targets, types")
		}

		var i=0
		while i < linkTitle.length {
			profile.addLink(Profile.Link(title: linkTitle[i], type: linkType[i], url: linkUrl[i]))
			i=i+1
		}

		acct.save(<-profile, to: Profile.storagePath)
		acct.link<&Profile.User{Profile.Public}>(Profile.publicPath, target: Profile.storagePath)

		let p =acct.borrow<&Profile.User>(from:Profile.storagePath)!
		p.verify("test")
	}
}
