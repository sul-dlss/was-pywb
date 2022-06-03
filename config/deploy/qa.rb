# frozen_string_literal: true

server 'was-pywb-qa.stanford.edu', user: 'was', roles: 'app'

# allow SSH to host
Capistrano::OneTimeKey.generate_one_time_key!
