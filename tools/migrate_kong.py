#!/bin/env python
# coding:utf8

import re
import time
import pickle
import argparse
import requests
from pprint import pprint


def change_upstream(upstream_url, new_profile):
    # hideweb特殊处理
    if 'hidevopsio' in upstream_url and 'web' in upstream_url:
        return 'http://hiweb.hidevopsio:8080'
    # hidevopsio特殊处理
    if 'hidevopsio' in upstream_url:
        return upstream_url.encode('utf8')
    reg = re.compile(r"http://.*-(.*):\d+")
    matchs = reg.findall(upstream_url)
    if len(matchs) == 1:
        profile = matchs[0]
        return upstream_url.replace(profile, new_profile).encode('utf8').replace("{0}uct".format(new_profile), "product")
    elif 'app' in upstream_url:
        router = upstream_url.split(".")[0]
        router_reg = re.compile(r"http://(.*)-(\w+-\w+)")
        app, project = router_reg.findall(router)[0]
        project_profile = re.findall(r'\w+-(\w+)', project)[0]
        new_project = project.replace(project_profile, new_profile)
        return 'http://{0}.{1}:8080'.format(app, new_project).replace("{0}uct".format(new_profile), "product")
    else:
        return upstream_url.encode('utf8').replace("{0}uct".format(new_profile), "product")
        

class Kong(object):
    def __init__(self, admin_url):
        self.admin_url = admin_url

    def export(self, filename):
        try:
            url = '{0}/apis?size=2000'.format(self.admin_url)
            resp = requests.get(url)
            if resp.status_code == 200:
                with open(filename, 'wb') as f:
                    pickle.dump(resp.json(), f)
                return True
            else:
                pprint("Oops, some wring in here ,The response code is {}".format(resp.status_code))
        except Exception as e:
            pprint('Export Failed')
            pprint(e)

    def cleanall(self):
        resp = requests.get('{0}/apis?size=1000'.format(self.admin_url)).json()
        apis = resp.get('data')
        if not apis:
            pprint("The Kong admin seem no data yet")
            exit(1)
        for api in apis:
            name = api.get('name')
            resp = requests.delete('{0}/apis/{1}'.format(self.admin_url, name))
            if resp.status_code != 204:
                pprint('{0} delete failed'.format(name))

    def _create(self, api_data):
        create_url = '{0}/apis/'.format(self.admin_url)
        resp = requests.post(create_url, api_data)
        if resp.status_code != 201:
            pprint('{0}'.format(resp.text))

    def dump(self, filename):
        try:
            with open(filename, 'rb') as f:
                resp = pickle.load(f)
            for api in resp.get('data'):
                hosts = list()
                uris = list()
                orig_hosts = api.get('hosts')
                hosts.append(','.join(orig_hosts))
                orig_uris = api.get('uris')
                uris.append(','.join(orig_uris))
                api['hosts'] = hosts
                api['uris'] = uris
                self._create(api)
        except Exception as e:
            pprint("Oops, some wrong occurd {}, May be the file not dump file".format(e))

    def migrate(self, filename, host, project, profile, prefix):
        hosts = list()
        hosts.append(host)
        with open(filename, 'rb') as f:
            resp = pickle.load(f)
        base_projects = [ 
            "moses", "cmbs", "fastdfs", "kong",
            "unauthenticated", "hidevopsio"
        ]
        if not resp.get('data'):
            pprint("The dump file semm not data yet, Please check it")
            exit(2)
        for api in resp.get('data'):
            uris = list()
            old_uris = api.get('uris')
            if prefix:
                old_uris = '/{0}{1}'.format(prefix, old_uris)
            uris.append(','.join(old_uris))
            api['hosts'] = hosts
            api['uris'] = uris
            upstream_url = api.get('upstream_url')
            new_upstream_url = change_upstream(upstream_url, profile)
            api["upstream_url"] = new_upstream_url
            if project == 'all':
                self._create(api)
            else:
                base_projects.append(project)
                if any([prefix in url.encode('utf8')
                        for prefix in base_projects
                        for url in uris]):
                    self._create(api)
                    pprint(new_upstream_url)


class Check(object):
    def __init__(self, arg_ns):
        self.arg_ns = arg_ns

    def check(self):
        action = self.arg_ns.action
        src = self.arg_ns.src
        dest = self.arg_ns.dest
        host = self.arg_ns.host
        filename = self.arg_ns.filename
        if action == 'import' or action == 'export' or action == 'migrate':
            if not filename:
                pprint("--filename must exists!")
                return False
            if action == 'export':
                if not src:
                    pprint("when action is export, --src must exists")
                    return False
            if action == 'migrate':
                if not (dest and host):
                    pprint("when action is migrate, --dest and --host must exists")
                    return False
            if action == 'import':
                if not dest:
                    pprint("when action is import, --dest must exists")
                    return False
        elif action == 'cleanall':
            if not dest:
                pprint("when action is cleanall, --dest must exists")
                return False
        else:
            pprint("not support action, use -h")
            return False
        return True


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=('Export/Import Kong apis by Kong admin api'))
    parser.add_argument("--action", help="import/export  kong api data", choices=["import", "export", "cleanall", "migrate"])
    kong_group = parser.add_mutually_exclusive_group()
    kong_group.add_argument("--src", help="Export's kong admin, like http://IP:PORT")
    kong_group.add_argument("--dest", help="import's kong admin,like http://IP:PORT")
    parser.add_argument("--host", help="migrate to new kong host")
    parser.add_argument("--project", help="Import's project, default all", default="all")
    parser.add_argument("--profile", help="new environment, default is dev", default="dev")
    parser.add_argument("--filename", help="export to filename or load from filename")
    parser.add_argument("--prefix", help="The URIS add the prefix,example /moses to /prefix/moses", default=None)
    args = parser.parse_args()
    check = Check(args)
    if check.check():
        if args.action == 'export':
            pprint("export")
            src_kong = Kong(args.src)
            src_kong.export(args.filename)
        elif args.action == 'migrate':
            dest_kong = Kong(args.dest)
            dest_kong.migrate(args.filename, args.host, args.project, args.profile, args.prefix)
        elif args.action == 'cleanall':
            pprint('Warning,You will delete {0} all apis'.format(args.dest))
            pprint("Sleep 20 second")
            time.sleep(20)
            dest_kong = Kong(args.dest)
            dest_kong.cleanall()
        elif args.action == "import":
            dest_kong = Kong(args.dest)
            dest_kong.dump(args.filename)
    else:
        pprint("Oops, yun don't use the script right, Plase use -h to get help")