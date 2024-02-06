import "SwapRouter"
import "FiatToken"
import "FlowToken"

access(all) fun main(usdcAmount: UFix64) : UFix64 {
    let path = [ Type<FiatToken>().identifier, Type<FlowToken>().identifier ]
    return   SwapRouter.getAmountsIn(amountOut: usdcAmount, tokenKeyPath:path)[0]
}

