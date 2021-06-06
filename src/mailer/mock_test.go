package mailer

import (
	"testing"

	"github.com/keighl/postmark"
)

func TestMock(t *testing.T) {
	var m Mailer

	m = &Mock{}

	_, err := m.SendTemplatedEmail(postmark.TemplatedEmail{})

	if err != nil {
		t.Error(err)
	}
}

func TestLoggerWorks(t *testing.T) {
	var m Mailer
	l := &MockLogger{}

	m = &Mock{
		Logger: l,
	}

	_, err := m.SendTemplatedEmail(postmark.TemplatedEmail{})
	_, err = m.SendTemplatedEmail(postmark.TemplatedEmail{})
	_, err = m.SendTemplatedEmail(postmark.TemplatedEmail{})
	_, err = m.SendTemplatedEmail(postmark.TemplatedEmail{})
	_, err = m.SendTemplatedEmail(postmark.TemplatedEmail{})

	if err != nil {
		t.Error(err)
	}

	if l.C != 5 {
		t.Errorf("Expected to count 5, got %d", l.C)
	}

	l.V = true
	_, err = m.SendTemplatedEmail(postmark.TemplatedEmail{})
	if err != nil {
		t.Error(err)
	}

	if l.C != 6 {
		t.Errorf("Expected to count 6, got %d", l.C)
	}

}
