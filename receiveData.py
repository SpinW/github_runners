from flask import Flask, request
import json
import subprocess
import os
import re
import shutil

app = Flask(__name__)

defaults = {
    'linux': {
        'gh_action_work_dir': '/home/github/work',
        'runner_version': '2.276.0',
        'filename': 'bootstrap_vars_linux.sh',
        'export_cmd': 'export'
    },
    'windows': {
        'gh_action_work_dir': 'c:/github/',
        'runner_version': '2.276.0',
        'filename': 'bootstrap_vars_windows',
        'export_cmd': ''
    },
    'macos': {
        'gh_action_work_dir': '/Users/github/work',
        'runner_version':     '2.276.0',
        'filename':           'bootstrap_vars_macos.sh',
        'export_cmd': 'export'
    }
}


def ssl_decode(value):
    with open('ssl_pw.txt', 'r') as f:
        ssl_pw = f.read().strip()
    value = value.replace('_', '\n').encode()
    ssl = subprocess.run(['openssl', 'enc', '-aes-256-cbc', '-d', '-a', '-pbkdf2', '-k', ssl_pw],
        input=value, stderr=subprocess.PIPE, stdout=subprocess.PIPE)
    return ssl.stdout.decode()


def write_vars(owner, repo, PAT, defaults, wd=''):
    filename = f'{wd}/{defaults["filename"]}'
    with open(filename, 'w') as fid:
        fid.write(f'{defaults["export_cmd"]} GITHUB_RUNNER_VERSION={defaults["runner_version"]}\n')
        fid.write(f'{defaults["export_cmd"]} RUNNER_WORKDIR={defaults["gh_action_work_dir"]}\n')
        fid.write(f'{defaults["export_cmd"]} GITHUB_OWNER={owner}\n')
        fid.write(f'{defaults["export_cmd"]} GITHUB_REPOSITORY={repo}\n')
        fid.write(f'{defaults["export_cmd"]} GITHUB_PAT={PAT}\n')
        fid.write(f'{defaults["export_cmd"]} GITHUB_ID="{wd}"\n')


def create_working_dir(dirname):
    os.makedirs(dirname, exist_ok=True)
    # Search/replace so image name has ID in it
    fout = open(dirname + '/Vagrantfile', 'w')
    with open('Vagrantfile.idtemplate', 'r') as f_in:
        for line in f_in:
            fout.write(line.replace('_IDSTR', f'_{dirname}'))
    fout.close()
    shutil.copy('bootstrap_linux.sh', dirname)
    shutil.copy('bootstrap_macos.sh', dirname)
    shutil.copy('bootstrap_windows.ps1', dirname)
    print(f'Working dir {dirname} created', flush=True)


@app.route('/', methods=['POST'])
def index():
    if request.method == 'POST':
        github_request = json.loads(request.data)
        req_data = github_request['data']
        repo_data = github_request['repository']
        owner, repo = repo_data.split('/')
        if not req_data.get('ghcontrol', False):
            info = 'ghcontrol data was not supplied'
            print(info + '. I am not doing anything', flush=True)
            return '{"success":"false", "info":"' + info + '"}'
        if not req_data.get('servers', False):
            info ='server data was not supplied'
            print(info + '. I am not doing anything', flush=True)
            return '{"success":"false", "info":"' + info + '"}'
        ID = req_data.get('ID', '')
        wd = ID if ID else None
        if ID and req_data['ghcontrol'] == 'create':
            # Create a working directory for each job
            create_working_dir(ID)
        processes = {}
        for server in re.sub(r'[\[\]\s]', '', req_data['servers']).split(','):
            server_type = server.split('-')[0]
            server_name = f'{server_type}_{ID}'
            if req_data['ghcontrol'] == 'create':
                PAT = ssl_decode(req_data.get('PAT', False))
                if not PAT:
                    return '{"success":"false", "info":"PAT not supplied"}'
                print(f'Bringing up server: {server_name}', flush=True)
                write_vars(owner, repo, PAT, defaults[server_type], ID)
                processes[server_name] = subprocess.Popen(['vagrant', 'up', server_name], cwd=wd)
            elif req_data['ghcontrol'] == 'destroy':
                print(f'Destroying server: {server_name}', flush=True)
                processes[server_name] = subprocess.Popen(['vagrant', 'destroy', server_name, '-f'], cwd=wd)
        retval = {}
        for proc in processes:
            retval[proc] = processes[proc].wait()
            print(f'Done {req_data["ghcontrol"]} server {proc}', flush=True)
        if all([retval[rv]==0 for rv in retval]):
            if ID and req_data['ghcontrol'] == 'destroy':
                shutil.rmtree(ID)
            print(f'Success doing {req_data["ghcontrol"]} on all servers', flush=True)
            return '{"success":"true", "info":"server actions complete"}'
        else:
            for proc in [rv for rv in retval if retval[rv]!=0]:
                print(f'Failed: An error occured in vagrant command when: ' 
                      f'{req_data["ghcontrol"]} server {proc}', flush=True)
            return '{"success":"false", "info":"error occured in vagrant command"}'


if __name__ == "__main__":   
    app.run(host='127.0.0.1', port=4000, threaded=True, debug=True) # will listen on port 4000
