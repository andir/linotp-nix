#! /usr/bin/env python3

import argparse
import io
import json
import logging
import requests
import sys
import time
from requests.auth import HTTPDigestAuth

LOG = logging.getLogger(__name__)


parser = argparse.ArgumentParser()
parser.add_argument('--linotp', help="Linotp base url e.g. https://linotp", default='https://linotp')
parser.add_argument('--debug', help='enable debug log level', action='store_true', default=False)

def main():
    args = parser.parse_args()
    logging.basicConfig(level=logging.DEBUG if args.debug else logging.INFO)


    LOG.info("Using LinOTP base url: %s", args.linotp)
    #LOG.info("Using puppet phone base url: %s", args.puppet_phone)

    session = requests.Session()

    session.verify = False
    session.auth = HTTPDigestAuth('admin', 'admin')

    response = session.post('{}/admin/getsession'.format(args.linotp))
    LOG.info('get session response: %s', response.text)
    session_param = list(session.cookies.values())[-1]

    # import users from CSV

    LOG.info("Importing users")
    csv_file = io.StringIO("user,20,,test user,,,,password")

    req = session.post('{}/tools/import_users'.format(args.linotp),
            data=dict(
                session=session_param,
                delimiter=',',
                quotechar='"',
                dryrun="false",
                resolver="def-passwd-plain",
                passwords_in_plaintext=True
            ),
            files=[('file', ('def-password-plain.csv', csv_file, 'text/csv'))]
    )
    LOG.info('import users body: %s', req.request.body)
    LOG.info('import users result: %s', req.text)


    # set realm

    LOG.info("Setting realm")
    req = session.post('{}/system/setRealm'.format(args.linotp),
            data=dict(
                realm="lino",
                resolvers="useridresolver.SQLIdResolver.IdResolver.def-passwd-plain",
                session=session_param,
            ))
    LOG.info('Setting realm result: %s', req.text)

    # set policies
    LOG.info("Setting policies")
    policies = [
    #    dict(name='challenge_response', user='*', realm='*', client='*', active=True, scope='authentication', action='challenge_response=*'),
    #    dict(name='default_provider', user='*', realm='*', client='*', active=True, scope='authentication', action='push_provider=default_push, '),
    #    dict(name='selfservice', user='*', realm='*', client='*', active=True, scope='selfservice', action='enrollPUSH, activate_PushToken'),
    ]

    for policy in policies:
        LOG.info("Setting policy: %s", policy)
        policy.update(session=session_param)
        req = session.post('{}/system/setPolicy'.format(args.linotp), data=policy)
        LOG.info("Setting policy result: %s", req.text)


    # Selfservice login
    LOG.info("Logging into selfservice as user:password")
    user_session = requests.Session()
    user_session.verify = False

    req = user_session.post('{}/userservice/login'.format(args.linotp), data=dict(login='user', password='password'))
    LOG.info('User login result: %s', req.text)
    LOG.info('User login request body: %s', req.request.body)
    user_session_cookie = list(user_session.cookies.values())[-1]
    LOG.info("User session cookie: %s", user_session_cookie)

    # enroll user push token
    PIN = '1234'
    LOG.info("Enrolling static password token with PIN %s", PIN)
    req = session.post('{}/admin/init'.format(args.linotp),
            data=dict(
              description='password token',
              serial="bestertoken",
              otppin=PIN,
              type='pw',
              otpkey=PIN,
              user="user",
              session=session_param,
        )
    )
    LOG.info("enrollment response: %s", req.text)
    response = req.json()
    LOG.info("enrollment detail: %s", response["detail"])
    LOG.info("serial: %s", response["detail"]['serial'])
    serial = response["detail"]['serial']

    req = session.post('{}/admin/show'.format(args.linotp),
            data=dict(
              session=session_param,
            )
    )

    LOG.info("admin info: %s", req.text)


if __name__ == "__main__":
    main()
