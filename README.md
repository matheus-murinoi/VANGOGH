# Aprimorar-Video

## Apoio opcional

Todos os recursos do app, incluindo exportação em 4K, são gratuitos e não mudam
com a assinatura. O plano é um apoio voluntário; RevenueCat valida compras e
restaura o entitlement `apoio`.

Configure a integração antes de testar compras:

1. Cadastre `aprimorar_video_pro_monthly` e `aprimorar_video_pro_yearly` como
	assinaturas no App Store Connect e no Google Play Console. Escolha o menor
	nível de preço disponível e configure período introdutório gratuito nos dois
	produtos para novos assinantes elegíveis.
2. Adicione os dois produtos no projeto RevenueCat e configure a conexão segura
	às lojas no painel. Não coloque credenciais privadas das lojas no app.
3. Crie o entitlement `apoio` e associe os produtos a ele.
4. Crie a offering atual `default`, com os pacotes mensal (`$rc_monthly`) e anual
	(`$rc_annual`). Os preços vêm da loja e não são fixados no código.
5. Passe as chaves públicas do SDK RevenueCat ao compilar:

```sh
flutter run \
  --dart-define=REVENUECAT_ANDROID_API_KEY=goog_public_sdk_key \
  --dart-define=REVENUECAT_IOS_API_KEY=appl_public_sdk_key
```

O checkout fica desabilitado para um pacote sem período introdutório de preço
zero. A elegibilidade do teste grátis é determinada pela loja; após o teste, o
preço e a renovação são mostrados antes da confirmação. Teste em TestFlight ou na
faixa de teste interno do Google Play com contas sandbox. Nenhum recurso do app
deve depender do entitlement.