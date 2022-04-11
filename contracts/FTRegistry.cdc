import FungibleToken from "./standard/FungibleToken.cdc"

pub contract FTRegistry {

    /* Event */
    pub event ContractInitialized()
    pub event FTInfoRegistered(alias: String, typeIdentifier: String)
    pub event FTInfoRemoved(alias: String, typeIdentifier: String)

    /* Paths */
    pub let FTRegistryStoragePath : StoragePath

    /* Variables */
    // Mapping of {Type Identifier : FT Info Struct}
    access(contract) var fungibleTokenList : {String : FTInfo}

    access(contract) var aliasMap : {String : String}

    /* Struct */
    pub struct FTInfo {
        pub(set) var alias : String
        pub(set) var typeIdentifier : String
        pub(set) var icon : String?
        pub(set) var receiverPath : PublicPath
        pub(set) var balancePath : PublicPath
        pub(set) var vaultPath : StoragePath

        init(alias : String, typeIdentifier: String, icon: String?, receiverPath: PublicPath, balancePath: PublicPath, vaultPath: StoragePath) {
            self.alias = alias
            self.typeIdentifier = typeIdentifier
            self.icon = icon
            self.receiverPath = receiverPath
            self.balancePath = balancePath
            self.vaultPath = vaultPath
        }

        /* 
        pub fun getVaultType() : Type? {
            return CompositeType(self.typeIdentifier)
        }

        pub fun getVaultReceiverType() : Type? {
            let restrictions = ["A.ee82856bf20e2aa6.FungibleToken.Receiver"]
            return RestrictedType(identifier: self.typeIdentifier, restrictions: restrictions)
        }

        pub fun getVaultBalanceType() : Type? {
            let restrictions = ["A.ee82856bf20e2aa6.FungibleToken.Balance"]
            return RestrictedType(identifier: self.typeIdentifier, restrictions: restrictions)
        }
        */
    } 

    /* getters */
    pub fun getFTInfo(typeIdentifier: String) : FTInfo? {
        return FTRegistry.fungibleTokenList[typeIdentifier]
    }

    pub fun getTypeIdentifier(alias: String) : String? {
        return FTRegistry.aliasMap[alias]
    }

    pub fun getFTInfoAll() : {String : FTInfo} {
        return FTRegistry.fungibleTokenList
    }

    pub resource Admin{

        /* setters */
        pub fun setFTInfo(alias: String, type: Type, icon: String?, receiverPath: PublicPath, balancePath: PublicPath, vaultPath: StoragePath) {
            pre{
                !FTRegistry.fungibleTokenList.containsKey(type.identifier) : "This FungibleToken Register already exist"
            }
            let typeIdentifier : String = type.identifier
            FTRegistry.fungibleTokenList[typeIdentifier] = FTInfo(alias: alias,
                                                                  typeIdentifier: typeIdentifier,
                                                                  icon: icon,
                                                                  receiverPath: receiverPath,
                                                                  balancePath: balancePath,
                                                                  vaultPath: vaultPath)
            
            FTRegistry.aliasMap[alias] = typeIdentifier

            emit FTInfoRegistered(alias: alias, typeIdentifier: typeIdentifier)

        }

        pub fun removeFTInfo(typeIdentifier: String) : FTInfo? {

            let info = FTRegistry.fungibleTokenList.remove(key: typeIdentifier) ?? panic("Cannot find this Fungible Token Registry.")

            FTRegistry.aliasMap.remove(key: info.alias)

            emit FTInfoRemoved(alias:info!.alias, typeIdentifier: info!.typeIdentifier)

            return info 
        }

        init() {

        }

    }

    init() {
        self.FTRegistryStoragePath = /storage/FTRegistry

        self.fungibleTokenList = {}
        self.aliasMap = {}

        self.account.save(<- create Admin(), to: FTRegistry.FTRegistryStoragePath)
    }


}