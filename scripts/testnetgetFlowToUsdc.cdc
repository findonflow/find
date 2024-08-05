import SwapRouter from "../contracts/community/SwapRouter.cdc"

pub fun main(usdcAmount: UFix64) : UFix64 {


    let path = [ "A.7e60df042a9c0868.FlowToken", "A.a983fecbed621163.FiatToken" ]
    return   SwapRouter.getAmountsIn(amountOut: usdcAmount, tokenKeyPath:path)[0]
}
