#!/usr/bin/env python

import sys
import struct
import httplib
import base64
import time
import datetime
import binascii
import json
import threading
import Queue

class Job(object):
  def __init__(self, pool, state, data, check = None):
    self.pool = pool
    self.state = state
    self.data = data
    self.check = check

class Pool(object):
  def __init__(self, dict):
    self.__dict__ = dict

  def sendresult(self, job, nonce):
    self.miner.log("Found share: %s:%s:%s:%s\n" % (self.name, binascii.hexlify(job.state), binascii.hexlify(job.data[64:76]), binascii.hexlify(nonce)))
    uploader = threading.Thread(None, self.uploadresult, self.name + "_uploadresult_" + binascii.hexlify(nonce), (job, nonce))
    uploader.daemon = True
    uploader.start()

  def uploadresult(self, job, nonce):
    failed = 0
    while True:
      for s in self.servers:
        try:
          conn = httplib.HTTPConnection(s.host, s.port, True, self.sendsharetimeout)
          req = json.dumps({"method": "getwork", "params": [binascii.hexlify(job.data[:76] + nonce + job.data[80:])], "id": 0})
          headers = {"User-Agent": "PyFPGAMiner " + miner.version, "Content-type": "application/json", "Content-Length": len(req), "Authorization": self.auth}
          conn.request("POST", s.path, req, headers)
          response = json.loads(conn.getresponse().read())
          self.miner.log(str(response))
          if response["error"] != None: raise Exception("Server reported error: %s" % response["error"])
          if response["result"]:
            self.miner.log("%s accepted share %s\n" % (self.name, binascii.hexlify(nonce)))
            self.accepted = self.accepted + 1
          else:
            self.miner.log("%s rejected share %s\n" % (self.name, binascii.hexlify(nonce)))
            failed = failed + 1
            if failed <= self.retrystales: continue
            self.rejected = self.rejected + 1
          return
        except Exception as e:
          self.miner.log("Error while uploading share to %s (%s:%d): %s\n" % (self.name, s.host, s.port, e))
          self.uploadretries = self.uploadretries + 1
      time.sleep(1)

  def getwork(self):
    while True:
      job = None
      for s in self.servers:
        if s.disabled > 0:
          s.disabled = s.disabled - 1
          continue
        try:
          self.requests = self.requests + 1
          conn = httplib.HTTPConnection(s.host, s.port, True, self.getworktimeout)
          req = json.dumps({"method": "getwork", "params": [], "id": 0})
          headers = {"User-Agent": "PyFPGAMiner " + miner.version, "Content-type": "application/json", "Content-Length": len(req), "Authorization": self.auth}
          conn.request("POST", s.path, req, headers)
          response = conn.getresponse()
          if not self.longpolling:
            headers = response.getheaders()
            for h in headers:
              if h[0] == "x-long-polling":
                url = h[1]
                try:
                  if url[0] == "/": url = "http://" + s.host + ":" + str(s.port) + url
                  if url[:7] != "http://": raise Exception()
                  parts = url[7:].split("/", 2)
                  path = "/" + parts[1]
                  parts = parts[0].split(":")
                  if len(parts) != 2: raise Exception()
                  host = parts[0]
                  port = parts[1]
                  self.miner.log("Found long polling URL for %s: %s\n" % (self.name, url), self.miner.green)
                  self.longpolling = True
                  self.longpollingthread = threading.Thread(None, self.longpollingworker, self.name + "_longpolling", (host, port, path))
                  self.longpollingthread.daemon = True
                  self.longpollingthread.start()
                except:
                  self.miner.log("Invalid long polling URL for %s: %s\n" % (self.name, url))
                break
          response = json.loads(response.read())
          state = binascii.unhexlify(response["result"]["midstate"])
          data = binascii.unhexlify(response["result"]["data"])
          job = Job(self, state, data)
          break
        except Exception as e:
          self.miner.log("Error while requesting job from %s (%s:%d): %s\n" % (self.name, s.host, s.port, e))
          s.disabled = 10
          self.failedreqs = self.failedreqs + 1
      if job != None:
        if self.longpollhit: self.longpollkilled = self.longpollkilled + 1
        else: self.queue.put(job)
        self.longpollhit = False
      else: time.sleep(1)

  def longpollingworker(self, host, port, path):
    while True:
      try:
        conn = httplib.HTTPConnection(host, port, True, self.longpolltimeout)
        headers = {"User-Agent": "PyFPGAMiner " + miner.version, "Authorization": self.auth}
        conn.request("GET", path, None, headers)
        response = json.loads(conn.getresponse().read())
        self.miner.log("Long polling: %s indicates that a new block was found\n" % self.name)
        state = binascii.unhexlify(response["result"]["midstate"])
        data = binascii.unhexlify(response["result"]["data"])
        job = Job(self, state, data)
        self.longpollhit = True
        while True:
          try:
            if not self.longpollhit: break
            self.queue.get(True, 0.1)
            self.longpollkilled = self.longpollkilled + 1
          except: break
        self.requests = self.requests + 1
        if self.miner.lastlongpoll > datetime.datetime.utcnow():
          self.queue.put(job)
        else:
          self.jobsaccepted = self.jobsaccepted + 1
          self.miner.mine(job, True)
          self.miner.lastlongpoll = datetime.datetime.utcnow() + datetime.timedelta(seconds = self.miner.longpollgrouptime)
      except: pass

class Server(object):
  def __init__(self, dict):
    self.__dict__ = dict

class Miner(object):
  def __init__(self, config, logfile):
    self.version = "0.0.2"
    self.config = config
    self.logfile = logfile

  def log(self, str):
    self.conlock.acquire()
    self.logfile.write(str)
    self.logfile.flush()
    print str
    self.conlock.release()

  def die(self, rc, str):
    self.rc = rc
    self.log(str)
    sys.stderr.write(str)
    sys.stderr.flush()
    exit(rc)

  def showstats(self):
    self.conlock.acquire()
    versionstr = "PyFPGAMiner v. " + self.version
    #if hasattr(self, "mhps"):
      #print "FPGA speed: \n"+"%.1f MH/s" % self.mhps
      #print " - job interval: "+"%.2fs" % self.fpgajobinterval
    self.conlock.release()

  def run(self):
    self.rc = 0
    self.conlock = threading.RLock()
    self.fpgalock = threading.RLock()
    self.buffer = getattr(config, "buffer", 2)
    self.fpgajobinterval = getattr(config, "fpgajobinterval", 999)
    self.fpgapollinterval = getattr(config, "fpgapollinterval", 1)
    self.getworktimeout = getattr(config, "getworktimeout", 20)
    self.sendsharetimeout = getattr(config, "sendsharetimeout", 20)
    self.longpolltimeout = getattr(config, "longpolltimeout", 120)
    self.longpollgrouptime = getattr(config, "longpollgrouptime", 20)
    self.retrystales = getattr(config, "retrystales", 1)
    self.namelen = 4
    self.pools = []
    for p in config.pools:
      p = Pool(p)
      p.buffer = getattr(p, "buffer", self.buffer)
      p.getworktimeout = getattr(p, "getworktimeout", self.getworktimeout)
      p.sendsharetimeout = getattr(p, "sendsharetimeout", self.sendsharetimeout)
      p.longpolltimeout = getattr(p, "longpolltimeout", self.longpolltimeout)
      p.retrystales = getattr(p, "retrystales", self.retrystales)
      p.username = getattr(p, "username", "")
      p.password = getattr(p, "password", "")
      p.auth = "Basic " + base64.b64encode(p.username + ":" + p.password)
      p.servers = getattr(p, "servers", [])
      servers = []
      for s in p.servers:
        s = Server(s)
        if not hasattr(s, "host"): continue
        s.port = getattr(s, "port", 8332)
        s.path = getattr(s, "path", "/")
        s.disabled = 0
        servers.append(s)
      if len(servers) == 0: continue
      p.servers = servers
      p.name = getattr(p, "name", p.servers[0].host)
      if len(p.name) > self.namelen: self.namelen = len(p.name)
      p.requests = 0
      p.failedreqs = 0
      p.uploadretries = 0
      p.longpollkilled = 0
      p.jobsaccepted = 0
      p.accepted = 0
      p.rejected = 0
      p.queue = Queue.Queue(p.buffer)
      p.miner = self
      p.longpolling = False
      p.longpollhit = False
      p.longpollingthread = None
      self.pools.append(p)
    self.job = None
    self.lastlongpoll = datetime.datetime.utcnow()
    self.fpgaspuriousack = False
    print "Connecting to FPGA \n"
    self.fpga = Logibone()
    self.fpga.reset();
    self.log("Measuring FPGA performance... ")
    starttime = datetime.datetime.utcnow()
    self.mine(Job(None, binascii.unhexlify("1625cbf1a5bc6ba648d1218441389e00a9dc79768a2fc6f2b79c70cf576febd0"), "\0" * 64 + binascii.unhexlify("4c0afa494de837d81a269421"), binascii.unhexlify("7bc2b302")))
    endtime = datetime.datetime.utcnow()
    delta = (endtime - starttime).total_seconds() - 0.0145
    self.mhps = 45.335163 / delta
    delta = min(60, delta * 94.738)
    self.log("%f MH/s\n" % self.mhps)
    self.fpgajobinterval = min(self.fpgajobinterval, max(0.5, delta * 0.8 - 1))
    self.fpgapollinterval = min(self.fpgapollinterval, self.fpgajobinterval / 5)
    self.log("FPGA job interval: ")
    self.log("%f seconds\n" % self.fpgajobinterval)
    for p in self.pools:
      p.thread = threading.Thread(None, p.getwork, p.name + "_getwork")
      p.thread.daemon = True
      p.thread.start()
    self.worker = threading.Thread(None, self.worker, "FPGA worker")
    self.worker.daemon = True
    self.worker.start()
    while True:
      if self.rc != 0: exit(self.rc)
      self.showstats()
      time.sleep(1)

  def worker(self):
    while True:
      job = None
      for p in self.pools:
        try:
          job = p.queue.get(False)
          p.jobsaccepted = p.jobsaccepted + 1
          break
        except: pass
      if job == None:
        self.log("Miner is idle!\n")
        time.sleep(1)
        continue
      self.mine(job)

  def mine(self, job, inject = False):
    if job.pool != None: self.log("Mining: %s:%s:%s\n" % (job.pool.name, binascii.hexlify(job.state), binascii.hexlify(job.data[64:76])))
    self.fpgalock.acquire()
    self.fpga.reset()
    self.fpga.write(job.state[::-1] + job.data[75:63:-1])
    if inject:
      self.job = job
      self.jobtimeout = datetime.datetime.utcnow() + datetime.timedelta(seconds = self.fpgajobinterval)
      self.fpgalock.release()
      return
    self.fpga.timeout = 1
    self.job = job
    self.jobtimeout = datetime.datetime.utcnow() + datetime.timedelta(seconds = self.fpgajobinterval)
    self.fpgalock.release()
    while True:
      if self.jobtimeout <= datetime.datetime.utcnow(): break
      self.fpga.timeout = self.fpgapollinterval
      self.fpga.getAvailable()
      resp = self.fpga.readState()
      #print "FPGA state :"+ str(resp)
      if resp[3] == 0: continue
      if resp[3] == 1:
        self.fpga.timeout = 1
      	nonce = self.fpga.readResult(); # getting result
      	print "nonce = %s \n" % binascii.hexlify(nonce)
        if self.job.check != None and self.job.check != nonce:
		self.die(6, "FPGA is not working correctly (returned %s instead of %s)\n" % (binascii.hexlify(nonce), binascii.hexlify(self.job.check)))
	if self.job.pool != None:
		self.job.pool.sendresult(self.job, nonce)
                break
	if self.job.check != None: break
        continue
	if resp[2] == 1:
	        self.log("FPGA exhausted keyspace!\n")
        break
        self.die(4, "Got bad message from FPGA: %d\n" % result)


if __name__ == "__main__":
  import config
  from logibone import Logibone
  miner = Miner(config, open("miner.log", "a"))
  try:
    miner.run()
  except KeyboardInterrupt:
    print("Terminated by Ctrl+C")
    exit(0)


