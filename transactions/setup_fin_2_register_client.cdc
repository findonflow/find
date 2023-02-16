import Admin from "../contracts/Admin.cdc"
import FindMarketAdmin from "../contracts/FindMarketAdmin.cdc"
import FIND from "../contracts/FIND.cdc"

//link together the administrator to the client, signed by the owner of the contract
transaction(ownerAddress: Address) {

    //versus account
    prepare(account: AuthAccount) {

        let owner= getAccount(ownerAddress)
        let client= owner.getCapability<&{Admin.AdminProxyClient}>(Admin.AdminProxyPublicPath)
                .borrow() ?? panic("Could not borrow admin client")

        let findMarketClient= owner.getCapability<&{FindMarketAdmin.AdminProxyClient}>(FindMarketAdmin.AdminProxyPublicPath)
                .borrow() ?? panic("Could not borrow find market admin client")

        let network=account.getCapability<&FIND.Network>(FIND.NetworkPrivatePath)
        client.addCapability(network)
        findMarketClient.addCapability(network)

    }
}

