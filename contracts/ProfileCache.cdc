import Clock from "../contracts/Clock.cdc"

pub contract ProfileCache {

	// If there is no findName, the string is set to "". 
	access(contract) let addressLeaseName : {Address : LeaseCache}
	access(contract) let nameAddress : {String : LeaseCache}

	access(contract) let profileWalletIndex : {Address : {Type : Int}}

	// Find Leases
	pub struct LeaseCache {
		pub let address : Address?
		pub let leaseName : String 
		pub let validUntil : UFix64 

		init(leaseName: String, validUntil: UFix64, address: Address?) {
			self.leaseName=leaseName 
			self.validUntil=validUntil
			self.address=address
		}
	}

	access(account) fun setAddressLeaseNameCache(address: Address, leaseName: String?, validUntil: UFix64) {
		if self.addressLeaseName[address] == nil {
			self.addressLeaseName[address] = LeaseCache(leaseName: leaseName ?? "", validUntil: validUntil, address: address)
		} 
		panic("There is already a cache for this address. Address : ".concat(address.toString()))
 	}

	pub fun getAddressLeaseName(_ address: Address) : String? {
		if self.addressLeaseName[address] == nil {
			return nil
		}
		if self.addressLeaseName[address]!.validUntil >= Clock.time() {
			return self.addressLeaseName[address]!.leaseName
		}
		return nil
	}

	access(account) fun setNameAddressCache(address: Address?, leaseName: String, validUntil: UFix64) {
		if self.nameAddress[leaseName] == nil {
			self.nameAddress[leaseName] = LeaseCache(leaseName: leaseName, validUntil: validUntil, address: address)
		} 
		panic("There is already a cache for this name. Name : ".concat(leaseName))
 	}

	pub fun getNameAddress(_ name: String) : LeaseCache? {
		if self.nameAddress[name]!.validUntil >= Clock.time() {
			return self.nameAddress[name]
		}
		return nil
	}

	access(account) fun resetLeaseCache(address: Address, leaseName: String) {
		self.addressLeaseName.remove(key: address)
		self.nameAddress.remove(key: leaseName)
	}



	access(account) fun setWalletIndexCache(address: Address, walletType: Type, index: Int) {
		if self.profileWalletIndex[address] == nil {
			self.profileWalletIndex[address] = {}
			self.profileWalletIndex[address]!.insert(key: walletType, index)
		} else if self.profileWalletIndex[address]![walletType] == nil{
			self.profileWalletIndex[address]!.insert(key: walletType, index)
		}
		panic("There is already a cache for this wallet. User : ".concat(address.toString()).concat(". Wallet : ").concat(walletType.identifier))
 	}

	pub fun getWalletIndex(address: Address, walletType: Type) : Int? {
		if self.profileWalletIndex[address] == nil {
			return nil
		}
		return self.profileWalletIndex[address]![walletType]
	}

	access(account) fun resetWalletIndexCache(address: Address) {
		self.profileWalletIndex.remove(key: address)
	}

	init() {
		self.addressLeaseName = {}
		self.nameAddress = {}

		self.profileWalletIndex = {}
	}

}
