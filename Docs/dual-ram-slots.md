# RAM em pé e dois slots independentes

Backup: `Backups/dual-upright-ram-20261117-012419/`.

A inspeção apresenta os DIMMs de perfil, elevados acima da placa-mãe: a face estreita do módulo, a lateral e a sombra de encaixe dão a leitura de uma peça perpendicular à placa-mãe. A placa-mãe agora possui dois slots, **A1 à esquerda e A2 à direita**. Capacitores de alimentação foram reposicionados para não ocupar o espaço do slot novo.

A2 começa vazio. Não há geração automática de uma segunda RAM. Traga uma peça real e compatível para o inventário, bandeja ou mãos e selecione-a na inspeção.

## Usar

1. Desligue o computador, retire os quatro parafusos da tampa e remova-a.
2. Selecione **Mãos (1)**. Em A2, abra suas duas travas, superior e inferior.
3. Selecione uma RAM disponível e clique no slot vazio da direita. Feche as duas travas de A2 para completar a montagem.
4. A1 e A2 são independentes: retirar uma peça ou abrir suas travas não altera o outro slot. Cada peça mantém sua identidade, condição e resultado de teste.
5. Ligue e aguarde o POST. É possível iniciar com apenas uma RAM saudável em A1 **ou** A2. Um módulo defeituoso, incompatível ou sem ambas as travas fechadas reprova a configuração; um slot vazio não exige travas fechadas.
6. **Testar RAM** verifica todos os módulos presentes e registra o resultado em cada unidade. A aba Componentes mostra A1 e A2 em linhas separadas. Não foram adicionados bônus de desempenho nem simulação de dual channel.
7. Para retirar um módulo, desligue, abra apenas as travas do slot desejado e clique no módulo. A peça vai para a bandeja ou inventário disponível. A placa-mãe não pode ser retirada enquanto houver RAM em qualquer dos dois slots.

Slots, peças e quatro travas são preservados no salvamento. A RAM dos saves anteriores continua em A1; A2 é vazio até a instalação manual. Ambos os slots e suas travas desaparecem quando a placa-mãe é retirada.

## Validação

Suíte específica com 30 verificações de cliques reais, travas independentes, DDR incompatível, módulo defeituoso, POST somente com A2, resultados de teste por peça e salvar/restaurar as posições. Também executada com renderização em 1360×768. Regressões aprovadas: bancada vazia 29, acesso aos testes 20 e equipamentos/computador pessoal 73. Capturas em `Docs/Previews/DualRAM/`.
