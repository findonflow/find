import {config} from "@onflow/fcl"
import { vars } from 'find-flow-contracts'

 const fclConfig = config()
 const contractVariables = vars[process.env.REACT_APP_NETWORK]
  Object.keys(contractVariables).forEach((contractAddressKey) => {
    fclConfig.put(contractAddressKey, contractVariables[contractAddressKey])
  })

fclConfig
	.put("accessNode.api", process.env.REACT_APP_ACCESS_NODE) // Configure FCL's Access Node
  .put("challenge.handshake", process.env.REACT_APP_WALLET_DISCOVERY) // Configure FCL's Wallet Discovery mechanism
  .put("env", process.env.REACT_APP_NETWORK)
  .put("decoder.Enum", (val) => {
      const result = {
        type: val.id
      };

      for (let i = 0; i < val.fields.length; i++) {
        const field = val.fields[i];
        result[field.name] = field.value;
      }

      return result;
    });

/*
fclConfig
  .put("accessNode.api", process.env.ACCESS_NODE) // Configure FCL's Access Node
  .put("challenge.handshake", process.env.WALLET_DISCOVERY) // Configure FCL's Wallet Discovery mechanism
  .put("discovery.wallet","http://localhost:3000/fcl/authn")
	*/
 
