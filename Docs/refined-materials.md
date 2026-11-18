# Materiais revisados — 17/11/2026

Backup: `Backups/realistic-materials-20261117-011351/`.

A revisão substitui as ondas repetitivas da madeira por ruído coerente, grão fino e variações suaves de prancha. Mármore recebe veios estreitos e menos contraste. Concreto e metal usam granulação discreta. Paletas padrão são mais neutras; cores personalizadas existentes são respeitadas.

Os revestimentos agora usam texturas originais de 512×512 pixels, com versões próprias para piso e móveis. São 16 PNGs gerados por `Tools/build_decoration_materials.gd`, em `Assets/Decoration/`. O jogo carrega os arquivos já preparados para evitar gerar os materiais ao iniciar.

O piso personalizado usa uma superfície contínua, em vez da antiga sobreposição quadriculada. O visual Original restaura as lajotas e suas texturas anteriores. As projeções dos materiais são distintas para faces verticais e tampos, evitando deformação nos móveis. Contornos claros dos móveis foram reduzidos.

Abra o jogo com F6, pressione F2 e experimente Madeira clara, Madeira escura, Rústico, Mármore ou Concreto. A prévia permite comparar antes de Aplicar e salvar. Salvamentos, itens, colisões, personagem e inspeção permanecem preservados. Esta é uma melhoria de materiais dentro da direção de arte 2D existente, sem conversão para 3D ou fotorrealismo.

Validação: 83 verificações de materiais, personalização, cancelamento, salvamento/restauração, uso dos PNGs preparados e recuperação da visibilidade do piso Original; também aprovadas com renderização em 1360×768. Capturas finais em `Docs/Previews/RefinedMaterials/`.
