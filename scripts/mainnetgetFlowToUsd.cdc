import SwapRouter from "../contracts/community/SwapRouter.cdc"

pub fun main(usdcAmount: UFix64) : UFix64 {


    let path = [ "A.1654653399040a61.FlowToken", "A.b19436aae4d94622.FiatToken" ]
    return   SwapRouter.getAmountsIn(amountOut: usdcAmount, tokenKeyPath:path)[0]
}
