//This contract is temporary until dapper finishes their initiative
access(all) contract NFTRegistry {

	/* Event */
	pub event ContractInitialized()
	pub event NFTInfoRegistered(alias: String, typeIdentifier: String)
	pub event NFTInfoRemoved(alias: String, typeIdentifier: String)

	/* Variables */
	// Mapping of {Type Identifier : NFT Info Struct}
	access(contract) var nonFungibleTokenList : {String : NFTInfo}

	// Mapping of {Alias : Type Identifier}
	access(contract) var aliasMap : {String : String}

	//TODO: name of init transactions
	//TODO: name of check storage slot script
	/* Struct */
	access(all) struct NFTInfo {
		access(all) let alias : String
		// Pass in @NFT type
		access(all) let type : Type              
		access(all) let typeIdentifier : String
		access(all) let icon : String?
		access(all) let providerPath : PrivatePath
		access(all) let providerPathIdentifier : String
		// Must implement {ViewResolver.ResolverCollection}
		access(all) let publicPath : PublicPath
		access(all) let publicPathIdentifier : String
		access(all) let storagePath : StoragePath
		access(all) let storagePathIdentifier : String
		// Pass in arrays of allowed Token Vault, nil => support  all types of FTs
		access(all) let allowedFTTypes : [Type]?  
		// Pass in the Contract Address
		access(all) let address : Address
		access(all) let externalFixedUrl : String

		init(alias: String, type: Type, typeIdentifier: String, icon: String?, providerPath: PrivatePath, publicPath: PublicPath, storagePath: StoragePath, allowedFTTypes: [Type]?, address: Address, externalFixedUrl: String) {
			self.alias = alias
			self.type = type
			self.typeIdentifier = typeIdentifier
			self.icon = icon
			self.providerPath = providerPath
			self.providerPathIdentifier = providerPath.toString().slice(from: "/private/".length, upTo: providerPath.toString().length)
			self.publicPath = publicPath
			self.publicPathIdentifier = publicPath.toString().slice(from: "/public/".length, upTo: publicPath.toString().length)
			self.storagePath = storagePath
			self.storagePathIdentifier = storagePath.toString().slice(from: "/storage/".length, upTo: storagePath.toString().length)
			self.allowedFTTypes = allowedFTTypes
			self.address = address
			self.externalFixedUrl = externalFixedUrl
		}
	} 

	/* getters */
	access(all) getNFTInfoByTypeIdentifier(_ typeIdentifier: String) : NFTInfo? {
		return NFTRegistry.nonFungibleTokenList[typeIdentifier]
	}

	access(all) getNFTInfoByAlias(_ alias: String) : NFTInfo? {
		if let identifier = NFTRegistry.aliasMap[alias] {
			return NFTRegistry.nonFungibleTokenList[identifier]
		}
		return nil
	}

	access(all) getNFTInfo(_ input: String) : NFTInfo? {
		if let info = self.getNFTInfoByAlias(input) {
			return info
		}
		if let info = self.getNFTInfoByTypeIdentifier(input) {
			return info
		}
		return nil
	}

	access(all) getTypeIdentifier(_ alias: String) : String? {
		return NFTRegistry.aliasMap[alias]
	}

	access(all) getNFTInfoAll() : {String : NFTInfo} {
		return NFTRegistry.nonFungibleTokenList
	}

	access(all) getSupportedNFTAlias() : [String] {
		return NFTRegistry.aliasMap.keys
	}

	access(all) getSupportedNFTTypeIdentifier() : [String] {
		return NFTRegistry.aliasMap.values
	}

	/* setters */
	access(account) fun setNFTInfo(alias: String, type: Type, icon: String?, providerPath: PrivatePath, publicPath: PublicPath, storagePath: StoragePath, allowedFTTypes: [Type]?, address: Address, externalFixedUrl: String ) {
        if NFTRegistry.nonFungibleTokenList.containsKey(type.identifier) {
            panic("This NonFungibleToken Register already exist")
        }
		let typeIdentifier : String = type.identifier
		NFTRegistry.nonFungibleTokenList[typeIdentifier] = NFTInfo(alias: alias,
		type: type,
		typeIdentifier: typeIdentifier,
		icon: icon,
		providerPath: providerPath,
		publicPath: publicPath,
		storagePath: storagePath,
		allowedFTTypes: allowedFTTypes,
		address: address,
		externalFixedUrl: externalFixedUrl)

		NFTRegistry.aliasMap[alias] = typeIdentifier
		emit NFTInfoRegistered(alias: alias, typeIdentifier: typeIdentifier)
	}

	access(account) fun removeNFTInfoByTypeIdentifier(_ typeIdentifier: String) : NFTInfo {
		let info = NFTRegistry.nonFungibleTokenList.remove(key: typeIdentifier) ?? panic("Cannot find this NonFungibleToken Registry. Type : ".concat(typeIdentifier))
		NFTRegistry.aliasMap.remove(key: info.alias)
		emit NFTInfoRemoved(alias:info!.alias, typeIdentifier: info!.typeIdentifier)
		return info 
	}

	access(account) fun removeNFTInfoByAlias(_ alias: String) : NFTInfo {
		let typeIdentifier = self.getTypeIdentifier(alias) ?? panic("Cannot find type identifier from this alias. Alias : ".concat(alias))
		return self.removeNFTInfoByTypeIdentifier(typeIdentifier)
	}

	init() {
		self.nonFungibleTokenList = {}
		self.aliasMap = {}
	}


}


