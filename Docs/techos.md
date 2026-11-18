# TechOS

> Atualização: a Loja de Peças agora oferece um catálogo mínimo de RAM com saldo
> de jogo, transações e entregas físicas. Os demais aplicativos continuam sem
> operações de negócio. Veja `Docs/playable-maintenance.md`.

Sistema operacional fictício, local e integrado ao computador da oficina.
Não há mensagens reais, clientes, compras, finanças ou acesso ao sistema de
arquivos do computador real. Os seis aplicativos apresentam estados vazios.

## Como testar

1. Pare qualquer execução anterior, abra `Scenes/World/World.tscn` e pressione F6.
2. Aproxime-se do computador da mesa e pressione E. Clique **Ligar computador**.
3. Após a inicialização do TechOS, abra um aplicativo com um clique no ícone
   do desktop ou pelo menu **Iniciar**.
4. Abra outros aplicativos: cada um possui uma única janela. Abrir novamente
   o mesmo aplicativo restaura e traz sua janela para a frente.
5. Arraste pelo título. A janela deve parar nos limites da área útil, acima
   da barra de tarefas. Soltar o mouse fora da janela encerra o arraste.
6. Clique em uma janela visível ou em sua entrada na barra para alternar.
   Ctrl+Tab também alterna entre os aplicativos abertos.
7. Clique no botão **—** para minimizar. Clicar na entrada ativa da barra
   também minimiza; clicar novamente restaura. O botão **×** fecha a janela.
8. Abra Iniciar e teste os seis atalhos. ESC ou clicar fora fecha o menu.
9. **Voltar à oficina** ou ESC, com o menu fechado, fecha a interface e devolve
   o controle sem desligar. Reabrir o PC mantém as janelas da sessão ligada.
10. **Desligar**, na barra ou no menu Iniciar, encerra todos os aplicativos,
    desliga o PC e devolve o controle ao personagem. Um novo boot começa sem janelas.
11. Reabra a bancada de manutenção: ela continua vazia e bloqueia a inspeção
    enquanto não houver um equipamento físico associado.

O relógio é fictício: começa às 09:00 do Dia 01 e avança um minuto a cada seis
segundos de execução da oficina, inclusive com o PC desligado. Não lê a hora,
data ou calendário do sistema operacional real. O tempo é mantido na sessão,
sem salvamento entre reinicializações do jogo.

## Organização

- `Scenes/UI/TechOS/Desktop.tscn`: wallpaper, ícones, área útil, barra e menu Iniciar.
- `Scripts/TechOS/desktop.gd`: atalhos, janelas únicas, foco, minimização, barra,
  relógio fictício, atalhos de teclado e sinais de energia/saída.
- `Scenes/UI/TechOS/AppWindow.tscn`: janela reutilizável com cabeçalho, controles
  e estado vazio; não contém lógica de clientes ou operações financeiras.
- `Scripts/TechOS/app_window.gd`: arraste, limites, destaque de foco e abertura suave.
- `Scripts/TechOS/app_icon.gd`: seis ícones vetoriais originais e escaláveis.
- `Scripts/TechOS/wallpaper.gd`: papel de parede original com geometria azul-escura.
- `Themes/techos.tres`: estilos independentes, transparências discretas e estados
  de foco/hover. O tema da bancada não foi alterado.
- `Scripts/PersonalComputer/personal_computer_ui.gd`: integração com energia,
  inicialização, pausa do jogo e retorno ao personagem.

O TechOS não cria nem associa equipamentos à bancada. O estado de tampa e
parafusos do sistema de manutenção não foi alterado.

## Verificação

```sh
godot --headless --path . --script res://Tools/verify_techos.gd
godot --headless --path . --script res://Tools/verify_equipment_and_personal.gd
godot --headless --path . --script res://Tools/verify_maintenance_ui.gd
godot --headless --path . --script res://Tools/verify_player.gd
```

O teste do TechOS usa eventos reais de mouse para abrir, fechar, minimizar,
restaurar, focar e arrastar janelas, inclusive além dos limites. Também testa
Ctrl+Tab, o relógio, energia, retorno do movimento e a bancada ainda vazia.
Sem `--headless`, acrescente `-- --capture` para capturas reais em 1360 × 768.

Prévias: `Docs/Previews/techos-desktop.png`, `techos-start.png` e `techos-apps.png`.
Backup anterior: `Backups/techos-20261116-204247/`.
