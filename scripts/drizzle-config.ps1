param(
    [Parameter(Mandatory=$true)]
    [string]$folderPath
)

# Check if the file exists
if (Test-Path -Path "$folderPath\drizzle.config.ts") {
    Write-Output "❌ drizzle.config.ts file already exists"
    exit
}

# Write the content to the file
Set-Content -Path "$folderPath\drizzle.config.ts" -Value @"
import type { Config } from 'drizzle-kit';
import 'dotenv/config';

const url =
    process.env.TURSO_CONFIG === 'dev' ? process.env.TURSO_LOCAL : process.env.TURSO_CONNECTION_URL;

const config = {
    schema: './src/lib/server/db/schema',
    out: './migrations',
    driver: 'turso',
    dbCredentials: {
        url: url,
        authToken: process.env.TURSO_AUTH_TOKEN
    }
};

export default config satisfies Config;
"@