CREATE TABLE public.profiles ( 
id uuid NOT NULL, 
username text, 
nome text, 
avatar_url text, 
created_at timestamp with time zone NOT NULL DEFAULT now(), updated_at timestamp with time zone NOT NULL DEFAULT now(), phone text, 
whatsapp text, 
email text, 
ativo boolean DEFAULT true, 
assinaturaid character varying, 
customerid character varying, 
stripe_customer_id text, 
subscription_id text, 
subscription_status text, 
subscription_end_date timestamp with time zone, 
CONSTRAINT profiles_pkey PRIMARY KEY (id), 
CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ); 
CREATE TABLE public.categorias ( 
id uuid NOT NULL DEFAULT gen_random_uuid(), 
userid uuid NOT NULL, 
nome text NOT NULL, 
tags text, 
created_at timestamp with time zone NOT NULL DEFAULT now(), updated_at timestamp with time zone NOT NULL DEFAULT now(), CONSTRAINT categorias_pkey PRIMARY KEY (id), 
CONSTRAINT categorias_userid_fkey FOREIGN KEY (userid) REFERENCES auth.users(id) 
); 


CREATE TABLE public.lembretes ( 
id bigint GENERATED ALWAYS AS IDENTITY NOT NULL, 
created_at timestamp with time zone NOT NULL DEFAULT now(), userid uuid, 
descricao text, 
data timestamp without time zone, 
valor real, 
CONSTRAINT lembretes_pkey PRIMARY KEY (id), 
CONSTRAINT lembretes_userid_fkey FOREIGN KEY (userid) REFERENCES public.profiles(id) 
); 
CREATE TABLE public.transacoes ( 
id bigint GENERATED ALWAYS AS IDENTITY NOT NULL, 
created_at timestamp with time zone NOT NULL DEFAULT now(), quando text,
estabelecimento character varying, 
valor numeric, 
detalhes text, 
tipo character varying, 
userid uuid DEFAULT gen_random_uuid(), 
category_id uuid NOT NULL, 
CONSTRAINT transacoes_pkey PRIMARY KEY (id), 
CONSTRAINT transacoes_userid_fkey FOREIGN KEY (userid) REFERENCES public.profiles(id), 
CONSTRAINT transacoes_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categorias(id) 
);


-- Função para criar perfil automaticamente quando um usuário se registra
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, nome, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data ->> 'nome', NEW.raw_user_meta_data ->> 'name', ''),
    NOW(),
    NOW()
  );
  RETURN NEW;
END;
$$;
-- Trigger que executa a função sempre que um usuário é criado
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
-- Habilitar RLS nas tabelas
ALTER TABLE public.categorias ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transacoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lembretes ENABLE ROW LEVEL SECURITY;
-- Políticas para a tabela categorias
CREATE POLICY "Users can view their own categories" ON public.categorias
  FOR SELECT USING (auth.uid() = userid);
CREATE POLICY "Users can create their own categories" ON public.categorias
  FOR INSERT WITH CHECK (auth.uid() = userid);
CREATE POLICY "Users can update their own categories" ON public.categorias
  FOR UPDATE USING (auth.uid() = userid);
CREATE POLICY "Users can delete their own categories" ON public.categorias
  FOR DELETE USING (auth.uid() = userid);
-- Políticas para a tabela transacoes
CREATE POLICY "Users can view their own transactions" ON public.transacoes
  FOR SELECT USING (auth.uid() = userid);
CREATE POLICY "Users can create their own transactions" ON public.transacoes
  FOR INSERT WITH CHECK (auth.uid() = userid);
CREATE POLICY "Users can update their own transactions" ON public.transacoes
  FOR UPDATE USING (auth.uid() = userid);
CREATE POLICY "Users can delete their own transactions" ON public.transacoes
  FOR DELETE USING (auth.uid() = userid);
-- Políticas para a tabela profiles
CREATE POLICY "Users can view their own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update their own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);
-- Políticas para a tabela lembretes
CREATE POLICY "Users can view their own reminders" ON public.lembretes
  FOR SELECT USING (auth.uid() = userid);
CREATE POLICY "Users can create their own reminders" ON public.lembretes
  FOR INSERT WITH CHECK (auth.uid() = userid);
CREATE POLICY "Users can update their own reminders" ON public.lembretes
  FOR UPDATE USING (auth.uid() = userid);
CREATE POLICY "Users can delete their own reminders" ON public.lembretes
  FOR DELETE USING (auth.uid() = userid);
