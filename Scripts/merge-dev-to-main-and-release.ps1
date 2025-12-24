param(
    [string]$DevBranch,
    [string]$MainBranch = "main",
    [string]$VerBranch
)

Write-Host "=== MERGE DEV -> MAIN + RELEASE ===" -ForegroundColor Cyan

# -------------------------------------------------------
# CONTESTO DI ESECUZIONE (user-friendly)
# -------------------------------------------------------

$workspacePath = Get-Location
$repoRoot      = git rev-parse --show-toplevel 2>$null
$currentBranch = git branch --show-current
$remoteOrigin  = git remote get-url origin 2>$null

Write-Host ""
Write-Host "=== CONTESTO DI ESECUZIONE ===" -ForegroundColor Cyan
Write-Host "Workspace        : $($workspacePath.Path)"
Write-Host "Repository Git   : $repoRoot"
Write-Host "Branch corrente  : $currentBranch"
Write-Host "Branch DEV       : $DevBranch"
Write-Host "Branch MAIN      : $MainBranch"
Write-Host "Branch VERSIONE  : $VerBranch"
Write-Host "Remote origin    : $remoteOrigin"

if ($workspacePath.Path -ne $repoRoot) {
    Write-Host "NOTA: stai lavorando in una sottocartella del repository." -ForegroundColor Yellow
}

Write-Host "==============================" -ForegroundColor Cyan
Write-Host ""

# -------------------------------------------------------
# 1. Verifica repository Git
# -------------------------------------------------------
if (-not (Test-Path ".git")) {
    Write-Error "ERRORE: questa cartella NON è un repository Git."
    exit 1
}

# -------------------------------------------------------
# 2. Verifica working tree pulito
# -------------------------------------------------------
if (git status --porcelain) {
    Write-Error "ERRORE: working tree NON pulito. Commit o stash prima di procedere."
    exit 1
}

# -------------------------------------------------------
# 3. Recupero branch locali NORMALIZZATI
# -------------------------------------------------------
$localBranches = git branch | ForEach-Object {
    $_ -replace '^\*', '' -replace '^\s+', '' -replace '\s+$', ''
}

# -------------------------------------------------------
# 4. Recupero branch remoti
# -------------------------------------------------------
git fetch | Out-Null
$remoteBranches = git branch -r | ForEach-Object {
    $_ -replace '^\s+', '' -replace '\s+$', ''
}

# -------------------------------------------------------
# 5. Verifica / checkout DEV branch
# -------------------------------------------------------
if ($localBranches -notcontains $DevBranch) {

    if ($remoteBranches -contains "origin/$DevBranch") {
        Write-Host "INFO: branch DEV '$DevBranch' trovato solo in remoto. Checkout automatico..." -ForegroundColor Yellow
        git checkout -b $DevBranch "origin/$DevBranch"
        if ($LASTEXITCODE -ne 0) {
            Write-Error "ERRORE: impossibile creare il branch DEV '$DevBranch'."
            exit 1
        }
    }
    else {
        Write-Error "ERRORE: branch DEV '$DevBranch' non trovato (né locale né remoto)."
        exit 1
    }
}

# -------------------------------------------------------
# 6. Verifica / checkout MAIN branch
# -------------------------------------------------------
if ($localBranches -notcontains $MainBranch) {

    if ($remoteBranches -contains "origin/$MainBranch") {
        Write-Host "INFO: branch MAIN '$MainBranch' trovato solo in remoto. Checkout automatico..." -ForegroundColor Yellow
        git checkout -b $MainBranch "origin/$MainBranch"
        if ($LASTEXITCODE -ne 0) {
            Write-Error "ERRORE: impossibile creare il branch MAIN '$MainBranch'."
            exit 1
        }
    }
    else {
        Write-Error "ERRORE: branch MAIN '$MainBranch' non trovato."
        exit 1
    }
}

# -------------------------------------------------------
# 7. Mostra differenze DEV -> MAIN
# -------------------------------------------------------
Write-Host ""
Write-Host "--- DIFFERENZE DEV -> MAIN ---" -ForegroundColor Yellow
git diff "$MainBranch..$DevBranch"

Write-Host ""
Write-Host "ATTENZIONE: verrà eseguito il MERGE su '$MainBranch' partendo da '$DevBranch' nel repository sopra indicato." -ForegroundColor Yellow
$confirm = Read-Host "Procedere con il merge? (SI/NO)"
if ($confirm -ne "SI") {
    Write-Host "Operazione annullata."
    exit 0
}

# -------------------------------------------------------
# 8. Merge DEV -> MAIN
# -------------------------------------------------------
git checkout $MainBranch
git pull
git merge $DevBranch
if ($LASTEXITCODE -ne 0) {
    Write-Error "ERRORE: merge fallito. Risolvere i conflitti manualmente."
    exit 1
}
git push

# -------------------------------------------------------
# 9. Creazione branch di versione
# -------------------------------------------------------
if (-not (git branch --list $VerBranch)) {
    git checkout -b $VerBranch
    git push -u origin $VerBranch
    git checkout $MainBranch
}
else {
    Write-Host "INFO: branch di versione '$VerBranch' già esistente."
}

# -------------------------------------------------------
# 10. Verifica allineamento finale
# -------------------------------------------------------
$hMain = git rev-parse $MainBranch
$hDev  = git rev-parse $DevBranch
$hVer  = git rev-parse $VerBranch

Write-Host ""
Write-Host "--- VERIFICA FINALE ---" -ForegroundColor Green
Write-Host "MAIN : $hMain"
Write-Host "DEV  : $hDev"
Write-Host "VER  : $hVer"

if ($hMain -eq $hDev -and $hMain -eq $hVer) {
    Write-Host ""
    Write-Host "SUCCESSO: tutti i branch sono allineati." -ForegroundColor Green
}
else {
    Write-Error "ERRORE: i branch NON sono allineati."
    exit 1
}
