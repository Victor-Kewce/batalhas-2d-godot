# Batalhas 2D em Godot — Victor Bispo

Protótipo com ataque por precisão, esquiva de projéteis e três dificuldades. A lógica da batalha fica separada da interface.

![Captura real da execução](https://victor-bispo-portfolio.netlify.app/assets/batalhas.png)

## Como executar

Abra `project.godot` no Godot 4 e pressione F6 na cena principal ou F5 para executar o projeto. O registro original de validação usou Godot 4.7.2 e renderizador Compatibility.

Controles: WASD/setas para movimento, Shift para reduzir a velocidade, Espaço/Enter para confirmar o ataque, Esc para pausa, R para reinício e B para voltar ao menu. As teclas 1/2/3 selecionam a dificuldade no menu.

## Arquitetura

- `battle.gd`: estados, energia, precisão, padrões e colisões.
- `main.gd`: entrada, desenho da interface e apresentação dos estados.
- `main.tscn`: cena principal.
- `tests/verify_battle.gd`: verificações da lógica.
- `tests/verify_scene.gd`: verificações da cena e da entrada.

Os três padrões de projéteis alternam chuva vertical, corredores horizontais e disparos com mira travada. A fase de esquiva dura oito segundos.

## Testes

Com o executável Godot disponível no PATH:

```sh
godot --headless --path . --script res://tests/verify_battle.gd
godot --headless --path . --script res://tests/verify_scene.gd
```

Os logs preservados em `docs/` registram 8.669 verificações e zero falhas funcionais na lógica, e zero falhas na cena. Esses dois logs são registros da execução anterior. Uma nova execução do pacote organizado em 4 de outubro de 2026 confirmou 8.669 verificações sem falhas e zero falhas de cena: `docs/verify_battle-publicacao.log` e `docs/verify_scene-publicacao.log`. Os ciclos completos usaram invulnerabilidade; não há validação humana da dificuldade. Os logs registram também avisos do armazenamento de certificados e de gravação do log interno no ambiente restrito de validação; os resultados funcionais acima foram produzidos apesar desses avisos.

## Participação

Projeto pessoal de Victor Bispo desenvolvido com apoio de IA. A participação informada por Victor inclui revisão e melhoria de parte dos códigos nos projetos pessoais.
