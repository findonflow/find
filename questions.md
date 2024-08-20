310 |     access(all) fun getMarketBidCollectionCapabilities(tenantRef: &FindMarket.Tenant{FindMarket.TenantPublic}, address: Address) : [Capability<&{FindMarket.MarketBidCollectionPublic}>] {

how to make that one safe. I want a Tenant capability. So if somebody else implements the interface and link i do not want it.



## capabilities

getCapability -> capabilities.get : this will not return an OPTIONAL. the type cannot be a restricted type
a capability can no longer be "soft" linked. 

how to check if it is there?

if you only want to borrow you can do capabilities.borrow and you do not need to go to get first



## resource types for interfaces
@FungibleToken.Vault -> @{FungibleToken.Vault}


- getAuthAccount in script does not work, need types
- FT does not emit events yet
- account.storage.storagePaths return &[StoragePath] and not [StoragePath]
