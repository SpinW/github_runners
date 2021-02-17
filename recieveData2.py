from flask import Flask, request
import json
import subprocess
import os

app = Flask(__name__)

defaults = {
    'linux': {
        'gh_action_work_dir': '/home/github/work',
        'runner_version': '2.276.0',
        'filename': 'bootstrap_vars.sh',
        'export_cmd': 'export'
    }
}


def write_vars(owner, repo, PAT, defaults):
    filename = defaults['filename']
    with open(filename, 'w') as fid:
        fid.write(f'{defaults["export_cmd"]} GITHUB_RUNNER_VERSION={defaults["runner_version"]}\n')
        fid.write(f'{defaults["export_cmd"]} RUNNER_WORKDIR={defaults["gh_action_work_dir"]}\n')
        fid.write(f'{defaults["export_cmd"]} GITHUB_OWNER={owner}\n')
        fid.write(f'{defaults["export_cmd"]} GITHUB_REPOSITORY={repo}\n')
        fid.write(f'{defaults["export_cmd"]} GITHUB_PAT={PAT}\n')


@app.route('/', methods=['POST'])
def index():
    if request.method == 'POST':
        github_request = json.loads(request.data)
        req_data = github_request['data']
        repo_data = github_request['repository']
        owner, repo = repo_data.split('/')
        if req_data.get('ghcontrol', False):
            if req_data.get('server', False):
                if req_data['ghcontrol'] == 'create':
                    PAT = req_data.get('PAT', False)
                    if not PAT:
                        return '{"success":"false", "info":"PAT not supplied"}'
                    print(f'Bringing up server: {req_data["server"]}')
                    write_vars(owner, repo, req_data['PAT'], defaults[req_data["server"]])
                    try:
                        subprocess.run(['vagrant', 'up', req_data["server"]])
                    finally:
                        os.remove(defaults[req_data['server']]['filename'])
                elif req_data['ghcontrol'] == 'destroy':
                    print(f'Destroying server: {req_data["server"]}')
                    subprocess.run(['vagrant', 'destroy', req_data["server"], '-f'])
                return '{"success":"true", "info":"server actions complete"}'
            else:
                info ='server data was not supplied'
                print(info + '. I am not doing anything')
        else:
            info = 'ghcontrol data was not supplied'
            print(info + '. I am not doing anything')
        return '{"success":"false", "info":"' + info + '"}'

if __name__ == "__main__":   
    app.run(host='127.0.0.1', port=4000, threaded=True, debug=True) # will listen on port 4000
