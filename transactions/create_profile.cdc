import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import Profile from "../contracts/Profile.cdc"


transaction(name: String, description: String, names:[String], allowStoringFollowers: Bool) {
	prepare(acct: AuthAccount) {

		let profile <-Profile.createUser(name:name, description: description, allowStoringFollowers:allowStoringFollowers, names:names)

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
		acct.save(<-profile, to: Profile.storagePath)
		acct.link<&Profile.User{Profile.Public}>(Profile.publicPath, target: Profile.storagePath)


		 //TODO; Add fin bids and leases here

		let p =acct.borrow<&Profile.User>(from:Profile.storagePath)!
		p.verify("test")
	}
}
