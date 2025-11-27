package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"github.com/charmbracelet/bubbles/list"
	"github.com/charmbracelet/bubbles/spinner"
	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

type (
	errMsg           struct{ err error }
	fetchedModelsMsg []list.Item
	apiResponseMsg   string
)

type state int

const (
	showList state = iota
	showChat
)

var (
	appStyle = lipgloss.NewStyle().Margin(1, 2)
)

// --- list item ---
type item struct {
	title, desc string
}

func (i item) Title() string       { return i.title }
func (i item) Description() string { return i.desc }
func (i item) FilterValue() string { return i.title }

// --- bubble tea model ---
type model struct {
	state         state
	list          list.Model
	textInput     textinput.Model
	spinner       spinner.Model
	client        APIClient
	selectedModel string
	messages      []string
	loading       bool
	err           error
}

func initialModel() model {
	apiKey := os.Getenv("GEMINI_API_KEY")

	if apiKey == "" {
		tempDir := "/home/garth/.gemini/tmp/3ecdc925ecdb6b43e72d58ab048373ba41b82a51a9e0668f8dbca38696f65085"
		keyFile := filepath.Join(tempDir, "gemini", "api-key")
		content, err := ioutil.ReadFile(keyFile)
		if err == nil {
			apiKey = string(content)
		}
	}

	if apiKey == "" {
		home, err := os.UserHomeDir()
		if err == nil {
			keyFile := filepath.Join(home, ".config", "gemini", "api-key")
			content, err := ioutil.ReadFile(keyFile)
			if err == nil {
				apiKey = string(content)
			}
		}
	}

	// setup list
	l := list.New([]list.Item{}, list.NewDefaultDelegate(), 0, 0)
	l.Title = "Select a Model"

	// setup text input
	ti := textinput.New()
	ti.Placeholder = "Ask Gemini..."
	ti.Focus()

	// setup spinner
	s := spinner.New()
	s.Spinner = spinner.Dot
	s.Style = lipgloss.NewStyle().Foreground(lipgloss.Color("205"))

	client := NewLiveAPIClient(apiKey)

	return model{
		state:     showList,
		list:      l,
		textInput: ti,
		spinner:   s,
		client:    client,
		selectedModel: "",
		loading:   false,
	}
}

func (m model) Init() tea.Cmd {
	return tea.Batch(tea.EnterAltScreen, fetchModels(m.client))
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.list.SetSize(msg.Width, msg.Height)
		return m, nil

	case tea.KeyMsg:
		switch msg.Type {
		case tea.KeyCtrlC, tea.KeyEsc:
			logToFile("Ctrl-C pressed")
			return m, tea.Quit
		case tea.KeyEnter:
			if m.state == showList {
				if i, ok := m.list.SelectedItem().(item); ok {
					m.selectedModel = i.title
					m.state = showChat
				}
				return m, nil
			} else { // In chat mode, send the message
				m.messages = append(m.messages, "You: "+m.textInput.Value())
				m.loading = true
				cmd = tea.Batch(m.spinner.Tick, makeApiCall(m.client, m.selectedModel, m.textInput.Value()))
			}
		}

	case fetchedModelsMsg:
		m.list.SetItems(msg)
		return m, nil

	case apiResponseMsg:
		m.loading = false
		m.messages = append(m.messages, "Gemini: "+string(msg))
		m.textInput.Reset()
		return m, nil

	case errMsg:
		m.loading = false
		m.err = msg.err
		return m, nil
	}

	var cmds []tea.Cmd
	cmds = append(cmds, cmd)

	// Update components based on current state
	switch m.state {
	case showList:
		m.list, cmd = m.list.Update(msg)
		cmds = append(cmds, cmd)
	case showChat:
		m.textInput, cmd = m.textInput.Update(msg)
		cmds = append(cmds, cmd)

		var spinnerCmd tea.Cmd
		m.spinner, spinnerCmd = m.spinner.Update(msg)
		cmds = append(cmds, spinnerCmd)
	}

	return m, tea.Batch(cmds...)
}

func (m model) View() string {
	if m.err != nil {
		return fmt.Sprintf("\nWe had some trouble: %v\n\n", m.err)
	}
	if m.client.(*LiveAPIClient).apiKey == "" {
		return "API key not found. Please set the GEMINI_API_KEY environment variable."
	}

	ss := ""
	switch m.state {
	case showList:
		ss += m.list.View()
	case showChat:
		var chatView strings.Builder
		chatView.WriteString("Chat with " + m.selectedModel + "\n\n")
		for _, msg := range m.messages {
			chatView.WriteString(msg + "\n")
		}
		chatView.WriteString("\n" + m.textInput.View())
		// Only show spinner if we're waiting for a response
		if m.loading {
			chatView.WriteString("\n" + m.spinner.View() + " Thinking...")
		}
		ss = chatView.String()
	}

	return appStyle.Render(ss)
}

// --- api client ---
type APIClient interface {
	FetchModels() ([]list.Item, error)
	GenerateContent(model, prompt string) (string, error)
}

type LiveAPIClient struct {
	apiKey string
}

func NewLiveAPIClient(apiKey string) *LiveAPIClient {
	return &LiveAPIClient{apiKey: apiKey}
}

func (c *LiveAPIClient) FetchModels() ([]list.Item, error) {
	url := fmt.Sprintf("https://generativelanguage.googleapis.com/v1beta/models?key=%s", c.apiKey)
	res, err := http.Get(url)
	if err != nil {
		return nil, err
	}
	defer res.Body.Close()

	body, err := ioutil.ReadAll(res.Body)
	if err != nil {
		return nil, err
	}

	var response struct {
		Models []struct {
			Name                       string   `json:"name"`
			SupportedGenerationMethods []string `json:"supportedGenerationMethods"`
		} `json:"models"`
	}
	if err := json.Unmarshal(body, &response); err != nil {
		return nil, err
	}

	items := []list.Item{}
	for _, model := range response.Models {
		for _, method := range model.SupportedGenerationMethods {
			if method == "generateContent" {
				items = append(items, item{title: strings.TrimPrefix(model.Name, "models/")})
			}
		}
	}
	return items, nil
}

func (c *LiveAPIClient) GenerateContent(model, prompt string) (string, error) {
	logToFile("--- New API Call ---")
	logToFile(fmt.Sprintf("Model: %s", model))
	logToFile(fmt.Sprintf("Prompt: %s", prompt))

	url := fmt.Sprintf("https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s", model, c.apiKey)
	logToFile(fmt.Sprintf("URL: %s", url))

	reqBody := apiRequest{
		Contents: []struct {
			Parts []struct {
				Text string `json:"text"`
			} `json:"parts"`
		}{
			{
				Parts: []struct {
					Text string `json:"text"`
				}{
					{Text: prompt},
				},
			},
		},
	}

	reqBytes, err := json.Marshal(reqBody)
	if err != nil {
		logToFile(fmt.Sprintf("ERROR marshalling request: %v", err))
		return "", err
	}
	logToFile(fmt.Sprintf("Request Body: %s", string(reqBytes)))

	res, err := http.Post(url, "application/json", bytes.NewBuffer(reqBytes))
	if err != nil {
		logToFile(fmt.Sprintf("ERROR making POST request: %v", err))
		return "", err
	}
	defer res.Body.Close()

	body, err := ioutil.ReadAll(res.Body)
	if err != nil {
		logToFile(fmt.Sprintf("ERROR reading response body: %v", err))
		return "", err
	}
	logToFile(fmt.Sprintf("Response Body: %s", string(body)))

	var response apiResponse
	if err := json.Unmarshal(body, &response); err != nil {
		logToFile(fmt.Sprintf("ERROR unmarshalling response: %v", err))
		return "", err
	}

	if len(response.Candidates) > 0 && len(response.Candidates[0].Content.Parts) > 0 {
		responseText := response.Candidates[0].Content.Parts[0].Text
		logToFile(fmt.Sprintf("Success. Response text: %s", responseText))
		return responseText, nil
	}

	logToFile("No response from model.")
	return "No response from model.", nil
}

// --- api call types ---
type apiRequest struct {
	Contents []struct {
		Parts []struct {
			Text string `json:"text"`
		} `json:"parts"`
	} `json:"contents"`
}

type apiResponse struct {
	Candidates []struct {
		Content struct {
			Parts []struct {
				Text string `json:"text"`
			} `json:"parts"`
		} `json:"content"`
	} `json:"candidates"`
}

func fetchModels(client APIClient) tea.Cmd {
	return func() tea.Msg {
		items, err := client.FetchModels()
		if err != nil {
			return errMsg{err}
		}
		return fetchedModelsMsg(items)
	}
}

func makeApiCall(client APIClient, model, prompt string) tea.Cmd {
	return func() tea.Msg {
		resp, err := client.GenerateContent(model, prompt)
		if err != nil {
			return errMsg{err}
		}
		return apiResponseMsg(resp)
	}
}

func logToFile(message string) {
	f, err := os.OpenFile("debug.log", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		// Can't log, so just print to stderr
		fmt.Fprintf(os.Stderr, "failed to open log file: %v", err)
		return
	}
	defer f.Close()
	if _, err := fmt.Fprintf(f, "%s\n", message); err != nil {
		fmt.Fprintf(os.Stderr, "failed to write to log file: %v", err)
	}
}

func main() {
	p := tea.NewProgram(initialModel())
	if _, err := p.Run(); err != nil {
		fmt.Printf("Alas, there's been an error: %v", err)
		os.Exit(1)
	}
}
