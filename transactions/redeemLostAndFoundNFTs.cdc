import FindLostAndFoundWrapper from "../contracts/FindLostAndFoundWrapper.cdc"
import LostAndFound from "../contracts/standard/LostAndFound.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import FIND from "../contracts/FIND.cdc"
import Bl0xPack from "../contracts/Bl0xPack.cdc"

transaction(ids: {String : [UInt64]}) {

	let receiverCaps : {String : Capability<&{NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>} 

	prepare(account: AuthAccount){

		let findPackCap= account.getCapability<&{NonFungibleToken.CollectionPublic}>(Bl0xPack.CollectionPublicPath)
		if !findPackCap.check() {
			account.save<@NonFungibleToken.Collection>( <- Bl0xPack.createEmptyCollection(), to: Bl0xPack.CollectionStoragePath)
			account.link<&Bl0xPack.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
				Bl0xPack.CollectionPublicPath,
				target: Bl0xPack.CollectionStoragePath
			)
		}

		let nftInfos : {String : NFTCatalog.NFTCollectionData} = {}
		self.receiverCaps = {}

		for type in ids.keys{ 

			if nftInfos[type] == nil {
				let collections = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: type) ?? panic("NFT type is not supported at the moment. Type : ".concat(type))
				nftInfos[type] = FINDNFTCatalog.getCatalogEntry(collectionIdentifier: collections.keys[0])!.collectionData
			}
			let nft = nftInfos[type]!

			var targetCapability = self.receiverCaps[type]
			if targetCapability == nil {
				targetCapability = account.getCapability<&{NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(nft.publicPath)
				self.receiverCaps.insert(key: type, targetCapability!)
			}

		}
	}

	execute{
		for type in ids.keys{ 
			for id in ids[type]! {
				FindLostAndFoundWrapper.redeemNFT(type: CompositeType(type)!, ticketID: id, receiver:self.receiverCaps[type]!)
			}
		}
	}
}

