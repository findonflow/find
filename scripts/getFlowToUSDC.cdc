import SwapRouter from "../contracts/community/SwapRouter.cdc"
import FiatToken from "../contracts/standard/FiatToken.cdc"
import FlowToken from "../contracts/standard/FlowToken.cdc"

access(all) fun main(usdcAmount: UFix64) : UFix64 {
    let path = [ Type<FiatToken>().identifier, Type<FlowToken>().identifier ]
    return   SwapRouter.getAmountsIn(amountOut: usdcAmount, tokenKeyPath:path)[0]
}

