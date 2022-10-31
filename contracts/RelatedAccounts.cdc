pub contract RelatedAccounts {

	pub let storagePath: StoragePath
	pub let publicPath: PublicPath

	// Deprecated
	pub event RelatedFlowAccountAdded()
	pub event RelatedFlowAccountRemoved()

	pub event RelatedAccountAdded(name: String, address: Address, related: String, network: String)
	pub event RelatedAccountRemoved(name: String, address: Address, related: String, network: String)

	pub struct AccountInformation{
		// unique alias for each wallet
		pub let name:String
		pub let address:Address?
		pub let network:String //do not use enum because of contract upgrade
		pub let otherAddress: String? //other networks besides flow may be not support Address

		init(name:String, address:Address?, network:String, otherAddress:String?){
			self.name=name
			self.address=address
			self.network=network
			self.otherAddress=otherAddress
		}
	}

	pub resource interface Public{
		pub fun getFlowAccounts() : {String: Address} 
		pub fun getRelatedAccounts(_ network: String) : {String : String} 
		pub fun getAllRelatedAccounts() : {String : {String : String}}
		pub fun verify(network: String, address: String) : Bool 
	}

	/// This is just an empty resource we create in storage, you can safely send a reference to it to obtain msg.sender
	pub resource Accounts: Public {

		access(self) let accounts: { String: AccountInformation}

		pub fun verify(network: String, address: String) : Bool {
			for account in self.accounts.keys {
				let item = self.accounts[account]!
				let addr = item.address?.toString() ?? item.otherAddress! 
				if item.network == network && addr == address {
					return true
				}
			}
			return false
		}

		pub fun getFlowAccounts() : {String: Address} {
			let items : {String: Address} ={}
			for account in self.accounts.keys {
				let item = self.accounts[account]!
				if item.network == "Flow" {
					items[item.name]=item.address!
				}
			}
			return items
		}

		pub fun getRelatedAccounts(_ network: String) : {String : String} {
			let items : {String: String} ={}
			for account in self.accounts.keys {
				let item = self.accounts[account]!
				if item.network == network {
					let address = item.address?.toString() ?? item.otherAddress!
					items[item.name]=address
				}
			}
			return items
		}

		pub fun getAllRelatedAccounts() : {String : {String : String}} {
			let items : {String: {String : String}} ={}
			for account in self.accounts.keys {
				let item = self.accounts[account]!
				if item.address != nil {
					let i = items[item.network] ?? {}
					i[item.name] = item.address!.toString()
					items[item.name] = i
					continue
				}
				let i = items[item.network] ?? {}
				i[item.name] = item.otherAddress!
				items[item.name] = i
			}
			return items
		}

		pub fun setFlowAccount(name: String, address:Address) {
			self.accounts[name] = AccountInformation(name: name, address:address, network: "Flow", otherAddress:nil)
			emit RelatedAccountAdded(name:name, address: self.owner!.address, related:address.toString(), network: "Flow")
		}

		pub fun setRelatedAccount(name: String, address: String, network: String) {
			self.accounts[name] = AccountInformation(name: name, address:nil, network: network, otherAddress:address)
			emit RelatedAccountAdded(name:name, address: self.owner!.address, related:address, network: network)
		}

		pub fun deleteAccount(name: String) {
			let item =self.accounts.remove(key: name)!
			emit RelatedAccountRemoved(name:name,address: self.owner!.address, related: item.address?.toString() ?? item.otherAddress!, network: "Flow")
		}

		init() {
			self.accounts={}
		}
	}

	pub fun createEmptyAccounts() : @Accounts{
		return <- create Accounts()
	}

	pub fun findRelatedFlowAccounts(address:Address) : { String: Address} {
		let cap = getAccount(address).getCapability<&Accounts{Public}>(self.publicPath)
		if !cap.check(){
			return {}
		}

		return cap.borrow()!.getFlowAccounts()
	}

	init() {

		self.storagePath = /storage/findAccounts
		self.publicPath = /public/findAccounts
	}

}


