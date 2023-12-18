import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import CharityNFT from "../contracts/CharityNFT.cdc"

//This transaction will prepare the art collection
transaction() {
	prepare(account: auth(BorrowValue) &Account) {

		let stdCap= account.getCapability<&{NonFungibleToken.Collection}>(CharityNFT.CollectionPublicPath)
		if !stdCap.check() {
			account.storage.save<@NonFungibleToken.Collection>(<- CharityNFT.createEmptyCollection(), to: CharityNFT.CollectionStoragePath)
			account.link<&{NonFungibleToken.Collection, ViewResolver.ResolverCollection}>(CharityNFT.CollectionPublicPath, target: CharityNFT.CollectionStoragePath)
		}

		let charityCap = account.getCapability<&{CharityNFT.CollectionPublic}>(/public/findCharityNFTCollection)
		if !charityCap.check() {
			account.link<&{CharityNFT.CollectionPublic, ViewResolver.ResolverCollection}>(/public/findCharityNFTCollection, target: CharityNFT.CollectionStoragePath)
		}
	}
}
