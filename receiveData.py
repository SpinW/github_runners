from flask import Flask, request

app = Flask(__name__)

@app.route('/', methods=['POST'])
def index():
    if request.method == 'POST':
        req_data = request.form
        if req_data.get('ghcontrol', False):
            if req_data.get('server', False):
                if req_data['ghcontrol'] == 'create':
                    print(f'Bringing up server: {req_data["server"]}')
                elif req_data['ghcontrol'] == 'destroy':
                    print(f'Destroying server: {req_data["server"]}')
            else:
                print('No "server" data. I am not doing anything')
        else:
            print('No "ghcontrol" data. I am not doing anything')
        return '{"success":"true"}'


if __name__ == "__main__":   
    app.run(host='127.0.0.1', port=4000, threaded=True, debug=True) # will listen on port 5000