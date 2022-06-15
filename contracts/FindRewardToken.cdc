import FungibleToken from "../contracts/standard/FungibleToken.cdc"

pub contract FindRewardToken {

    // Map task to amount of reward
    access(contract) let tasks: [String]

    // Map tenantToken to custom task rewards 
    access(contract) let defaultTaskRewards: {Type : {String : UFix64}}

    pub resource interface FindReward {
        pub fun reward(name: String, receiver: &{FungibleToken.Receiver}, task: String) 
    } 

    init(){
        self.tasks = []
        self.defaultTaskRewards = {} 
    }

}