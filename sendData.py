__author__ = 'github.com/wardsimon'
__version__ = '0.0.1'

import requests

url = 'http://ylfv9iicoffywpdjeurqjy.webrelay.io'
data = {'ghcontrol': 'create',
        'server': 'linux'}

r = requests.post(url, data=data)

data = {'ghcontrol': 'destroy',
        'server': 'linux'}

r = requests.post(url, data=data)
