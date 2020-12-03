import hvac
import base64
from environs import Env

env = Env()
# Read .env into os.environ
env.read_env()

def initialize_vault_token():
    VAULT_URL = env('VAULT_URL')

    with open("/tmp/vault_token") as f: 
        VAULT_TOKEN = f.readlines()
        VAULT_TOKEN = VAULT_TOKEN[0].strip('\n')

    print(f'Vault token = {VAULT_TOKEN}')
    print(f'Vault token = {VAULT_URL}')
    client    = hvac.Client(url=VAULT_URL, token=VAULT_TOKEN)
    return client


# print(client.is_authenticated())
# print(client.lookup_token())

# You can also get the token directly from querying K8s
# Kubernetes (from k8s pod)
#f = open('/var/run/secrets/kubernetes.io/serviceaccount/token')
#jwt = f.read()
#client.auth_kubernetes("webblog", jwt)
#print(client.is_authenticated())
#print(client.lookup_token())


def isfloat(value):
  try:
    float(value)
    return True
  except ValueError:
    return False

def transit_encrypt(plain_text, encrypt_key="webblog-key", mount_point='transit'):
    """Encrypt plain text data with Transit.

    Keyword arguments:
    plain_text  -- the text to encrypt (string)
    encrypt_key -- encryption key to use (string)

    Return:
    ciphertext (string)
    """
    if isinstance(plain_text, int) or isinstance(plain_text, float) or isinstance(plain_text, str):
        # Convert plain_text to string
        plain_text = str(plain_text)
        encoded = base64.b64encode(plain_text.encode("utf-8"))
    else:
        return plain_text
    client = initialize_vault_token()
    ciphertext = client.secrets.transit.encrypt_data(
        name = encrypt_key,
        plaintext = str(encoded, "utf-8"),
        context = str(base64.b64encode('random'.encode("utf-8")), "utf-8")
    )

    return ciphertext["data"]["ciphertext"]

def transit_decrypt(ciphertext, decrypt_key="webblog-key", mount_point='transit'):
    """Decrypt ciphertext into plain text.

    Keyword arguments:
    ciphertext -- the text to decrypt (string)
    decrypt_key -- decryption key to use (string)

    Return:
    Base64 decoded plaintext
    """
    # encrypted ciphertext is of type string, so if we don't encrypt something like datetime the check below returns the same ciphertext which is actually plaintext because we didn't encrypt it to begin with.
    if not isinstance(ciphertext, str):
        return ciphertext
    client = initialize_vault_token()
    decrypt_data_response = client.secrets.transit.decrypt_data(
        name = decrypt_key,
        ciphertext = ciphertext,
        context = str(base64.b64encode('random'.encode("utf-8")), "utf-8")
    )
    
    
    response = decrypt_data_response["data"]["plaintext"]
    decoded = base64.b64decode(response)
    decoded_str = str(decoded, "utf-8")
    if decoded_str.isdigit():
        decoded_final = int(decoded_str)
    elif isfloat(decoded_str):
        decoded_final = float(decoded_str)
    else:
        decoded_final = decoded_str
    return decoded_final
