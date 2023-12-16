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
	pub fun createAdminProxyClient() : @AdminProxy {
		return <- create AdminProxy()
	}

	//interface to use for capability receiver pattern
	pub resource interface AdminProxyClient {
		pub fun addCapability(_ cap: Capability<&FIND.Network>)
	}

	//admin proxy with capability receiver
	pub resource AdminProxy: AdminProxyClient {

		access(self) var capability: Capability<&FIND.Network>?

		pub fun addCapability(_ cap: Capability<&FIND.Network>) {
			pre {
				cap.check() : "Invalid server capablity"
				self.capability == nil : "Server already set"
			}
			self.capability = cap
		}

		pub fun createFindMarket(name: String, address:Address, findCutSaleItem: FindMarket.TenantSaleItem?) : Capability<&FindMarket.Tenant> {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			return  FindMarket.createFindMarket(name:name, address:address, findCutSaleItem: findCutSaleItem)
		}

		pub fun removeFindMarketTenant(tenant: Address) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			FindMarket.removeFindMarketTenant(tenant: tenant)
		}

		pub fun getFindMarketClient():  &FindMarket.TenantClient{
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

      		let path = FindMarket.TenantClientStoragePath
      		return FindMarketAdmin.account.storage.borrow<&FindMarket.TenantClient>(from: path) ?? panic("Cannot borrow Find market tenant client Reference.")
		}

		/// ===================================================================================
		// Find Market Options
		/// ===================================================================================
		pub fun addSaleItemType(_ type: Type) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			FindMarket.addSaleItemType(type)
		}

		pub fun addMarketBidType(_ type: Type) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			FindMarket.addMarketBidType(type)
		}

		pub fun addSaleItemCollectionType(_ type: Type) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			FindMarket.addSaleItemCollectionType(type)
		}

		pub fun addMarketBidCollectionType(_ type: Type) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			FindMarket.addMarketBidCollectionType(type)
		}

		pub fun removeSaleItemType(_ type: Type) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			FindMarket.removeSaleItemType(type)
		}

		pub fun removeMarketBidType(_ type: Type) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			FindMarket.removeMarketBidType(type)
		}

		pub fun removeSaleItemCollectionType(_ type: Type) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			FindMarket.removeSaleItemCollectionType(type)
		}

		pub fun removeMarketBidCollectionType(_ type: Type) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			FindMarket.removeMarketBidCollectionType(type)
		}

		/// ===================================================================================
		// Tenant Rules Management
		/// ===================================================================================
		pub fun getTenantRef(_ tenant: Address) : &FindMarket.Tenant {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			let string = FindMarket.getTenantPathForAddress(tenant)
			let pp = PrivatePath(identifier: string) ?? panic("Cannot generate storage path from string : ".concat(string))
			let cap = FindMarketAdmin.account.getCapability<&FindMarket.Tenant>(pp)
			return cap.borrow() ?? panic("Cannot borrow tenant reference from path. Path : ".concat(pp.toString()) )
		}

		pub fun addFindBlockItem(tenant: Address, item: FindMarket.TenantSaleItem) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			let tenant = self.getTenantRef(tenant)
			tenant.addSaleItem(item, type: "find")
		}

		pub fun removeFindBlockItem(tenant: Address, name: String) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			let tenant = self.getTenantRef(tenant)
			tenant.removeSaleItem(name, type: "find")
		}

		pub fun setFindCut(tenant: Address, saleItem: FindMarket.TenantSaleItem) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			let tenant = self.getTenantRef(tenant)
			tenant.addSaleItem(saleItem, type: "cut")
		}

		pub fun setExtraCut(tenant: Address, types: [Type], category: String, cuts: FindMarketCutStruct.Cuts) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			let tenant = self.getTenantRef(tenant)
			tenant.setExtraCut(types: types, category: category, cuts: cuts)
		}

		pub fun setMarketOption(tenant: Address, saleItem: FindMarket.TenantSaleItem) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			let tenant = self.getTenantRef(tenant)
			tenant.addSaleItem(saleItem, type: "tenant")
			//Emit Event here
		}

		pub fun removeMarketOption(tenant: Address, name: String) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			let tenant = self.getTenantRef(tenant)
			tenant.removeSaleItem(name, type: "tenant")
		}

		pub fun enableMarketOption(tenant: Address, name: String) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			let tenant = self.getTenantRef(tenant)
			tenant.alterMarketOption(name: name, status: "active")
		}

		pub fun deprecateMarketOption(tenant: Address, name: String) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			let tenant = self.getTenantRef(tenant)
			tenant.alterMarketOption(name: name, status: "deprecated")
		}

		pub fun stopMarketOption(tenant: Address, name: String) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			let tenant = self.getTenantRef(tenant)
			tenant.alterMarketOption(name: name, status: "stopped")
		}

		pub fun setupSwitchboardCut(tenant: Address) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			let tenant = self.getTenantRef(tenant)
			tenant.setupSwitchboardCut()
		}

		/// ===================================================================================
		// Royalty Residual
		/// ===================================================================================

		pub fun setResidualAddress(_ address: Address) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			FindMarket.setResidualAddress(address)
		}

		pub fun getSwitchboardReceiverPublic() : Capability<&{FungibleToken.Receiver}> {
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

