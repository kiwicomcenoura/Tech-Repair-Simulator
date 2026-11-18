# Inspeção visual do desktop

> A inspeção agora inclui troca manual de RAM no slot A1, travas, POST, teste
> de memória e persistência. Siga `Docs/playable-maintenance.md` para o fluxo
> atual. O roteiro abaixo documenta a primeira versão de tampa e parafusos.

Primeira etapa de desmontagem da tampa. O desktop ilustrado está desligado e
sem alimentação. Não há diagnóstico, inventário ou troca de componentes.

**Pré-condição atual:** a bancada inicia vazia. Nenhum computador de exemplo
é gerado. O roteiro de desmontagem abaixo só se aplica após um equipamento
físico válido ser fornecido e colocado por uma futura mecânica de transporte.
Por enquanto, o teste jogável é confirmar o estado vazio e o bloqueio da inspeção.
Veja `Docs/equipment-and-personal.md` para o contrato de colocação e retirada.

## Testar todas as interações

1. Pare a execução anterior, abra `Scenes/World/World.tscn` e pressione F6.
2. Aproxime-se da bancada de reparos, pressione E e clique em **Inspecionar**.
3. Clique no centro da tampa: ela deve continuar presa e explicar que faltam
   quatro parafusos.
4. Sem selecionar a ferramenta, clique em um parafuso: a interface deve pedir
   a chave Phillips, sem alterar a fixação.
5. Selecione **Phillips** e clique nos quatro parafusos, nos cantos da tampa.
   A contagem muda e os parafusos retirados aparecem na bandeja inferior.
6. Com apenas três retirados, tente abrir a tampa: a operação deve ser impedida.
7. Retire o quarto e clique na tampa, ou em **Retirar tampa**. O interior aparece.
8. Passe o mouse sobre placa-mãe, CPU/cooler, RAM, GPU, fonte, armazenamento e
   cabos. Os nomes aparecem abaixo do gabinete e também em tooltips.
9. Clique nas peças: a seleção recebe contorno ciano. É somente identificação
   visual, sem remoção ou resultados de diagnóstico.
10. Use **Voltar à bancada** ou ESC. Reabra a inspeção: a tampa deve continuar
    retirada e os parafusos na bandeja.
11. Feche toda a bancada pelo X e reabra com E. O estado também é preservado.
12. Clique na tampa apoiada à direita do gabinete, ou em **Recolocar tampa**.
    Ela volta sem parafusos fixados automaticamente.
13. Com a Phillips, clique nos quatro pontos para recolocar os parafusos.
    A tampa fica presa novamente. Enquanto instalada, cada ponto alterna entre
    parafuso fixado e retirado; com Mãos selecionadas, essa ação é bloqueada.
14. ESC dentro da inspeção volta à bancada; ESC novamente fecha a bancada.
    O movimento permanece bloqueado em ambas as telas e volta ao fechar.

O estado dura enquanto a instância da oficina estiver carregada. Reiniciar a
cena ou o jogo inicia uma nova sessão; não há salvamento em disco nesta etapa.

## Organização e recursos originais

- `Scenes/UI/DesktopInspection.tscn`: interface ampliada reutilizável.
- `Scripts/Inspection/inspection_session.gd`: tampa, quatro parafusos,
  ferramenta e seleção, separados da apresentação.
- `Scripts/Inspection/desktop_canvas.gd`: desenho, áreas clicáveis alinhadas
  aos PNGs, nomes sob o mouse, destaques e bandeja de parafusos.
- `Scripts/Inspection/desktop_inspection.gd`: controles e mensagens contextuais.
- `Assets/Inspection/desktop_open.png`: gabinete e componentes em pixel art
  original, RGBA transparente, 320 × 240 pixels.
- `Assets/Inspection/desktop_lid.png`: tampa lateral em uma camada independente.
- `Assets/Inspection/phillips.png`: ícone original da chave Phillips.
- `Tools/build_inspection_art.gd`: gerador determinístico dos três PNGs.

O estado pertence aos dados do equipamento físico, não à interface da bancada,
para sobreviver às trocas de tela e à retirada e recolocação do mesmo objeto.
A oficina, o Player, o script de movimento e a câmera não
foram alterados. O tema e as quatro abas da interface continuam disponíveis.

## Validação executável

```sh
godot --headless --path . --script res://Tools/verify_desktop_inspection.gd
godot --headless --path . --script res://Tools/verify_maintenance_ui.gd
godot --headless --path . --script res://Tools/verify_player.gd
```

Com a bancada vazia, o teste verifica os bloqueios e não cria equipamento para
executar o fluxo positivo de desmontagem. O roteiro visual anterior permanece
no teste para uso com um equipamento realmente fornecido. Sem `--headless`, acrescente
`-- --capture` para renderizar capturas da tampa aberta e fechada.

Capturas reais em `Docs/Previews/desktop-inspection-open.png` e
`Docs/Previews/desktop-inspection-closed.png`.
Backup anterior: `Backups/desktop-inspection-20261116-185714/`.
