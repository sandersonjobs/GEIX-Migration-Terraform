#!/usr/bin/env python

import os
import requests
import json
import sys
import getpass
import logging
import ssl
from bs4 import BeautifulSoup
from prettytable import PrettyTable
from requests.adapters import HTTPAdapter

#requests.packages.urllib3.util.ssl_.DEFAULT_CIPHERS = 'ALL'

### GE ATL Stage
#keystoneUrl = "https://stage-us-east2.geix.cloud.ge.com:13000"
#shibbolethUri = '/v3/auth/OS-FEDERATION/websso/mapped?origin=https://stage-us-east2.geix.cloud.ge.com/dashboard/auth/websso/'

### GE ATL Production
keystoneUrl = "https://us-east2.geix.cloud.ge.com:13000"
shibbolethUri = '/v3/auth/OS-FEDERATION/websso/mapped?origin=https://us-east2.geix.cloud.ge.com/dashboard/auth/websso/'

sslverification = True
requests.packages.urllib3.disable_warnings()

FORCED_CIPHERS = (
    'ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:ECDH+HIGH:'
    'DH+HIGH:ECDH+3DES:DH+3DES:RSA+AESGCM:RSA+AES:RSA+HIGH:RSA+3DES'
)

# override the default PoolManager
class DESAdapter(HTTPAdapter):
    """
    A TransportAdapter that re-enables 3DES support in Requests.
    """
    def create_ssl_context(self):
        #ctx = create_urllib3_context(ciphers=FORCED_CIPHERS)
        ctx = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
        # allow TLS 1.0 and TLS 1.2 and later (disable SSLv3 and SSLv2)
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
def getUnscopedToken(username, password):
	session = requests.Session()
	session.mount('https://', DESAdapter())
	print ("Contacting Keystone...")
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
	print ("Authenticating with GE SSO...")
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
			print ("Validating GE SSO token with Keystone...")
			keystoneResponse = session.post(keystoneEndpoint, data=keystonePayload, verify=sslverification)
			newSoup = BeautifulSoup(keystoneResponse.text.encode('iso-8859-1'), "html.parser")
                        unscopedToken = newSoup.find('input').get('value')
                        return unscopedToken
		else:
			print ("GE SSO authentication failed.  Please verify your credentials.")
			sys.exit(1)
	else:
		print ("Unspecified error when authenticating against GE SSO.")
		sys.exit(1)

def checkUnscopedToken(unscopedToken):
	print ("Validating unscoped token...")
	keystoneResponse = requests.get(keystoneUrl + shibbolethUri, headers = {"X-Auth-Token":unscopedToken})
	if keystoneResponse.status_code != 200:
		return False
	else:
		return True

def main():
	try:
		unscopedToken = os.environ["OS_TOKEN"]
		if checkUnscopedToken(unscopedToken):
			pass
		else:
			unscopedToken = getUnscopedToken(username, password)
	except KeyError:
		username = raw_input("GE SSO: ")
		password = getpass.getpass()
		unscopedToken = getUnscopedToken(username, password)
		pass

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

	print ("Please select a project:")
	print (projectTable)

	projectId = int(raw_input("Please select a project (1-" + str(projectCount) + "): "))

	if os.name == "posix":
		envSet = "export"
		outFileName = "samlrc"
	elif os.name == "nt":
		envSet = "SET"
		outFileName = "samlrc.cmd"

	outFile = open(outFileName, "w")

	outFile.write(envSet + " OS_PROJECT_DOMAIN_ID=default" + os.linesep)
	outFile.write(envSet + " OS_IDENTITY_PROVIDER_URL=" + keystoneUrl + shibbolethUri + os.linesep)
	outFile.write(envSet + " OS_AUTH_TYPE=v3token" + os.linesep)
	outFile.write(envSet + " OS_PROTOCOL=saml2" + os.linesep)
	outFile.write(envSet + " OS_TOKEN=" + unscopedToken + os.linesep)
	outFile.write(envSet + " OS_PROJECT_ID=" + projectSelector[projectId - 1][0] + os.linesep)
	outFile.write(envSet + " OS_AUTH_URL=" + keystoneUrl + "/v3/" + os.linesep)
        outFile.write(envSet + " OS_INTERFACE=public" + os.linesep)
        outFile.write(envSet + " OS_IDENTITY_API_VERSION=3" + os.linesep)
	outFile.write("openstack token issue --fit-width" + os.linesep)

	if os.name == "posix":
		print (os.linesep + "Done!  Source 'samlrc' to continue:")
		print (". samlrc")
	elif os.name == "nt":
		print (os.linesep + "Done!  Please run 'samlrc.cmd' to continue.")

main()

