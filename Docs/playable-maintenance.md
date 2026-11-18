> Documento histórico da etapa RAM. A implementação atual está documentada em [Manutenção, inventário e loja](components-inventory-market.md), incluindo desmontagem de todas as peças e o novo armário.

# Primeira manutenção jogável — RAM

Esta etapa implementa um fluxo completo e físico de manutenção de RAM. Não
implementa toda a desmontagem de GPU, SSD ou placa-mãe. Esses componentes têm
IDs, modelos, dados individuais persistidos, sprites originais e identificação
visual, mas permanecem instalados e somente identificáveis nesta versão.

## Começar

Pare a execução anterior, abra `Scenes/World/World.tscn` e execute com F6.
Em um jogo novo há um gabinete na área **RECEBIMENTO**, uma caixa de RAM DDR4,
uma caixa de ferramentas fixa perto da prateleira e 500 créditos de jogo.
A bancada começa vazia. Se já houver um save válido, ele é restaurado e esse
kit inicial não é gerado novamente.

Os modelos são fictícios. O PC recebido possui um problema de memória; a saúde
exata não é mostrada automaticamente. O kit de reposição não é instalado pelo jogo.

## Controles no cenário

| Entrada | Ação |
|---|---|
| WASD | Movimento existente, inclusive diagonais |
| E perto de objeto solto | Pegar uma unidade; se for caixa, primeiro desembalar |
| E enquanto carrega | Soltar no chão livre, colocar na bancada ou guardar na prateleira |
| E perto da bancada, mãos vazias | Abrir a interface de manutenção |
| Shift+E perto da bancada | Retirar e carregar o gabinete, desde que esteja desligado |
| E perto da caixa de ferramentas | Liberar a chave Phillips na inspeção |
| E junto da prateleira, mãos vazias | Retirar a primeira peça armazenada; uma por vez |
| F5 / botão Salvar | Salvar progresso |
| F9 / botão Restaurar | Recarregar progresso, fechando as interfaces com segurança |

Clique na janela do jogo para dar foco antes de usar teclas de função. Os
botões Salvar/Restaurar no canto superior direito são alternativas às teclas.
Cada ação que altera itens ou progresso também dispara um autosave.

## Roteiro completo de RAM

1. Vá à caixa azul **FERRAMENTAS**, à esquerda do balcão, e pressione E.
2. Vá ao gabinete no **RECEBIMENTO**, à direita do balcão, e pressione E.
   O gabinete aparece nas mãos. Você não pode transportar uma segunda unidade.
3. Leve-o até a frente da bancada de reparos, ao fundo, e pressione E para
   colocá-lo sobre o tampo. A inspeção só é liberada depois dessa associação física.
4. Pressione E novamente e clique em **Inspecionar**.
5. Opcionalmente clique **Ligar PC**: o POST deve detectar erros na RAM original.
   Tente um parafuso: a desmontagem é bloqueada enquanto o equipamento estiver ligado.
6. Clique **Desligar PC**, selecione **Phillips** e clique nos quatro parafusos
   nos cantos da tampa. Clique na tampa para retirá-la.
7. Selecione **Mãos**. A RAM funcional desta etapa é o slot **A1**, primeiro
   slot à direita do cooler. Os outros slots são somente representação visual.
8. Clique nas duas travas, superior e inferior, do slot A1. Fechadas, elas
   impedem a retirada. Com ambas abertas, clique no módulo para retirá-lo.
9. A RAM retirada aparece na bandeja física da bancada. Ela mantém o mesmo ID;
   não é apagada nem clonada. Ligar sem RAM deve falhar por componente ausente.
   Para transportá-la, feche a interface e aproxime-se da face diagonal da bancada
   em frente à peça até aparecer **E — Pegar**. Não é preciso entrar no móvel.
10. Volte à oficina pelo X/ESC. Abra a caixa de RAM no recebimento com E,
    pressione E de novo para pegar o módulo e leve-o à bancada.
11. Opcionalmente guarde a RAM na prateleira com E. Para usá-la depois, retire-a
    com E e transporte-a até a bancada. Estoque da prateleira não se teletransporta
    para o gabinete.
12. Com a RAM nas mãos, pressione E junto da bancada para deixá-la na bandeja.
    Pressione E novamente e entre na inspeção. Tampa e parafusos continuam no
    estado anterior, mesmo se você fechar e reabrir a bancada.
13. No seletor **RAM À MÃO / BANDEJA**, escolha a unidade de reposição. Cada
    opção mostra ID resumido e origem, para distinguir módulos de mesmo modelo.
    O tooltip mostra apenas informações conhecidas. Selecionar não instala.
14. Com **Mãos**, ambas as travas abertas e o slot vazio, clique no slot A1.
    Uma RAM DDR4 é aceita; DDR5 é recusada e permanece na bandeja.
15. Feche as duas travas. Ligar antes disso deve falhar por montagem incompleta.
16. Clique **Ligar PC** e aguarde o POST. Com a DDR4 de reposição corretamente
    instalada, o sistema inicializa. Nenhuma etapa de montagem foi automatizada.
17. Clique **Testar RAM**, na inspeção ou na aba **Testes**. O teste revela a saúde real do módulo instalado e
    sua categoria. Outras peças continuam com condição desconhecida.
18. Para fechar o gabinete, desligue, recoloque a tampa e use a Phillips nos
    quatro pontos. A RAM instalada não muda ao manipular a tampa.

Os comandos também estão disponíveis diretamente na aba **Testes** da bancada:
**Iniciar POST**, **Ligar/Desligar PC** e **Testar RAM**. Não é necessário abrir
a inspeção só para testar. A aba Diagnóstico também oferece **Iniciar POST**.

Para testar a RAM, ligue o PC, aguarde o POST e mantenha um módulo compatível
instalado com as duas travas fechadas. O diagnóstico básico da bancada também
funciona quando a RAM defeituosa impede o boot do sistema operacional: a falha
no POST não bloqueia o botão. O teste revela a saúde real e não corrige a peça.
Quando alguma condição impede a ação, a aba mostra a instrução e o botão exibe
o motivo no tooltip. Temperatura e estabilidade continuam explicitamente indisponíveis.

As legendas de interação do cenário aparecem em um painel escuro com borda
discreta, cantos arredondados e largura ajustada ao texto, sem prompt duplicado.

## TechMarket e entregas

No computador pessoal, pressione E, ligue o TechOS e abra **Loja de Peças**.
O catálogo funcional inicial oferece DDR4 (150 créditos) e DDR5 (180 créditos).
Comprar debita o saldo uma vez, registra uma transação com ID e programa uma
entrega física em três segundos. A caixa chega ao recebimento e precisa ser
aberta com E. Nada é adicionado automaticamente à bancada ou ao gabinete.
Fechar a loja não cancela nem duplica uma entrega. A fila e o saldo são salvos.

Comprar DDR5 é uma forma de testar a rejeição de incompatibilidade. A placa-mãe
do primeiro PC usa DDR4; o módulo recusado continua sendo sua unidade física.
Clientes, vendas, receitas, relatórios financeiros, marketing e mensagens não
foram implementados. Finanças continua sendo uma janela de preparação.

## Saúde conhecida e saúde real

| Saúde real | Categoria |
|---|---|
| 90–100% | Perfeito estado |
| 70–89% | Bom |
| 45–69% | Mediano |
| 15–44% | Ruim |
| 0–14% | Quebrado |

Cada unidade possui saúde e possíveis defeitos próprios. Na interface, itens
não testados mostram **Condição desconhecida**. Não se usa cor do sprite para
entregar a condição oculta. O POST calcula seus sintomas a partir dos componentes
instalados, presença das peças essenciais, saúde, DDR, travas e armazenamento
inicializável. Não há simulação elétrica ou térmica detalhada nesta versão.

## Persistência e fonte de verdade

- `Scripts/Gameplay/workshop_ledger.gd`: registro único por ID, localização,
  proprietário físico, componentes instalados, saúde/descoberta, transações e fila.
- `Scripts/Gameplay/physical_workshop.gd`: E, transporte, projeção dos objetos,
  integração com EquipmentData/dock/inspeção e salvamento.
- `Scenes/Items/PhysicalItem.tscn`: representação reutilizável com sprite;
  gabinetes no chão têm colisão. A cena não mantém outro inventário.
- `Scripts/Gameplay/techmarket.gd`: catálogo funcional mínimo dentro do TechOS.
- `Tools/build_physical_parts.gd`: gerador dos sprites originais, sem downloads.

Localizações são exclusivas: chão, carregando, prateleira, bandeja, bancada,
entrega ou instalado. Uma peça instalada não possui simultaneamente uma cópia
solta. Há limite de uma unidade carregada, um PC na bancada, seis peças na
prateleira e quatro na bandeja. Mover um item altera seu registro; atores de
cenário, Resources de equipamento e linhas da interface são projeções dele.

O save fica em `user://workshop_save_v1.json` (pasta de dados do projeto no Godot).
Inclui IDs, saúde real e conhecida, DDR, defeitos, localização, gabinete/tampa,
parafusos, travas, energia, POST, ferramentas, saldo, compras, entregas e posição
do jogador. Fechar/reabrir a cena retoma o arquivo em vez de gerar outro kit.
Janelas abertas do TechOS não fazem parte do save da manutenção.

O arquivo é escrito em `.tmp`, validado e rotacionado com `.bak`. Na leitura,
um arquivo inválido pode ser recuperado pelo backup; uma cópia corrompida é
preservada como `.corrupt`, sem substituir o backup válido. Se não houver nenhuma
cópia válida, o jogo avisa e não gera novas unidades por cima do progresso.

## O que ainda não está funcional

- Desmontagem de GPU (cabo, parafuso e trava PCIe), SSD/cabos SATA, CPU/cooler,
  fonte e placa-mãe: dados/sprites/identificação disponíveis, mecânicas adiadas.
- Compra de outros tipos de peça, vários slots RAM operáveis, encaixe por arraste,
  testes de bancada externos especializados e diagnóstico completo: não implementados.
- Ferramentas operáveis: Phillips e Mãos. A caixa não contém um sistema completo
  de ferramentas físicas transportáveis.
- Prateleira: armazenamento funcional com retirada por ordem de slot; ainda não
  há uma janela dedicada para administrar grandes estoques.

## Verificação

`Tools/verify_ram_workshop.gd` executa o fluxo com eventos reais de E e mouse,
incluindo compras, entrega, DDR incorreta, travas, POST, condições, save/load e
recuperação de arquivo corrompido. Seus arquivos ficam isolados em `.godot/`;
o save do jogador nunca é usado por esse teste.

```sh
godot --headless --path . --script res://Tools/verify_ram_workshop.gd
```

Sem `--headless`, acrescente `-- --capture` para as capturas reais em 1360 × 768.
As suítes anteriores usam `Tools/test_world.gd` para isolar o save e desativar
apenas a entrega inicial em seus cenários vazios de regressão.

Backup anterior: `Backups/playable-ram-20261116-211037/`.

