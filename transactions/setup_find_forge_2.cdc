import FindForge from "../contracts/FindForge.cdc"
import FIND from "../contracts/FIND.cdc"

//link together the administrator to the client, signed by the owner of the contract
transaction(ownerAddress: Address) {

    //versus account
    prepare(account: auth(BorrowValue, IssueStorageCapabilityController) &Account) {

        let owner= getAccount(ownerAddress)
        let client= owner.capabilities.borrow<&{FindForge.ForgeAdminProxyClient}>(/public/findForgeAdminProxy) ?? panic("Could not borrow admin client")

        let network = account.capabilities.storage.issue<&FIND.Network>(FIND.NetworkStoragePath)
        client.addCapability(network)

    }
}

