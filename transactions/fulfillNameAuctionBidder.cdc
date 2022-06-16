import FIND from "../contracts/FIND.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import Profile from "../contracts/Profile.cdc"
import FindRewardToken from "../contracts/FindRewardToken.cdc"

transaction(owner: Address, name: String) {
	prepare(acct: AuthAccount) {


	//Add exising FUSD or create a new one and add it
		let fusdReceiver = acct.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
		if !fusdReceiver.check() {
			let fusd <- FUSD.createEmptyVault()
			acct.save(<- fusd, to: /storage/fusdVault)
			acct.link<&FUSD.Vault{FungibleToken.Receiver}>( /public/fusdReceiver, target: /storage/fusdVault)
			acct.link<&FUSD.Vault{FungibleToken.Balance}>( /public/fusdBalance, target: /storage/fusdVault)
		}

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

		let profileCap = acct.getCapability<&{Profile.Public}>(Profile.publicPath)
		if !profileCap.check() {
			let profile <-Profile.createUser(name:name, createdAt: "find")

			let fusdWallet=Profile.Wallet( name:"FUSD", receiver:fusdReceiver, balance:acct.getCapability<&{FungibleToken.Balance}>(/public/fusdBalance), accept: Type<@FUSD.Vault>(), names: ["fusd", "stablecoin"])

			profile.addWallet(fusdWallet)

			/* Add Reward Tokens */
			let rewardTokenCaps = FindRewardToken.getRewardVaultViews() 
			for rewardTokenCap in rewardTokenCaps {
				if !rewardTokenCap.check() {
					continue
				}
				if let VaultData = rewardTokenCap.borrow()!.resolveView(Type<FindRewardToken.FTVaultData>()) {
					let v = VaultData as! FindRewardToken.FTVaultData
					let userTokenCap = acct.getCapability<&{FungibleToken.Receiver}>(v.receiverPath)
					if userTokenCap.check() {
						if !profile.hasWallet(v.tokenAlias) {
							let tokenWallet=Profile.Wallet( name:v.tokenAlias, receiver:acct.getCapability<&{FungibleToken.Receiver}>(v.receiverPath), balance:acct.getCapability<&{FungibleToken.Balance}>(v.balancePath), accept: v.vaultType, names: [v.tokenAlias])
							profile.addWallet(tokenWallet)
						}
						continue
					}
					acct.save( <- v.createEmptyVault() , to: v.storagePath)
					acct.link<&{FungibleToken.Receiver}>(v.receiverPath, target: v.storagePath)
					acct.link<&{FungibleToken.Balance}>(v.balancePath, target: v.storagePath)
					if !profile.hasWallet(v.tokenAlias) {
						let tokenWallet=Profile.Wallet( name:v.tokenAlias, receiver:acct.getCapability<&{FungibleToken.Receiver}>(v.receiverPath), balance:acct.getCapability<&{FungibleToken.Balance}>(v.balancePath), accept: v.vaultType, names: [v.tokenAlias])
						profile.addWallet(tokenWallet)
					}
				}
			}

			acct.save(<-profile, to: Profile.storagePath)
			acct.link<&Profile.User{Profile.Public}>(Profile.publicPath, target: Profile.storagePath)
			acct.link<&{FungibleToken.Receiver}>(Profile.publicReceiverPath, target: Profile.storagePath)
		}

		let leaseCollectionOwner = getAccount(owner).getCapability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(FIND.LeasePublicPath)
		leaseCollectionOwner.borrow()!.fulfillAuction(name)

	}
}
