param(
    [Parameter(Mandatory=$true)]
    [string]$inputParam
)

$ErrorActionPreference = 'Stop'
try {

    $location = Get-Location;

    $scriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent

    Write-Host "🚀 Creating new project $inputParam"
    Invoke-Expression -Command "bun create svelte@latest $inputParam"
    Write-Host "✅ Project $inputParam has been created successfully!" -ForegroundColor DarkGreen

    Write-Host "`n=============`n"

    Write-Host "🚀 Updating project dependencies"
    
    Write-Host "`n🔨 Move to project directory"
    Invoke-Expression -Command "cd ./$inputParam"

    Write-Host "`n🔨 Add tailwindcss"
    Invoke-Expression -Command "bunx svelte-add@latest tailwindcss"

    Write-Host "`n🔨 Install initial dependencies"
    Invoke-Expression -Command "bun install"

    Write-Host "`n🔨 Initialize shadcn"
    Invoke-Expression -Command "bunx shadcn-svelte@latest init"

    Write-Host "`n🔨 Add default components"
    Invoke-Expression -Command "bunx shadcn-svelte@latest add avatar button context-menu form input label sonner skeleton -y"

    Write-Host "`n🔨 Add other required dependencies"
    Invoke-Expression -Command "bun install -D drizzle-kit prettier-plugin-tailwindcss"
    Invoke-Expression -Command "bun install @libsql/client @lucia-auth/adapter-drizzle arctic dotenv drizzle-orm lucia lucide-svelte oslo svelte-cloudinary"

    Write-Host "`n🔨 Update package dependencies"
    Invoke-Expression -Command "bun update --force"

    Write-Host "`n✅ Project dependencies have been updated successfully!" -ForegroundColor DarkGreen
    
    Write-Host "`n=============`n"

    Write-Host "🚀 Setup configurations"

    Write-Host "`n🔨 Update .gitignore"
    Add-Content "$location/$inputParam/.gitignore" -Value "bun.lockb","local.db","pnpm-lock.yaml"

    Write-Host "`n🔨 Update package script"
    Invoke-Expression -Command "$scriptDir/scripts/drizzle-script $location/$inputParam"

    Write-Host "`n🔨 Setup initial environment variables"
    Invoke-Expression -Command "$scriptDir/scripts/env-script $location/$inputParam"

    Write-Host "`n🔨 Setup turso database configiration"
    Invoke-Expression -Command "$scriptDir/scripts/drizzle-config $location/$inputParam"

    Write-Host "`n🔨 Generate required files"
    Invoke-Expression -Command "$scriptDir/scripts/source-generator $location/$inputParam"
    
    Write-Host "`n🔨 Generate initial migration"
    Invoke-Expression -Command "bun db:generate"

    Write-Host "`n✅ Configuration has been set up successfully!" -ForegroundColor DarkGreen

    Write-Host "`n=============`n"

    Write-Host "🚀 Setting up git"
    
    Write-Host "`n🔨 Initialize git"
    Invoke-Expression -Command "git init"

    Write-Host "`n🔨 Add initial commit"
    Invoke-Expression -Command "git add ."
    Invoke-Expression -Command "git commit -m 'feat: initial commits'"

    Write-Host "`n✅ Git has been setup successfully!" -ForegroundColor DarkGreen

    Write-Host "`n🔥Opening VS Code`n"
    Invoke-Expression -Command "code ."

    Invoke-Expression -Command "cd $location"
    Write-Host "🚀 Done! Happy coding! 🚀🚀🚀`n"
}
catch {
    Write-Host "❌ Error: $_"
    exit
}