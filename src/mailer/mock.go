package mailer

import (
	"fmt"
	"log"

	"github.com/keighl/postmark"
)

// Mock is a fake mailer used for testing
type Mock struct {
	Logger Logger
}

// Logger allows you to pass in a logger
type Logger interface {
	Add()
	Log(string)
}

// MockLogger is our implementation of a Logger
type MockLogger struct {
	C int  // the counter
	V bool // verbose mode
}

// Add increments the counter
func (l *MockLogger) Add() {
	l.C++
	return
}

// Log logs the message if Verbose mode has been switched on
func (l *MockLogger) Log(s string) {
	if !l.V {
		return
	}

	log.Println(s)
	return
}

// SendEmail pretends to send an email successfully
func (m *Mock) SendEmail(t postmark.Email) (postmark.EmailResponse, error) {
	if m.Logger != nil {
		m.Logger.Add()
		m.Logger.Log(fmt.Sprintf("[DEBUG] SentEmail: %+v", t))
	}

	return postmark.EmailResponse{}, nil
}

// SendTemplatedEmail pretends to send a templated email successfully
func (m *Mock) SendTemplatedEmail(t postmark.TemplatedEmail) (postmark.EmailResponse, error) {
	if m.Logger != nil {
		m.Logger.Add()
		m.Logger.Log(fmt.Sprintf("[DEBUG] SentTemplatedEmail: %+v", t))
	}

	return postmark.EmailResponse{}, nil
}
