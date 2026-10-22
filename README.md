# Guia de Manutenção do Windows

Ferramenta em Batch para diagnóstico e manutenção de computadores com Windows. O menu separa tarefas por permissão, registra as execuções e cria backups antes de algumas limpezas. As versões publicadas são identificadas pelas tags do GitHub.

> **Atenção:** execute somente em computadores próprios ou nos quais você tenha autorização. Em ambientes corporativos, siga as políticas da equipe de TI. As operações de manutenção podem alterar ou remover dados; faça backups independentes e teste em um ambiente controlado.

## Recursos

- Painel com informações do computador, usuário, Windows, memória, espaço em disco e endereços IPv4.
- Relatório detalhado de sistema, rede e drivers.
- Verificações e reparos do disco, dos arquivos protegidos e da imagem do Windows, usando CHKDSK, SFC e DISM.
- Limpeza de cache DNS, arquivos temporários do usuário e do Windows e cache do Windows Update.
- Reinício do serviço de impressão, otimização de disco e opção para esvaziar a lixeira.
- Escolha no início entre abrir o programa como administrador ou continuar como usuário comum; o menu mostra apenas as tarefas disponíveis para o modo escolhido.
- Confirmação para operações sensíveis e logs de execução.
- Backups prévios em limpezas selecionadas.
- Atalhos para abrir as pastas de logs e backups.

## Requisitos

- Windows 10 ou Windows 11.
- Prompt de Comando e Windows PowerShell.
- Ferramentas nativas do Windows utilizadas por cada tarefa, como `chkdsk`, `DISM`, `sfc`, `robocopy` e `defrag`.
- Permissão de administrador para tarefas identificadas como administrativas.
- Espaço em disco suficiente para armazenar os backups, que podem ocupar vários gigabytes.

## Como executar

1. Acesse as [tags do projeto](https://github.com/atenente/bash_manutecao/tags), escolha a versão desejada e baixe o código-fonte daquela tag.
2. Execute o `.bat` com duplo clique ou pelo Prompt de Comando.
3. Se o programa não estiver elevado, escolha **S** para abrir uma nova janela com privilégios de administrador e acessar todas as tarefas, ou **N** para continuar sem elevação e ver somente as tarefas de usuário. Se apenas pressionar **Enter**, a opção padrão é **S**. Se já estiver elevado, o menu abre diretamente com todas as tarefas.
4. Escolha uma tarefa no menu e pressione **Enter**. Confirme ou cancele as operações sensíveis quando solicitado.

Ao escolher **S**, autorize a abertura da janela elevada pelo UAC; a janela inicial será encerrada. As opções do menu são numeradas conforme as tarefas disponíveis no modo escolhido. Políticas corporativas podem impedir a elevação.

## Tarefas do menu

| Acesso | Tarefa |
|:---:|---|
| Usuário | Atualizar painel de diagnóstico |
| Usuário | Salvar relatório detalhado |
| Usuário | Limpar cache DNS |
| Administrador | Verificar disco (`chkdsk /scan`) |
| Administrador | Verificar imagem do Windows (`DISM /ScanHealth`) |
| Administrador | Verificar arquivos do Windows (`sfc /verifyonly`) |
| Administrador | Limpar temporários com backup |
| Administrador | Limpar cache do Windows Update com backup |
| Administrador | Esvaziar lixeira |
| Administrador | Reiniciar serviço de impressão |
| Administrador | Reparar imagem do Windows (`DISM /RestoreHealth`) |
| Administrador | Reparar arquivos do Windows (`sfc /scannow`) |
| Administrador | Otimizar disco |
| Usuário | Abrir pasta de backups |
| Usuário | Abrir pasta de logs |

> No modo sem elevação, apenas tarefas de **Usuário** aparecem. No modo administrador, aparecem as tarefas dos dois níveis.

## Logs e backups

Os arquivos são gravados em `%LOCALAPPDATA%\GuiaManutencao\`, nas pastas `Logs` e `Backups`. Os logs incluem eventos e saídas dos comandos; os relatórios podem conter nomes de máquinas, endereços IP, adaptadores e outras informações internas. Proteja esses arquivos antes de compartilhá-los.

Os backups são criados para algumas limpezas, mas não são validados por hash e não há restauração automática. Códigos de retorno do `robocopy` inferiores a 8 não garantem que a cópia esteja completa. Backups não são removidos automaticamente; monitore o espaço e defina uma política de retenção.

## Cuidados e limitações

- Esvaziar a lixeira remove os itens permanentemente e não cria backup automático.
- Arquivos temporários em uso podem não ser removidos; feche aplicativos antes da limpeza.
- A limpeza do Windows Update depende da parada e do reinício do serviço `wuauserv`. Evite executá-la durante atualizações.
- Reiniciar o Spooler pode interromper impressões em andamento.
- Reparos do DISM e SFC podem demorar; o DISM pode depender de uma fonte de reparo e de configurações de rede ou atualização.
- A otimização é delegada ao Windows, que escolhe a operação apropriada para o disco.
- Uma mensagem de sucesso baseada no código de retorno de uma ferramenta não equivale a uma auditoria completa do estado do sistema.
- O script precisa ser testado no computador de destino antes de ser usado em produção; ferramentas e permissões podem se comportar de maneira diferente conforme a instalação do Windows.

## Autor

**Anderson Tenente**
