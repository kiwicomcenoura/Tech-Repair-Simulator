# Revisão gráfica de 17/11/2026

Backup anterior: `Backups/graphics-pass-20261117-004924/`.

- Camadas de inspeção aumentadas de 3× para 4×: gabinete em 1280×960, placa-mãe em 580×460. O enquadramento continua automático e a janela mantém 1360×768. RAM preserva suas proporções, slot com ouro somente à direita quando vazio e borda superior completa.
- Quinze capacitores incorporados à arte da placa-mãe: oito na região do VRM junto ao socket da CPU, dois junto à alimentação dos DIMMs e cinco na região de áudio inferior esquerda. MOSFETs e componentes SMD complementam essas regiões, sem obstruir os encaixes. Não são peças removíveis nesta etapa.
- O posicionamento é uma interpretação de um layout real de placa-mãe, sem reproduzir um modelo comercial exato. Referências: [arquitetura de alimentação ASUS](https://www.asus.com/microsite/motherboard/Teamed-power-stages/) e [manual/layout H81M ASUS](https://dlcdnets.asus.com/pub/ASUS/mb/LGA1150/H81M-A/E8599_H81M-Series.pdf?model=H81M-E).
- Texturas originais de metal e piso com 128×128 pixels; granulação mais fina. Bordas suavizadas nos elementos do cenário, realce discreto das superfícies maiores dos móveis e sombras de contato alinhadas às suas bases. `Scripts/World/workshop_finish.gd` é exclusivamente visual.
- Cenário, peças, jogador, colisões, movimentação, câmera, interface e salvamentos foram mantidos. Os capacitores acompanham a camada da placa-mãe ao retirá-la, sem elementos soltos no gabinete.

## Conferir no jogo

Pare a execução e rode World.tscn com F6. Observe o piso, contornos e sombras dos móveis. Coloque o gabinete na bancada, abra a inspeção e retire a tampa. Use Mãos e a roda do mouse para aproximar a região da CPU e da RAM. Retire a GPU para visualizar também a região de áudio. Botão direito retorna à vista completa.

## Validação

325 verificações aprovadas: personagem (141), interface da bancada (29), equipamentos/computador pessoal (73), TechOS (49), arte e integração gráfica (33). Esta última também foi executada com renderização OpenGL em 1360×768. Capturas revisadas: `Docs/Previews/GraphicsPass/workshop.png` e `inspection.png`. As sessões de teste não alteraram o progresso do jogador.
