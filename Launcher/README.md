# Launcher do Tech Repair Simulator

Projeto independente em Godot 4.7.2 para Windows 10/11 x64. Abra `Launcher/project.godot` no Godot ou execute a cena pelo console do Godot no terminal do VS Code.

## Configurar o GitHub

Digite `OWNER/REPO` no launcher. A configuração é gravada para a próxima abertura. Para definir um valor inicial em builds locais, preencha `repository` em `Launcher/repository.cfg`. O workflow preenche esse valor com o repositório onde for executado.

Em GitHub Releases, clique em **`Tech Repair Simulator.exe`** para baixar o launcher como `Tech.Repair.Simulator.exe`. O launcher usa releases estáveis públicas, com tags como `v0.1.0`, e baixa o jogo pelo pacote `Tech-Repair-Simulator-Windows-x64.zip`. Esse pacote contém o executável do jogo `Tech Repair Simulator.exe` na raiz. A consulta lê o tamanho e o SHA-256 do ZIP nos metadados do GitHub.

O jogo instalado fica em `%LOCALAPPDATA%\Tech Repair Simulator\Launcher\installations`. O launcher usa sua própria pasta de preferências no Godot. O progresso e as opções do jogo continuam em `%APPDATA%\Godot\app_userdata\Tech Repair Simulator`. Uma instalação independente anterior pode continuar usando esses mesmos dados. A primeira execução do launcher baixa sua própria cópia gerenciada.

## Testar localmente

Defina `$godot` como o caminho do `Godot_v4.7.2-stable_win64_console.exe` em um terminal PowerShell no VS Code. Execute os comandos abaixo a partir da raiz do jogo.

### Suíte automatizada

```powershell
$env:APPDATA = Join-Path $env:TEMP ('tech-repair-launcher-test-' + [guid]::NewGuid())
New-Item -ItemType Directory -Path $env:APPDATA | Out-Null
& $godot --headless --path Launcher --script res://Tests/verify_launcher.gd -- --fixture-port=47813
```

O teste usa HTTP em loopback e verifica instalação, comparação numérica, início automático, atualização, download truncado, SHA-256 inválido e modo offline. O modo de teste simula o início do jogo e guarda as instalações em uma pasta separada.

### Testar a interface com o ZIP atual

No primeiro terminal, inicie o servidor de teste com o ZIP atual.

```powershell
$zip = (Resolve-Path 'Builds/Tech-Repair-Simulator-Windows-x64.zip').Path
& $godot --headless --path Launcher --script res://Tests/serve_release.gd -- 47812 v0.1.0 $zip
```

No segundo terminal, abra o launcher.

```powershell
& $godot --path Launcher -- --fixture-port=47812
```

1. Clique em **Instalar** e observe a barra de progresso.
2. Feche e reabra o launcher na mesma porta. A tela indica que o jogo seria aberto automaticamente.
3. Reinicie o servidor na mesma porta com a tag `v0.2.0` e execute **Verificar versão**. Confira o botão **Atualizar**.
4. Para testar um erro, acrescente `truncate` ou `digest` ao comando do servidor. A versão anterior continua disponível depois da tentativa.
5. Pare o servidor com **Ctrl+C**, verifique a versão e use **Jogar offline**. O modo de teste indica qual versão abriria.

O argumento de fixture funciona somente no executável do editor. Para usar outra instalação de teste, escolha outra porta ou um `APPDATA` temporário.

### Exportar localmente

Instale os templates do Godot 4.7.2 e escolha uma pasta de saída separada dos arquivos do jogo.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Launcher\Build-Windows.ps1 -GodotConsole $godot -OutputDirectory (Join-Path $env:TEMP 'tech-repair-launcher-build')
```

O script gera o launcher em `Tech Repair Simulator.exe`, na raiz da pasta de saída. O executável independente do jogo fica em `game/Tech Repair Simulator.exe`. O ZIP e o arquivo de verificação SHA-256 ficam junto do launcher. Para testar a consulta real pelo launcher exportado, configure um repositório público que já contenha um pacote compatível.

O parâmetro `-ExecutionPolicy Bypass` vale para o processo PowerShell desse comando.

## Publicação manual futura

Quando o repositório estiver pronto e você autorizar a publicação, coloque o workflow na branch padrão. No GitHub, abra **Actions → Publicar versão Windows → Run workflow**, informe uma tag nova e selecione a branch ou tag de origem.

O único gatilho é `workflow_dispatch`. O workflow usa `GITHUB_TOKEN` para criar o rascunho e anexa o launcher como `Tech.Repair.Simulator.exe` com o rótulo `Tech Repair Simulator.exe`. Ele confere o nome do download e o rótulo antes de publicar. O anúncio do Discord aponta para a página da release publicada. Se a execução falhar após criar um rascunho, confira os arquivos e a tag no GitHub antes de repetir a publicação.
