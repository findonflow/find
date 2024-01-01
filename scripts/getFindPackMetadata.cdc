import FindPack from "../contracts/FindPack.cdc"
import FTRegistry from "../contracts/FTRegistry.cdc"
import FlowStorageFees from "../contracts/standard/FlowStorageFees.cdc"
import MetadataViews from "../contracts/standard/MetadataViews.cdc"
import FIND from "../contracts/FIND.cdc"

access(all) fun main(packTypeName: String, packTypeId: UInt64) : AnyStruct? {
    return FindPack.getMetadataById(packTypeName: packTypeName, typeId: packTypeId) 
}

