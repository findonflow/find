import FIND from "../contracts/FIND.cdc"

pub fun main(name:String) : Address?{

	return FIND.resolve(name)

}
