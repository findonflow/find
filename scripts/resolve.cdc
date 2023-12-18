import FIND from "../contracts/FIND.cdc"

access(all) main(name:String) : Address?{

	return FIND.resolve(name)

}
