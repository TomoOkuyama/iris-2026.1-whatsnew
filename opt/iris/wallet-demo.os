// セキュリティウォレットデモ（2025.3以降）
// 実行: docker exec -i iris-2026 iris session IRIS -U %SYS < opt/iris/wallet-demo.os
zn "%SYS"
write !,"=== 1. リソース作成 ===",!
write "  AppUseWallet: ",##class(Security.Resources).Create("AppUseWallet","App Wallet Use",""),!
write "  AppEditWallet: ",##class(Security.Resources).Create("AppEditWallet","App Wallet Edit",""),!

write !,"=== 2. コレクション作成 ===",!
write "  Collection create: ",##class(%Wallet.Collection).Create("AppCollection",{"UseResource":"AppUseWallet","EditResource":"AppEditWallet"}),!

write !,"=== 3. シークレット登録 ===",!
write "  KeyValue create: ",##class(%Wallet.KeyValue).Create("AppCollection.SFTP",{"Secret":{"user":"appuser","password":"P@ssw0rd!"}}),!

write !,"=== 4. シークレット取得 ===",!
set val = ##class(%Wallet.KeyValue).GetSecretValue("AppCollection.SFTP")
write "  Retrieved: ",val,!
set obj = {}.%FromJSON(val)
write "  user: ",obj.user,!
write "  password: ",obj.password,!

write !,"=== 5. クリーンアップ ===",!
write "  KeyValue delete: ",##class(%Wallet.KeyValue).Delete("AppCollection.SFTP"),!
write "  Collection delete: ",##class(%Wallet.Collection).Delete("AppCollection"),!
write "  AppUseWallet delete: ",##class(Security.Resources).Delete("AppUseWallet"),!
write "  AppEditWallet delete: ",##class(Security.Resources).Delete("AppEditWallet"),!
halt
