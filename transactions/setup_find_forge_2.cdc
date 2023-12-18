import FindForge from "../contracts/FindForge.cdc"
import FIND from "../contracts/FIND.cdc"

//link together the administrator to the client, signed by the owner of the contract
transaction(ownerAddress: Address) {

    //versus account
    prepare(account: auth(BorrowValue) &Account) {

        let owner= getAccount(ownerAddress)
        let client= owner.getCapability<&{FindForge.ForgeAdminProxyClient}>(/public/findForgeAdminProxy)
                .borrow() ?? panic("Could not borrow admin client")

        let network=account.getCapability<&FIND.Network>(FIND.NetworkPrivatePath)
        client.addCapability(network)

    }
}
 
