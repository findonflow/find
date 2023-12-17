import FINDNFTCatalog from "./FINDNFTCatalog.cdc"
import NFTCatalog from "./standard/NFTCatalog.cdc"

// NFTCatalogAdmin
//
// An admin contract that defines an    admin resource and
// a proxy resource to receive a capability that lets you make changes to the NFT Catalog
// and manage proposals

access(all) contract FINDNFTCatalogAdmin {

    access(all) let AdminStoragePath: StoragePath

    access(all) let AdminProxyPublicPath: PublicPath
    access(all) let AdminProxyStoragePath: StoragePath

    // Admin
    // Admin resource to manage NFT Catalog
    access(all) resource Admin {

        access(all) fun addCatalogEntry(collectionIdentifier: String, metadata : NFTCatalog.NFTCatalogMetadata) {
            FINDNFTCatalog.addCatalogEntry(collectionIdentifier: collectionIdentifier, metadata : metadata)
        }

        access(all) fun updateCatalogEntry(collectionIdentifier : String , metadata : NFTCatalog.NFTCatalogMetadata) {
            FINDNFTCatalog.updateCatalogEntry(collectionIdentifier: collectionIdentifier, metadata : metadata)
        }

        access(all) fun removeCatalogEntry(collectionIdentifier : String) {
            FINDNFTCatalog.removeCatalogEntry(collectionIdentifier : collectionIdentifier)
        }

        access(all) fun approveCatalogProposal(proposalID : UInt64) {
            if (FINDNFTCatalog.getCatalogProposalEntry(proposalID : proposalID) == nil) {
                panic("Invalid Proposal ID")
            }
            if (FINDNFTCatalog.getCatalogProposalEntry(proposalID : proposalID)!.status != "IN_REVIEW") {
                panic("Invalid Proposal")
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

        access(all) fun rejectCatalogProposal(proposalID : UInt64) {
            if (FINDNFTCatalog.getCatalogProposalEntry(proposalID : proposalID) == nil) {
                panic("Invalid Proposal ID")
            }
            if (FINDNFTCatalog.getCatalogProposalEntry(proposalID : proposalID)!.status != "IN_REVIEW") {
                panic("Invalid Proposal")
            }
            let catalogProposalEntry = FINDNFTCatalog.getCatalogProposalEntry(proposalID : proposalID)!
            let newCatalogProposalEntry = NFTCatalog.NFTCatalogProposal(collectionIdentifier : catalogProposalEntry.collectionIdentifier, metadata : catalogProposalEntry.metadata, message : catalogProposalEntry.message, status: "REJECTED", proposer: catalogProposalEntry.proposer)
            FINDNFTCatalog.updateCatalogProposal(proposalID : proposalID, proposalMetadata : newCatalogProposalEntry)
        }

        access(all) fun removeCatalogProposal(proposalID : UInt64) {
            if (FINDNFTCatalog.getCatalogProposalEntry(proposalID : proposalID) == nil) {
                panic("Invalid Proposal ID")
            }
            FINDNFTCatalog.removeCatalogProposal(proposalID : proposalID)
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
        self.AdminProxyPublicPath = /public/FINDnftCatalogAdminProxy
        self.AdminProxyStoragePath = /storage/FINDnftCatalogAdminProxy
        
        self.AdminStoragePath = /storage/FINDnftCatalogAdmin

        let admin    <- create Admin()

        self.account.storage.save(<-admin, to: self.AdminStoragePath)
        let adminCap = self.account.capabilities.storage.issue<&Admin>(self.AdminStoragePath)
    }
}
