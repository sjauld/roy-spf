package main

import (
	"context"
	"log"
	"net/url"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/keighl/postmark"
	"github.com/sjauld/roy-spf/src/crypto"
	"github.com/sjauld/roy-spf/src/mailer"
)

var (
	encryptionSecret string
	mailerClient     mailer.Mailer
	trackerBaseURL   *url.URL
)

// trackerURL encodes the victim's address so we can send it to the endpoint
func trackerURL(email string) string {
	u := *trackerBaseURL
	u.Path = crypto.Encrypt(email, encryptionSecret)

	return u.String()
}

func sender(ctx context.Context, request Request) error {
	log.Printf("[DEBUG] received %v", request)

	for _, t := range request.Targets {
		t.TemplateModel["tracker_url"] = trackerURL(t.Address)

		email := postmark.TemplatedEmail{
			TemplateAlias: request.PostmarkTemplateAlias,
			TrackOpens:    true,

			From:          request.From,
			To:            t.Address,
			TemplateModel: t.TemplateModel,
		}

		if _, err := mailerClient.SendTemplatedEmail(email); err != nil {
			log.Printf("[ERROR] unable to send email: %v", err)
		}
	}

	return nil
}

func main() {
	lambda.Start(sender)
}
