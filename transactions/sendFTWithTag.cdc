import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import Profile from "../contracts/Profile.cdc"
import Sender from "../contracts/Sender.cdc"
import FIND from "../contracts/FIND.cdc"
import CharityNFT from "../contracts/CharityNFT.cdc"


transaction(name: String, amount: UFix64, type: String, tag:String) {

	prepare(account: AuthAccount) {

		let stdCap= account.getCapability<&{NonFungibleToken.CollectionPublic}>(CharityNFT.CollectionPublicPath)
		if !stdCap.check() {
			account.save<@NonFungibleToken.Collection>(<- CharityNFT.createEmptyCollection(), to: CharityNFT.CollectionStoragePath)
			account.link<&{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(CharityNFT.CollectionPublicPath, target: CharityNFT.CollectionStoragePath)
		}

		let charityCap = account.getCapability<&{CharityNFT.CollectionPublic}>(/public/findCharityNFTCollection)
		if !charityCap.check() {
			account.link<&{CharityNFT.CollectionPublic, MetadataViews.ResolverCollection}>(/public/findCharityNFTCollection, target: CharityNFT.CollectionStoragePath)
		}

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

		let profileCap = account.getCapability<&{Profile.Public}>(Profile.publicPath)
		if !profileCap.check() {
			let profileName = account.address.toString()

			let profile <-Profile.createUser(name:profileName, createdAt: "find")

			let fusdWallet=Profile.Wallet( name:"FUSD", receiver:fusdReceiver, balance:account.getCapability<&{FungibleToken.Balance}>(/public/fusdBalance), accept: Type<@FUSD.Vault>(), names: ["fusd", "stablecoin"])

			profile.addWallet(fusdWallet)

			let flowWallet=Profile.Wallet(
				name:"Flow", 
				receiver:account.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver),
				balance:account.getCapability<&{FungibleToken.Balance}>(/public/flowTokenBalance),
				accept: Type<@FlowToken.Vault>(),
				names: ["flow"]
			)
	
			profile.addWallet(flowWallet)
			profile.addCollection(Profile.ResourceCollection("FINDLeases",leaseCollection, Type<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>(), ["find", "leases"]))
			profile.addCollection(Profile.ResourceCollection("FINDBids", bidCollection, Type<&FIND.BidCollection{FIND.BidCollectionPublic}>(), ["find", "bids"]))

			account.save(<-profile, to: Profile.storagePath)
			account.link<&Profile.User{Profile.Public}>(Profile.publicPath, target: Profile.storagePath)
			account.link<&{FungibleToken.Receiver}>(Profile.publicReceiverPath, target: Profile.storagePath)
		}

		if account.borrow<&Sender.Token>(from: Sender.storagePath) == nil {
			account.save(<- Sender.create(), to: Sender.storagePath)
		}

		let token =account.borrow<&Sender.Token>(from: Sender.storagePath)!


		if type == "fusd" {
			let vaultRef = account.borrow<&FUSD.Vault>(from: /storage/fusdVault) ?? panic("Could not borrow reference to the fusdVault!")
			let vault <- vaultRef.withdraw(amount: amount)
			FIND.depositWithTagAndMessage(to: name, message: "", tag: tag, vault: <- vault, from: token)
			return 
		}

		let vaultRef = account.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault) ?? panic("Could not borrow reference to the fusdVault!")
		let vault <- vaultRef.withdraw(amount: amount)
		FIND.depositWithTagAndMessage(to: name, message: "", tag: tag, vault: <- vault, from: token)
	}

}

