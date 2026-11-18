# Manutenção, inventário, armário e TechMarket

Implementação de 16/11/2026. A oficina, o jogador, a câmera e as animações existentes foram preservados. O backup anterior a esta alteração está em `Backups/components-storage-shop-20261116-224403/`.

## Como iniciar

Pare a execução anterior e rode `Scenes/World/World.tscn` com F6, ou o projeto com F5 no editor. O salvamento existente é reutilizado: não é necessário reiniciar nem apagar seu progresso. A bancada continua vazia até um gabinete físico ser colocado nela. Em um jogo novo, o recebimento existente oferece gabinete e RAM de reposição; nenhum PC é criado pela inspeção.

## Teclas

| Tecla | Função |
|---|---|
| WASD | Movimento e diagonais existentes |
| E | Interagir, desembalar, pegar, soltar e colocar na bancada |
| E junto do armário | Abrir estoque e inventário, inclusive enquanto segura uma peça |
| I | Abrir/fechar inventário fora das outras interfaces |
| Shift+E junto da bancada | Transportar gabinete desligado |
| 1 na inspeção | Mãos, para componentes, conectores e travas |
| 2 na inspeção | Chave Phillips, após liberar ferramentas na oficina |
| ESC | Voltar/fechar a interface atual; cancelar confirmação de compra |
| F5 / F9 no jogo | Salvar / restaurar |

O inventário bloqueia o movimento enquanto está aberto. Possui 12 espaços de componentes, e o armário 6. Gabinetes continuam sendo transportados nas mãos. Um item tem uma única localização; o armário só pode ser acessado de perto. No inventário, clique em uma peça para carregá-la; uma peça já carregada oferece **Guardar no inventário**. No armário, clique na peça escolhida para transferi-la entre estoque e inventário. Caixas devem ser desembaladas antes da instalação.

## Testes e resultado da RAM

1. Coloque o gabinete físico na bancada e pressione E para abrir.
2. Na aba **Testes**, clique **Iniciar POST** e aguarde. A RAM defeituosa do recebimento pode impedir o boot, mas ainda pode ser testada com alimentação, placa-mãe, CPU e cooler operacionais.
3. Clique **Testar RAM**. A aba **Componentes** agora consulta a saúde e o resultado da unidade instalada, em tempo real: por exemplo, `8% · Quebrado`, em vez do texto fixo `não testado`.
4. No seletor da aba **Testes**, escolha CPU, GPU, placa-mãe, armazenamento, fonte ou refrigeração e clique **Testar componente**. Aguarde a verificação de 1,8 segundo. O resultado fica associado à própria peça, acompanha o item retirado e é salvo.
5. Desligar cancela um teste em andamento. Peças ausentes, soltas ou desconectadas bloqueiam seu teste. O POST também reprova montagem incompleta. Os testes são verificações básicas do modelo simulado do jogo, não benchmarks completos: não há temperaturas, FPS ou tensões inventadas.

## Desmontagem e remontagem visual

Abra as ferramentas com E no cenário para liberar a Phillips. Entre em **Inspecionar** ou **Trocar componente**, desligue o PC, solte os quatro parafusos da tampa com 2 e retire a tampa. Passe o mouse nos pontos para ver seus nomes e estado. Azul-ciano indica conexão; âmbar indica liberação. Os parafusos mudam entre fixados e alojamentos vazios.

| Peça | Fixação e liberação |
|---|---|
| RAM | Mãos: abrir as duas travas A1, depois clicar no módulo |
| GPU | 2 parafusos de suporte, energia e trava PCIe |
| SSD SATA | 4 parafusos, cabo SATA de dados e SATA de energia |
| Fonte | 4 parafusos e chicote de energia |
| Cooler | 4 parafusos e conector CPU FAN; remover antes da CPU |
| Processador | Somente alavanca do socket, sem parafusos; cooler precisa estar retirado |
| Placa-mãe | 6 parafusos, ATX 24 pinos, EPS CPU e painel frontal; retirar RAM, GPU, cooler e CPU antes |

Use a Phillips em cada parafuso e Mãos em cada conector/trava. Depois clique no corpo da peça para retirá-la. Ela desaparece do gabinete e aparece na bandeja; se a bandeja de quatro peças estiver cheia, vai para o inventário disponível. Se ambos estiverem cheios, a retirada é bloqueada.

Para remontar, selecione a peça no seletor **PEÇAS · INVENTÁRIO / BANDEJA**, use Mãos e clique no encaixe vazio correspondente. Instale placa-mãe, CPU, cooler, GPU, armazenamento, fonte e RAM; reconecte e reaperte os pontos de cada peça. CPU e cooler usam o socket fictício TR4. RAM precisa corresponder à DDR da placa-mãe; DDR5 não encaixa na placa DDR4. Selecionar uma peça não a instala automaticamente. Peças guardadas no armário precisam primeiro ser retiradas para o inventário.

Tampa, parafusos, conectores, travas, peças e conhecimento dos testes permanecem ao fechar a janela e ao salvar/restaurar. Salvamentos antigos recebem as fixações adicionais sob demanda, preservando os itens e a RAM já testada.

## Loja

Abra o computador da oficina, ligue-o e entre no TechMarket. O catálogo oferece as sete categorias de componentes, com RAM DDR4 e DDR5. Filtre pela categoria. Ao passar o mouse ou focar uma linha pelo teclado, o cartão lateral mostra a imagem original pixel art e os dados do produto.

Clique no produto para abrir **Você tem certeza que quer comprar esse item?**. **Sim** é verde e **Não** é vermelho; ESC também cancela. Nenhum crédito é debitado antes do Sim. A confirmação gera uma única compra e entrega física, sem instalação automática. Saldo insuficiente bloqueia a compra. O SSD novo vem sem sistema inicializável, e pode ser testado sem ser tratado como um disco com sistema instalado.

Os identificadores internos foram retirados das legendas e listas visíveis. Eles continuam no modelo e no salvamento para distinguir unidades do mesmo modelo e impedir clonagem/perda de peças.

## Verificação executada

`Tools/verify_components_inventory.gd` exercita cliques reais nos testes, parafusos e conexões, desmontagem e remontagem completas, resultado da RAM na aba Componentes, transferências selecionadas, filtros, imagens de produtos, cancelamento/aceite e cobrança única. A mesma suíte pode ser executada com `--capture` em renderização para salvar as telas em `.godot/components-*.png`, em resolução 1360×768. Os testes usam sessões isoladas e não alteram o salvamento do jogador.

Resultado final: oito suítes de regressão, 536 verificações, zero falhas. A suíte nova também passou com renderização OpenGL em 1360×768 (116 verificações). Capturas revisadas estão em Docs/Previews/ComponentsInventory/. O ambiente headless emite um aviso de certificados do sistema; não houve erro de script/cena nas execuções finais.

## Revisão visual e fixações — 16/11/2026

Backup: `Backups/detailed-hardware-20261116-231635/`.

As nove camadas de hardware agora são originais em resolução 3×, geradas por `Tools/build_component_layers.gd`. O gabinete completo usa 960×720 pixels, mantendo a geometria lógica e o filtro Nearest. Foram detalhados metal, aletas, heatpipes, PCB, trilhas, capacitores, contatos, conectores, etiquetas, RAM e cabos. Loja e inventário reutilizam essas camadas detalhadas.

A GPU passou a ser representada **de perfil**, perpendicular à placa-mãe: borda do PCB junto ao PCIe, dissipador abaixo, ventiladores voltados para o fundo do gabinete. Seus dois parafusos ficam **no suporte traseiro**, à esquerda da inspeção, e não nas extremidades do dissipador. A trava PCIe está na extremidade do slot, e a alimentação na borda da GPU. Os quatro parafusos da fonte também foram deslocados para o painel traseiro. A placa-mãe usa seis pontos de espaçadores, o cooler quatro fixações próprias e o SSD quatro pontos de sua bandeja. Não há parafusos na CPU nem na RAM. A tampa continua com quatro fixações de painel.

A montagem foi usada como referência de geometria: [guia oficial ASUS de instalação PCIe](https://www.asus.com/support/faq/1047391/). A representação continua sendo uma ilustração 2D simplificada, não um modelo 3D de um fabricante.

Para conferir: reinicie World.tscn com F6, coloque um gabinete na bancada, abra Inspecionar, desligue, retire os parafusos da tampa com 2 e remova a tampa. Passe o mouse na margem esquerda: as legendas identificam os parafusos do suporte traseiro. Solte os dois da GPU, libere energia e trava com 1 e clique no corpo da placa para retirar. Reinstale selecionando a peça e clicando no slot vazio; fixe e reconecte os mesmos pontos. Saves anteriores mantêm o estado das fixações; não é necessário apagar progresso.

Capturas da execução real em 1360×768 estão em `Docs/Previews/DetailedHardware/`.
