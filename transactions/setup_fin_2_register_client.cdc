import "Admin"
//import "FindMarketAdmin"
import "FIND"

//link together the administrator to the client, signed by the owner of the contract
transaction(ownerAddress: Address) {

    //versus account
    prepare(account: auth(BorrowValue, IssueStorageCapabilityController, GetStorageCapabilityController) &Account) {

        let owner= getAccount(ownerAddress)

        let client= owner.capabilities.borrow<&{Admin.AdminProxyClient}>(Admin.AdminProxyPublicPath) ?? panic("Could not borrow admin client")
        //let findMarketClient= owner.capabilities.borrow<&{FindMarketAdmin.AdminProxyClient}>(FindMarketAdmin.AdminProxyPublicPath) ?? panic("Could not borrow admin client")

        let storage= account.capabilities.storage
        //we issue a capability from our storage
        let capability = storage.issue<&FIND.Network>(FIND.NetworkStoragePath)

        //we set the name as tag so it is easy for us to revoke it later using a friendly name
        let capcon = storage.getController(byCapabilityID:capability.id)!
        capcon.setTag("findAdmin")

        client.addCapability(capability)
        //       findMarketClient.addCapability(capability)

    }
}

