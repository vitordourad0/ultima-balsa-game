# Última Balsa

Parkour para Roblox em que você corre pelos telhados de um porto até a balsa Estrela do Porto. Atravesse a linha ciano para iniciar o cronômetro, passe pelos três checkpoints e embarque pelo pórtico amarelo. Se cair, você volta ao último checkpoint com o cronômetro em andamento. O botão **Reiniciar** e a tecla **R** devolvem você à largada. O menor tempo fica no HUD até você sair do servidor.

A pista foi dimensionada para corridas de **60 a 90 segundos**. Depois do Checkpoint 1, o caminho verde faz a volta pelos depósitos à direita. O atalho laranja segue em frente, com vãos maiores e plataformas mais estreitas. As duas rotas se encontram antes do Checkpoint 2. A borda colorida indica de onde saltar e a faixa clara indica onde pousar.

## Abrir e testar pela primeira vez

1. Instale o [Roblox Studio](https://create.roblox.com/docs/studio/setup) em Windows ou macOS. Abra `UltimaBalsa.rbxl` pelo menu **File → Open from File**.
2. Clique em **Play** (F5) na aba **Test**. Use **WASD** e **Espaço** no PC ou o analógico e o botão de pulo nativos no modo móvel. Use o mouse ou arraste a tela para girar a câmera.
3. Para simular celular no Studio, selecione **Device Emulator** na aba **Test**, escolha um telefone em modo paisagem e inicie **Play**. Para verificar toque e desempenho num Android físico, publique o lugar com acesso de teste para sua conta e abra a experiência no app Roblox.
4. Para checar dois jogadores, escolha **Server & Clients** na aba **Test**, configure **2** clientes e inicie o teste. Atravesse a largada em um cliente, espere alguns segundos e atravesse com o outro. Confira que o primeiro cronômetro começou antes. Faça um corredor cair após o Checkpoint 1 e reinicie o outro. Os dois devem manter seus próprios tempos e destinos de retorno.

### Sequência de teste no celular

| Ação | Resultado esperado |
| --- | --- |
| Na largada, olhe para a frente e atravesse a linha ciano. | A balsa é indicada pelo mastro e pela placa no horizonte. O cronômetro começa ao cruzar a linha. |
| Passe pelo Checkpoint 1 e caia no próximo vão. | Você reaparece no Checkpoint 1, com progresso de 1/3 e tempo em andamento. |
| Na bifurcação, siga as plataformas laranja em frente. | Os saltos exigem uma saída mais perto da borda e aterrissagem central. O atalho reencontra o caminho verde antes do Checkpoint 2. |
| Passe pelos checkpoints 2 e 3 e embarque pelo pórtico amarelo. | O cronômetro congela, o HUD confirma a chegada e registra o melhor tempo. |
| Toque em **Correr de novo** e atravesse a linha. Desta vez, siga as setas verdes à direita no garfo. | Você larga do zero com o melhor tempo anterior visível. O recorde muda somente se você completar uma corrida mais rápida. |

## Gerar o arquivo com Rojo

O projeto usa Rojo **7.6.1**, fixado em `rokit.toml`. Instale essa versão pelo [release oficial](https://github.com/rojo-rbx/rojo/releases/tag/v7.6.1) ou rode `rokit install` com o [Rokit](https://github.com/rojo-rbx/rokit) já instalado. Na raiz do projeto, execute:

```sh
rojo build default.project.json -o UltimaBalsa.rbxl
```

Para usar o fluxo de edição ao vivo, rode `rojo serve default.project.json` e conecte o [plugin do Rojo](https://rojo.space/docs/v7/getting-started/installation/) no Studio. O código fica em `src/server` e `src/client`. O mapa pronto está em `src/map/Porto.rbxmx`. Edite as peças no Studio para prototipar ou altere o gerador Luau para manter as mudanças reproduzíveis. Os marcadores invisíveis em `Workspace/Porto/RaceMarkers` controlam largada, checkpoints, respawns e chegada. Se mover uma dessas áreas, ajuste também o marcador correspondente.

O build normal já inclui o mapa gerado. Para regenerá-lo e testar a lógica pura da corrida, use o [CLI Luau](https://github.com/luau-lang/luau/releases) na raiz:

```sh
luau tools/generate-map.luau > src/map/Porto.rbxmx
luau tools/test-run.luau
```

## Eventos da corrida

Na experiência publicada, o servidor envia os eventos ao Roblox Analytics. Em testes no Studio, procure as mesmas ocorrências na janela **Output**, com o prefixo `[UltimaBalsa]`.

| Evento | Quando é registrado |
| --- | --- |
| `RaceStarted` | A cada largada válida. |
| `RaceCheckpoint1` | Ao validar o primeiro checkpoint da tentativa. |
| `RaceFinished` | Ao validar a chegada após os três checkpoints. |
| `RaceRetried` | Ao cruzar a largada a partir da segunda tentativa da sessão, mesmo se a anterior foi abandonada. |

Para medir a conversão por tentativa, use o funil `UltimaBalsa_Run`, com uma ID por corrida e as etapas **Largada → Checkpoint 1 → Chegada**. Os eventos personalizados têm valor 1 e incluem a ocorrência `first_in_session` ou `repeat_in_session` no segundo campo personalizado, permitindo contar a primeira ocorrência de cada etapa por jogador em cada sessão. O primeiro campo distingue a primeira tentativa das demais. O melhor tempo também é mantido por sessão.
