import FIND from "../contracts/FIND.cdc"

access(all) fun main(name:String) : Address?{

    return FIND.resolve(name)

}
