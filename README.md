# FIN - Flow Identity Network

Flow does not have any equivalent to ENS or any way to lookup a user by a tag/alias/nick. 

Fin is here to solve that issue. 

In order to use FIN you create your Flow Identity and store that in your account. Then you can optionally register that with FIN for a small yearly fee. 

FIN is priced on a sliding scale from 0.1 for tags with 6+ characters to 0.6 for single character tags.

## Flow Identity
Right now an Identity in FIN is a single user. 

A user "is" an NFT that is you send in a NFT to represent you as your avatar. Note that currently the NFT standard is not rich enough to do this, so I have added a content field to the NFT interface in this contract as an example. 

An identity also has a wallet capability linked that you can send money into. 


## Plans

 - Add group identity, that is a set of FlowIdentities that collaborate on income. The Group will have a wallet set up with given fractions and when any user in the group wants to distribute money it is distributed according to that fraction. Using the flow-sharded-wallet
 - Add pool identity, a set of FlowIdentities that collaborate on funding something. The group will pool FT according to the given fractions and when everybody has pooled the flow will be moved to a central wallet that can then be transfered or used to stake a node
 - Add community identity, the combination of pool and group. Coolborate on both income and funding

 - Add support for sending friend requests and adding friends. Showing fiends. Sending public messages to a friend.
 - Add support for Identity strength
 - Add support for storing information that the Identity has gone through KYC with a given provider. 


