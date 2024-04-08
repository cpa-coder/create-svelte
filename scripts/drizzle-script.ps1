param(
    [Parameter(Mandatory=$true)]
    [string]$inputParam
)

$fileContent = Get-Content "$inputParam\package.json"

$fileContent[7] += @"
    `n`t`t"db:push": "drizzle-kit push:sqlite --config=drizzle.config.ts",
    "db:studio": "drizzle-kit studio",
    "db:generate": "npx drizzle-kit generate:sqlite --config drizzle.config.ts",
"@

$fileContent | Set-Content "$inputParam\package.json"