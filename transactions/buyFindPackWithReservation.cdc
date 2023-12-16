import FindPack from "../contracts/FindPack.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FUSD from "../contracts/standard/FUSD.cdc"
import Profile from "../contracts/Profile.cdc"

transaction(packTypeName: String, packTypeId:UInt64, packId: UInt64, amount: UFix64, signature:String) {
	let packs: &FindPack.Collection{FindPack.CollectionPublic}

	let userPacks: Capability<&FindPack.Collection{NonFungibleToken.Receiver}>
	let salePrice: UFix64
	let packsLeft: UInt64

	let userFlowTokenVault: &FlowToken.Vault

	let paymentVault: @FungibleToken.Vault
	let balanceBeforeTransfer:UFix64

	prepare(account: AuthAccount) {

		let findPackCap= account.getCapability<&{NonFungibleToken.CollectionPublic}>(FindPack.CollectionPublicPath)
		if !findPackCap.check() {
			account.save<@NonFungibleToken.Collection>( <- FindPack.createEmptyCollection(), to: FindPack.CollectionStoragePath)
			account.link<&FindPack.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, ViewResolver.ResolverCollection}>(
				FindPack.CollectionPublicPath,
				target: FindPack.CollectionStoragePath
			)
		}

		let profileCap = account.getCapability<&{Profile.Public}>(Profile.publicPath)
		if !profileCap.check() {
			let profile <-Profile.createUser(name:account.address.toString(), createdAt: "find")

			//Add exising FUSD or create a new one and add it
			let fusdReceiver = account.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
			if !fusdReceiver.check() {
				let fusd <- FUSD.createEmptyVault()
				account.save(<- fusd, to: /storage/fusdVault)
				account.link<&FUSD.Vault{FungibleToken.Receiver}>( /public/fusdReceiver, target: /storage/fusdVault)
				account.link<&FUSD.Vault{FungibleToken.Balance}>( /public/fusdBalance, target: /storage/fusdVault)
			}

			let fusdWallet=Profile.Wallet(
				name:"FUSD", 
				receiver:account.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver),
				balance:account.getCapability<&{FungibleToken.Balance}>(/public/fusdBalance),
				accept: Type<@FUSD.Vault>(),
				names: ["fusd", "stablecoin"]
			)

			profile.addWallet(fusdWallet)

			let flowWallet=Profile.Wallet(
				name:"Flow", 
				receiver:account.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver),
				balance:account.getCapability<&{FungibleToken.Balance}>(/public/flowTokenBalance),
				accept: Type<@FlowToken.Vault>(),
				names: ["flow"]
			)
			profile.addWallet(flowWallet)
			account.save(<-profile, to: Profile.storagePath)
			account.link<&Profile.User{Profile.Public}>(Profile.publicPath, target: Profile.storagePath)
			account.link<&{FungibleToken.Receiver}>(Profile.publicReceiverPath, target: Profile.storagePath)


		}

		self.userPacks=account.getCapability<&FindPack.Collection{NonFungibleToken.Receiver}>(FindPack.CollectionPublicPath)
		self.packs=FindPack.getPacksCollection(packTypeName: packTypeName, packTypeId:packTypeId)

		self.salePrice= FindPack.getCurrentPrice(packTypeName: packTypeName, packTypeId:packTypeId, user:account.address) ?? panic ("Cannot buy the pack now") 

		self.packsLeft= UInt64(self.packs.getPacksLeft())


		self.userFlowTokenVault = account.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault) ?? panic("Cannot borrow FlowToken vault from account storage")
		self.balanceBeforeTransfer = self.userFlowTokenVault.balance

		if self.balanceBeforeTransfer < amount {
			panic("Your account does not have enough funds has ".concat(self.balanceBeforeTransfer.toString()).concat(" needs ").concat(amount.toString()))
		}
		self.paymentVault <- self.userFlowTokenVault.withdraw(amount: amount)
	}

	pre {
		self.salePrice == amount: "unexpected sending amount"
		self.packs.contains(packId): "The pack does not exist. ID : ".concat(packId.toString())
		self.userPacks.check() : "User need a receiver to put the pack in"
	}

	execute {
		self.packs.buyWithSignature(packId:packId, signature: signature, vault: <- self.paymentVault, collectionCapability: self.userPacks)
	}

}
