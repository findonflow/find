import "../contracts/FIN.cdc"


//link together the administrator to the client, signed by the owner of the contract
transaction(ownerAddress: Address) {

    //versus account
    prepare(account: AuthAccount) {

        let owner= getAccount(ownerAddress)
        let client= owner.getCapability<&{FIN.AdminProxyClient}>(FIN.AdminProxyPublicPath)
                .borrow() ?? panic("Could not borrow admin client")

        let admin=account.getCapability<&FIN.Administrator>(FIN.AdministratorPrivatePath)
        client.addCapability(admin)

    }
}
 
