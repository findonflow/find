import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
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
		profile.setDescription(name)
		profile.setAvatar(name)

		let existingTags=profile.setTags(tags)

		let oldLinks=profile.getLinks()

		for link in links {
			if link["remove"] == "true" {
			  profile.removeLink(link["title"]!)	
			}
			profile.addLink(Profile.Link(title: link["title"]!, type: link["type"]!, url: link["url"]!))
		}
	}
}

