package main

import (
	"context"
	"fmt"
	"log"
	"net/url"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/keighl/postmark"
	"github.com/sjauld/roy-spf/src/crypto"
	"github.com/sjauld/roy-spf/src/helpers"
	"github.com/sjauld/roy-spf/src/mailer"
)

var responseHeaders = map[string]string{
	"Access-Control-Allow-Origin": "*",
	"Content-Type":                "application/json",
}

var (
	decryptionSecret string
	mailerClient     mailer.Mailer
	mailFrom         string
	mailTo           string
	redirectURLError *url.URL
	redirectURLMatch *url.URL
)

func tracker(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	log.Printf("[DEBUG] received %v", request)

	if request.Path == "/" {
		return helpers.ResponsePermanentRedirect(redirectURLError.String())
	}

	// Try to detect the user
	email, err := crypto.Decrypt(request.Path[1:], decryptionSecret)
	if err != nil {
		log.Printf("[ERROR] could not decrypt %v: %v", request.Path, err)
		return helpers.ResponsePermanentRedirect(redirectURLError.String())
	}

	log.Printf("[INFO] captured a click from %v", email)

	_, err = mailerClient.SendEmail(postmark.Email{
		From:     mailFrom,
		To:       mailTo,
		Subject:  fmt.Sprintf("[RoySPF] %v is a victim!", email),
		TextBody: fmt.Sprintf("You caught %v! Time for compulsory phishing re-education!", email),
	})

	if err != nil {
		log.Printf("[ERROR] could not send tracker email: %v", err)
	}

	return helpers.ResponsePermanentRedirect(redirectURLMatch.String())
}

func main() {
	lambda.Start(tracker)
}
