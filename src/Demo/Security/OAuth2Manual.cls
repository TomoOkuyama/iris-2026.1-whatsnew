/// 2025.1以前のOAuth2自前実装サンプル（参照用）
///
/// IRIS 2025.1以前のバージョンでは、外部IdP（Keycloak、Azure AD、Okta等）から
/// 受け取ったOAuth2 Bearerトークンを使ってIRISのCSP/RESTアプリを認証するために、
/// 本クラスのような認証ロジックを「自前で」実装する必要がありました。
///
/// 2025.2以降では、この全体が標準クラス（%OAuth2.ResourceServer.SimpleAuthenticator）
/// で提供されるため、利用側のコードは3行で済みます。
///
/// 本クラスは「以前は何をどれだけ書く必要があったか」を示すための参照実装です。
/// docs/05-security.md の「コード量の比較: 自前実装 vs 標準クラス」セクションから
/// 参照されます。
///
/// 注: ASN.1/DERエンコードや署名検証は最小限の実装にとどめており、
/// 本番運用では追加のテスト・脆弱性対策（none攻撃、JWKSローテーション処理など）が必要です。
Class Demo.Security.OAuth2Manual Extends %CSP.REST
{

Parameter JWKSHOST = "keycloak";

Parameter JWKSPORT = 8080;

Parameter JWKSPATH = "/realms/iris-demo/protocol/openid-connect/certs";

Parameter EXPECTEDISSUER = "http://keycloak:8080/realms/iris-demo";

Parameter EXPECTEDAUDIENCE = "iris-client";

Parameter JWKSCACHETTL = 3600;

/// CSP/RESTのリクエストディスパッチ前にBearerトークンを検証する
/// 2025.1以前ではこの一連の処理をすべて自前で実装する必要があった
ClassMethod OnPreDispatch(pUrl As %String, pMethod As %String, ByRef pContinue As %Boolean) As %Status
{
    set pContinue = 0

    // 1. AuthorizationヘッダからBearerトークンを抽出
    set authHeader = %request.GetCgiEnv("HTTP_AUTHORIZATION")
    if ($extract(authHeader, 1, 7) '= "Bearer ") {
        set %response.Status = "401 Unauthorized"
        quit $$$OK
    }
    set token = $extract(authHeader, 8, *)

    // 2. JWTを header.payload.signature の3パートに分解
    set header = $piece(token, ".", 1)
    set payload = $piece(token, ".", 2)
    set sigPart = $piece(token, ".", 3)
    if (header = "") || (payload = "") || (sigPart = "") {
        set %response.Status = "401 Unauthorized"
        quit $$$OK
    }

    // 3. ヘッダをデコードし kid と alg を取得（noneアルゴリズム攻撃の防止含む）
    set headerObj = ##class(%DynamicObject).%FromJSON(..Base64UrlDecode(header))
    set kid = headerObj.kid
    set alg = headerObj.alg
    if (kid = "") || (alg '= "RS256") {
        set %response.Status = "401 Unauthorized"
        quit $$$OK
    }

    // 4. JWKSエンドポイントから公開鍵PEMを取得（キャッシュ含む）
    set publicKeyPem = ..GetJwksPublicKey(kid)
    if publicKeyPem = "" {
        set %response.Status = "401 Unauthorized"
        quit $$$OK
    }

    // 5. 署名検証（RS256: RSA-SHA256）
    set signedData = header _ "." _ payload
    set sigBytes = ..Base64UrlDecodeBytes(sigPart)
    if '$system.Encryption.RSASHAVerify(256, signedData, sigBytes, publicKeyPem) {
        set %response.Status = "401 Unauthorized"
        quit $$$OK
    }

    // 6. payload(claims)をデコードし、exp / iss / aud を検証
    set claims = ##class(%DynamicObject).%FromJSON(..Base64UrlDecode(payload))
    set nowUnix = ##class(%PosixTime).LogicalToUnixTime(##class(%PosixTime).CurrentUTCTimeStamp())

    if (claims.exp = "") || (claims.exp < nowUnix) {
        set %response.Status = "401 Unauthorized"
        quit $$$OK
    }
    if claims.iss '= ..#EXPECTEDISSUER {
        set %response.Status = "401 Unauthorized"
        quit $$$OK
    }
    if '..AudienceMatches(claims.aud, ..#EXPECTEDAUDIENCE) {
        set %response.Status = "401 Unauthorized"
        quit $$$OK
    }

    // 7. claims から IRIS ユーザーへマッピング
    set username = claims.%Get("preferred_username")
    if username = "" set username = claims.%Get("sub")
    if '##class(Security.Users).Exists(username) {
        set %response.Status = "403 Forbidden"
        quit $$$OK
    }
    set %session.Username = username

    set pContinue = 1
    quit $$$OK
}

/// JWKSエンドポイントから kid に該当する公開鍵をPEM形式で取得（キャッシュTTL付き）
ClassMethod GetJwksPublicKey(kid As %String) As %String
{
    set nowUnix = ##class(%PosixTime).LogicalToUnixTime(##class(%PosixTime).CurrentUTCTimeStamp())

    // キャッシュ確認
    if $data(^Demo.JwksCache(kid)) {
        set entry = ^Demo.JwksCache(kid)
        set cachedPem = $listget(entry, 1)
        set expireAt = $listget(entry, 2)
        if (cachedPem '= "") && (expireAt > nowUnix) {
            quit cachedPem
        }
    }

    // JWKSエンドポイントへHTTP GET
    set req = ##class(%Net.HttpRequest).%New()
    set req.Server = ..#JWKSHOST
    set req.Port = ..#JWKSPORT
    set sc = req.Get(..#JWKSPATH)
    if $$$ISERR(sc) quit ""
    if req.HttpResponse.StatusCode '= 200 quit ""

    set jwks = ##class(%DynamicObject).%FromJSON(req.HttpResponse.Data.Read(32000))

    // 該当 kid を探して PEM へ変換
    set pem = ""
    set iter = jwks.keys.%GetIterator()
    while iter.%GetNext(.k, .key) {
        if key.kid = kid {
            set pem = ..JwkToPem(key)
            if pem '= "" {
                set ^Demo.JwksCache(kid) = $listbuild(pem, nowUnix + ..#JWKSCACHETTL)
            }
            quit
        }
    }
    quit pem
}

/// JWK (RSA: n, e) → PEM公開鍵 (X.509 SubjectPublicKeyInfo)
/// ASN.1 DER エンコードを自前で組み立てる必要があった
ClassMethod JwkToPem(jwk As %DynamicObject) As %String
{
    set nBytes = ..Base64UrlDecodeBytes(jwk.n)
    set eBytes = ..Base64UrlDecodeBytes(jwk.e)

    // PKCS#1 RSAPublicKey ::= SEQUENCE { modulus INTEGER, publicExponent INTEGER }
    set rsaPubKey = ..EncodeSequence(..EncodeInteger(nBytes) _ ..EncodeInteger(eBytes))

    // X.509 SubjectPublicKeyInfo でラップ
    set spki = ..EncodeSpki(rsaPubKey)

    // Base64 + PEMヘッダ/フッタ
    set base64 = $system.Encryption.Base64Encode(spki)
    quit "-----BEGIN PUBLIC KEY-----" _ $char(10) _ base64 _ $char(10) _ "-----END PUBLIC KEY-----"
}

/// ASN.1 INTEGER 型としてエンコード（先頭バイトの符号ビット対応）
ClassMethod EncodeInteger(bytes As %Binary) As %Binary
{
    if $ascii(bytes, 1) >= 128 set bytes = $char(0) _ bytes
    quit $char(2) _ ..EncodeLength($length(bytes)) _ bytes
}

/// ASN.1 SEQUENCE としてエンコード
ClassMethod EncodeSequence(content As %Binary) As %Binary
{
    quit $char(48) _ ..EncodeLength($length(content)) _ content
}

/// ASN.1 SubjectPublicKeyInfo (X.509) でラップ
ClassMethod EncodeSpki(rsaPubKey As %Binary) As %Binary
{
    // AlgorithmIdentifier (rsaEncryption OID = 1.2.840.113549.1.1.1) + NULL parameters
    set algId = $char(48,13,6,9,42,134,72,134,247,13,1,1,1,5,0)
    // BIT STRING: 先頭の未使用ビット数(0x00) + RSA公開鍵
    set bitStringContent = $char(0) _ rsaPubKey
    set bitString = $char(3) _ ..EncodeLength($length(bitStringContent)) _ bitStringContent
    quit ..EncodeSequence(algId _ bitString)
}

/// ASN.1 の長さフィールド（可変長エンコーディング）
ClassMethod EncodeLength(len As %Integer) As %Binary
{
    if len < 128 quit $char(len)
    set bytes = ""
    set tmp = len
    while tmp > 0 {
        set bytes = $char(tmp # 256) _ bytes
        set tmp = tmp \ 256
    }
    quit $char(128 + $length(bytes)) _ bytes
}

/// aud claim の照合（配列形式と単一文字列の両対応）
ClassMethod AudienceMatches(aud, expected As %String) As %Boolean
{
    if '$isobject(aud) {
        quit (aud = expected)
    }
    set iter = aud.%GetIterator()
    while iter.%GetNext(.k, .v) {
        if v = expected quit 1
    }
    quit 0
}

/// Base64URL → 文字列（パディング補正）
ClassMethod Base64UrlDecode(s As %String) As %String
{
    set s = $translate(s, "-_", "+/")
    set mod = $length(s) # 4
    if mod = 2 set s = s _ "=="
    if mod = 3 set s = s _ "="
    quit $system.Encryption.Base64Decode(s)
}

/// Base64URL → バイナリ
ClassMethod Base64UrlDecodeBytes(s As %String) As %Binary
{
    quit ..Base64UrlDecode(s)
}

}
