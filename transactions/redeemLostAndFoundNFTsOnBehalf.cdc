import "FindLostAndFoundWrapper"
import "LostAndFound"
import "FINDNFTCatalog"
import "NFTCatalog"
import "NonFungibleToken"
import "MetadataViews"
import "FindViews"
import "FIND"

//IMPORT

transaction(receiverAddress: Address, ids: {String : [UInt64]}) {

    let nftInfos : {String : NFTCatalog.NFTCollectionData}
    let receiverAddress : Address

    prepare(account: auth(BorrowValue) &Account){

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

