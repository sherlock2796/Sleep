# Sleep

App per iPhone e Apple Watch, ispirata a Pillow, per monitorare il sonno:

- registrazione dei suoni durante la notte (russare, parlato, tosse, rumori);
- lettura delle fasi del sonno dall'Apple Watch tramite l'app Salute;
- statistiche e trend delle notti.

## Stato attuale: versione di prova (0.1)

Questa prima versione serve solo a verificare che le basi funzionino sul tuo iPhone:

1. **Microfono**: il livello sonoro si muove quando parli.
2. **Ascolto a schermo spento**: con il telefono bloccato l'app continua ad ascoltare.
3. **App Salute**: l'app riesce a leggere le notti registrate dall'Apple Watch.

## Come funziona la compilazione

Non serve un Mac. A ogni modifica del codice GitHub compila l'app su un Mac virtuale e produce un file `Sleep.ipa`. Lo installi sull'iPhone dal PC Windows con **Sideloadly**, usando il tuo ID Apple gratuito.

Con l'ID Apple gratuito l'app **scade dopo 7 giorni** e va rinnovata. I dati (registrazioni, statistiche) non si perdono quando la rinnovi.

## Installazione sull'iPhone (PC Windows)

### Una volta sola: preparare il PC

1. Installa **iTunes** e **iCloud** scaricandoli dal sito Apple, non dal Microsoft Store:
   - iTunes: <https://www.apple.com/it/itunes/> → "Windows" → scarica la versione a 64 bit
   - iCloud: <https://support.apple.com/it-it/103232>
2. Installa **Sideloadly** da <https://sideloadly.io>.

### Scaricare l'app

1. Apri <https://github.com/sherlock2796/Sleep/actions> ed entra nell'esecuzione più recente di **Build iOS** con il segno verde ✅.
2. In fondo alla pagina, sotto **Artifacts**, scarica `Sleep-build-N`.
3. Estrai lo zip: dentro c'è `Sleep.ipa`.

### Installare con Sideloadly

1. Collega l'iPhone al PC con il cavo, sbloccalo e conferma **"Autorizza questo computer"**.
2. Apri Sideloadly e trascina `Sleep.ipa` nella finestra.
3. Inserisci il tuo ID Apple e premi **Start**. Ti verranno chiesti la password e il codice di verifica a due fattori.
   - Consiglio facoltativo: puoi creare un ID Apple secondario apposta per questo.
4. Sull'iPhone apri **Impostazioni → Generali → VPN e gestione dispositivi**, tocca il tuo ID Apple e scegli **Autorizza**.
5. Se l'iPhone lo chiede, attiva **Impostazioni → Privacy e sicurezza → Modalità sviluppatore** e riavvia il telefono.

### Rinnovo ogni 7 giorni

Ripeti l'installazione con Sideloadly prima della scadenza: l'app viene aggiornata e i dati restano. Puoi anche attivare il rinnovo automatico via Wi-Fi nelle opzioni di Sideloadly, che richiede il PC acceso e sulla stessa rete dell'iPhone.

## Prova da fare

1. Apri l'app, tocca **Avvia ascolto** e consenti l'uso del microfono. Parla: il livello deve muoversi.
2. Blocca il telefono per **5 minuti**, poi riaprilo. Nel registro devono esserci righe `Minuto: … app in background`.
3. Tocca **Collega app Salute**, consenti l'accesso a *Analisi del sonno* e *Battito cardiaco*, e controlla che compaiano le ultime notti.
4. Tocca **Esporta registro** e invia il testo a Claude.

## Struttura del progetto

| Percorso | Contenuto |
|---|---|
| `project.yml` | Definizione del progetto Xcode (generato con [XcodeGen](https://github.com/yonaskolb/XcodeGen)) |
| `Sleep/App` | Punto di avvio dell'app |
| `Sleep/Views` | Schermate (SwiftUI) |
| `Sleep/Services` | Microfono, app Salute, registro diagnostico |
| `.github/workflows/build-ios.yml` | Compilazione automatica e creazione del file `.ipa` |
