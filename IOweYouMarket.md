# IOweYou 

## Create and Redeem 

### Create
Escrowed :  
    Withdraw from user FT vault, pass in to IOU Collection and create IOU 

    User vault -> withdraw amount needed for IOU -> create IOU in user IOU Collection -> IOU

Dapper : 
    Withdraw from dapper FT vault on behalf of Dapper wallet user, pass in to IOU Collection and create IOU 

    Dapper vault -> withdraw amount needed for IOU  -> create IOU in user IOU Collection (Dapper Coin goes back to Dapper Vault through Find Merch Account) -> IOU

### Top Up (Add value to IOU)
Escrowed :  
    Withdraw from user FT vault, pass in to IOU

    User vault -> withdraw amount needed for top up -> IOU

Dapper : 
    Withdraw from dapper FT vault on behalf of Dapper wallet user, pass in to IOU Collection and create IOU 

    Dapper vault -> withdraw amount needed for IOU -> IOU (Dapper Coin goes back to Dapper Vault through Find Merch Account) 

### Redeem 
Escrowed :  
    Pass in the IOU, pass in nil for vault and redeem in IOU collection

    IOU -> redeem IOU in user IOU Collection -> User vault

Dapper : 
    Withdraw from dapper FT vault on behalf of Find, Pass in the IOU and the dapper FT vault, redeem in IOU collection

    Dapper vault -> withdraw amount needed to redeem IOU (in name of Find Merch Account) -> redeem IOU in user IOU Collection -> Dapper vault (in name of user Account)



# I Owe You Market 

## Market Actions 

### List For Auction 
Escrowed :  
    Specify listing price and token type. Create listings accordingly. 
    Dapper Coin Types are blocked. for this market type. 

Dapper : 
    Ditto. Except that only Dapper Coin types are allowed for this market type. 

### Bid / increase Bid For Auction 
Escrowed :  
    User withdraw token from user vault, create / topUp to IOU for auction bids

Dapper :  
    User and Dapper co-sign the transaction. 
    User withdraw from Dapper wallet and pass the vault in to create / top up the IOU for bidding

### Fulfill Finished Auctions 
Escrowed : 
    Pass in nil for vault to fulfill auction. IOU will be redeemed by Find and distribute the funds to seller and royalty holders 

Dapper : 
    User and Dapper co-sign the transaction. 
    Withdraw required amounts from Dapper wallet on behalf of Find. Pass in the vault to fulfill auction. IOU will be redeemed by Find and distribute the funds to seller and royalty holders 

### Cancel Auctions
Escrowed : 
    IOU will be sent back to users' IOU Collection. 
    If the user's receiver capability is valid, the IOU will be redeemed automatically for the buyer. 

Dapper : 
    IOU will be sent back to users' IOU Collection. 
    User has to sign their own transactions to redeem Dapper IOU. 