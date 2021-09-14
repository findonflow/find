import {config} from "@onflow/fcl"
import { vars } from 'find-flow-contracts'

 const fclConfig = config()
 const contractVariables = vars["emulator"]
  Object.keys(contractVariables).forEach((contractAddressKey) => {
    fclConfig.put(contractAddressKey, contractVariables[contractAddressKey])
  })

fclConfig
  .put("accessNode.api", process.env.ACCESS_NODE) // Configure FCL's Access Node
  .put("challenge.handshake", process.env.WALLET_DISCOVERY) // Configure FCL's Wallet Discovery mechanism
  .put("discovery.wallet","http://localhost:3000/fcl/authn")
 
