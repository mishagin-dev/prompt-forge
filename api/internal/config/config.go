package config

import (
	"fmt"
	"log"
	"os"

	"github.com/joho/godotenv"
)

// Provider types
type AIProvider string

const (
	ProviderOpenAI      AIProvider = "openai"
	ProviderAzureOpenAI AIProvider = "azure-openai"
	ProviderAnthropic   AIProvider = "anthropic"
)

// Configuration structure
type Config struct {
	DefaultProvider AIProvider
	OpenAI          OpenAIConfig
	AzureOpenAI     AzureOpenAIConfig
	Anthropic       AnthropicConfig
}

type OpenAIConfig struct {
	APIKey  string
	BaseURL string // Optional, for custom endpoints
}

type AzureOpenAIConfig struct {
	APIKey     string
	BaseURL    string
	APIVersion string
}

type AnthropicConfig struct {
	APIKey  string
	BaseURL string // Optional, for custom endpoints
}

// Global configuration instance
var AppConfig *Config

// Initialize configuration from environment variables
func InitConfig() {
	// Load .env file - try multiple possible locations
	err := loadEnvFile()
	if err != nil {
		log.Printf("Warning: Could not load .env file: %v", err)
		log.Println("Note: Make sure .env file exists in the project root or set environment variables manually")
	}

	AppConfig = &Config{
		DefaultProvider: getDefaultProvider(),
		OpenAI: OpenAIConfig{
			APIKey:  getEnv("OPENAI_API_KEY", ""),
			BaseURL: getEnv("OPENAI_BASE_URL", "https://api.openai.com/v1"),
		},
		AzureOpenAI: AzureOpenAIConfig{
			APIKey:     getEnv("AZURE_OPENAI_API_KEY", ""),
			BaseURL:    getEnv("AZURE_OPENAI_BASE_URL", ""),
			APIVersion: getEnv("AZURE_OPENAI_API_VERSION", ""),
		},
		Anthropic: AnthropicConfig{
			APIKey:  getEnv("ANTHROPIC_API_KEY", ""),
			BaseURL: getEnv("ANTHROPIC_BASE_URL", "https://api.anthropic.com"),
		},
	}
}

// loadEnvFile tries to load .env file from current directory
func loadEnvFile() error {
	// Load .env file from current directory (same location as binary)
	if err := godotenv.Load(".env"); err == nil {
		log.Println("Successfully loaded .env file from current directory")
		return nil
	}

	// If no .env file found, that's not necessarily an error
	// Environment variables might be set directly in the system
	return fmt.Errorf("no .env file found in current directory")
}

func getDefaultProvider() AIProvider {
	provider := getEnv("DEFAULT_AI_PROVIDER", "anthropic")
	switch provider {
	case "openai":
		return ProviderOpenAI
	case "azure-openai":
		return ProviderAzureOpenAI
	case "anthropic":
		return ProviderAnthropic
	default:
		return ProviderAnthropic
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// Model deployment mappings for Azure OpenAI (backwards compatibility)
var ModelDeployments = map[string]string{
	"gpt-4.1": "gpt-4.1",
	"o3":      "o3",
}

// GetEndpointURL builds the complete endpoint URL for Azure OpenAI (backwards compatibility)
func GetEndpointURL(model string) string {
	deployment, exists := ModelDeployments[model]
	if !exists {
		deployment = "gpt-4.1" // fallback to default
	}
	return fmt.Sprintf("%s/openai/deployments/%s/chat/completions?api-version=%s", AppConfig.AzureOpenAI.BaseURL, deployment, AppConfig.AzureOpenAI.APIVersion)
}

// Backward compatibility constants (deprecated - use AppConfig instead)
var (
	AZURE_BASE_URL = ""
	AZURE_API_KEY  = ""
	API_VERSION    = ""
)
