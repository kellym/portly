#!/usr/bin/ruby

require 'rubygems'
require 'daemons'

Daemons.run('data_monitor.rb')
