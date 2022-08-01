import FINDNFTCatalog from "./FINDNFTCatalog.cdc"
import NFTCatalog from "./standard/NFTCatalog.cdc"

// NFTCatalogAdmin
//
// An admin contract that defines an    admin resource and
// a proxy resource to receive a capability that lets you make changes to the NFT Catalog
// and manage proposals

pub contract FINDNFTCatalogAdmin {

    pub let AdminPrivatePath: PrivatePath
    pub let AdminStoragePath: StoragePath

    pub let AdminProxyPublicPath: PublicPath
    pub let AdminProxyStoragePath: StoragePath

    // Admin
    // Admin resource to manage NFT Catalog
    pub resource Admin {

        pub fun addCatalogEntry(collectionIdentifier: String, metadata : NFTCatalog.NFTCatalogMetadata) {
            FINDNFTCatalog.addCatalogEntry(collectionIdentifier: collectionIdentifier, metadata : metadata)
        }

        pub fun updateCatalogEntry(collectionIdentifier : String , metadata : NFTCatalog.NFTCatalogMetadata) {
            FINDNFTCatalog.updateCatalogEntry(collectionIdentifier: collectionIdentifier, metadata : metadata)
        }

        pub fun removeCatalogEntry(collectionIdentifier : String) {
            FINDNFTCatalog.removeCatalogEntry(collectionIdentifier : collectionIdentifier)
        }

        pub fun approveCatalogProposal(proposalID : UInt64) {
            pre {
                FINDNFTCatalog.getCatalogProposalEntry(proposalID : proposalID) != nil : "Invalid Proposal ID"
                FINDNFTCatalog.getCatalogProposalEntry(proposalID : proposalID)!.status == "IN_REVIEW" : "Invalid Proposal"
            }
            let catalogProposalEntry = FINDNFTCatalog.getCatalogProposalEntry(proposalID : proposalID)!
            let newCatalogProposalEntry = NFTCatalog.NFTCatalogProposal(collectionIdentifier : catalogProposalEntry.collectionIdentifier, metadata : catalogProposalEntry.metadata, message : catalogProposalEntry.message, status: "APPROVED", proposer: catalogProposalEntry.proposer)
            FINDNFTCatalog.updateCatalogProposal(proposalID : proposalID, proposalMetadata : newCatalogProposalEntry)

            if FINDNFTCatalog.getCatalogEntry(collectionIdentifier : FINDNFTCatalog.getCatalogProposalEntry(proposalID : proposalID)!.collectionIdentifier) == nil {
                FINDNFTCatalog.addCatalogEntry(collectionIdentifier: newCatalogProposalEntry.collectionIdentifier, metadata : newCatalogProposalEntry.metadata)
            } else {
                FINDNFTCatalog.updateCatalogEntry(collectionIdentifier: newCatalogProposalEntry.collectionIdentifier, metadata: newCatalogProposalEntry.metadata)
            }
        }

        pub fun rejectCatalogProposal(proposalID : UInt64) {
            pre {
                FINDNFTCatalog.getCatalogProposalEntry(proposalID : proposalID) != nil : "Invalid Proposal ID"
                FINDNFTCatalog.getCatalogProposalEntry(proposalID : proposalID)!.status == "IN_REVIEW" : "Invalid Proposal"
            }
            let catalogProposalEntry = FINDNFTCatalog.getCatalogProposalEntry(proposalID : proposalID)!
            let newCatalogProposalEntry = NFTCatalog.NFTCatalogProposal(collectionIdentifier : catalogProposalEntry.collectionIdentifier, metadata : catalogProposalEntry.metadata, message : catalogProposalEntry.message, status: "REJECTED", proposer: catalogProposalEntry.proposer)
            FINDNFTCatalog.updateCatalogProposal(proposalID : proposalID, proposalMetadata : newCatalogProposalEntry)
        }

        pub fun removeCatalogProposal(proposalID : UInt64) {
            pre {
                FINDNFTCatalog.getCatalogProposalEntry(proposalID : proposalID) != nil : "Invalid Proposal ID"
            }
            FINDNFTCatalog.removeCatalogProposal(proposalID : proposalID)
        }

        init () {}

    }

    // AdminProxy
    // A proxy resource that can store
    // a capability to admin controls
    pub resource interface IAdminProxy {
        pub fun addCapability(capability : Capability<&Admin>)
        pub fun hasCapability() : Bool
    }

    pub resource AdminProxy : IAdminProxy {
        
        access(self) var capability : Capability<&Admin>?

        pub fun addCapability(capability : Capability<&Admin>) {
            pre {
                capability.check() : "Invalid Admin Capability"
                self.capability == nil : "Admin Proxy already set"
            }
            self.capability = capability
        }

        pub fun getCapability() : Capability<&Admin>? {
            return self.capability
        }

        pub fun hasCapability() : Bool {
            return self.capability != nil
        }

        init() {
            self.capability = nil
        }
        
    }

    pub fun createAdminProxy() : @AdminProxy {
        return <- create AdminProxy()
    }

    init () {
        self.AdminProxyPublicPath = /public/FINDnftCatalogAdminProxy
        self.AdminProxyStoragePath = /storage/FINDnftCatalogAdminProxy
        
        self.AdminPrivatePath = /private/FINDnftCatalogAdmin
        self.AdminStoragePath = /storage/FINDnftCatalogAdmin

        let admin    <- create Admin()

        self.account.save(<-admin, to: self.AdminStoragePath)
        self.account.link<&Admin>(self.AdminPrivatePath, target: self.AdminStoragePath)
    }
}