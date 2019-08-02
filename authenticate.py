import os
import logging
import requests
import json
import sys
import getopt
import getpass
import subprocess
import pprint
import re
import logging
import ssl
import yaml
#import guestfs
import fileinput
import argparse
# Import get_flavors file
#from get_flavors import Flavor, get_flavor
# import partition
from bs4 import BeautifulSoup
from prettytable import PrettyTable
from os.path import expanduser
from shutil import copyfile
#from glanceclient import client
from requests.adapters import HTTPAdapter

logpath = str(os.getcwd()) + '/logs/' + sys.argv[0] + '.log'
logging.basicConfig(filename=logpath, level=logging.DEBUG)

### Read Config File
with open("config.yml", 'r') as ymlfile:
    cfg = yaml.load(ymlfile, Loader=yaml.FullLoader)

### GE ATL Production
keystoneUrl = cfg['keystone_auth']['keystone_url']
shibbolethUri = cfg['keystone_auth']['shibboleth_Uri']

sslverification = True
requests.packages.urllib3.disable_warnings()

FORCED_CIPHERS = (
    'ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:ECDH+HIGH:'
    'DH+HIGH:ECDH+3DES:DH+3DES:RSA+AESGCM:RSA+AES:RSA+HIGH:RSA+3DES'
)
SCRIPT_NAME = "authenticate.py"

class DESAdapter(HTTPAdapter):
    def create_ssl_context(self):
        ctx = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
        # Allow TLS 1.0 and TLS 1.2 and later (disable SSLv3 and SSLv2)
        ctx.options |= ssl.OP_NO_SSLv2
        ctx.options |= ssl.OP_NO_SSLv3
        ctx.set_ciphers( FORCED_CIPHERS )
        return ctx
    def init_poolmanager(self, *args, **kwargs):
        logging.debug(' ----------- DESAdapter.init_poolmanager -------------- ')
        kwargs['ssl_context'] = self.create_ssl_context()
        return super(DESAdapter, self).init_poolmanager(*args, **kwargs)
    def proxy_manager_for(self, *args, **kwargs):
        logging.debug(' ----------- DESAdapter.proxy_manager_for -------------- ')
        kwargs['ssl_context'] = self.create_ssl_context()
        return super(DESAdapter, self).proxy_manager_for(*args, **kwargs)

# Get the unscoped token from Keystone
def getUnscopedToken(username, password):
    session = requests.Session()
    session.mount('https://', DESAdapter())
    logging.info("Contacting Keystone...")
    response = session.get(keystoneUrl + shibbolethUri)
    if response.ok:
        soup = BeautifulSoup(response.text.encode('iso-8859-1'), "html.parser")
    payload = {}
    payload["username"] = username
    payload["password"] = password
    for inputtag in soup.find_all('input'):
        try: 
            if "submit" not in inputtag.get('name'):
                payload[inputtag.get('name')] = inputtag.get('value')
        except TypeError:
            continue
    logging.info("Authenticating with GE SSO...")
    authResponse = session.post("https://" + response.url.split('/')[2] + soup.find('form')["action"], data=payload, verify=sslverification)

    keystonePayload = {}
    if authResponse.ok:
        newSoup = BeautifulSoup(authResponse.text.encode('iso-8859-1'), "html.parser")
        for inputtag in newSoup.find_all('input'):
            try: 
                keystonePayload[inputtag.get('name')] = inputtag.get('value')
            except TypeError:
                continue
        keystoneEndpoint = newSoup.find('form').get('action')
        if "13000" in keystoneEndpoint:
            logging.info("Validating GE SSO token with Keystone...")
            keystoneResponse = session.post(keystoneEndpoint, data=keystonePayload, verify=sslverification)
            newSoup = BeautifulSoup(keystoneResponse.text.encode('iso-8859-1'), "html.parser")
            unscopedToken = newSoup.find('input').get('value')
            return unscopedToken
        else:
            logging.error("GE SSO authentication failed. Please verify your credentials.")
            sys.exit(1)
    else:
        logging.error("Unspecified error when authenticating against GE SSO.")
        sys.exit(1)

# Verify the token retrieved from Keystone
def checkUnscopedToken(unscopedToken):
    print("Validating unscoped token...")
    keystoneResponse = requests.get(keystoneUrl + shibbolethUri, headers = {"X-Auth-Token":unscopedToken})
    if keystoneResponse.status_code != 200:
        logging.info("Check failed")
        return False
    else: 
        logging.info("Check succeeded")
        return True

def getProject(unscopedToken):
    # Get the list of projects
    keystoneResponse = requests.get(keystoneUrl + "/v3/OS-FEDERATION/projects", headers = {"X-Auth-Token":unscopedToken})
    projectTable = PrettyTable(["number", "id", "name"])
    projectJson = json.loads(keystoneResponse.text)["projects"]
    projectSelector = []
    projectJson.sort(key=lambda i:i['name'])
    projectCount = 0
    for each in projectJson:
        projectCount += 1
        projectSelector.append([each["id"], each["name"]])
        projectId = each["id"]
        projectName = each["name"]
        projectTable.add_row([projectCount, projectId, projectName])

    # If there is only one project, use that; else, choose the project to use
    if projectCount == 1:
        projectId = int(1)
        pass
    else:
        print("Please select a project:")
        logging.info(projectTable)
        projectId = int(raw_input("Please select a project (1-" + str(projectCount) + "): "))

    # Set the required parameters to use an openstack command
    OS_PROJECT_DOMAIN_ID = "default"
    OS_IDENTITY_PROVIDER_URL = keystoneUrl + shibbolethUri
    OS_AUTH_TYPE = "v3token"
    OS_PROTOCOL = "saml2"
    OS_TOKEN = unscopedToken
    OS_PROJECT_ID = projectSelector[projectId - 1][0]
    OS_AUTH_URL = keystoneUrl + "/v3/"
    OS_INTERFACE = "public"
    OS_IDENTITY_API_VERSION = '3'

    os_params = '--os-project-domain-id ' + OS_PROJECT_DOMAIN_ID + ' --os-identity-provider ' + OS_IDENTITY_PROVIDER_URL + ' --os-auth-type ' + OS_AUTH_TYPE + ' --os-auth-url ' + OS_AUTH_URL + ' --os-auth-type ' + OS_AUTH_TYPE + ' --os-protocol ' + OS_PROTOCOL + ' --os-token ' + OS_TOKEN + ' --os-project-id ' + OS_PROJECT_ID + ' --os-auth-url ' + OS_AUTH_URL + ' --os-interface ' + OS_INTERFACE + ' --os-identity-api-version ' + OS_IDENTITY_API_VERSION
    return os_params


if __name__ == '__main__':


    token = os.environ.get("OS_TOKEN")

    if (token != None and checkUnscopedToken(token)):
        print("Current token is still good...passing")
        exit(0)
    else:
        token = getUnscopedToken(cfg['creds']['username'],cfg['creds']['password'])
        settings = {
            "OS_PROJECT_DOMAIN_ID": "default",
            "OS_IDENTITY_PROVIDER_URL": keystoneUrl + shibbolethUri,
            "OS_AUTH_TYPE": "v3token",
            "OS_PROTOCOL": "saml2",
            "OS_TOKEN": token,
            "OS_PROJECT_ID": cfg['keystone_auth']['project_id'],
            "OS_AUTH_URL": keystoneUrl + "/v3/",
            "OS_INTERFACE": "public",
            "OS_IDENTITY_API_VERSION": '3'
        }

        f = open("env_vars.sh", "w")
        for setting,setting_val in settings.items():
            f.write("export {setting}={setting_val}\n".format(setting=setting,setting_val=setting_val))
        f.close()
        exit(0)
