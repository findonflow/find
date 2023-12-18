import FindLostAndFoundWrapper from "../contracts/FindLostAndFoundWrapper.cdc"
import LostAndFound from "../contracts/standard/LostAndFound.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FindViews from "../contracts/FindViews.cdc"
import FIND from "../contracts/FIND.cdc"
import Bl0xPack from "../contracts/Bl0xPack.cdc"

//IMPORT

transaction(receiverAddress: Address, ids: {String : [UInt64]}) {

	let nftInfos : {String : NFTCatalog.NFTCollectionData}
	let receiverAddress : Address

	prepare(account: auth(BorrowValue)  AuthAccountAccount){

		self.receiverAddress = receiverAddress

		self.nftInfos = {}

		for type in ids.keys{ 
			if self.nftInfos[type] == nil {
				let collections = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: type) ?? panic("NFT type is not supported at the moment. Type : ".concat(type))
				self.nftInfos[type] = FINDNFTCatalog.getCatalogEntry(collectionIdentifier: collections.keys[0])!.collectionData
			}
		}

	}

	execute{
		for type in ids.keys{ 
			let path = self.nftInfos[type]!.publicPath
			for id in ids[type]! {
				FindLostAndFoundWrapper.redeemNFT(type: CompositeType(type)!, ticketID: id, receiverAddress:self.receiverAddress, collectionPublicPath: path)
			}
		}
	}
}

