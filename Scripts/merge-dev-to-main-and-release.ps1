param(
    [string]$DevBranch  = "PWA_Trascrizione_AzureBot_Dev",
    [string]$MainBranch = "main",
    [string]$VerBranch  = "PWA_Trascrizione_Ver02"
)

Write-Host "=== MERGE DEV → MAIN + RELEASE ===" -ForegroundColor Cyan

# 1. Verifica repo Git
if (-not (Test-Path ".git")) {
    Write-Error "❌ Questa cartella NON è un repository Git."
    exit 1
}

# 2. Verifica working tree pulito
$status = git status --porcelain
if ($status) {
    Write-Error "❌ Working tree NON pulito. Commit o stash prima di procedere."
    exit 1
}

# 3. Verifica esistenza branch
$branches = git branch --list
if ($branches -notmatch $DevBranch) {
    Write-Error "❌ Branch DEV '$DevBranch' non trovato."
    exit 1
}
if ($branches -notmatch $MainBranch) {
    Write-Error "❌ Branch MAIN '$MainBranch' non trovato."
    exit 1
}

# 4. Mostra differenze
Write-Host "`n--- DIFFERENZE DEV → MAIN ---" -ForegroundColor Yellow
git diff $MainBranch..$DevBranch

$confirm = Read-Host "`nProcedere con il merge? (SI/NO)"
if ($confirm -ne "SI") {
    Write-Host "❌ Operazione annullata."
    exit 0
}

# 5. Checkout main
git checkout $MainBranch
git pull

# 6. Merge
git merge $DevBranch
if ($LASTEXITCODE -ne 0) {
    Write-Error "❌ Merge fallito. Risolvi i conflitti manualmente."
    exit 1
}

# 7. Push main
git push

# 8. Creazione branch di versione (se non esiste)
$verExists = git branch --list $VerBranch
if (-not $verExists) {
    git checkout -b $VerBranch
    git push -u origin $VerBranch
    git checkout $MainBranch
} else {
    Write-Host "ℹ️ Branch $VerBranch già esistente. Nessuna creazione."
}

# 9. Verifica finale hash
$hMain = git rev-parse $MainBranch
$hDev  = git rev-parse $DevBranch
$hVer  = git rev-parse $VerBranch

Write-Host "`n--- VERIFICA FINALE ---" -ForegroundColor Green
Write-Host "MAIN : $hMain"
Write-Host "DEV  : $hDev"
Write-Host "VER  : $hVer"

if ($hMain -eq $hDev -and $hMain -eq $hVer) {
    Write-Host ""
    Write-Host "SUCCESSO: tutti i branch sono allineati." -ForegroundColor Green
}
else {
    Write-Error ""
    Write-Error "ERRORE: i branch NON sono allineati."
    exit 1
}

