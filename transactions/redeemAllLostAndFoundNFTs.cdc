import FindLostAndFoundWrapper from "../contracts/FindLostAndFoundWrapper.cdc"
import LostAndFound from "../contracts/standard/LostAndFound.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"

transaction() {

	let receiverCaps : {String : Capability<&{NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>} 
	let ids : {String : [UInt64]}

	prepare(account: AuthAccount){

        let nftInfos : {String : NFTCatalog.NFTCollectionData} = {}
		self.receiverCaps = {}

		self.ids = FindLostAndFoundWrapper.getTicketIDs(user: account.address, specificType: Type<@NonFungibleToken.NFT>())

		for type in self.ids.keys{ 

            if nftInfos[type] == nil {
                let collections = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: type) ?? panic("NFT type is not supported at the moment. Type : ".concat(type))
                nftInfos[type] = FINDNFTCatalog.getCatalogEntry(collectionIdentifier: collections.keys[0])!.collectionData
            }
            let nft = nftInfos[type]!

			var targetCapability = self.receiverCaps[type]
			if targetCapability == nil {
				targetCapability = account.getCapability<&{NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(nft.publicPath)
				if !targetCapability!.check(){
					panic("Corresponding collection is not initialized. Type : ".concat(type))
				}
				self.receiverCaps.insert(key: type, targetCapability!)
			}

		}
	}

	execute{
		for type in self.ids.keys{ 
			for id in self.ids[type]! {
				FindLostAndFoundWrapper.redeemNFT(type: CompositeType(type)!, ticketID: id, receiver:self.receiverCaps[type]!)
			}
		}
	}
}
 