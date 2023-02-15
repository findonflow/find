import FungibleToken from "./standard/FungibleToken.cdc"
import MetadataViews from "./standard/MetadataViews.cdc"
import FIND from "./FIND.cdc"
import FindMarket from "./FindMarket.cdc"

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

		pub fun createFindMarket(name: String, address:Address, defaultCutRules: [FindMarket.TenantRule], findCut: UFix64?) : Capability<&FindMarket.Tenant> {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			var findRoyalty:MetadataViews.Royalty?=nil
			if let cut = findCut{
				let receiver=FindMarketAdmin.account.getCapability<&{FungibleToken.Receiver}>(/public/findProfileReceiver)
				findRoyalty=MetadataViews.Royalty(receiver: receiver, cut: cut,  description: "find")
			}

			return  FindMarket.createFindMarket(name:name, address:address, defaultCutRules: defaultCutRules, findRoyalty:findRoyalty)
		}

		pub fun removeFindMarketTenant(tenant: Address) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			FindMarket.removeFindMarketTenant(tenant: tenant)
		}

		pub fun createFindMarketDapper(name: String, address:Address, defaultCutRules: [FindMarket.TenantRule], findRoyalty: MetadataViews.Royalty) : Capability<&FindMarket.Tenant> {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			return  FindMarket.createFindMarket(name:name, address:address, defaultCutRules: defaultCutRules, findRoyalty:findRoyalty)
		}

		pub fun getFindMarketClient():  &FindMarket.TenantClient{
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

      		let path = FindMarket.TenantClientStoragePath
      		return FindMarketAdmin.account.borrow<&FindMarket.TenantClient>(from: path) ?? panic("Cannot borrow Find market tenant client Reference.")
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

		pub fun setFindCut(tenant: Address, saleItemName: String, cut: UFix64?, rules: [FindMarket.TenantRule]?, status: String) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			let tenant = self.getTenantRef(tenant)
			let oldCut = tenant.removeSaleItem(saleItemName, type: "cut")

			var newCut = oldCut.cut!
			if cut != nil {
				newCut = MetadataViews.Royalty(receiver: oldCut.cut!.receiver, cut: cut!, description: oldCut.cut!.description)
			}

			var newRules = oldCut.rules
			if rules != nil {
				newRules = rules!
			}

			let newSaleItem = FindMarket.TenantSaleItem(
				name: oldCut.name,
				cut: newCut ,
				rules: newRules,
				status: status
			)
			tenant.addSaleItem(newSaleItem, type: "cut")
		}

		pub fun addFindCut(tenant: Address, FindCutName: String, rayalty: MetadataViews.Royalty, rules: [FindMarket.TenantRule], status: String) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			if !(rules.length > 0) {
				panic("Rules cannot be empty array")
			}
			let tenant = self.getTenantRef(tenant)

			if tenant.checkFindCuts(FindCutName) {
				panic("This find cut already exist. FindCut rule Name : ".concat(FindCutName))
			}

			let newSaleItem = FindMarket.TenantSaleItem(
				name: FindCutName,
				cut: rayalty ,
				rules: rules,
				status: status
			)
			tenant.addSaleItem(newSaleItem, type: "cut")
		}

		pub fun setMarketOption(tenant: Address, saleItem: FindMarket.TenantSaleItem) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			let tenant = self.getTenantRef(tenant)
			tenant.addSaleItem(saleItem, type: "tenant")
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

		pub fun setTenantRule(tenant: Address, optionName: String, tenantRule: FindMarket.TenantRule) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			let tenantRef = self.getTenantRef(tenant)
			tenantRef.setTenantRule(optionName: optionName, tenantRule: tenantRule)
		}

		pub fun removeTenantRule(tenant: Address, optionName: String, tenantRuleName: String) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			let tenantRef = self.getTenantRef(tenant)
			tenantRef.removeTenantRule(optionName: optionName, tenantRuleName: tenantRuleName)
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

		init() {
			self.capability = nil
		}

	}


	init() {

		self.AdminProxyPublicPath= /public/findMarketAdminProxy
		self.AdminProxyStoragePath=/storage/findMarketAdminProxy

	}

}

