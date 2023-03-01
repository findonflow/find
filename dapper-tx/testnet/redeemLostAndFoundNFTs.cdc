import FindLostAndFoundWrapper from 0x35717efbbce11c74
import LostAndFound from 0xbe4635353f55bbd4
import FINDNFTCatalog from 0x35717efbbce11c74
import NFTCatalog from 0x324c34e1c517e4db
import NonFungibleToken from 0x631e88ae7f1d7c20
import MetadataViews from 0x631e88ae7f1d7c20
import FindViews from 0x35717efbbce11c74
import FIND from 0x35717efbbce11c74

//IMPORT

transaction(ids: {String : [UInt64]}) {

    let nftInfos : {String : NFTCatalog.NFTCollectionData}
    let receiverAddress : Address

    prepare(account: AuthAccount){

        //LINK
        self.nftInfos = {}

        for type in ids.keys{ 
            if self.nftInfos[type] == nil {
                let collections = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: type) ?? panic("NFT type is not supported at the moment. Type : ".concat(type))
                self.nftInfos[type] = FINDNFTCatalog.getCatalogEntry(collectionIdentifier: collections.keys[0])!.collectionData
            }
        }

        self.receiverAddress = account.address
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
