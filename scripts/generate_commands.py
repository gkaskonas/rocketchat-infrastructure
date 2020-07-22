# mongo --quiet --eval rs.initiate( {_id : "rocketchat", members: [{ _id: 0, host: "ec2-54-171-217-206.eu-west-1.compute.amazonaws.com"}, {_id: 1, host: "ec2-52-215-219-81.eu-west-1.compute.amazonaws.com"}]})
# 

import json
import sys
import os


def read_hosts(path):

    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), path)

    with open(path) as json_data:
        hosts = json.load(json_data)
    
    return hosts

def generate_mongo_command(hosts):

    index = 0
    line = ''
    for host in hosts:

        line += "{0}_id: {1}, host: '{2}'{3},".format('{', index, host, '}')
        index += 1
    
    line = line[:-1]
    final_string = "#!/bin/bash\nmongo --eval \"printjson(rs.initiate({0}_id: \'rocketchat\', members: [{1}]{2}))\"".format('{', line, '}')

    f = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), '../ansible_stuff/init_mongo'), 'w')
    f.write(final_string)
    f.close()

    return final_string

def generate_rocketchat_command(hosts):

    line = ''
    for host in hosts:
        line += '{0}:27017,'.format(host)
    
    mongo_url = 'mongodb://{0}'.format(line)[:-1]


    final_string = "#!/bin/bash\nsudo docker run -d -v /mnt/efs/rocketchat:/app/uploads -e PORT=3000 -e ROOT_URL=https://rocketchat.example.co.uk \
    -e MONGO_URL={0}/rocketchat?replicaSet=rocketchat -e MONGO_OPLOG_URL={0}/local?replicaSet=rocketchat -e Accounts_UseDNSDomainCHeck=True -p 3000:3000 rocket.chat:latest".format(mongo_url)

    f = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), '../ansible_stuff/init_rocketchat'), 'w')
    f.write(final_string)
    f.close()

    return final_string

def generate_ansible_inv(m_hosts, r_hosts):

    inv_file = '[webservers]\n'

    for host in r_hosts:
        inv_file += host + '\n'
    
    inv_file += '[dbservers]\n'

    for host in m_hosts:
        inv_file += host + '\n'
        break
    
    f = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), '../ansible_stuff/ansible_hosts'), 'w')
    f.write(inv_file)
    f.close()

    return inv_file

def generate_efs_command(efs_dns):

    final_string = "sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport {0}:/ /mnt/efs/rocketchat".format(efs_dns)

    
    f = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), '../ansible_stuff/init_efs'), 'w')
    f.write(final_string)
    f.close()

    return final_string
    

if __name__ == '__main__':

    mongo_path = sys.argv[1]

    rocketchat_path = sys.argv[2]

    efs_path = sys.argv[3]
    

    mongo_hosts = read_hosts(mongo_path)
    rocketchat_hosts = read_hosts(rocketchat_path)
    efs_dns = read_hosts(efs_path)
    mongo_command = generate_mongo_command(mongo_hosts)
    rocketchat_command = generate_rocketchat_command(mongo_hosts)
    efs_command = generate_efs_command(efs_dns)

    ansible_inv = generate_ansible_inv(mongo_hosts, rocketchat_hosts)

    print(mongo_command)

    print(ansible_inv)
    print(efs_command)

