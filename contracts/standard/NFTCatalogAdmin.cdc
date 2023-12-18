import NFTCatalog from "./NFTCatalog.cdc"

// NFTCatalogAdmin
//
// An admin contract that defines an    admin resource and
// a proxy resource to receive a capability that lets you make changes to the NFT Catalog
// and manage proposals

access(all) contract NFTCatalogAdmin {

    access(all) let AdminPrivatePath: PrivatePath
    access(all) let AdminStoragePath: StoragePath

    access(all) let AdminProxyPublicPath: PublicPath
    access(all) let AdminProxyStoragePath: StoragePath

    // Admin
    // Admin resource to manage NFT Catalog
    access(all) resource Admin {

        access(all) fun addCatalogEntry(collectionIdentifier: String, metadata : NFTCatalog.NFTCatalogMetadata) {
            NFTCatalog.addCatalogEntry(collectionIdentifier: collectionIdentifier, metadata : metadata)
        }

        access(all) fun updateCatalogEntry(collectionIdentifier : String , metadata : NFTCatalog.NFTCatalogMetadata) {
            NFTCatalog.updateCatalogEntry(collectionIdentifier: collectionIdentifier, metadata : metadata)
        }

        access(all) fun removeCatalogEntry(collectionIdentifier : String) {
            NFTCatalog.removeCatalogEntry(collectionIdentifier : collectionIdentifier)
        }

        access(all) fun approveCatalogProposal(proposalID : UInt64) {
            pre {
                NFTCatalog.getCatalogProposalEntry(proposalID : proposalID) != nil : "Invalid Proposal ID"
                NFTCatalog.getCatalogProposalEntry(proposalID : proposalID)!.status == "IN_REVIEW" : "Invalid Proposal"
            }
            let catalogProposalEntry = NFTCatalog.getCatalogProposalEntry(proposalID : proposalID)!
            let newCatalogProposalEntry = NFTCatalog.NFTCatalogProposal(collectionIdentifier : catalogProposalEntry.collectionIdentifier, metadata : catalogProposalEntry.metadata, message : catalogProposalEntry.message, status: "APPROVED", proposer: catalogProposalEntry.proposer)
            NFTCatalog.updateCatalogProposal(proposalID : proposalID, proposalMetadata : newCatalogProposalEntry)

            if NFTCatalog.getCatalogEntry(collectionIdentifier : NFTCatalog.getCatalogProposalEntry(proposalID : proposalID)!.collectionIdentifier) == nil {
                NFTCatalog.addCatalogEntry(collectionIdentifier: newCatalogProposalEntry.collectionIdentifier, metadata : newCatalogProposalEntry.metadata)
            } else {
                NFTCatalog.updateCatalogEntry(collectionIdentifier: newCatalogProposalEntry.collectionIdentifier, metadata: newCatalogProposalEntry.metadata)
            }
        }

        access(all) fun rejectCatalogProposal(proposalID : UInt64) {
            pre {
                NFTCatalog.getCatalogProposalEntry(proposalID : proposalID) != nil : "Invalid Proposal ID"
                NFTCatalog.getCatalogProposalEntry(proposalID : proposalID)!.status == "IN_REVIEW" : "Invalid Proposal"
            }
            let catalogProposalEntry = NFTCatalog.getCatalogProposalEntry(proposalID : proposalID)!
            let newCatalogProposalEntry = NFTCatalog.NFTCatalogProposal(collectionIdentifier : catalogProposalEntry.collectionIdentifier, metadata : catalogProposalEntry.metadata, message : catalogProposalEntry.message, status: "REJECTED", proposer: catalogProposalEntry.proposer)
            NFTCatalog.updateCatalogProposal(proposalID : proposalID, proposalMetadata : newCatalogProposalEntry)
        }

        access(all) fun removeCatalogProposal(proposalID : UInt64) {
            pre {
                NFTCatalog.getCatalogProposalEntry(proposalID : proposalID) != nil : "Invalid Proposal ID"
            }
            NFTCatalog.removeCatalogProposal(proposalID : proposalID)
        }

        init () {}

    }

    // AdminProxy
    // A proxy resource that can store
    // a capability to admin controls
    access(all) resource interface IAdminProxy {
        access(all) fun addCapability(capability : Capability<&Admin>)
        access(all) fun hasCapability() : Bool
    }

    access(all) resource AdminProxy : IAdminProxy {
        
        access(self) var capability : Capability<&Admin>?

        access(all) fun addCapability(capability : Capability<&Admin>) {
            pre {
                capability.check() : "Invalid Admin Capability"
                self.capability == nil : "Admin Proxy already set"
            }
            self.capability = capability
        }

        access(all) fun getCapability() : Capability<&Admin>? {
            return self.capability
        }

        access(all) fun hasCapability() : Bool {
            return self.capability != nil
        }

        init() {
            self.capability = nil
        }
        
    }

    access(all) fun createAdminProxy() : @AdminProxy {
        return <- create AdminProxy()
    }

    init () {
        self.AdminProxyPublicPath = /public/nftCatalogAdminProxy
        self.AdminProxyStoragePath = /storage/nftCatalogAdminProxy
        
        self.AdminStoragePath = /storage/nftCatalogAdmin

        let admin    <- create Admin()

        self.account.storage.save(<-admin, to: self.AdminStoragePath)
        let adminCap = self.account.capabilities.storage.issue<&Admin>(AdminStoragePath)
    }
}
