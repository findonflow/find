# Developing .find

.find uses some of the tools that I (bjartek) have made to develop and test cadence code. 

 -  [overflow](https://github.com/bjartek/overflow) is beeing used for testing and running manual `storylines`

This repo is the backend code, there are two other repos in this solutions namely
 - [find-lookup](https://github.com/findonflow/find-lookup) a serverless function to lookup names from web2
 - [find-web](https://github.com/findonflow/find-web) the frontend code
 

## Transactions
There are a lot of transactions in the transactions folder in .find. These can be grouped as follows:

### Direct sales of NFT

- buyNFTForSale
- delistAllNFTSale
- delistNFTSale
- listNFTForSale

### Direct Offers of NFTs 

This direct offer variant will escrow funds in the owners account so that we know they have enough and can pay

- bidMarketDirectOfferEscrowed
- cancelMarketDirectOfferEscrowed
- fulfillMarketDirectOfferEscrowed
- retractOfferMarketDirectOfferEscrowed
- increaseBidMarketDirectOfferEscrowed


### Auctions of NFTs 

This auction variant will escrow funds in the owners account so that we know they have enough and can pay

- cancelMarketAuctionEscrowed
- bidMarketAuctionEscrowed
- fulfillMarketAuctionEscrowed
- fulfillMarketAuctionEscrowedFromBidder
- increaseBidMarketAuctionEscrowed
- listNFTForAuctionEscrowed

### Auctions of NFTs for Dapper Utility Coin
A specialized version of auctions that can work with the struct rules for dapper utlity coin.

- increaseBidMarketAuctionSoft
- fulfillMarketAuctionSoft
- cancelMarketAuctionSoft
- bidMarketAuctionSoft
- listNFTForAuctionSoft


### Direct Offers on NFTs for Dapper Utility Coin

A specialized version of directOffers that can work with the struct rules for dapper utlity coin.

- bidMarketDirectOfferSoft
- acceptDirectOfferSoft
- cancelMarketDirectOfferSoft
- fulfillMarketDirectOfferSoft
- retractOfferMarketDirectOfferSoft
- increaseBidMarketDirectOfferSoft


### Listing and Auctions for .find names

These will seldom be used in other places then .find

- bidName
- startNameAuction
- cancelNameAuction
- cancelNameBid
- delistAllNameSale
- delistNameSale
- fulfillName
- fulfillNameAuction
- fulfillNameAuctionBidder
- increaseNameBid
- listNameForAuction
- listNameForSale
- rejectNameDirectOffer


### Misc transactions mainly used in .find

- buyAddon
- mintDandy
- moveNameTO
- register
- registerGift
- removeCurratedCollection
- removeMarketOption
- removeRelatedAccount
- removeTenantRule
- renewName
- createCharity
- createProfile
- editProfile
- sendCharity
- sendFT
- setMainName
- setPrivateMode
- setProfile
- setRelatedAccount
- storeCuratedCollections
- addCuratedCollection
- alterMarketOption

## Tests
In order to run the tests for .find we recommend using (gotestsum)[https://github.com/gotestyourself/gotestsum] with the following invocation

```
gotestsum -f testname --hide-summary output
```

## Storylines
There are also some tasks or storylines that you might want to run/modify if you want to experiment with how .find works

Take a look in the tasks folder and run a task with the form
```
go run tasks/demo/main.go
```

## Integrating between frontend and backend
.find uses a feature in [overflow](https://github.com/bjartek/overflow) to convert the transactions/scripts in this repo into a json file that is then published to npm.

This flow will be integrated into CI but right now it works like this

 - `make client` will run the logic to generate the file lib/find.json
 - `make minor|patch|major` will bump the semantic version of the lib/package.json file
 - `make publish` will publish this file to NPM

In the frontend code this module is then used as an [NPM import](https://github.com/findonflow/find-web/blob/master/src/functions/txfunctions.js#L3) and used with FCL in a transaction [like this](https://github.com/findonflow/find-web/blob/master/src/functions/txfunctions.js#L13)

We are planning to look at flow-cadut in the future
