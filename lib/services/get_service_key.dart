

import 'package:googleapis_auth/auth_io.dart';

class GetServerKey {
  Future<String> getServerKeyToken() async {
    final scopes = [
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/firebase.database',
      'https://www.googleapis.com/auth/firebase.messaging',
    ];

    final client = await clientViaServiceAccount(
      ServiceAccountCredentials.fromJson(
       {
          "type": "service_account",
          "project_id": "nexora-health-22eb4",
          "private_key_id": "6b374e17008c40e6bc81244fe96cb4abf1bed644",
          "private_key":
              "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQClcaB0uYu6xKa8\nWpSMHWdKB6PvH4+PaPRTjEzSKko+QHbolL8wDvZ2O4YU0peqPDqdhZUuq+XP5xnK\nm4cUSNogVrWrhkSm1E238jqIfbWQ17k5VImlKHb3CU9VxLRicUvmexQbbjYIoCWT\nMMO/V00LRGIFKD9ddia6RanWtC6sSOLRhyLVRpl3Ak0yCedacdpqSyLwUogS+UWS\nJWvmduoDxb7AmPNAphG7uc7Q3rEF6Bn6iYvfvkjfQAm5iz1OCU4FWrBht9PR+PO3\n5IXjHwCicvWAY5cYHPJhYMVbjN2weoXre+P7KDg1pyHKeAuxvse2q9osgcsjALnD\np/669sVFAgMBAAECggEAAN+j5DSPuQtbkAhFvt024gVbFb82apJGlON30mB/WGsj\ngEQelahTA2SzLkVM2SlwXZLnDl7BcS1uDZniFRpktcxy+CDzGC+Id/g92+Hefko/\nGTDmQH/zJN1ZqivGc9e7MrPcc0OExds4Z5KevDWjTVeKJvZDf9YeJ+ZrtsZaA6D6\nuM3PdbqUSlMcTOkHIUMoeKQkawZvMLRliHZSUiZMHRC/dZ10jIErwkeQ+PiogQ6i\nRTpXbHyR/C943QNHoslWZHpeYNk/Vk7JU94oe0GDLH6Eg5aveYVsqQWx96/3kdWT\nztSYoNnE1hNYI5Kj0gvvpQ3//rCjaj/Atcss/uYoDwKBgQDWFGLCJgNTPJOh/8OZ\n8iQpApzlVpRPv4Rx+VD4Sv37C3JVAmCfQdok5zrpHNZUVyWoCBmLlCePoDclfOUr\nCtfh3DkmMHcNQvThkFmQTtE5g1futLM/518FwONBePvxcQE7vXuoCVZI6ZgPXqGm\n0K8WczF9gI7R084Z+Zf2w0vfmwKBgQDF1yymEf4XkiBy4Gk0vUlpDnR0OCl9uFQ5\na1GM3OUyWWD1AKgTazcUEwML8A/7vMENUV+dNi5a+8nvLh4MydmgvQOk/fOpVpQ5\nnimWDHqq9uSwVDFCcohHx+MTfIbegPUi6sDPJ/suqYF0IbIZ5soi3ZIph0X0lY6M\nuf7X81zsnwKBgEVuMSV0fKmXQO5ObBrWnIGsdkQvE0TWAVeRm4Abmkm8SaVmcv3T\ntrM3RzTphF2wMedQUTCiqT38oUYIPq76AlAfQ22uVD450///9/xEg7jabz9c3bHB\nEWFlUI8gdN22X8cHSj6SYKifEhESCO14SwDF9WwVsLw+rF5iQ7XlWws3AoGAMXsC\nkLp5SV3jvbeAuI8K+DqER7jwL6BVeFLt/4QT0sbl6AD1CH5NNTkYDvlIlhZ8Vh9f\nAYvWhizpMWfgXiRxyLDdY3ucYGLmCY8UKZIPcAj141/7Pfo1OXa1xV7kwGuSY9xA\nws7mFKKSXQA8chv1vEicUMSja2uoTmwKX+pe+FMCgYBcMGNu9KUU8rPwLUAgKfTz\nFikcSCcNXcKpyJXBm/qHFiRYM8pZ7Bjl/+FLXrwrjUxGa/hoV11IiEe1fH+qt3+F\nynvu854PC8JV5MEAGkJG2skfpXhCnnG0aD0Jgrn2vaP/fK7PVP+jM+y10uVmZPL8\nLphv5PkjaHsC2SP0QILn0g==\n-----END PRIVATE KEY-----\n",
          "client_email":
              "firebase-adminsdk-fbsvc@nexora-health-22eb4.iam.gserviceaccount.com",
          "client_id": "110914970468408272427",
          "auth_uri": "https://accounts.google.com/o/oauth2/auth",
          "token_uri": "https://oauth2.googleapis.com/token",
          "auth_provider_x509_cert_url":
              "https://www.googleapis.com/oauth2/v1/certs",
          "client_x509_cert_url":
              "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40nexora-health-22eb4.iam.gserviceaccount.com",
          "universe_domain": "googleapis.com",
        }

      ),
      scopes,
    );
    final accessServerKey = client.credentials.accessToken.data;
    return accessServerKey;
  }
}
