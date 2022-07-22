import FungibleToken from "../contracts/standard/FungibleToken.cdc"

pub contract FindRewardToken {

    // Map tenantToken to custom task rewards 
    access(contract) let defaultTaskRewards:  {String : UFix64}
    access(contract) let tenantTokenCapabilities: {Address : Capability<&{FindReward , VaultViews, FungibleToken.Provider}>}

    pub resource interface VaultViews {

    }
	// Deprecated in testnet
    pub struct FTVaultData {
        pub let tokenAlias: String
        pub let storagePath: StoragePath
        pub let receiverPath: PublicPath
        pub let balancePath: PublicPath
        pub let providerPath: PrivatePath
        pub let findRewardPath: PrivatePath?
        pub let vaultType: Type
        pub let receiverType: Type
        pub let balanceType: Type
        pub let providerType: Type
        pub let findRewardType: Type?
        pub let createEmptyVault: ((): @FungibleToken.Vault)

        init(
            tokenAlias: String, 
            storagePath: StoragePath,
            receiverPath: PublicPath,
            balancePath: PublicPath,
            providerPath: PrivatePath,
            findRewardPath: PrivatePath?,
            vaultType: Type,
            receiverType: Type,
            balanceType: Type,
            providerType: Type,
            findRewardType: Type?,
            createEmptyVault: ((): @FungibleToken.Vault)
        ) {
            pre {
                receiverType.isSubtype(of: Type<&{FungibleToken.Receiver}>()): "Receiver type must include FungibleToken.Receiver interfaces."
                balanceType.isSubtype(of: Type<&{FungibleToken.Balance}>()): "Balance type must include FungibleToken.Balance interfaces."
                providerType.isSubtype(of: Type<&{FungibleToken.Provider}>()): "Provider type must include FungibleToken.Provider interface."
                findRewardType == nil || findRewardType!.isSubtype(of: Type<&{FindRewardToken.FindReward}>()): "FindReward type must include FindRewardToken.FindReward interface."
            }
            self.tokenAlias=tokenAlias
            self.storagePath=storagePath
            self.receiverPath=receiverPath
            self.balancePath=balancePath
            self.providerPath = providerPath
            self.findRewardPath = findRewardPath
            self.vaultType=vaultType
            self.receiverType=receiverType
            self.balanceType=balanceType
            self.providerType = providerType
            self.findRewardType = findRewardType
            self.createEmptyVault=createEmptyVault
        }
    }

    pub resource interface FindReward {

    } 

    access(account) fun addTenantRewardToken(tenant: Address, cap: Capability<&{FindReward, VaultViews, FungibleToken.Provider}>) {
        if self.tenantTokenCapabilities[tenant] != nil {
            panic("This tenant token has already registered.")
        }
        self.tenantTokenCapabilities[tenant] = cap
    }

    access(account) fun removeTenantRewardToken(tenant: Address) {
        if self.tenantTokenCapabilities[tenant] == nil {
            panic("This tenant token has not yet registered.")
        }
        self.tenantTokenCapabilities.remove(key: tenant)
    }

    access(account) fun getRewardVault(_ tenant: Address) : Capability<&{FindReward , VaultViews, FungibleToken.Provider}>? {
        return FindRewardToken.tenantTokenCapabilities[tenant]
    }

    access(account) fun getRewardVaults() : [Capability<&{FindReward , VaultViews , FungibleToken.Provider}>] {
        return FindRewardToken.tenantTokenCapabilities.values
    }

    pub fun getRewardVaultViews() : [Capability<&{VaultViews}>] {
        return FindRewardToken.tenantTokenCapabilities.values
    }

    pub fun getDefaultTaskRewards() : {String : UFix64} {
        return self.defaultTaskRewards
    }

    pub fun getTasks() : [String] {
        return self.defaultTaskRewards.keys
    }


    init(){
        self.defaultTaskRewards = {
            "findName_register" : 10.0, 
            "findName_fulfill_buyer" : 5.0,
            "findName_fulfill_seller" : 10.0,
            "findMarket_fulfill_buyer" : 5.0,
            "findMarket_fulfill_seller" : 10.0 
        } 
        self.tenantTokenCapabilities = {}
    }

}