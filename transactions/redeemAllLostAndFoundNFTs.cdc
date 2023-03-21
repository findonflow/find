import FindLostAndFoundWrapper from "../contracts/FindLostAndFoundWrapper.cdc"
import LostAndFound from "../contracts/standard/LostAndFound.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"

//IMPORT

transaction() {

	let ids : {String : [UInt64]}
	let nftInfos : {String : NFTCatalog.NFTCollectionData}
	let receiverAddress : Address

	prepare(account: AuthAccount){

		//LINK


		self.nftInfos = {}
		self.ids = FindLostAndFoundWrapper.getTicketIDs(user: account.address, specificType: Type<@NonFungibleToken.NFT>())

		for type in self.ids.keys{
			if self.nftInfos[type] == nil {
				let collections = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: type) ?? panic("NFT type is not supported at the moment. Type : ".concat(type))
				self.nftInfos[type] = FINDNFTCatalog.getCatalogEntry(collectionIdentifier: collections.keys[0])!.collectionData
			}
		}

		self.receiverAddress = account.address
	}

	execute{
		for type in self.ids.keys{
			let path = self.nftInfos[type]!.publicPath
			for id in self.ids[type]! {
				FindLostAndFoundWrapper.redeemNFT(type: CompositeType(type)!, ticketID: id, receiverAddress: self.receiverAddress, collectionPublicPath: path)
			}
		}
	}
}

