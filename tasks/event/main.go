package main

import (
	"fmt"
	"os"

	"github.com/bjartek/go-with-the-flow/v2/gwtf"
)

func main() {

	// cronjob ready, read blockHeight from file
	g := gwtf.NewGoWithTheFlowDevNet()

	url, ok := os.LookupEnv("DISCORD_WEBHOOK_URL")
	if !ok {
		fmt.Println("webhook url is not present")
		os.Exit(1)
	}

	eventPrefix := "A.dc5299b787551b63.FIND"
	_, err := g.EventFetcher().
		Workers(1).
		BatchSize(25).
		TrackProgressIn(".find-testnet.events").
		EventIgnoringFields(fmt.Sprintf("%s.%s", eventPrefix, "Register"), []string{"expireAt"}).
		EventIgnoringFields(fmt.Sprintf("%s.%s", eventPrefix, "Locked"), []string{"lockedUntil"}).
		EventIgnoringFields(fmt.Sprintf("%s.%s", eventPrefix, "Sold"), []string{"expireAt"}).
		EventIgnoringFields(fmt.Sprintf("%s.%s", eventPrefix, "Moved"), []string{"expireAt"}).
		EventIgnoringFields(fmt.Sprintf("%s.%s", eventPrefix, "Freed"), []string{}).
		EventIgnoringFields(fmt.Sprintf("%s.%s", eventPrefix, "BlindBid"), []string{}).
		EventIgnoringFields(fmt.Sprintf("%s.%s", eventPrefix, "BlindBidRejected"), []string{}).
		EventIgnoringFields(fmt.Sprintf("%s.%s", eventPrefix, "BlindBidCanceled"), []string{}).
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
