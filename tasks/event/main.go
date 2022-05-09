package main

import (
	"fmt"
	"os"

	"github.com/bjartek/overflow/overflow"
)

func main() {

	// cronjob ready, read blockHeight from file
	o := overflow.NewOverflowTestnet().Start()

	url, ok := os.LookupEnv("DISCORD_WEBHOOK_URL")
	if !ok {
		fmt.Println("webhook url is not present")
		os.Exit(1)
	}

	eventPrefix := "A.85f0d6217184009b.FIND"
	_, err := o.EventFetcher().
		Workers(5).
		BatchSize(25).
		TrackProgressIn(".find-testnet.events").
		EventIgnoringFields(fmt.Sprintf("%s.%s", eventPrefix, "Register"), []string{}).
		EventIgnoringFields(fmt.Sprintf("%s.%s", eventPrefix, "Sold"), []string{"expireAt"}).
		EventIgnoringFields(fmt.Sprintf("%s.%s", eventPrefix, "Moved"), []string{"expireAt"}).
		EventIgnoringFields(fmt.Sprintf("%s.%s", eventPrefix, "Freed"), []string{}).
		EventIgnoringFields(fmt.Sprintf("%s.%s", eventPrefix, "DirectOffer"), []string{}).
		EventIgnoringFields(fmt.Sprintf("%s.%s", eventPrefix, "DirectOfferRejected"), []string{}).
		EventIgnoringFields(fmt.Sprintf("%s.%s", eventPrefix, "DirectOfferCanceled"), []string{}).
		EventIgnoringFields(fmt.Sprintf("%s.%s", eventPrefix, "AuctionCancelled"), []string{}).
		EventIgnoringFields(fmt.Sprintf("%s.%s", eventPrefix, "AuctionStarted"), []string{}).
		EventIgnoringFields(fmt.Sprintf("%s.%s", eventPrefix, "AuctionBid"), []string{}).
		EventIgnoringFields(fmt.Sprintf("%s.%s", eventPrefix, "ForSale"), []string{"expireAt"}).
		EventIgnoringFields(fmt.Sprintf("%s.%s", eventPrefix, "ForAuction"), []string{"expireAt"}).
		RunAndSendToWebhook(url)

	if err != nil {
		panic(err)
	}

}
