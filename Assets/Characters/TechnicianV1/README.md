# Técnico — primeira versão animada

Pixel art original desenhada programaticamente em `Tools/build_player_art.gd`.
Não usa o ícone do Godot nem substitui o PNG antigo.

- `technician_atlas.png`: PNG RGBA transparente, 320 × 384 pixels, 80 quadros.
- Cada célula mede 32 × 48 pixels; escala 2 no AnimatedSprite2D, filtro Nearest.
- Linhas: down, up, left, right, down_left, down_right, up_left, up_right.
- Colunas 0–1: idle; colunas 2–9: walk.
- Idle: dois quadros a 2 FPS; walk: oito poses diferentes a 12 FPS; ambos em loop.
- Caminhada a 180 pixels/s; o ciclo acompanha a velocidade real ao deslizar em obstáculos.
- Ao virar durante a caminhada, preserva o quadro e a fase do passo atual.
- O personagem ocupa aproximadamente 40 × 84 pixels no cenário, além da sombra.
- Origem do Player nos pés; cápsula de colisão horizontal de 26 × 14 pixels.
- WASD move em oito direções; diagonais têm a mesma velocidade das direções retas.
- Cada diagonal tem sprites próprios em três quartos, com idle e caminhada.
- A direção é recalculada a cada passo de física: W+D → W+A troca imediatamente,
  sem precisar soltar W. Ao soltar as teclas, mantém a última direção diagonal.
- Ao tentar andar contra um obstáculo sem deslocamento, reproduz idle.
- A câmera segue o Player e a profundidade dos móveis continua funcionando.

Para regenerar o PNG, a partir da raiz do projeto:

```sh
godot --headless --path . --script res://Tools/build_player_art.gd
```

Para executar a validação de quadros, entrada, animações, colisão e profundidade:

```sh
godot --headless --path . --script res://Tools/verify_player.gd
```

No editor, abra `Scenes/World/World.tscn` e execute com F6. Teste WASD,
diagonais, soltura das teclas e as duas faces de cada bancada. Na cena Player,
abra o recurso SpriteFrames do AnimatedSprite2D para conferir cada animação.
Os backups estão em `Backups/animated-player-20261116-175609/`.
O backup anterior à inclusão das diagonais está em `Backups/diagonal-player-20261116-180523/`.
