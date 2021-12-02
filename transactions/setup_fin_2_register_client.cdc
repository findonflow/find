import "../contracts/Admin.cdc"

//link together the administrator to the client, signed by the owner of the contract
transaction(ownerAddress: Address) {

    //versus account
    prepare(account: AuthAccount) {

        let owner= getAccount(ownerAddress)
        let client= owner.getCapability<&{Admin.AdminProxyClient}>(Admin.AdminProxyPublicPath)
                .borrow() ?? panic("Could not borrow admin client")

        let network=account.getCapability<&FIND.Network>(FIND.NetworkPrivatePath)
        client.addCapability(network)

    }
}
 
