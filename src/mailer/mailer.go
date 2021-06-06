package mailer

import (
	"github.com/keighl/postmark"
)

// Mailer provides an interface for the Keighl Postmark implementation
type Mailer interface {
	SendEmail(postmark.Email) (postmark.EmailResponse, error)
	SendTemplatedEmail(postmark.TemplatedEmail) (postmark.EmailResponse, error)
}
