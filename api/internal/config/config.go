package config

import (
	"fmt"
	"log"
	"os"
	"path/filepath"

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
	DatabasePath    string
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
	loadEnvFile()

	AppConfig = &Config{
		DefaultProvider: getDefaultProvider(),
		DatabasePath:    getEnv("DATABASE_PATH", "promptforge.db"),
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

// loadEnvFile tries to load .env file from binary directory
func loadEnvFile() error {
	// Get the directory where the binary is located
	execPath, err := os.Executable()
	if err != nil {
		log.Printf("Failed to get executable path: %v", err)
		return err
	}

	binDir := filepath.Dir(execPath)
	envPath := filepath.Join(binDir, ".env")

	// Load .env file from binary directory
	if err := godotenv.Load(envPath); err == nil {
		log.Printf("Successfully loaded .env file from: %s", envPath)
		return nil
	}

	// If no .env file found, that's not necessarily an error
	// Environment variables might be set directly in the system
	// Just log a debug message instead of returning an error
	log.Printf("No .env file found at %s, using environment variables and defaults", envPath)
	return nil
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
