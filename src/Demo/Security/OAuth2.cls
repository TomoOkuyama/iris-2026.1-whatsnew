/// OAuth2認証改善デモ（2025.2）
/// 2026.1では、たった数行のコードでOAuth2トークンベースの認証が実現できます。
/// Keycloakからトークンを取得し、ResourceServer + SimpleAuthenticatorで
/// カスタムコードなしに認証を完了するE2Eデモ。
Class Demo.Security.OAuth2 Extends %RegisteredObject
{

ClassMethod Run()
{
    write "============================================================",!
    write " OAuth2認証改善デモ",!
    write " 2026.1なら、これだけで複雑な認証機構を実装できる",!
    write "============================================================",!
    write !,"  IRISバージョン: ", $zversion,!!

    // --- 1. クラス存在確認（%SYS名前空間で確認） ---
    write "--- 1. OAuth2 ResourceServer関連クラスの確認 ---",!
    set prevNS = $namespace
    set $namespace = "%SYS"
    set hasRS = ##class(%Dictionary.ClassDefinition).%ExistsId("OAuth2.ResourceServer")
    set hasAuth = ##class(%Dictionary.ClassDefinition).%ExistsId("%OAuth2.ResourceServer.SimpleAuthenticator")
    set $namespace = prevNS
    write "  OAuth2.ResourceServer:              ", $select(hasRS:"[あり]", 1:"[なし]"),!
    write "  %OAuth2.ResourceServer.SimpleAuth:  ", $select(hasAuth:"[あり]", 1:"[なし]"),!!

    // --- 2. Keycloakからトークン取得 ---
    write "--- 2. 外部IdP（Keycloak）からアクセストークンを取得 ---",!
    set token = ..GetToken()
    if token = "" {
        write "  [失敗] Keycloakに接続できません。",!
        write "    docker compose up -d keycloak を実行してください",!
        quit
    }
    write "  [成功] OAuth2アクセストークンを取得しました",!!

    // --- 3. JWTの中身を確認 ---
    write "--- 3. トークンの中身（JWTペイロード） ---",!
    set claims = ..DecodeClaims(token)
    if '$isobject(claims) { write "  デコード失敗",! quit }
    write "  ユーザー名:  ", claims.%Get("preferred_username"),!
    write "  メール:     ", claims.%Get("email"),!
    write "  発行者:     ", claims.%Get("iss"),!
    write "  ユーザーID: ", claims.%Get("sub"),!!

    // --- 4. 認証の実行 ---
    if (hasRS && hasAuth) {
        write "--- 4. [2026.1] SimpleAuthenticatorで認証 ---",!
        write !
        write "  // たったこれだけで、OAuth2トークンからユーザーを認証:",!
        write "  set auth = ##class(%OAuth2.ResourceServer.SimpleAuthenticator).%New()",!
        write "  set sc = auth.Authenticate(claims, 0, .props)",!
        write "  set user = auth.DetermineUser(claims)",!
        write !

        // 実際に実行
        set prevNS = $namespace
        set $namespace = "%SYS"
        set auth = ##class(%OAuth2.ResourceServer.SimpleAuthenticator).%New()
        set sc = auth.Authenticate(claims, 0, .props)
        set user = auth.DetermineUser(claims)
        set $namespace = prevNS

        write "  実行結果:",!
        write "    Authenticate(): ", $select(sc:"成功 ✓", 1:"失敗"),!
        write "    DetermineUser(): ", user,!
        write !
        write "  → カスタム認証クラスを一行も書かずに、",!
        write "    OAuth2トークンからユーザーの認証が完了しました。",!
        write !
        write "  従来（2025.1）では、この認証処理を実現するために",!
        write "  トークン検証・ユーザーマッピング・エラー処理を含む",!
        write "  カスタム認証クラスを自作する必要がありました。",!
    } else {
        write "--- 4. [2025.1] カスタム認証クラスが必要 ---",!
        write !
        write "  OAuth2.ResourceServerとSimpleAuthenticatorが存在しないため、",!
        write "  このトークンでIRISの認証を行うには、以下を自作する必要があります:",!
        write "    1. トークンの署名検証（JWKSエンドポイントから公開鍵を取得）",!
        write "    2. トークンの有効期限・発行者の検証",!
        write "    3. claimsからIRISユーザーへのマッピング",!
        write "    4. エラーハンドリング（期限切れ、無効トークン等）",!
        write "    5. これらを含むカスタム認証クラスの実装・テスト・運用",!
        write !
        write "  2026.1なら、上記すべてがSimpleAuthenticatorに内蔵されています。",!
    }

    write !,"============================================================",!
    write " Keycloak管理画面: http://localhost:11718 (admin/admin)",!
    write "============================================================",!
}

/// Keycloakからアクセストークンを取得
ClassMethod GetToken() As %String
{
    set token = ""
    try {
        set req = ##class(%Net.HttpRequest).%New()
        set req.Server = "keycloak"
        set req.Port = 8080
        set req.ContentType = "application/x-www-form-urlencoded"
        do req.EntityBody.Write("grant_type=password&client_id=iris-client&client_secret=iris-demo-secret&username=testuser&password=testpass")
        set sc = req.Post("/realms/iris-demo/protocol/openid-connect/token")
        if $$$ISERR(sc) quit
        if req.HttpResponse.StatusCode '= 200 quit
        set json = ##class(%DynamicObject).%FromJSON(req.HttpResponse.Data.Read(32000))
        set token = json.%Get("access_token")
    } catch ex { }
    quit token
}

/// JWTペイロードをデコード
ClassMethod DecodeClaims(token As %String) As %DynamicObject
{
    set claims = ""
    try {
        set payload = $piece(token, ".", 2)
        set payload = $translate(payload, "-_", "+/")
        set mod = $length(payload) # 4
        if mod = 2 set payload = payload _ "=="
        if mod = 3 set payload = payload _ "="
        set decoded = $system.Encryption.Base64Decode(payload)
        set claims = ##class(%DynamicObject).%FromJSON(decoded)
    } catch ex { }
    quit claims
}

}
