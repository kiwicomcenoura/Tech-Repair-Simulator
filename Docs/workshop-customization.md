# Personalização da oficina

Abra o menu com **F2** ou com o botão **Decorar (F2)** no canto superior direito. Ele pode ser aberto durante a circulação na oficina; feche antes a bancada, o inventário ou o TechOS. Enquanto o menu está aberto, o personagem fica parado e a oficina continua visível para prévia.

Escolha uma das seis superfícies: paredes, chão, bancada de manutenção, mesa do computador, balcão de atendimento ou armário. Cada uma guarda sua combinação independente. A personalização afeta os revestimentos do móvel: os objetos, teclado, monitor, ferramentas, componentes, posições e colisões permanecem os mesmos.

Estilos disponíveis: Original, Moderno, Madeira clara, Madeira escura, Rústico, Concreto, Mármore e Industrial. As amostras exibem a textura e a cor básica do estilo. Use as seis cores rápidas ou o seletor de cor livre para mudar o acabamento. As texturas são procedurais e seguem os eixos isométricos; nenhum download ou serviço externo é usado.

**Aplicar e salvar** confirma todas as mudanças e grava a aparência junto ao progresso existente. **Cancelar**, ESC ou F2 descarta apenas a prévia desta abertura. **Restaurar esta superfície** retorna a seleção atual ao visual original; confirme em Aplicar para salvar essa restauração. Os salvamentos antigos, sem preferências de decoração, continuam válidos e usam a aparência original. F9 restaura também os estilos e cores do salvamento.

O painel troca de lado ao selecionar a mesa do computador, para não cobrir o móvel durante a prévia. O conteúdo usa rolagem em janelas menores, mantendo Aplicar e Cancelar fixos na parte inferior.

## Estrutura

- `Scripts/World/workshop_appearance.gd`: catálogo de alvos/materiais, geração de textura, preservação do visual original e aplicação por superfície.
- `Scripts/UI/workshop_customization.gd`: menu, prévia temporária, cores, confirmação e cancelamento.
- `Scripts/Gameplay/physical_workshop.gd`: tecla F2, botão e integração com salvar/restaurar.
- `Scripts/Gameplay/workshop_ledger.gd`: validação opcional do campo `decoration` no salvamento.

Backup antes das alterações: `Backups/workshop-customization-20261117-005902/`.

## Verificações executadas

77 verificações específicas de personalização: seis alvos, oito estilos por alvo, cores independentes, aplicação por clique, cancelamento por ESC, restauração em disco, rejeição de estilos/cores inválidos, limites da interface e preservação de equipamento/colisões. A suíte também passou com renderização em 1360×768. Regressões: interface da bancada 29, personagem 141, equipamentos e computador pessoal 73, TechOS 49. Total: **369 verificações sem falhas**.

Capturas da sessão de teste: `Docs/Previews/WorkshopCustomization/preview.png` e `finished.png`. As imagens exemplificam uma combinação de materiais; o jogador continua com o visual original até escolher e aplicar suas preferências. Os testes usam um salvamento isolado e não modificam o progresso real.
