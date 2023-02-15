import FindLostAndFoundWrapper from 0x097bafa4e0b48eef
import LostAndFound from 0x473d6a2c37eab5be
import FINDNFTCatalog from 0x097bafa4e0b48eef
import NFTCatalog from 0x49a7cda3a1eecc29
import NonFungibleToken from 0x1d7e57aa55817448
import MetadataViews from 0x1d7e57aa55817448
import FIND from 0x097bafa4e0b48eef

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
