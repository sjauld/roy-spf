package main

type Request struct {
	// Targets: Who you are sending to
	Targets []Target `json:"targets"`
	// PostmarkTemplateAlias: The alias of the postmark template we'll use
	PostmarkTemplateAlias string `json:"postmark_template_alias"`
	// From: Who it is coming from e.g. "Jane Doe <jane@acrne.com>"
	From string `json:"from"`
}

type Target struct {
	// Address: The name and address of the target e.g. "Bob Doe <bob@acme.com>"
	Address string `json:"address"`
	// TemplateModel: Variables to substitute into your template
	TemplateModel map[string]interface{} `json:"template_model"`
}
