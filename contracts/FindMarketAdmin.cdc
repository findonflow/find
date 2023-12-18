import FungibleToken from "./standard/FungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import FIND from "./FIND.cdc"
import FindMarket from "./FindMarket.cdc"
import FindMarketCutStruct from "./FindMarketCutStruct.cdc"

pub contract FindMarketAdmin {

	//store the proxy for the admin
	pub let AdminProxyPublicPath: PublicPath
	pub let AdminProxyStoragePath: StoragePath

	/// ===================================================================================
	// Admin things
	/// ===================================================================================

	//Admin client to use for capability receiver pattern
	access(all) createAdminProxyClient() : @AdminProxy {
		return <- create AdminProxy()
	}

	//interface to use for capability receiver pattern
	pub resource interface AdminProxyClient {
		access(all) addCapability(_ cap: Capability<&FIND.Network>)
	}

	//admin proxy with capability receiver
	pub resource AdminProxy: AdminProxyClient {

		access(self) var capability: Capability<&FIND.Network>?

		access(all) addCapability(_ cap: Capability<&FIND.Network>) {
			pre {
				cap.check() : "Invalid server capablity"
				self.capability == nil : "Server already set"
			}
			self.capability = cap
		}

		access(all) createFindMarket(name: String, address:Address, findCutSaleItem: FindMarket.TenantSaleItem?) : Capability<&FindMarket.Tenant> {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			return  FindMarket.createFindMarket(name:name, address:address, findCutSaleItem: findCutSaleItem)
		}

		access(all) removeFindMarketTenant(tenant: Address) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			FindMarket.removeFindMarketTenant(tenant: tenant)
		}

		access(all) getFindMarketClient():  &FindMarket.TenantClient{
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

      		let path = FindMarket.TenantClientStoragePath
      		return FindMarketAdmin.account.storage.borrow<&FindMarket.TenantClient>(from: path) ?? panic("Cannot borrow Find market tenant client Reference.")
		}

		/// ===================================================================================
		// Find Market Options
		/// ===================================================================================
		access(all) addSaleItemType(_ type: Type) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			FindMarket.addSaleItemType(type)
		}

		access(all) addMarketBidType(_ type: Type) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			FindMarket.addMarketBidType(type)
		}

		access(all) addSaleItemCollectionType(_ type: Type) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			FindMarket.addSaleItemCollectionType(type)
		}

		access(all) addMarketBidCollectionType(_ type: Type) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			FindMarket.addMarketBidCollectionType(type)
		}

		access(all) removeSaleItemType(_ type: Type) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			FindMarket.removeSaleItemType(type)
		}

		access(all) removeMarketBidType(_ type: Type) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			FindMarket.removeMarketBidType(type)
		}

		access(all) removeSaleItemCollectionType(_ type: Type) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			FindMarket.removeSaleItemCollectionType(type)
		}

		access(all) removeMarketBidCollectionType(_ type: Type) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			FindMarket.removeMarketBidCollectionType(type)
		}

		/// ===================================================================================
		// Tenant Rules Management
		/// ===================================================================================
		access(all) getTenantRef(_ tenant: Address) : &FindMarket.Tenant {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			let string = FindMarket.getTenantPathForAddress(tenant)
			let pp = PrivatePath(identifier: string) ?? panic("Cannot generate storage path from string : ".concat(string))
			let cap = FindMarketAdmin.account.getCapability<&FindMarket.Tenant>(pp)
			return cap.borrow() ?? panic("Cannot borrow tenant reference from path. Path : ".concat(pp.toString()) )
		}

		access(all) addFindBlockItem(tenant: Address, item: FindMarket.TenantSaleItem) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			let tenant = self.getTenantRef(tenant)
			tenant.addSaleItem(item, type: "find")
		}

		access(all) removeFindBlockItem(tenant: Address, name: String) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			let tenant = self.getTenantRef(tenant)
			tenant.removeSaleItem(name, type: "find")
		}

		access(all) setFindCut(tenant: Address, saleItem: FindMarket.TenantSaleItem) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			let tenant = self.getTenantRef(tenant)
			tenant.addSaleItem(saleItem, type: "cut")
		}

		access(all) setExtraCut(tenant: Address, types: [Type], category: String, cuts: FindMarketCutStruct.Cuts) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			let tenant = self.getTenantRef(tenant)
			tenant.setExtraCut(types: types, category: category, cuts: cuts)
		}

		access(all) setMarketOption(tenant: Address, saleItem: FindMarket.TenantSaleItem) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			let tenant = self.getTenantRef(tenant)
			tenant.addSaleItem(saleItem, type: "tenant")
			//Emit Event here
		}

		access(all) removeMarketOption(tenant: Address, name: String) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			let tenant = self.getTenantRef(tenant)
			tenant.removeSaleItem(name, type: "tenant")
		}

		access(all) enableMarketOption(tenant: Address, name: String) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			let tenant = self.getTenantRef(tenant)
			tenant.alterMarketOption(name: name, status: "active")
		}

		access(all) deprecateMarketOption(tenant: Address, name: String) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			let tenant = self.getTenantRef(tenant)
			tenant.alterMarketOption(name: name, status: "deprecated")
		}

		access(all) stopMarketOption(tenant: Address, name: String) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			let tenant = self.getTenantRef(tenant)
			tenant.alterMarketOption(name: name, status: "stopped")
		}

		access(all) setupSwitchboardCut(tenant: Address) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			let tenant = self.getTenantRef(tenant)
			tenant.setupSwitchboardCut()
		}

		/// ===================================================================================
		// Royalty Residual
		/// ===================================================================================

		access(all) setResidualAddress(_ address: Address) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			FindMarket.setResidualAddress(address)
		}

		access(all) getSwitchboardReceiverPublic() : Capability<&{FungibleToken.Receiver}> {
			// we hard code it here instead, to avoid importing just for path
			return FindMarketAdmin.account.getCapability<&{FungibleToken.Receiver}>(/public/GenericFTReceiver)
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

