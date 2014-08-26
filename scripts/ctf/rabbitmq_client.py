#!/usr/bin/env python

import pika
import requests
import simplejson as json
import pprint

class RabbitMQClient(object):

	"""RabbitMQ client that uses the Management Plugin HTTP API."""

	def __init__(self, port=15672):
		self.base_url = 'http://localhost:%d' % port
		self.session = requests.Session()
		self.session.headers = {'Content-Type': 'application/json'}
		self.UseCredentials('guest', 'guest')

	def CreateQueue(self, vhost, queue):
		"""Create a queue in the specified vhost."""
		api_url = '/api/queues/%s/%s' % (vhost, queue)
		data = json.dumps({'durable': False})
		self.session.put(self.base_url + api_url, data=data)

	def CreateExchange(self, vhost, exchange):
		"""Create an exchange in the specified vhost."""
		api_url = '/api/exchanges/%s/%s' % (vhost, exchange)
		data = json.dumps({'type': 'topic'})
		self.session.put(self.base_url + api_url, data=data)

	def CreateBinding(self, vhost, exchange, queue, routing_key):
		"""Bind a queue to an exchange with the specified routing key."""
		api_url = '/api/bindings/%s/e/%s/q/%s' % (vhost, exchange, queue)
		data = json.dumps({'routing_key': routing_key})
		self.session.post(self.base_url + api_url, data=data)

	def GetMessages(self, vhost, queue, num_messages):
		"""Get the specified number messages from a queue.

		Returns: List of messages (list of dict (JSON objects))
		"""
		api_url = '/api/queues/%s/%s/get' % (vhost, queue)
		data = json.dumps({'count': num_messages, 'requeue': False, 'encoding': 'auto'})
		response = self.session.post(self.base_url + api_url, data=data)
		# parse_float is used here so that floats are handled with full precision.
		response_json = json.loads(response.text, parse_float=decimal.Decimal)
		LOGGER.debug(response_json)
		return [msg['payload'] for msg in response_json]

	def UseCredentials(self, username, password):
		"""Sets the credentials to be used by this client."""
		self.session.auth = (username, password)

	def ListExchanges(self):
		api_url = '/api/exchanges'
		data = self.session.get(self.base_url + api_url)
		return json.loads(data.content)


if __name__ == '__main__':
	p = RabbitMQClient()
	exchanges = p.ListExchanges()
	for i in exchanges:
		if i['vhost'] == '/rsa/sa' and i['name'] == 'carlos.alerts':
			print i
