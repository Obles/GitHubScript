# merge-dev-to-main-and-release.ps1
Guida operativa all’utilizzo nel progetto

## Scopo

Questo script automatizza in modo controllato, sicuro e ripetibile il flusso standard di promozione del codice:

1. sviluppo su branch _Dev  
2. merge consapevole su main  
3. creazione di una versione (VerXX)  
4. verifica finale di allineamento tra i branch  

Lo script è progettato per ridurre errori manuali, impedire merge accidentali e standardizzare la gestione delle release nei progetti.

---

## Quando usarlo

Usare lo script solo quando:

- il branch _Dev contiene codice completo e verificato  
- si vuole promuovere _Dev a nuova baseline (main)  
- si desidera congelare lo stato corrente in una versione (Ver02, Ver03, …)

NON usarlo se:

- il working tree non è pulito  
- il branch _Dev non è pronto  
- si sta lavorando direttamente su main  

---

## Prerequisiti

- Git installato e disponibile nel PATH  
- PowerShell  
- Permessi di push sul repository  
- Repository clonato in locale  
- Nessuna modifica non committata (git status pulito)

---

## Dove eseguire lo script

Lo script va sempre eseguito dalla root del repository di progetto.

Esempio:

cd C:\LAVORO\PWA_Trascrizione_AzureBot

---

## Parametri dello script

param(
    [string]$DevBranch  = "PWA_Trascrizione_AzureBot_Dev",
    [string]$MainBranch = "main",
    [string]$VerBranch  = "PWA_Trascrizione_Ver02"
)

### Significato dei parametri

DevBranch  → Branch di sviluppo quotidiano  
MainBranch → Branch di baseline ufficiale  
VerBranch  → Branch di versione (snapshot)

I parametri possono essere sovrascritti da linea di comando.

---

## Esecuzione base

powershell -ExecutionPolicy Bypass -File C:\LAVORO\GitHubScript\scripts\merge-dev-to-main-and-release.ps1

---

## Esecuzione con parametri personalizzati

powershell -ExecutionPolicy Bypass -File C:\LAVORO\GitHubScript\scripts\merge-dev-to-main-and-release.ps1 -DevBranch "MyProject_Dev" -MainBranch "main" -VerBranch "MyProject_Ver01"

---

## Comportamento dello script

Lo script esegue automaticamente:

1. verifica che la cartella corrente sia un repository Git  
2. verifica che il working tree sia pulito  
3. controlla l’esistenza dei branch _Dev e main  
4. mostra le differenze reali tra _Dev e main  
5. richiede conferma esplicita prima del merge  
6. esegue checkout di main, pull, merge da _Dev e push  
7. crea il branch di versione VerXX se non esiste  
8. verifica che _Dev, main e VerXX puntino allo stesso commit  

---

## Conferma interattiva

Prima del merge lo script richiede:

Procedere con il merge? (SI/NO)

Solo rispondendo SI (maiuscolo) l’operazione viene eseguita.  
Qualsiasi altra risposta annulla l’operazione senza effetti collaterali.

---

## Esito positivo

Se tutto è corretto, lo script conferma che:

- Dev  
- main  
- VerXX  

puntano allo stesso hash di commit.

---

## Gestione degli errori

Lo script si interrompe se:

- non si è in un repository Git  
- il working tree non è pulito  
- uno dei branch non esiste  
- il merge genera conflitti  
- i branch finali non risultano allineati  

In nessun caso viene effettuato un push distruttivo.

---

## Regole operative consigliate

- lo sviluppo avviene solo su _Dev  
- main riceve solo merge controllati  
- i branch VerXX sono immutabili  
- per ogni nuova release si continua su _Dev e si rilancia lo script  

---

## Nota architetturale

Lo script utilizza branch di versione (VerXX).  
In contesti più avanzati può essere affiancato o sostituito da tag di release o pipeline CI/CD.

---

## Repository ufficiale degli script

Gli script condivisi sono mantenuti in:

https://github.com/Obles/GitHubScript
