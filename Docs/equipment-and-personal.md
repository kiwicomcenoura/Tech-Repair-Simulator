# Bancada vazia e computador pessoal

> Atualização: o primeiro fluxo físico jogável está descrito em
> `Docs/playable-maintenance.md`. A bancada ainda inicia vazia, mas um jogo novo
> recebe gabinete e RAM na área de recebimento. E transporta e coloca os objetos;
> a Loja de Peças agora possui um catálogo mínimo de RAM com entregas físicas.
> O registro canônico e o save desse fluxo substituem a ausência de inventário
> e persistência descrita na etapa original abaixo.

## Teste no jogo

1. Pare o jogo, abra `Scenes/World/World.tscn` e execute com F6.
2. Aproxime-se da bancada de reparos, pressione E: a interface deve mostrar
   **Nenhum equipamento na bancada**, sem gabinete, parafusos ou peças.
3. Inspecionar, Iniciar diagnóstico, Substituir peça e Finalizar manutenção
   devem estar desabilitados. As abas continuam navegáveis, com estados vazios.
4. Feche por X ou ESC e ande até o computador da mesa.
5. Pressione E para abrir **Computador da oficina**. Ele inicia desligado.
6. Clique **Ligar computador**: aparece o boot TechOS, com progresso local
   de aproximadamente 3,2 segundos, seguido da área de trabalho.
7. Os seis ícones abrem janelas de estados vazios. A navegação do sistema está
   funcional, mas nenhum aplicativo possui operações de negócio ou dados reais.
8. Clique **Desligar** para encerrar as janelas, desligar e voltar ao personagem.
   Também é possível cancelar o boot. Monitor e LED acompanham a energia no cenário.
9. Fechar a janela não desliga o PC: o boot continua e o estado de energia é
   mantido durante a sessão. ESC/X fecha a interface e devolve o movimento.
10. Reabra a bancada: ela continua vazia, independentemente da energia do PC pessoal.

Não existe ainda coleta, entrega ou inventário para obter equipamentos. Nenhum
computador padrão foi colocado na bancada, nem mesmo para os testes.

## Dados reutilizáveis de equipamento

`Scripts/Equipment/equipment_data.gd` é um Resource, sem instância associada ao
World por padrão. Representa:

| Campo | Finalidade |
|---|---|
| equipment_id | ID único do equipamento real |
| equipment_type | Tipo, por exemplo desktop |
| display_name | Nome exibido |
| owner_id / owner_name | Proprietário, separado do jogador e do PC administrativo |
| components | Mapa de componentes realmente declarados |
| condition | Condição conhecida, sem diagnóstico presumido |
| maintenance_state | Estado da manutenção |
| inspection_profile | Layout visual explicitamente associado ao equipamento |

O perfil atual `desktop_atx` representa a arte já existente, com CPU, GPU, RAM,
placa-mãe, armazenamento, fonte e refrigeração. Para evitar inventar peças,
somente equipamentos desktop com esse perfil e os sete componentes declarados
liberam a inspeção. Outros tipos ou dados incompletos podem ocupar a bancada,
mas exigirão um perfil visual compatível antes de serem inspecionados.

A sessão de tampa/parafusos é criada de forma preguiçosa apenas para o equipamento
compatível, e guardada no próprio Resource em memória. Retirar e recolocar o
mesmo objeto preserva essa sessão. Salvar/carregar o jogo não foi implementado.

## Como a colocação física será identificada

O nó `Actors/RepairBench/EquipmentDock` possui o marcador `EquipmentSlot` sobre
o tampo. `place_equipment(item)` é o ponto de integração para uma futura entrega
ou ação de soltar um item **já existente no mundo**. Não cria nem clona objetos.

A chamada só aceita um Node2D com `equipment_item.gd`, dados válidos, arte visível,
presença na mesma árvore e distância de no máximo 28 pixels do marcador.
O objeto é então encaixado no marcador e o dock emite `equipment_changed`.
A interface consulta exclusivamente esse dock para exibir o equipamento.
Associar somente um Resource, aproximar o personagem ou abrir a janela não basta.

Integração futura, sem criar equipamento de exemplo:

```gdscript
# item_ja_existente foi fisicamente solto junto ao marcador pela mecânica futura.
var aceito: bool = dock.place_equipment(item_ja_existente)

# parent_no_mundo já existe; a posição de retirada deve ficar fora da área de apoio.
var retirado: Node2D = dock.remove_equipment(parent_no_mundo, posicao_de_retirada)
```

`remove_equipment` devolve o mesmo objeto, sem apagá-lo ou recriá-lo. Alterações
futuras nos metadados devem chamar `emit_changed()` no Resource. O dock acompanha
a validade do objeto, sua visibilidade, posição e parent mesmo durante uma pausa.
Remover, mover, esconder ou liberar o objeto invalida a associação e fecha a
inspeção. Nenhum gabinete residual continua sendo desenhado após desvincular.

## Computador pessoal separado

- `Scripts/PersonalComputer/personal_computer.gd`: controlador do PC fixo e
  estados OFF, BOOTING e ON. Não utiliza EquipmentData ou EquipmentItem.
- `Scripts/PersonalComputer/personal_computer_ui.gd` e
  `Scenes/UI/PersonalComputerUI.tscn`: tela de energia, boot e reservas de aplicativos.
- `Scripts/World/interaction_range.gd`: apenas proximidade compartilhada; escolhe
  a interação mais próxima para não sobrepor prompts entre mesa e bancada.

O PC pessoal não pode ser passado como equipamento para o dock. Mensagens,
clientes, loja, finanças, marketing e arquivos têm apenas janelas de estados vazios.
Não há contas reais, redes, APIs, navegador ou serviços externos.
Veja `Docs/techos.md` para os controles da área de trabalho e o gerenciador de janelas.

## Verificação

```sh
godot --headless --path . --script res://Tools/verify_equipment_and_personal.gd
godot --headless --path . --script res://Tools/verify_maintenance_ui.gd
godot --headless --path . --script res://Tools/verify_desktop_inspection.gd
godot --headless --path . --script res://Tools/verify_player.gd
```

Os testes não instanciam dados nem objetos de equipamento. Validam o estado vazio,
as rejeições de colocação inválida, a separação do PC fixo, energia, boot, reservas
desabilitadas e os controles existentes. O fluxo positivo de colocar/retirar um
equipamento real não foi executado porque não foi gerado um equipamento de teste.
As mecânicas de inspeção anteriores estão preservadas para essa integração futura.

Backup: `Backups/empty-bench-personal-pc-20261116-200944/`.
