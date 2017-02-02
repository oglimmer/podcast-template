#!/usr/bin/python

import urllib2
import sys
import json
import datetime

authToken = sys.argv[1]

today = datetime.date.today() - datetime.timedelta(days=30)
toComp =  "%d-%02d-%02d" % (today.year, today.month, today.day)

req = urllib2.Request('https://www.googleapis.com/drive/v2/files')
req.add_header('Authorization', 'Bearer '+authToken)
r = urllib2.urlopen(req)
allDocs = r.read()

allDocsJson = json.loads(allDocs);

for rec in allDocsJson['items']:
	createDate = rec['createdDate']
	if createDate < toComp:
		mimeType = rec['mimeType']		
		if mimeType != 'application/vnd.google-apps.folder':
			fileId = rec['id']
			originalFilename = rec['originalFilename']
			#print "delete %s (created : %s)" % (originalFilename, createDate)		
			req = urllib2.Request('https://www.googleapis.com/drive/v2/files/'+fileId)
			req.add_header('Authorization', 'Bearer '+authToken)
			req.get_method = lambda: 'DELETE'
			r = urllib2.urlopen(req)
			answer = r.read()
			#print answer


