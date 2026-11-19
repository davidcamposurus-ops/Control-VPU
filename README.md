# VPU Control — primeira versão

## O que está incluído
- Dashboard com contagem de VPUs disponíveis, reservadas e em campo.
- Cadastro de equipamentos e chave de licença.
- Consulta pública de equipamentos e reservas.
- Reservas de VPU para fazendas.
- Exclusão administrativa de reservas e de equipamentos sem reservas vinculadas.
- Painel de estoque com ações rápidas para marcar reservas como separadas ou concluídas.
- Copiar chaves de licença e compartilhar dados completos de separação pelo WhatsApp.
- Confirmações e avisos personalizados na interface, sem caixas de diálogo nativas do navegador.
- Histórico básico de movimentações.
- Acesso administrativo por e-mail e senha do Supabase Auth.

## Antes de usar
Esta versão ainda precisa ser conectada ao seu projeto Supabase. O arquivo `index.html` não contém credenciais reais.

### 1. Criar o projeto
1. Entre em https://supabase.com e crie um projeto.
2. Abra o SQL Editor.
3. Cole e execute todo o conteúdo de `supabase.sql`.
4. Em Project Settings > API, copie a Project URL e a chave `anon` / publishable.
5. Guarde a Project URL e a chave `anon` / `publishable` como valores seguros para configurar nos provedores de hospedagem.

Nunca use a chave `service_role` no navegador.

### 2. Criar o administrador
1. No Supabase, abra Authentication > Users.
2. Adicione o e-mail e senha do administrador.
3. Copie o UUID do usuário criado.
4. No SQL Editor, execute:
   `insert into public.app_admins (user_id) values ('1657e3b9-f119-4da8-8a64-0d1885592b13');`
5. Use o botão “Acesso administrativo” no site para entrar.

### 3. Publicar no GitHub e Vercel

#### GitHub Pages
1. Envie esta pasta para um repositório no GitHub e use a branch `main`.
2. Em **Settings > Secrets and variables > Actions**, crie os secrets:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
3. Em **Settings > Pages**, selecione **GitHub Actions** como fonte.
4. Cada push na branch `main` publicará o site automaticamente.

Não envie `supabase.sql` para acesso público. Ele contém apenas estrutura e políticas do banco, mas não precisa ficar disponível na hospedagem.

#### Vercel
1. Importe o repositório no painel da Vercel.
2. A raiz do projeto deve apontar para a pasta `vpu-control`.
3. Em **Settings > Environment Variables**, cadastre:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
4. Mantenha `npm run build` e `dist` conforme `vercel.json`, ou importe pelo arquivo já configurado.
5. Faça o deploy.

O build gera `dist/config.js` com as configurações, sem incluir a chave `service_role`. A chave `anon` ou `publishable` do Supabase é segura para uso no navegador, pois o acesso continua protegido pelo RLS.

## Comportamento do acesso
- Visitantes sem login conseguem consultar equipamentos, licenças e reservas.
- Somente usuários listados em `app_admins` conseguem cadastrar e alterar dados.
- O banco aplica as permissões com Row Level Security (RLS). Não dependa apenas de esconder botões na interface.

## Limitações conhecidas da primeira versão
- O painel atualiza automaticamente a cada 45 segundos; não usa sincronização em tempo real ainda.
- A movimentação de status é básica. Antes de uso operacional definitivo, validar o fluxo de devolução, conclusão e cancelamento.
- O histórico é registrado pela interface. Uma próxima etapa deve transferir a auditoria para triggers no banco e registrar todas as alterações de forma inviolável.
- Como a consulta é pública, qualquer pessoa com o link poderá ver as chaves de licença e os nomes das fazendas. Confirme que essa exposição é aceitável para sua operação antes de publicar.
- A chave de licença é única no banco e fica copiada na reserva como fotografia do vínculo usado naquela operação.

## Teste inicial sugerido
1. Cadastre VPU 01 com uma chave de teste.
2. Confirme que ela aparece como disponível.
3. Crie uma reserva para “Fazenda Teste”.
4. Confira se a VPU sai da lista de disponíveis e aparece nas reservas.
5. Atualize a reserva para “Em campo”.
6. Ao devolver, atualize para “Devolvida” e confira se o equipamento volta a disponível.
