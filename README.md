```
                                ██╗  ██╗██╗   ██╗███╗   ██╗████████╗███████╗██████╗
                                ██║  ██║██║   ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗
                                ███████║██║   ██║██╔██╗ ██║   ██║   █████╗  ██████╔╝
                                ██╔══██║██║   ██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗
                                ██║  ██║╚██████╔╝██║ ╚████║   ██║   ███████╗██║  ██║
                                ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝
```

                                   **Bug Bounty Recon Framework** v2.0 by Renzi

---

# 🇧🇷 Português

## O que é o Hunter?

**Hunter** é um framework automatizado de reconhecimento para Bug Bounty, escrito em Bash. Ele orquestra diversas ferramentas de segurança em um pipeline encadeado, cobrindo desde enumeração de subdomínios até varredura de vulnerabilidades, análise de JavaScript e descoberta de arquivos sensíveis no Web Archive — tudo em um único comando.

---

## ⚙️ Instalação e Requisitos

Antes de rodar o Hunter, certifique-se de ter as ferramentas abaixo instaladas e disponíveis no `PATH`:

| Ferramenta       | Finalidade                                      |
|------------------|-------------------------------------------------|
| `subfinder`      | Enumeração passiva de subdomínios               |
| `assetfinder`    | Enumeração de subdomínios via fontes públicas   |
| `dnsx`           | Resolução e brute-force DNS                     |
| `httpx`          | Probing de hosts ativos                         |
| `nuclei`         | Varredura de vulnerabilidades por templates     |
| `naabu`          | Scanner de portas                               |
| `katana`         | Crawler web ativo                               |
| `urlfinder`      | Coleta passiva de URLs                          |
| `ffuf`           | Fuzzing de arquivos de backup                   |
| `uro`            | Deduplicação e filtragem de URLs                |
| `uncover`        | Consultas ao Shodan/Fofa via queries            |
| `slicepathsurl`  | Segmentação de paths de URLs                    |
| `curl`           | Consultas à API do Wayback Machine              |

> O Hunter não interrompe a execução se uma ferramenta estiver ausente — ele exibe um aviso e pula a etapa correspondente.

---

## 🚀 Uso

```bash

  ██╗  ██╗██╗   ██╗███╗   ██╗████████╗███████╗██████╗ 
  ██║  ██║██║   ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗
  ███████║██║   ██║██╔██╗ ██║   ██║   █████╗  ██████╔╝
  ██╔══██║██║   ██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗
  ██║  ██║╚██████╔╝██║ ╚████║   ██║   ███████╗██║  ██║
  ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
         Bug Bounty Recon Framework |  v2.0 by Renzi
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Usage:
    ./hunter.sh -d <domains.txt> -w <wordlist.txt> [OPTIONS]

  Required:
    -d, --domains  <file>    Domains list (one per line)
    -w, --wordlist <file>    DNS brute-force wordlist

  Options:
    -o, --output   <dir>     Output directory (default: ./hunter-output)
    -b, --background         Run in background, detach from terminal
    -h, --help               Show this help message

  Examples:
    # Run in foreground
    ./hunter.sh -d domains.txt -w wordlist.txt

    # Run in background (detached, logs to hunter-output/hunter.log)
    ./hunter.sh -d domains.txt -w wordlist.txt -o ./results -b


```

### Argumentos obrigatórios

| Flag              | Descrição                                  |
|-------------------|--------------------------------------------|
| `-d, --domains`   | Arquivo com os domínios-alvo (um por linha)|
| `-w, --wordlist`  | Wordlist para brute-force DNS              |

### Opções

| Flag              | Descrição                                                       |
|-------------------|-----------------------------------------------------------------|
| `-o, --output`    | Diretório de saída (padrão: `./hunter-output`)                  |
| `-b, --background`| Executa em background desacoplado do terminal                   |
| `-h, --help`      | Exibe a mensagem de ajuda                                       |

### Exemplos

```bash
# Execução normal (foreground)
./hunter.sh -d domains.txt -w wordlist.txt

# Execução em background com diretório de saída personalizado
./hunter.sh -d domains.txt -w wordlist.txt -o ./results -b
```

> **Modo background:** o processo roda desacoplado com `nohup`. O PID, o arquivo de log e o comando para matar o processo são exibidos na tela após o lançamento.
> Monitoramento: `tail -f hunter-output/hunter.log`

---

## 🔍 Fases do Pipeline

### Fase 1 — Enumeração de Subdomínios
Combina três fontes:
- **subfinder** — enumeração passiva recursiva com todas as fontes disponíveis
- **assetfinder** — subdomínios via fontes públicas
- **dnsx** — brute-force DNS com a wordlist fornecida (opcional)

Ao final, os resultados são mesclados e deduplicados em `subdomains/all-subdomains.txt`.

---

### Fase 3 — Probing de Hosts Ativos (httpx)
Verifica quais subdomínios respondem HTTP/HTTPS nas portas `80, 443, 8080, 8888, 8443`, aceitando status codes `200, 301, 302, 404`. Resultados salvos em `urls/live-hosts.txt`.

---

### Fase 4 — Varredura com Nuclei (alvos httpx)
Roda o Nuclei contra os hosts ativos com severidades: `critical, high, medium, low, unknown`.

---

### Fase 5 — Shodan / Uncover
Gera queries Shodan automáticas por domínio (SSL, hostname, certificado) e usa o **uncover** para buscar hosts expostos. Resultados passam por Nuclei.

---

### Fase 6 — Coleta Passiva de URLs + DAST
- **urlfinder** coleta URLs de fontes como AlienVault, CommonCrawl, Wayback, URLScan e VirusTotal
- URLs são filtradas com `uro` e verificadas com `httpx`
- Nuclei roda em modo **DAST** (Dynamic Application Security Testing)

---

### Fase 7 — Crawler Ativo (katana) + DAST
- **katana** faz crawling ativo nos subdomínios
- URLs são deduplicadas com `uro` e verificadas com `httpx`
- Nuclei DAST é aplicado sobre os resultados

---

### Fase 8 — SlicePath URL Scan
Une as URLs do katana e da coleta passiva, aplica **slicepathsurl** para gerar variações de path em até 3 níveis, verifica os hosts ativos e roda Nuclei (padrão + DAST).

---

### Fase 9 — Port Scan (naabu) + Nuclei
Scanner de portas nas top-1000, **excluindo** as portas web já cobertas. Nuclei é executado contra os serviços descobertos em portas não-web.

---

### Fase 10 — Templates Nuclei Customizados (coffinxp)
Se o diretório `../coffinxp/nuclei-templates/` existir, roda Nuclei com templates privados/customizados contra os hosts ativos.

---

### Fase 11 — Análise de Arquivos JavaScript
- **katana** mapeia arquivos `.js` acessíveis
- **nuclei** aplica templates de `exposures` para buscar segredos, tokens e dados sensíveis expostos em JS

---

### Fase 12 — Descoberta de Arquivos de Backup (ffuf)
Usa **ffuf** para fuzzing de arquivos de backup nos domínios, com uma wordlist dedicada. Resultados salvos em formato Markdown.

---

### Fase 13 — Análise do Web Archive
Consulta a API CDX do Wayback Machine para cada domínio, filtra URLs que apontem para extensões sensíveis (`.sql`, `.env`, `.zip`, `.bak`, `.pem`, `.key`, `.config`, entre outros) e verifica quais ainda retornam HTTP 200.

---

## 📁 Estrutura de Saída

```
hunter-output/
├── subdomains/
│   ├── subfinder.txt
│   ├── assetfinder.txt
│   ├── dnsx.txt
│   └── all-subdomains.txt          ← todos os subdomínios mesclados
├── urls/
│   ├── live-hosts.txt              ← hosts ativos verificados
│   ├── passive-urls.txt
│   ├── passive-urls-filtered.txt
│   ├── katana-crawl.txt
│   ├── katana-filtered.txt
│   ├── slice-paths.txt
│   ├── js-files.txt
│   └── webarchive-sensitive.txt
├── nuclei/
│   ├── nuclei-httpx.txt
│   ├── nuclei-shodan.txt
│   ├── nuclei-dast-passive.txt
│   ├── nuclei-dast-katana.txt
│   ├── nuclei-slice.txt
│   ├── nuclei-slice-dast.txt
│   ├── nuclei-naabu.txt
│   ├── nuclei-coffinxp.txt
│   └── nuclei-js.txt
└── misc/
    ├── shodan-queries.txt
    ├── shodan-hosts.txt
    ├── non-web-ports.txt
    ├── webarchive-raw.txt
    └── backup-files.txt
```

---

## ⚠️ Aviso Legal

Esta ferramenta foi desenvolvida **exclusivamente para uso em programas de Bug Bounty e testes autorizados**. O uso não autorizado contra sistemas de terceiros é ilegal. O autor não se responsabiliza pelo uso indevido desta ferramenta.

---
---

# 🇺🇸 English

## What is Hunter?

**Hunter** is an automated Bug Bounty recon framework written in Bash. It orchestrates multiple security tools into a chained pipeline, covering everything from subdomain enumeration to vulnerability scanning, JavaScript analysis, and sensitive file discovery on the Web Archive — all in a single command.

---

## ⚙️ Installation & Requirements

Before running Hunter, make sure the following tools are installed and available in your `PATH`:

| Tool             | Purpose                                          |
|------------------|--------------------------------------------------|
| `subfinder`      | Passive subdomain enumeration                    |
| `assetfinder`    | Subdomain discovery via public sources           |
| `dnsx`           | DNS resolution and brute-force                   |
| `httpx`          | Live host probing                                |
| `nuclei`         | Template-based vulnerability scanning            |
| `naabu`          | Port scanner                                     |
| `katana`         | Active web crawler                               |
| `urlfinder`      | Passive URL collection                           |
| `ffuf`           | Backup file fuzzing                              |
| `uro`            | URL deduplication and filtering                  |
| `uncover`        | Shodan/Fofa queries via query files              |
| `slicepathsurl`  | URL path segmentation                            |
| `curl`           | Wayback Machine CDX API queries                  |

> Hunter does not stop execution if a tool is missing — it displays a warning and skips the corresponding step.

---

## 🚀 Usage

```bash

  ██╗  ██╗██╗   ██╗███╗   ██╗████████╗███████╗██████╗ 
  ██║  ██║██║   ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗
  ███████║██║   ██║██╔██╗ ██║   ██║   █████╗  ██████╔╝
  ██╔══██║██║   ██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗
  ██║  ██║╚██████╔╝██║ ╚████║   ██║   ███████╗██║  ██║
  ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
         Bug Bounty Recon Framework |  v2.0 by Renzi
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Usage:
    ./hunter.sh -d <domains.txt> -w <wordlist.txt> [OPTIONS]

  Required:
    -d, --domains  <file>    Domains list (one per line)
    -w, --wordlist <file>    DNS brute-force wordlist

  Options:
    -o, --output   <dir>     Output directory (default: ./hunter-output)
    -b, --background         Run in background, detach from terminal
    -h, --help               Show this help message

  Examples:
    # Run in foreground
    ./hunter.sh -d domains.txt -w wordlist.txt

    # Run in background (detached, logs to hunter-output/hunter.log)
    ./hunter.sh -d domains.txt -w wordlist.txt -o ./results -b

```

### Required Arguments

| Flag              | Description                                      |
|-------------------|--------------------------------------------------|
| `-d, --domains`   | File containing target domains (one per line)    |
| `-w, --wordlist`  | Wordlist for DNS brute-force                     |

### Options

| Flag              | Description                                                     |
|-------------------|-----------------------------------------------------------------|
| `-o, --output`    | Output directory (default: `./hunter-output`)                   |
| `-b, --background`| Run detached from the terminal in the background                |
| `-h, --help`      | Show the help message                                           |

### Examples

```bash
# Normal run (foreground)
./hunter.sh -d domains.txt -w wordlist.txt

# Background run with custom output directory
./hunter.sh -d domains.txt -w wordlist.txt -o ./results -b
```

> **Background mode:** the process runs detached via `nohup`. PID, log file path, and the kill command are displayed after launch.  
> Monitor with: `tail -f hunter-output/hunter.log`

---

## 🔍 Pipeline Phases

### Phase 1 — Subdomain Enumeration
Combines three sources:
- **subfinder** — recursive passive enumeration with all available sources
- **assetfinder** — subdomains via public sources
- **dnsx** — DNS brute-force with the provided wordlist (optional)

Results are merged and deduplicated into `subdomains/all-subdomains.txt`.

---

### Phase 3 — Live Host Probing (httpx)
Checks which subdomains respond on HTTP/HTTPS across ports `80, 443, 8080, 8888, 8443`, accepting status codes `200, 301, 302, 404`. Results saved to `urls/live-hosts.txt`.

---

### Phase 4 — Nuclei Scan (httpx targets)
Runs Nuclei against live hosts with severity levels: `critical, high, medium, low, unknown`.

---

### Phase 5 — Shodan / Uncover
Automatically generates Shodan queries per domain (SSL, hostname, certificate) and uses **uncover** to discover exposed hosts. Results are then passed through Nuclei.

---

### Phase 6 — Passive URL Collection + DAST
- **urlfinder** gathers URLs from AlienVault, CommonCrawl, Wayback, URLScan, and VirusTotal
- URLs are filtered with `uro` and probed with `httpx`
- Nuclei runs in **DAST** (Dynamic Application Security Testing) mode

---

### Phase 7 — Active Crawl (katana) + DAST
- **katana** actively crawls subdomains
- URLs are deduplicated with `uro` and probed with `httpx`
- Nuclei DAST is applied against the results

---

### Phase 8 — SlicePath URL Scan
Merges katana and passive URLs, applies **slicepathsurl** to generate path variations up to 3 levels deep, probes for live hosts, and runs Nuclei (standard + DAST).

---

### Phase 9 — Port Scan (naabu) + Nuclei
Scans the top-1000 ports, **excluding** ports already covered by web probing. Nuclei is run against services discovered on non-web ports.

---

### Phase 10 — Custom Nuclei Templates (coffinxp)
If the directory `../coffinxp/nuclei-templates/` exists, Nuclei runs using private/custom templates against live hosts.

---

### Phase 11 — JavaScript File Analysis
- **katana** maps accessible `.js` files
- **nuclei** applies `exposures` templates to hunt for secrets, tokens, and sensitive data exposed in JavaScript

---

### Phase 12 — Backup File Discovery (ffuf)
Uses **ffuf** to fuzz for backup files across all domains using a dedicated wordlist. Results are saved in Markdown format.

---

### Phase 13 — Web Archive Analysis
Queries the Wayback Machine CDX API for each domain, filters URLs pointing to sensitive extensions (`.sql`, `.env`, `.zip`, `.bak`, `.pem`, `.key`, `.config`, and many others), then verifies which ones still return HTTP 200.

---

## 📁 Output Structure

```
hunter-output/
├── subdomains/
│   ├── subfinder.txt
│   ├── assetfinder.txt
│   ├── dnsx.txt
│   └── all-subdomains.txt          ← all merged subdomains
├── urls/
│   ├── live-hosts.txt              ← verified live hosts
│   ├── passive-urls.txt
│   ├── passive-urls-filtered.txt
│   ├── katana-crawl.txt
│   ├── katana-filtered.txt
│   ├── slice-paths.txt
│   ├── js-files.txt
│   └── webarchive-sensitive.txt
├── nuclei/
│   ├── nuclei-httpx.txt
│   ├── nuclei-shodan.txt
│   ├── nuclei-dast-passive.txt
│   ├── nuclei-dast-katana.txt
│   ├── nuclei-slice.txt
│   ├── nuclei-slice-dast.txt
│   ├── nuclei-naabu.txt
│   ├── nuclei-coffinxp.txt
│   └── nuclei-js.txt
└── misc/
    ├── shodan-queries.txt
    ├── shodan-hosts.txt
    ├── non-web-ports.txt
    ├── webarchive-raw.txt
    └── backup-files.txt
```

---

## ⚠️ Legal Disclaimer

This tool was built **exclusively for use in authorized Bug Bounty programs and penetration testing engagements**. Unauthorized use against third-party systems is illegal. The author takes no responsibility for misuse of this tool.
