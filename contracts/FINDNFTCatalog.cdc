import NFTCatalog from "./standard/NFTCatalog.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"

// NFTCatalog
//
// A general purpose NFT registry for Flow NonFungibleTokens.
//
// Each catalog entry stores data about the NFT including
// its collection identifier, nft type, storage and public paths, etc.
//
// To make an addition to the catalog you can propose an NFT and provide its metadata.
// An Admin can approve a proposal which would add the NFT to the catalog

access(all) contract FINDNFTCatalog {
    // EntryAdded
    // An NFT collection has been added to the catalog
    access(all) event EntryAdded(
        collectionIdentifier : String,
        contractName : String,
        contractAddress : Address,
        nftType : Type,
        storagePath: StoragePath,
        publicPath: PublicPath,
        privatePath: PrivatePath,
        publicLinkedType : Type,
        privateLinkedType : Type,
        displayName : String,
        description: String,
        externalURL : String
    )

    // EntryUpdated
    // An NFT Collection has been updated in the catalog
    access(all) event EntryUpdated(
        collectionIdentifier : String,
        contractName : String,
        contractAddress : Address,
        nftType : Type,
        storagePath: StoragePath,
        publicPath: PublicPath,
        privatePath: PrivatePath,
        publicLinkedType : Type,
        privateLinkedType : Type,
        displayName : String,
        description: String,
        externalURL : String
    )

    // EntryRemoved
    // An NFT Collection has been removed from the catalog
    access(all) event EntryRemoved(collectionIdentifier : String)

    // ProposalEntryAdded
    // A new proposal to make an addtion to the catalog has been made
    access(all) event ProposalEntryAdded(proposalID : UInt64, collectionIdentifier : String, message: String, status: String, proposer : Address)

    // ProposalEntryUpdated
    // A proposal has been updated
    access(all) event ProposalEntryUpdated(proposalID : UInt64, collectionIdentifier : String, message: String, status: String, proposer : Address)

    // ProposalEntryRemoved
    // A proposal has been removed from storage
    access(all) event ProposalEntryRemoved(proposalID : UInt64)

    access(all) let ProposalManagerStoragePath: StoragePath

    access(all) let ProposalManagerPublicPath: PublicPath

    access(self) let catalog: {String : NFTCatalog.NFTCatalogMetadata} // { collectionIdentifier -> Metadata }
    access(self) let catalogTypeData: {String : {String : Bool}} // Additional view to go from { NFT Type Identifier -> {Collection Identifier : Bool } }

    access(self) let catalogProposals : {UInt64 : NFTCatalog.NFTCatalogProposal} // { ProposalID : Metadata }

    access(self) var totalProposals : UInt64

    // Get FIND and Dapper NFTCatalog 
    access(all) fun getCatalog() : {String : NFTCatalog.NFTCatalogMetadata} {
        let find = self.catalog 
        let dapper = NFTCatalog.getCatalog()
        for item in dapper.keys {
            find[item] = dapper[item]
        }
        return find
    }

    access(all) fun getCatalogEntry(collectionIdentifier : String) : NFTCatalog.NFTCatalogMetadata? {
        if let dapper = NFTCatalog.getCatalogEntry(collectionIdentifier : collectionIdentifier) {
            return dapper
        }
        return self.catalog[collectionIdentifier]
    }

    access(all) fun getCollectionsForType(nftTypeIdentifier: String) : {String : Bool}? {
        if let dapper = NFTCatalog.getCollectionsForType(nftTypeIdentifier: nftTypeIdentifier) {
            // If there's dappers input and Find input, dappers will overwrite what's on find
            if let find = self.catalogTypeData[nftTypeIdentifier] {
                for item in dapper.keys {
                    find[item] = dapper[item]
                }
                return find
            }
            // If there's only dapper input, return it
            return dapper
        }
            // Else return what's on find
        return self.catalogTypeData[nftTypeIdentifier]
    }

    access(all) fun getCatalogTypeData() : {String : {String : Bool}} {
        let find = self.catalogTypeData 
        let dapper = NFTCatalog.getCatalogTypeData()
        for item in dapper.keys {
            find[item] = dapper[item]
        }
        return find
    }

    // A helper function to get CollectionData directly from NFTIdentifier
    access(all) fun getCollectionDataForType(nftTypeIdentifier: String) : NFTCatalog.NFTCollectionData? {
        if let collections = FINDNFTCatalog.getCollectionsForType(nftTypeIdentifier: nftTypeIdentifier) {
            if collections.length < 1 {
                return nil
            }
            if let collection = FINDNFTCatalog.getCatalogEntry(collectionIdentifier : collections.keys[0]) {
                return collection.collectionData
            }
        }
        return nil
    }

    // helper function to get Paths 
    access(all) fun getMetadataFromType(_ t: Type) : NFTCatalog.NFTCatalogMetadata? {
        let collectionIdentifier = self.getCollectionsForType(nftTypeIdentifier: t.identifier) 
        if collectionIdentifier == nil || collectionIdentifier!.length < 1 {
            return nil
        }
        return self.getCatalogEntry(collectionIdentifier : collectionIdentifier!.keys[0])
    }

    // Get only FIND NFTCatalog
    access(all) fun getFINDCatalog() : {String : NFTCatalog.NFTCatalogMetadata} {
        return self.catalog
    }

    access(all) fun getFINDCatalogEntry(collectionIdentifier : String) : NFTCatalog.NFTCatalogMetadata? {
        return self.catalog[collectionIdentifier]
    }

    access(all) fun getFINDCollectionsForType(nftTypeIdentifier: String) : {String : Bool}? {
        return self.catalogTypeData[nftTypeIdentifier]
    }

    access(all) fun getFINDCatalogTypeData() : {String : {String : Bool}} {
        return self.catalogTypeData
    }

    // Propose an NFT collection to the catalog
    // @param collectionIdentifier: The unique name assinged to this nft collection
    // @param metadata: The Metadata for the NFT collection that will be stored in the catalog
    // @param message: A message to the catalog owners
    // @param proposer: Who is making the proposition(the address needs to be verified)
    access(all) fun proposeNFTMetadata(collectionIdentifier : String, metadata : NFTCatalog.NFTCatalogMetadata, message : String, proposer : Address) : UInt64 {
        let proposerManagerCap = getAccount(proposer).capabilities.get<&NFTCatalog.NFTCatalogProposalManager>(NFTCatalog.ProposalManagerPublicPath)!

        assert(proposerManagerCap.check(), message : "Proposer needs to set up a manager")

        let proposerManagerRef = proposerManagerCap.borrow()!

        assert(proposerManagerRef.getCurrentProposalEntry()! == collectionIdentifier, message: "Expected proposal entry does not match entry for the proposer")

        let catalogProposal = NFTCatalog.NFTCatalogProposal(collectionIdentifier : collectionIdentifier, metadata : metadata, message : message, status: "IN_REVIEW", proposer: proposer)
        self.totalProposals = self.totalProposals + 1
        self.catalogProposals[self.totalProposals] = catalogProposal

        emit ProposalEntryAdded(proposalID : self.totalProposals, collectionIdentifier : collectionIdentifier, message: catalogProposal.message, status: catalogProposal.status, proposer: catalogProposal.proposer)
        return self.totalProposals
    }

    // Withdraw a proposal from the catalog
    // @param proposalID: The ID of proposal you want to withdraw
    access(all) fun withdrawNFTProposal(proposalID : UInt64) {
        pre {
            self.catalogProposals[proposalID] != nil : "Invalid Proposal ID"
        }
        let proposal = self.catalogProposals[proposalID]!
        let proposer = proposal.proposer

        let proposerManagerCap = getAccount(proposer).capabilities.get<&NFTCatalog.NFTCatalogProposalManager>(NFTCatalog.ProposalManagerPublicPath)!

        assert(proposerManagerCap.check(), message : "Proposer needs to set up a manager")

        let proposerManagerRef = proposerManagerCap.borrow()!

        assert(proposerManagerRef.getCurrentProposalEntry()! == proposal.collectionIdentifier, message: "Expected proposal entry does not match entry for the proposer")

        self.removeCatalogProposal(proposalID : proposalID)
    }

    access(all) fun getCatalogProposals() : {UInt64 : NFTCatalog.NFTCatalogProposal} {
        return self.catalogProposals
    }

    access(all) fun getCatalogProposalEntry(proposalID : UInt64) : NFTCatalog.NFTCatalogProposal? {
        return self.catalogProposals[proposalID]
    }

    access(all) fun createNFTCatalogProposalManager(): @NFTCatalog.NFTCatalogProposalManager {
        return <- NFTCatalog.createNFTCatalogProposalManager()
    }

    access(account) fun addCatalogEntry(collectionIdentifier : String, metadata: NFTCatalog.NFTCatalogMetadata) {
        pre {
            self.catalog[collectionIdentifier] == nil : "The nft name has already been added to the catalog"
        }

        self.addCatalogTypeEntry(collectionIdentifier : collectionIdentifier , metadata: metadata)

        self.catalog[collectionIdentifier] = metadata

        emit EntryAdded(
            collectionIdentifier : collectionIdentifier,
            contractName : metadata.contractName,
            contractAddress : metadata.contractAddress,
            nftType: metadata.nftType,
            storagePath: metadata.collectionData.storagePath,
            publicPath: metadata.collectionData.publicPath,
            privatePath: metadata.collectionData.privatePath,
            publicLinkedType : metadata.collectionData.publicLinkedType,
            privateLinkedType : metadata.collectionData.privateLinkedType,
            displayName : metadata.collectionDisplay.name,
            description: metadata.collectionDisplay.description,
            externalURL : metadata.collectionDisplay.externalURL.url
        )
    }

    access(account) fun updateCatalogEntry(collectionIdentifier : String , metadata: NFTCatalog.NFTCatalogMetadata) {
        pre {
            self.catalog[collectionIdentifier] != nil : "Invalid collection identifier"
        }
        // remove previous nft type entry
        self.removeCatalogTypeEntry(collectionIdentifier : collectionIdentifier , metadata: metadata)
        // add updated nft type entry
        self.addCatalogTypeEntry(collectionIdentifier : collectionIdentifier , metadata: metadata)

        self.catalog[collectionIdentifier] = metadata

        let nftType = metadata.nftType

        emit EntryUpdated(
            collectionIdentifier : collectionIdentifier,
            contractName : metadata.contractName,
            contractAddress : metadata.contractAddress,
            nftType: metadata.nftType,
            storagePath: metadata.collectionData.storagePath,
            publicPath: metadata.collectionData.publicPath,
            privatePath: metadata.collectionData.privatePath,
            publicLinkedType : metadata.collectionData.publicLinkedType,
            privateLinkedType : metadata.collectionData.privateLinkedType,
            displayName : metadata.collectionDisplay.name,
            description: metadata.collectionDisplay.description,
            externalURL : metadata.collectionDisplay.externalURL.url
        )
    }

    access(account) fun removeCatalogEntry(collectionIdentifier : String) {
        pre {
            self.catalog[collectionIdentifier] != nil : "Invalid collection identifier"
        }

        self.removeCatalogTypeEntry(collectionIdentifier : collectionIdentifier , metadata: self.catalog[collectionIdentifier]!)
        self.catalog.remove(key: collectionIdentifier)

        emit EntryRemoved(collectionIdentifier : collectionIdentifier)
    }

    access(account) fun updateCatalogProposal(proposalID: UInt64, proposalMetadata : NFTCatalog.NFTCatalogProposal) {
        self.catalogProposals[proposalID] = proposalMetadata

        emit ProposalEntryUpdated(proposalID : proposalID, collectionIdentifier : proposalMetadata.collectionIdentifier, message: proposalMetadata.message, status: proposalMetadata.status, proposer: proposalMetadata.proposer)
    }

    access(account) fun removeCatalogProposal(proposalID : UInt64) {
        self.catalogProposals.remove(key : proposalID)

        emit ProposalEntryRemoved(proposalID : proposalID)
    }

    access(contract) fun addCatalogTypeEntry(collectionIdentifier : String , metadata: NFTCatalog.NFTCatalogMetadata) {
        if self.catalogTypeData[metadata.nftType.identifier] != nil {
            let typeData : {String : Bool} = self.catalogTypeData[metadata.nftType.identifier]!
            assert(self.catalogTypeData[metadata.nftType.identifier]![collectionIdentifier] == nil, message : "The nft name has already been added to the catalog")
            typeData[collectionIdentifier] = true
            self.catalogTypeData[metadata.nftType.identifier] = typeData
        } else {
            let typeData : {String : Bool} = {}
            typeData[collectionIdentifier] = true
            self.catalogTypeData[metadata.nftType.identifier] = typeData
        }
    }

    access(contract) fun removeCatalogTypeEntry(collectionIdentifier : String , metadata: NFTCatalog.NFTCatalogMetadata) {
        let prevMetadata = self.catalog[collectionIdentifier]!
        let prevCollectionsForType = self.catalogTypeData[prevMetadata.nftType.identifier]!
        prevCollectionsForType.remove(key : collectionIdentifier)
        if prevCollectionsForType.length == 0 {
            self.catalogTypeData.remove(key: prevMetadata.nftType.identifier)
        } else {
            self.catalogTypeData[prevMetadata.nftType.identifier] = prevCollectionsForType
        }
    }

    init() {
        self.ProposalManagerStoragePath = /storage/FINDnftCatalogProposalManager
        self.ProposalManagerPublicPath = /public/FINDnftCatalogProposalManager

        self.totalProposals = 0
        self.catalog = {}
        self.catalogTypeData = {}

        self.catalogProposals = {}
    }

}
