
import FIND from "../contracts/FIND.cdc"

pub fun main(input:String) : Address?{
	return FIND.resolve(input)
}
