from flask import Flask, request
import json
import subprocess

app = Flask(__name__)

@app.route('/', methods=['POST'])
def index():
    if request.method == 'POST':
        github_request = json.loads(request.data)
        req_data = github_request['data']
        if req_data.get('ghcontrol', False):
            if req_data.get('server', False):
                if req_data['ghcontrol'] == 'create':
                    print(f'Bringing up server: {req_data["server"]}')
                    subprocess.run(['vagrant', 'up', req_data["server"]])
                elif req_data['ghcontrol'] == 'destroy':
                    print(f'Destroying server: {req_data["server"]}')
                    subprocess.run(['vagrant', 'destroy', req_data["server"], '-f'])
            else:
                print('No "server" data. I am not doing anything')
        else:
            print('No "ghcontrol" data. I am not doing anything')
        return '{"success":"true"}'


if __name__ == "__main__":   
    app.run(host='127.0.0.1', port=4000, threaded=True, debug=True) # will listen on port 4000