# Guia de Manutenção do Windows

Ferramenta em Batch para diagnóstico e manutenção de computadores com Windows. A versão 2.0 documenta um menu modular, separação de tarefas por permissão, registros de execução e backups antes de algumas limpezas.

> **Atenção:** execute somente em computadores próprios ou nos quais você tenha autorização. Em ambientes corporativos, siga as políticas da equipe de TI. As operações de manutenção podem alterar ou remover dados; faça backups independentes e teste em um ambiente controlado.

## Recursos da versão 2.0

- Painel com informações do computador, usuário, Windows, memória, espaço em disco e endereços IPv4.
- Relatório detalhado de sistema, rede e drivers.
- Verificações e reparos do disco, dos arquivos protegidos e da imagem do Windows, usando CHKDSK, SFC e DISM.
- Limpeza de cache DNS, arquivos temporários e cache do Windows Update.
- Reinício do serviço de impressão, otimização de disco e opção para esvaziar a lixeira.
- Confirmação para operações sensíveis e solicitação de elevação para tarefas administrativas.
- Logs de execução e backups prévios em limpezas selecionadas.
- Atalhos para abrir as pastas de logs e backups.

## Requisitos

- Windows 10 ou Windows 11.
- Prompt de Comando e Windows PowerShell.
- Ferramentas nativas do Windows utilizadas por cada tarefa, como `chkdsk`, `DISM`, `sfc`, `robocopy` e `defrag`.
- Permissão de administrador para tarefas identificadas como administrativas.
- Espaço em disco suficiente para armazenar os backups, que podem ocupar vários gigabytes.

## Como executar

1. Baixe o arquivo do programa pela página de [releases](https://github.com/atenente/bash_manutecao/releases/latest).
2. Execute o `.bat` com duplo clique ou pelo Prompt de Comando.
3. Escolha uma opção do menu e pressione **Enter**.
4. Confirme ou cancele as operações quando solicitado. Para tarefas administrativas, autorize a elevação pelo UAC.

As tarefas de usuário comum podem ser iniciadas sem abrir o programa como administrador. A elevação é solicitada quando uma tarefa administrativa é selecionada; políticas corporativas podem impedir essa ação.

## Opções do menu 2.0

| Nº | Acesso | Tarefa |
|---:|:---:|---|
| 1 | Usuário | Atualizar painel de diagnóstico |
| 2 | Usuário | Salvar relatório detalhado |
| 3 | Usuário | Limpar cache DNS |
| 4 | Administrador | Verificar disco (`chkdsk /scan`) |
| 5 | Administrador | Verificar imagem do Windows (`DISM /ScanHealth`) |
| 6 | Administrador | Verificar arquivos do Windows (`sfc /verifyonly`) |
| 7 | Administrador | Limpar temporários com backup |
| 8 | Administrador | Limpar cache do Windows Update com backup |
| 9 | Administrador | Esvaziar lixeira |
| 10 | Administrador | Reiniciar serviço de impressão |
| 11 | Administrador | Reparar imagem do Windows (`DISM /RestoreHealth`) |
| 12 | Administrador | Reparar arquivos do Windows (`sfc /scannow`) |
| 13 | Administrador | Otimizar disco |
| 14 | Usuário | Abrir pasta de backups |
| 15 | Usuário | Abrir pasta de logs |
| 0 | — | Sair |

> **Usuário** indica execução sem elevação. **Administrador** requer privilégios elevados. Algumas tarefas de usuário ainda podem ser bloqueadas por políticas ou configurações do computador.

## Logs e backups

Na versão 2.0, os arquivos são gravados em `%LOCALAPPDATA%\GuiaManutencao2\`, nas pastas `Logs` e `Backups`. Os logs incluem eventos e saídas dos comandos; os relatórios podem conter nomes de máquinas, endereços IP, adaptadores e outras informações internas. Proteja esses arquivos antes de compartilhá-los.

Os backups são criados para algumas limpezas, mas não são validados por hash e não há restauração automática. Códigos de retorno do `robocopy` inferiores a 8 não garantem que a cópia esteja completa. Backups não são removidos automaticamente; monitore o espaço e defina uma política de retenção. Tarefas elevadas podem gravar arquivos no perfil da conta administrativa utilizada.

## Cuidados e limitações

- Esvaziar a lixeira remove os itens permanentemente e não cria backup automático.
- Arquivos temporários em uso podem não ser removidos; feche aplicativos antes da limpeza.
- A limpeza do Windows Update depende da parada e do reinício do serviço `wuauserv`. Evite executá-la durante atualizações.
- Reiniciar o Spooler pode interromper impressões em andamento.
- Reparos do DISM e SFC podem demorar; o DISM pode depender de uma fonte de reparo e de configurações de rede ou atualização.
- A otimização é delegada ao Windows, que escolhe a operação apropriada para o disco.
- Uma mensagem de sucesso baseada no código de retorno de uma ferramenta não equivale a uma auditoria completa do estado do sistema.
- A versão 2.0 não foi validada em um computador Windows neste ambiente.

## Estado dos arquivos neste repositório

O arquivo `Guia_Manutencao_v_2.bat` contém o menu 2.0 e as rotinas descritas neste README. O script foi atualizado neste repositório, mas ainda precisa ser executado e validado em um computador Windows antes de ser distribuído.

## Autor

**Anderson Tenente**
