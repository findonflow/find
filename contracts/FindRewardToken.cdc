import FungibleToken from "../contracts/standard/FungibleToken.cdc"

pub contract FindRewardToken {

    // Map tenantToken to custom task rewards 
    access(contract) let defaultTaskRewards:  {String : UFix64}
    access(contract) let tenantTokenCapabilities: {Address : Capability<&{FungibleToken.Provider}>}

    access(account) fun addTenantRewardToken(tenant: Address, cap: Capability<&{FungibleToken.Provider}>) {
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

    access(account) fun getRewardVault(_ tenant: Address) : Capability<&{FungibleToken.Provider}>? {
        return FindRewardToken.tenantTokenCapabilities[tenant]
    }

    access(account) fun getRewardVaults() : [Capability<&{FungibleToken.Provider}>] {
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