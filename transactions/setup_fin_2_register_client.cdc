import "../contracts/FIND.cdc"


//link together the administrator to the client, signed by the owner of the contract
transaction(ownerAddress: Address) {

    //versus account
    prepare(account: AuthAccount) {

        let owner= getAccount(ownerAddress)
        let client= owner.getCapability<&{FIND.AdminProxyClient}>(FIND.AdminProxyPublicPath)
                .borrow() ?? panic("Could not borrow admin client")

        let admin=account.getCapability<&FIND.Administrator>(FIND.AdministratorPrivatePath)
        client.addCapability(admin)

    }
}
 
