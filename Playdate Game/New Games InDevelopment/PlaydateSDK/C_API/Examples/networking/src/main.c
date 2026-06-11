//
//  main.c
//  Extension
//
//  Created by Dave Hayden on 7/30/14.
//  Copyright (c) 2014 Panic, Inc. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>

#include "pd_api.h"

PlaydateAPI* pd;
static int update(void* userdata);

const struct playdate_http* http;
const struct playdate_tcp* tcp;

#ifdef _WINDLL
__declspec(dllexport)
#endif
int eventHandler(PlaydateAPI* playdate, PDSystemEvent event, uint32_t arg)
{
	(void)arg; // arg is currently only used for event = kEventKeyPressed

	if ( event == kEventInit )
	{
		pd = playdate;
		pd->system->setUpdateCallback(update, pd);
		
		http = pd->network->http;
		tcp = pd->network->tcp;
	}
	
	return 0;
}

enum {
	kRequestingHTTPAccess,
	kWaitingForHTTPAccess,
	kHTTPGet,
	kWaitingForHTTPResponse,
	
	kRequestingTCPAccess,
	kWaitingForTCPAccess,
	kTCPGet,
	kWaitingForTCPResponse,
} state = kRequestingHTTPAccess;


// --- HTTP ---

HTTPConnection* httpconn;

void HTTPAccessCallback(bool allowed, void* userdata)
{
	pd->system->logToConsole("HTTPAccessCallback: %i", allowed);
	state = kHTTPGet;
}

void headerReceivedCallback(HTTPConnection* conn, const char* header, const char* value)
{
	pd->system->logToConsole("header: %s = %s", header, value);
//	connected = true;
}

void headersReadCallback(HTTPConnection* conn)
{
	pd->system->logToConsole("headers read");
}

void HTTPRequestCompleteCallback(HTTPConnection* conn)
{
	int avail = http->getBytesAvailable(conn);
	PDNetErr err = http->getError(conn);
	
	if ( err != NET_OK )
		pd->system->logToConsole("http request complete, err=%i", err);
	else
		pd->system->logToConsole("http request complete, %i bytes available", avail);
	
	while ( avail > 0 )
	{
		char buf[256];
		int n = http->read(conn, buf, sizeof(buf));
		
		if ( n > 0 )
			pd->system->logToConsole("%.*s", n, buf);
		
		avail = http->getBytesAvailable(conn);
	}

	state = kRequestingTCPAccess;
}

void HTTPConnectionClosedCallback(HTTPConnection* conn)
{
	pd->system->logToConsole("connection closed");
}

static void requestHTTP(void)
{
	httpconn = http->newConnection("localhost", 65433, false);
	http->setHeaderReceivedCallback(httpconn, headerReceivedCallback);
	http->setHeadersReadCallback(httpconn, headersReadCallback);
	http->setRequestCompleteCallback(httpconn, HTTPRequestCompleteCallback);
	http->setConnectionClosedCallback(httpconn, HTTPConnectionClosedCallback);

	PDNetErr err = http->get(httpconn, "/PING", NULL, 0);
	pd->system->logToConsole("http->get() err=%i", err);
}


// --- TCP ---

TCPConnection* tcpconn;

void TCPAccessCallback(bool allowed, void* userdata)
{
	pd->system->logToConsole("TCPAccessCallback: %i", allowed);
	state = kTCPGet;
}

void TCPConnectionClosedCallback(TCPConnection* conn, PDNetErr err)
{
	pd->system->logToConsole("TCP connection closed");

	int avail = tcp->getBytesAvailable(conn);
	
	if ( err != NET_OK )
		pd->system->logToConsole("tcp request complete, err=%i", err);
	else
		pd->system->logToConsole("tcp request complete, %i bytes available", avail);
	
	while ( avail > 0 )
	{
		char buf[256];
		int n = tcp->read(conn, buf, sizeof(buf));
		pd->system->logToConsole("%.*s", n, buf);
		avail = tcp->getBytesAvailable(conn);
	}

	state = kRequestingTCPAccess;
}

void tcpOpenCallback(TCPConnection* conn, PDNetErr err, void* ud)
{
	pd->system->logToConsole("TCP connection open, sending PING");
	tcp->write(conn, "PING\n", 5);
}

static void requestTCP(void)
{
	tcpconn = tcp->newConnection("localhost", 65431, false);
	tcp->setConnectionClosedCallback(tcpconn, TCPConnectionClosedCallback);

	PDNetErr err = tcp->open(tcpconn, tcpOpenCallback, NULL);
	pd->system->logToConsole("tcp->get() err=%i", err);
}

static int update(void* userdata)
{
	switch ( state )
	{
		case kRequestingHTTPAccess:
			http->requestAccess("localhost", 65433, false, "for testing", HTTPAccessCallback, NULL);
			state = kWaitingForHTTPAccess;
			break;
			
		case kWaitingForHTTPAccess:
			break;
			
		case kHTTPGet:
			requestHTTP();
			state = kWaitingForHTTPResponse;
			break;
			
		case kWaitingForHTTPResponse:
			break;
			
		case kRequestingTCPAccess:
			tcp->requestAccess("localhost", 65431, false, "for testing", TCPAccessCallback, NULL);
			break;
		
		case kWaitingForTCPAccess:
			break;
			
		case kTCPGet:
			requestTCP();
			state = kWaitingForTCPResponse;
			break;
			
		case kWaitingForTCPResponse:
			break;
	}
	
	return 1;
}

