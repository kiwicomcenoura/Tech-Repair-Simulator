# Interface da Bancada de Manutenção

> Fluxo atual: `Docs/playable-maintenance.md`. O gabinete é recebido fisicamente
> no cenário e precisa ser transportado até a bancada. A inspeção permite trocar
> a RAM; este documento também conserva as notas da etapa inicial da interface.

Interface exclusiva da bancada de reparos. A bancada inicia vazia e não gera
um desktop de demonstração. A inspeção com tampa e parafusos está preservada,
mas só é liberada para um equipamento físico realmente colocado na área de apoio.
Não implementa inventário, clientes, diagnósticos funcionais nem troca de componentes.
Veja o roteiro completo em `Docs/desktop-inspection.md`.
Para a arquitetura e o computador pessoal, veja `Docs/equipment-and-personal.md`.

## Testar

1. Pare qualquer execução anterior e abra `Scenes/World/World.tscn`.
2. Pressione F6 e aproxime o personagem da bancada de reparos, ao fundo.
3. Quando aparecer **E — Abrir bancada**, pressione E.
4. Navegue por Visão Geral, Diagnóstico, Componentes e Testes.
5. Confirme **Nenhum equipamento na bancada**, sem gabinete, parafusos ou peças.
   Inspecionar, Diagnóstico, Substituir e Finalizar devem estar indisponíveis.
6. Tente andar: a oficina fica pausada enquanto a interface está aberta.
7. Feche pelo X ou ESC. O controle volta ao personagem.
8. O computador da mesa abre uma interface pessoal separada, com energia e boot;
   ele não é associado à bancada e não abre a inspeção.

## Organização

- `Scenes/UI/MaintenanceBenchUI.tscn`: CanvasLayer, janela, painéis, abas,
  containers responsivos, prompt e controles com nomes claros.
- `Themes/maintenance_bench.tres`: cores, fontes, estilos, foco e estados.
- `Scripts/UI/maintenance_bench_ui.gd`: abertura, fechamento, foco e pausa.
- `Scripts/UI/pc_blueprint.gd`: ilustração vetorial escalável de estado vazio.
- `Scripts/World/maintenance_bench_interaction.gd`: proximidade e tecla E.
- `Scenes/Workshop/RepairBench.tscn`: nó filho Interaction. Sua geometria e
  colisão não foram alteradas.
- `Scenes/World/World.tscn`: instância da interface.
- `project.godot`: ação interact, tecla física E.

A proximidade usa a distância até o polígono de colisão da bancada, com raio
de 48 pixels configurável no nó Interaction. Os caminhos do personagem e da
interface são propriedades exportadas para facilitar a reutilização da cena.
O script do personagem não foi modificado: a pausa bloqueia movimento e mantém
a câmera estável, enquanto a interface continua recebendo entrada.

A janela inicia sempre na Visão Geral. Sem equipamento, campos mostram
travessões e slots vazios; o gabinete fica oculto. Os indicadores de teste
mostram **Sem medição**. Nenhum resultado é simulado.

## Validação

```sh
godot --headless --path . --script res://Tools/verify_maintenance_ui.gd
godot --headless --path . --script res://Tools/verify_player.gd
```

O primeiro teste verifica proximidade, tecla E, abas, ações desabilitadas,
pausa, retomada do movimento, ESC e X. Para gerar capturas das quatro abas,
execute sem `--headless`, acrescentando `-- --capture`; elas são salvas em
`.godot/maintenance-preview-0.png` a `.godot/maintenance-preview-3.png`.

Uma captura atual da bancada vazia está em `Docs/Previews/empty-maintenance-bench.png`.
Backup dos arquivos anteriores: `Backups/maintenance-ui-20261116-183223/`.
