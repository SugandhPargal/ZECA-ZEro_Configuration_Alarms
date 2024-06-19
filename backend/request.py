import requests
url = 'http://localhost:5000/api'
r = requests.post(url,json=
    [{
    'Magnetometer x':-1.8161,
    'Magnetometer z':64.1164,
    'Orientation roll':-1.6991,
    'Proximity':1,
    'Screen':1},
    {
    'Magnetometer x':-0.8161,
    'Magnetometer z':64.1164,
    'Orientation roll':-0.6991,
    'Proximity':0,
    'Screen':1}]
    )
print(r.json())