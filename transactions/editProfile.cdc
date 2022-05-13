import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FIND from "../contracts/FIND.cdc"
import Profile from "../contracts/Profile.cdc"

transaction(name:String, description: String, avatar: String, tags:[String], allowStoringFollowers: Bool, links: [{String: String}]) {
	prepare(acct: AuthAccount) {

		let profile =acct.borrow<&Profile.User>(from:Profile.storagePath)!

		//Add exising FUSD or create a new one and add it
		let fusdReceiver = acct.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
		if !fusdReceiver.check() {
			let fusd <- FUSD.createEmptyVault()
			acct.save(<- fusd, to: /storage/fusdVault)
			acct.link<&FUSD.Vault{FungibleToken.Receiver}>( /public/fusdReceiver, target: /storage/fusdVault)
			acct.link<&FUSD.Vault{FungibleToken.Balance}>( /public/fusdBalance, target: /storage/fusdVault)
		}


		var hasFusdWallet=false
		var hasFlowWallet=false
		let wallets=profile.getWallets()
		for wallet in wallets {
			if wallet.name=="FUSD" {
				hasFusdWallet=true
			}

			if wallet.name =="Flow" {
				hasFlowWallet=true
			}
		}

		if !hasFlowWallet {
			let flowWallet=Profile.Wallet(
				name:"Flow", 
				receiver:acct.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver),
				balance:acct.getCapability<&{FungibleToken.Balance}>(/public/flowTokenBalance),
				accept: Type<@FlowToken.Vault>(),
				names: ["flow"]
			)
			profile.addWallet(flowWallet)
		}

		if !hasFusdWallet {
			let fusdWallet=Profile.Wallet(
				name:"FUSD", 
				receiver:acct.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver),
				balance:acct.getCapability<&{FungibleToken.Balance}>(/public/fusdBalance),
				accept: Type<@FUSD.Vault>(),
				names: ["fusd", "stablecoin"]
			)
			profile.addWallet(fusdWallet)
		}

		profile.setName(name)
		profile.setDescription(description)
		profile.setAvatar(avatar)

		let existingTags=profile.setTags(tags)

		let oldLinks=profile.getLinks()

		for link in links {
			if !link.containsKey("title") {
				continue
			}
			if link["remove"] == "true" {
				profile.removeLink(link["title"]!)	
				continue
			}
			profile.addLink(Profile.Link(title: link["title"]!, type: link["type"]!, url: link["url"]!))
		}
		acct.borrow<&Profile.User>(from: Profile.storagePath)!.emitUpdatedEvent()

		let leaseCollection = acct.getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
		if !leaseCollection.check() {
			acct.save(<- FIND.createEmptyLeaseCollection(), to: FIND.LeaseStoragePath)
			acct.link<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>( FIND.LeasePublicPath, target: FIND.LeaseStoragePath)

		}

		let bidCollection = acct.getCapability<&FIND.BidCollection{FIND.BidCollectionPublic}>(FIND.BidPublicPath)
		if !bidCollection.check() {
			acct.save(<- FIND.createEmptyBidCollection(receiver: fusdReceiver, leases: leaseCollection), to: FIND.BidStoragePath)
			acct.link<&FIND.BidCollection{FIND.BidCollectionPublic}>( FIND.BidPublicPath, target: FIND.BidStoragePath)
		}
	}
}

