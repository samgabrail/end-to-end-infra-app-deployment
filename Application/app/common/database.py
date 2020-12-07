__author__ = 'SamG'

import pymongo, os, requests
from environs import Env

class Database(object):
    ENCRYPT = True
    env = Env()
    # Read .env into os.environ
    env.read_env()
    SERVER = env('DB_SERVER')
    # SERVER = os.environ['DB_SERVER']
    PORT = env('DB_PORT')
    # PORT = os.environ['DB_PORT']
    VAULT_URL = env('VAULT_URL')
    # Uncomment USER and PASSWORD below to grab creds from .env file
    # USER = env('DB_USER')
    # PASSWORD = env('DB_PASSWORD')
    # Uncomment USER and PASSWORD below to show Vault's functionality
    USER = None
    PASSWORD = None
    URI = ''
    DATABASE = None

    @staticmethod
    def getDynamicSecret_API(vault_token):
        response = requests.get(f'{Database.VAULT_URL}/v1/mongodb_azure/creds/mongodb-azure-role',
        params={'q': 'requests+language:python'},
        headers={'X-Vault-Token': vault_token},
        )
        json_response = response.json()
        print(f'response is:')
        print(json_response)
        Database.USER = json_response['data']['username']
        Database.PASSWORD = json_response['data']['password']

    @staticmethod
    def buildURI_Injected_StaticKVsecrets():
        env = Env()
        # Read .env into os.environ
        env.read_env('/app/secrets/.envapp')
        Database.USER = env('DB_USER')
        Database.PASSWORD = env('DB_PASSWORD')

    @staticmethod
    def buildURI_Injected_DynamicSecrets():
        with open("/tmp/vault_token") as f: 
            VAULT_TOKEN = f.readlines()
            VAULT_TOKEN = VAULT_TOKEN[0].strip('\n')
        print(f'Vault token = {VAULT_TOKEN}')
        Database.getDynamicSecret_API(VAULT_TOKEN)

    @staticmethod
    def initialize():
        # Uncomment the 2 lines below to show Vault grabbing static secrets that were injected by the K8s injector
        # print('Initializing Database using Static Injected Secrets from Vault')
        # Database.buildURI_Injected_StaticKVsecrets()
        # Uncomment the 2 lines below to show Vault grabbing Dynamic secrets by utilizing an injected Vault token by the K8s injector
        print('Initializing Database using Dynamic Secrets from Vault')
        Database.buildURI_Injected_DynamicSecrets()
        Database.URI = f'mongodb://{Database.USER}:{Database.PASSWORD}@{Database.SERVER}:{Database.PORT}'
        print(f'Database Server: {Database.SERVER} and PORT: {Database.PORT} and user: {Database.USER} and password: {Database.PASSWORD}')
        client = pymongo.MongoClient(Database.URI)
        if Database.ENCRYPT:
            Database.DATABASE = client['webblogencrypted']
        else:
            Database.DATABASE = client['webblog']

    @staticmethod
    def insert(collection, data):
        Database.DATABASE[collection].insert(data)

    @staticmethod
    def find(collection, query):
        return Database.DATABASE[collection].find(query)

    @staticmethod
    def find_one(collection, query):
        try:
            return Database.DATABASE[collection].find_one(query)
        except pymongo.errors.OperationFailure:
            print(f'mongoDB auth failed due to creds expiring. Rotating creds now')
            Database.initialize()
            return Database.DATABASE[collection].find_one(query)

        