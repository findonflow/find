import FINDNFTCatalog from "../contracts/FINDNFTCatalog.cdc"
import NFTCatalog from "../contracts/standard/NFTCatalog.cdc"
import FindViews from "../contracts/FindViews.cdc"
import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FungibleToken from "../contracts/standard/FungibleToken.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"
import FIND from "../contracts/FIND.cdc"
import FindLostAndFoundWrapper from "../contracts/FindLostAndFoundWrapper.cdc"

transaction(nftIdentifiers: [String], allReceivers: [String] , ids:[UInt64], memos: [String]) {

    let pointers : [FindViews.AuthNFTPointer]
    let nftInfos : [NFTCatalog.NFTCollectionData]
    let flowVault : &FungibleToken.Vault
    let flowTokenRepayment : Capability<&FlowToken.Vault{FungibleToken.Receiver}>

    prepare(account: AuthAccount){

        if allReceivers.length != nftIdentifiers.length || allReceivers.length != ids.length || allReceivers.length != memos.length {
            panic("The length of arrays passed in are not equal")
        }

        let pointers : [FindViews.AuthNFTPointer] = []
        let nftInfos : {String : NFTCatalog.NFTCollectionData} = {}
        self.nftInfos = []
        let providerCaps : {String : Capability<&{NonFungibleToken.Provider, MetadataViews.ResolverCollection, NonFungibleToken.CollectionPublic}>} = {}


        for i, id in ids {
            if nftInfos[nftIdentifiers[i]] == nil {
                let collections = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftIdentifiers[i]) ?? panic("NFT type is not supported at the moment. Type : ".concat(nftIdentifiers[i]))
                nftInfos[nftIdentifiers[i]] = FINDNFTCatalog.getCatalogEntry(collectionIdentifier: collections.keys[0])!.collectionData
            }
            self.nftInfos.append(nftInfos[nftIdentifiers[i]]!)

            if providerCaps[nftIdentifiers[i]] == nil {
                // Initialize the providerCap if the user doesn't have one
                var providerCap=account.getCapability<&{NonFungibleToken.Provider, MetadataViews.ResolverCollection, NonFungibleToken.CollectionPublic}>(self.nftInfos[i].privatePath)

                if !providerCap.check() {
                    let newCap = account.link<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
                        self.nftInfos[i].privatePath,
                        target: self.nftInfos[i].storagePath
                    )
                    if newCap == nil {
                        // If linking is not successful, we link it using finds custom link 
                        let pathIdentifier = self.nftInfos[i].privatePath.toString()
                        let findPath = PrivatePath(identifier: pathIdentifier.slice(from: "/private/".length , upTo: pathIdentifier.length).concat("_FIND"))!
                        account.link<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(
                            findPath,
                            target: self.nftInfos[i].storagePath
                        )
                        providerCap = account.getCapability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MetadataViews.ResolverCollection}>(findPath)
                    }
                }
                providerCaps[nftIdentifiers[i]] = providerCap
            }

            let providerCap = providerCaps[nftIdentifiers[i]]!

            pointers.append(FindViews.AuthNFTPointer(cap: providerCap, id: id))
        }
        self.pointers = pointers

        // Get Vault for paying flow storage fee
        self.flowVault = account.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault) ?? panic("Cannot borrow reference to sender's flow vault")
        self.flowTokenRepayment = account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver) 
    }

    execute{
        let initialFlowBalance = self.flowVault.balance
        let receivingAddresses : {String : Address} = {}

        var receivers = allReceivers
        for i , receiver in receivers {
            if receivingAddresses[receiver] == nil {
                let receivingAddress = FIND.resolve(receiver) ?? panic("invalid find name or address. Input : ".concat(receiver))
                receivingAddresses.insert(key: receiver, receivingAddress)
            }
            let receivingAddress = receivingAddresses[receiver]!
            let receiverCap = getAccount(receivingAddress).getCapability<&{NonFungibleToken.Receiver}>(self.nftInfos[i].publicPath)

            FindLostAndFoundWrapper.depositNFT(
                receiverCap: receiverCap,
                item: self.pointers[i],
                memo: memos[i],
                storagePayment: self.flowVault,
                flowTokenRepayment: self.flowTokenRepayment
            )


        }
    
    }


}
 