import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import CharityNFT from "../contracts/CharityNFT.cdc"

//This transaction will prepare the art collection
transaction() {
	prepare(account: AuthAccount) {

		let stdCap= account.getCapability<&{NonFungibleToken.CollectionPublic}>(CharityNFT.CollectionPublicPath)
		if !stdCap.check() {
			account.save<@NonFungibleToken.Collection>(<- CharityNFT.createEmptyCollection(), to: CharityNFT.CollectionStoragePath)
			account.link<&{NonFungibleToken.CollectionPublic}>(CharityNFT.CollectionPublicPath, target: CharityNFT.CollectionStoragePath)
		}

		let charityCap = account.getCapability<&{CharityNFT.CollectionPublic}>(/public/findCharityNFTCollection)
		if !charityCap.check() {
			account.link<&{CharityNFT.CollectionPublic}>(/public/findCharityNFTCollection, target: CharityNFT.CollectionStoragePath)
		}
	}
}
