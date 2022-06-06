# frozen_string_literal: true

server 'was-pywb-prod.stanford.edu', user: 'was', roles: 'app'

# allow SSH to host
Capistrano::OneTimeKey.generate_one_time_key!
