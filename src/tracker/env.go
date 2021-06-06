package main

import (
	"github.com/keighl/postmark"
	"github.com/sjauld/roy-spf/src/helpers"
)

var (
	// If testing, we'll skip all of this
	testMode = false
)

func init() {
	if testMode {
		return
	}

	decryptionSecret = helpers.MustReadSSMSecret("roy-spf-tracker", "decryption-secret")
	mailFrom = helpers.MustReadStringEnv("MAIL_FROM")
	mailTo = helpers.MustReadStringEnv("MAIL_TO")
	redirectURLError = helpers.MustReadURLEnv("REDIRECT_URL_ERROR")
	redirectURLMatch = helpers.MustReadURLEnv("REDIRECT_URL_MATCH")

	mailerClient = postmark.NewClient(
		helpers.MustReadSSMSecret("roy-spf-tracker", "postmark-server-token"),
		"",
	)
}
