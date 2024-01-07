import FungibleToken from "./standard/FungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import FIND from "./FIND.cdc"
import FindMarket from "./FindMarket.cdc"
import FindMarketCutStruct from "./FindMarketCutStruct.cdc"

access(all) contract FindMarketAdmin {
    access(all) entitlement Owner

    //store the proxy for the admin
    access(all) let AdminProxyPublicPath: PublicPath
    access(all) let AdminProxyStoragePath: StoragePath

    /// ===================================================================================
    // Admin things
    /// ===================================================================================

    //Admin client to use for capability receiver pattern
    access(all) fun createAdminProxyClient() : @AdminProxy {
        return <- create AdminProxy()
    }

    //interface to use for capability receiver pattern
    access(all) resource interface AdminProxyClient {
        access(all) fun addCapability(_ cap: Capability<&FIND.Network>)
    }

    //admin proxy with capability receiver
    access(all) resource AdminProxy: AdminProxyClient {

        access(self) var capability: Capability<&FIND.Network>?

        access(all) fun addCapability(_ cap: Capability<&FIND.Network>) {
            pre {
                cap.check() : "Invalid server capablity"
                self.capability == nil : "Server already set"
            }
            self.capability = cap
        }

        access(Owner) fun createFindMarket(name: String, address:Address, findCutSaleItem: FindMarket.TenantSaleItem?) : Capability<&FindMarket.Tenant> {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }

            return  FindMarket.createFindMarket(name:name, address:address, findCutSaleItem: findCutSaleItem)
        }

        access(Owner) fun removeFindMarketTenant(tenant: Address) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }

            FindMarket.removeFindMarketTenant(tenant: tenant)
        }

        access(Owner) fun getFindMarketClient():  &FindMarket.TenantClient{
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }

            let path = FindMarket.TenantClientStoragePath
            return FindMarketAdmin.account.storage.borrow<auth(FindMarket.TenantClientOwner) &FindMarket.TenantClient>(from: path) ?? panic("Cannot borrow Find market tenant client Reference.")
        }

        /// ===================================================================================
        // Find Market Options
        /// ===================================================================================
        access(Owner) fun addSaleItemType(_ type: Type) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }
            FindMarket.addSaleItemType(type)
        }

        access(Owner) fun addMarketBidType(_ type: Type) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }
            FindMarket.addMarketBidType(type)
        }

        access(Owner) fun addSaleItemCollectionType(_ type: Type) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }
            FindMarket.addSaleItemCollectionType(type)
        }

        access(Owner) fun addMarketBidCollectionType(_ type: Type) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }
            FindMarket.addMarketBidCollectionType(type)
        }

        access(Owner) fun removeSaleItemType(_ type: Type) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }
            FindMarket.removeSaleItemType(type)
        }

        access(Owner) fun removeMarketBidType(_ type: Type) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }
            FindMarket.removeMarketBidType(type)
        }

        access(Owner) fun removeSaleItemCollectionType(_ type: Type) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }
            FindMarket.removeSaleItemCollectionType(type)
        }

        access(Owner) fun removeMarketBidCollectionType(_ type: Type) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }
            FindMarket.removeMarketBidCollectionType(type)
        }

        /// ===================================================================================
        // Tenant Rules Management
        /// ===================================================================================
        access(Owner) fun getTenantRef(_ tenant: Address) : &FindMarket.Tenant {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }
            let string = FindMarket.getTenantPathForAddress(tenant)
            let pp = PublicPath(identifier: string) ?? panic("Cannot generate storage path from string : ".concat(string))
            let cap = FindMarketAdmin.account.capabilities.borrow<&FindMarket.Tenant>(pp) ?? panic("Cannot borrow tenant reference from path. Path : ".concat(pp.toString()) )
            return cap
        }

        access(Owner) fun addFindBlockItem(tenant: Address, item: FindMarket.TenantSaleItem) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }
            let tenant = self.getTenantRef(tenant)
            tenant.addSaleItem(item, type: "find")
        }

        access(Owner) fun removeFindBlockItem(tenant: Address, name: String) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }
            let tenant = self.getTenantRef(tenant)
            tenant.removeSaleItem(name, type: "find")
        }

        access(Owner) fun setFindCut(tenant: Address, saleItem: FindMarket.TenantSaleItem) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }
            let tenant = self.getTenantRef(tenant)
            tenant.addSaleItem(saleItem, type: "cut")
        }

        access(Owner) fun setExtraCut(tenant: Address, types: [Type], category: String, cuts: FindMarketCutStruct.Cuts) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }
            let tenant = self.getTenantRef(tenant)
            tenant.setExtraCut(types: types, category: category, cuts: cuts)
        }

        access(Owner) fun setMarketOption(tenant: Address, saleItem: FindMarket.TenantSaleItem) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }
            let tenant = self.getTenantRef(tenant)
            tenant.addSaleItem(saleItem, type: "tenant")
            //Emit Event here
        }

        access(Owner) fun removeMarketOption(tenant: Address, name: String) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }
            let tenant = self.getTenantRef(tenant)
            tenant.removeSaleItem(name, type: "tenant")
        }

        access(Owner) fun enableMarketOption(tenant: Address, name: String) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }
            let tenant = self.getTenantRef(tenant)
            tenant.alterMarketOption(name: name, status: "active")
        }

        access(Owner) fun deprecateMarketOption(tenant: Address, name: String) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }
            let tenant = self.getTenantRef(tenant)
            tenant.alterMarketOption(name: name, status: "deprecated")
        }

        access(Owner) fun stopMarketOption(tenant: Address, name: String) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }
            let tenant = self.getTenantRef(tenant)
            tenant.alterMarketOption(name: name, status: "stopped")
        }

        access(Owner) fun setupSwitchboardCut(tenant: Address) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }
            let tenant = self.getTenantRef(tenant)
            tenant.setupSwitchboardCut()
        }

        /// ===================================================================================
        // Royalty Residual
        /// ===================================================================================

        access(Owner) fun setResidualAddress(_ address: Address) {
            pre {
                self.capability != nil: "Cannot create FIND, capability is not set"
            }
            FindMarket.setResidualAddress(address)
        }

        access(all) fun getSwitchboardReceiverPublic() : Capability<&{FungibleToken.Receiver}> {
            // we hard code it here instead, to avoid importing just for path
            return FindMarketAdmin.account.capabilities.get<&{FungibleToken.Receiver}>(/public/GenericFTReceiver)!
        }

        init() {
            self.capability = nil
        }

    }


    init() {

        self.AdminProxyPublicPath= /public/findMarketAdminProxy
        self.AdminProxyStoragePath=/storage/findMarketAdminProxy

    }

}

