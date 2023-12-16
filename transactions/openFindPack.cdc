import FindPack from "../contracts/FindPack.cdc"
import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"

/// A transaction to open a pack with a given id
/// @param packId: The id of the pack to open
transaction(packId:UInt64) {

    let packs: &FindPack.Collection
    let receiver: { Type : Capability<&{NonFungibleToken.Receiver}>}

    prepare(account: AuthAccount) {
        self.packs=account.borrow<&FindPack.Collection>(from: FindPack.CollectionStoragePath)!

        let packData = self.packs.borrowFindPack(id: packId) ?? panic("You do not own this pack. ID : ".concat(packId.toString()))
        let packMetadata = packData.getMetadata()
        let types = packMetadata.itemTypes

        self.receiver = {}

        // check the account setup for receiving nfts
        for type in types {
            let collection = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: type.identifier)
            if collection == nil || collection!.length == 0 {
                panic("Type : ".concat(type.identifier).concat(" is not supported in NFTCatalog at the moment"))
            }
            let collectionInfo = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collection!.keys[0])!.collectionData

            let cap = account.getCapability<&{NonFungibleToken.Receiver}>(collectionInfo.publicPath)
            let storage= account.borrow<&NonFungibleToken.Collection>(from: collectionInfo.storagePath)
            if storage == nil {
                let newCollection <- FindPack.createEmptyCollectionFromPackData(packData: packMetadata, type: type)
                account.save(<- newCollection, to: collectionInfo.storagePath)
                account.link<&{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection}>( collectionInfo.publicPath, target: collectionInfo.storagePath)
            }

            if !cap.check() {
                account.unlink(collectionInfo.publicPath)
                account.link<&{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, ViewResolver.ResolverCollection}>( collectionInfo.publicPath, target: collectionInfo.storagePath) 
            }
            self.receiver[type] = cap
        }

    }

    execute {
        self.packs.open(packId: packId, receiverCap:self.receiver)
    }

    post {
        !self.packs.getIDs().contains(packId) : "The pack is still present in the users collection"
    }
}
