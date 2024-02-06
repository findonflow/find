
import "Admin"
import "FindMarketAdmin"
import "FUSD"
import "FungibleToken"

//set up the adminClient in the contract that will own the network
transaction() {

    prepare(account: auth(SaveValue, IssueStorageCapabilityController,PublishCapability) &Account) {

        let fusd <- FUSD.createEmptyVault()
        account.storage.save(<- fusd, to: /storage/fusdVault)
        let cap = account.capabilities.storage.issue<&{FungibleToken.Receiver}>(/storage/fusdVault)
        account.capabilities.publish(cap, at: /public/fusdReceiver)

        let capb = account.capabilities.storage.issue<&{FungibleToken.Vault}>(/storage/fusdVault)
        account.capabilities.publish(capb, at: /public/fusdBalance)


        let caps = account.capabilities
        let storage = account.storage

        //Dont know why this does not work
        /*
        if caps.exists(Admin.AdminProxyPublicPath) {
            caps.unpublish(Admin.AdminProxyPublicPath)
            destroy <- storage.load<@AnyResource>(from: Admin.AdminProxyStoragePath)    
        }
        */
        storage.save(<- Admin.createAdminProxyClient(), to:Admin.AdminProxyStoragePath)
        let proxyCap =caps.storage.issue<&{Admin.AdminProxyClient}>(Admin.AdminProxyStoragePath)
        caps.publish(proxyCap, at: Admin.AdminProxyPublicPath)

        /*
        if caps.exists(FindMarketAdmin.AdminProxyPublicPath) {
            caps.unpublish(FindMarketAdmin.AdminProxyPublicPath)
            destroy <- storage.load<@AnyResource>(from:FindMarketAdmin.AdminProxyStoragePath)
        }
        */
        storage.save(<- FindMarketAdmin.createAdminProxyClient(), to:FindMarketAdmin.AdminProxyStoragePath)
        let marketProxyCap =caps.storage.issue<&{FindMarketAdmin.AdminProxyClient}>(FindMarketAdmin.AdminProxyStoragePath)
        caps.publish(marketProxyCap, at: FindMarketAdmin.AdminProxyPublicPath)


    }
}
