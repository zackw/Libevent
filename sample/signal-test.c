/*
 * Compile with:
 * cc -I/usr/local/include -o signal-test \
 *   signal-test.c -L/usr/local/lib -levent
 */

#include <event2/event.h>
#include <stdio.h>
#include <signal.h>
#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <winsock2.h>
#endif

#ifdef EVENT____func__
#define __func__ EVENT____func__
#endif

int called = 0;

static void
signal_cb(evutil_socket_t fd, short event, void *arg)
{
	struct event *signal = arg;

	printf("%s: got signal %d\n", __func__, event_get_signal(signal));

	if (called >= 2)
		event_del(signal);

	called++;
}

int
main(int argc, char **argv)
{
	struct event *signal_int;
	struct event_base* base;
#ifdef _WIN32
	WORD wVersionRequested;
	WSADATA wsaData;

	wVersionRequested = MAKEWORD(2, 2);

	(void) WSAStartup(wVersionRequested, &wsaData);
#endif

	/* Initalize the event library */
	base = event_base_new();

	/* Initalize one event */
	signal_int = evsignal_new(base, SIGINT, signal_cb, event_self_cbarg());

	event_add(signal_int, NULL);

	event_base_dispatch(base);
	event_base_free(base);

	return (0);
}

