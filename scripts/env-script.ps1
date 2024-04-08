param(
    [Parameter(Mandatory=$true)]
    [string]$inputParam
)

$fileExists = Test-Path "$inputParam\.env"
if ($fileExists) {
    Write-Output "❌ .env file already exists"
    exit
}

Set-Content -Path "$inputParam\.env" -Value @"
# TURSO DATABASE
TURSO_CONFIG="dev"
TURSO_LOCAL="file:local.db"
TURSO_CONNECTION_URL=""
TURSO_AUTH_TOKEN=""

# GITHUB AUTH
GITHUB_CLIENT_ID=""
GITHUB_CLIENT_SECRET=""

# GOOGLE OAUTH
GOOGLE_CLIENT_ID="...apps.googleusercontent.com"
GOOGLE_CLIENT_SECRET="GOCSPX..."

# CLOUDINARY
VITE_PUBLIC_CLOUDINARY_CLOUD_NAME=""
PUBLIC_CLOUDINARY_UPLOAD_PRESET=""

# CLOUDINARY SIGNED UPLOAD
CLOUDINARY_API_SECRET=""
VITE_PUBLIC_CLOUDINARY_API_KEY=""
"@