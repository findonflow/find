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

    prepare(account: auth (StorageCapabilities, SaveValue,PublishCapability, BorrowValue) &Account) {
        self.packs=account.storage.borrow<&FindPack.Collection>(from: FindPack.CollectionStoragePath)!

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


            let storage= account.storage.borrow<&{NonFungibleToken.Collection}>(from: collectionInfo.storagePath)
            if storage == nil {
                let newCollection <- FindPack.createEmptyCollectionFromPackData(packData: packMetadata, type: type)
                account.storage.save(<- newCollection, to: collectionInfo.storagePath)
                let fc= account.capabilities.storage.issue<&FindPack.Collection>(collectionInfo.storagePath)
                account.capabilities.publish(fc, at: collectionInfo.publicPath)
            }
            self.receiver[type] = account.capabilities.get<&{NonFungibleToken.Collection}>(collectionInfo.publicPath)!
        }

    }

    execute {
        self.packs.open(packId: packId, receiverCap:self.receiver)
    }

    post {
        !self.packs.getIDs().contains(packId) : "The pack is still present in the users collection"
    }
}
