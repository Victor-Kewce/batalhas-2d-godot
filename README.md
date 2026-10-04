# Batalhas 2D em Godot - Victor Bispo

Meu protótipo combina ataque por precisão, esquiva de projéteis e três dificuldades. No meu projeto, a lógica da batalha fica separada da interface.

![Captura real do meu protótipo](https://victor-bispo-portfolio.netlify.app/assets/batalhas.png)

## O que tenho neste projeto

- Ataque com marcador de precisão e fase de esquiva de oito segundos.
- Três padrões de projéteis: chuva vertical, corredores horizontais e disparos com mira travada.
- Menu, seleção de dificuldade, pausa, vitória, derrota e reinício.

## Minha participação

Usei IA no desenvolvimento deste projeto. Nos meus projetos pessoais, revisei e melhorei parte dos códigos.

## Como executar meu protótipo

Abra `project.godot` no Godot 4 e pressione F6 na cena principal ou F5 para executar o projeto. Nos registros originais do meu projeto, a validação usou Godot 4.7.2 e renderizador Compatibility.

Controles: WASD/setas para movimento, Shift para reduzir a velocidade, Espaço/Enter para confirmar o ataque, Esc para pausa, R para reinício e B para voltar ao menu. As teclas 1/2/3 selecionam a dificuldade no menu.

## Organização do meu código

- `battle.gd`: estados, energia, precisão, padrões e colisões.
- `main.gd`: entrada, desenho da interface e apresentação dos estados.
- `main.tscn`: cena principal.
- `tests/verify_battle.gd`: verificações da lógica.
- `tests/verify_scene.gd`: verificações da cena e da entrada.

## Testes do meu projeto

Com o executável Godot disponível no PATH:

```sh
godot --headless --path . --script res://tests/verify_battle.gd
godot --headless --path . --script res://tests/verify_scene.gd
```

Tenho registros de 8.669 verificações sem falhas na lógica e zero falhas na cena. Meu pacote passou por uma nova conferência em 4 de outubro de 2026, com os mesmos resultados. Reúno os [logs da publicação no meu portfólio](https://victor-bispo-portfolio.netlify.app/evidencias/batalhas.html#validacao).

Ainda preciso avaliar a dificuldade com jogadores: os ciclos completos dos testes usaram invulnerabilidade. Nos logs do meu projeto, há avisos de certificados e de gravação do log interno, além dos resultados funcionais.

[Meu portfólio](https://victor-bispo-portfolio.netlify.app/)
